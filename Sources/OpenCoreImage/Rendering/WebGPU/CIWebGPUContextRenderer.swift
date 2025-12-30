//
//  CIWebGPUContextRenderer.swift
//  OpenCoreImage
//
//  WebGPU-based implementation of CIContextRenderer for WASM environments.
//

#if arch(wasm32)
import Foundation
import JavaScriptKit
import SwiftWebGPU
import OpenCoreGraphics

/// WebGPU-based implementation of `CIContextRenderer`.
///
/// This class receives rendering commands from `CIContext` and renders them using WebGPU.
/// It handles the complete rendering pipeline including:
/// - Filter graph compilation
/// - Texture management
/// - GPU command submission
/// - Result readback
///
/// This renderer is configured automatically by CIContext on WASM architecture.
/// Users interact with the standard CoreImage API without needing to configure
/// the renderer directly.
///
/// ## Usage
///
/// ```swift
/// // On WASM, CIContext automatically uses WebGPU for rendering
/// let context = CIContext()
/// let cgImage = try await context.createCGImageAsync(outputImage, from: rect)
/// ```
internal final class CIWebGPUContextRenderer: CIContextRenderer, @unchecked Sendable {

    // MARK: - Properties

    /// The WebGPU device.
    private var device: GPUDevice?

    /// The GPU queue for submitting commands.
    private var queue: GPUQueue?

    /// Task for GPU initialization.
    private var gpuInitTask: Task<GPUDevice, Error>?

    /// Context options.
    private let options: [CIContextOption: Any]

    // MARK: - Initialization

    /// Creates a new WebGPU context renderer.
    ///
    /// - Parameter options: Context options.
    init(options: [CIContextOption: Any]?) {
        self.options = options ?? [:]
        startGPUInitialization()
    }

    /// Starts GPU initialization in the background.
    private func startGPUInitialization() {
        gpuInitTask = Task {
            try await GPUContextManager.shared.getDevice()
        }
    }

    /// Returns the GPU device, waiting for initialization if needed.
    private func getGPUDevice() async throws -> GPUDevice {
        if let device = device {
            return device
        }
        if let task = gpuInitTask {
            device = try await task.value
            return device!
        }
        device = try await GPUContextManager.shared.getDevice()
        return device!
    }

    // MARK: - CIContextRenderer

    func render(
        image: CIImage,
        to rect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) async throws -> CIRenderResult {
        let device = try await getGPUDevice()
        let queue = try await GPUContextManager.shared.getQueue()

        let width = Int(rect.width)
        let height = Int(rect.height)

        // Handle solid color images
        if let color = image._color, image._filters.isEmpty {
            let pixelData = createSolidColorData(color: color, width: width, height: height)
            guard let cgImage = createCGImageFromPixelData(
                pixelData,
                width: width,
                height: height,
                colorSpace: colorSpace
            ) else {
                throw CIError.renderingFailed
            }
            return CIRenderResult(pixelData: pixelData, width: width, height: height, cgImage: cgImage)
        }

        // Handle direct CGImage source with no filters
        if let cgImage = image.cgImage, image._filters.isEmpty {
            let pixelData = extractPixelData(from: cgImage, width: width, height: height)
            return CIRenderResult(pixelData: pixelData, width: width, height: height, cgImage: cgImage)
        }

        // Build filter graph DAG to get source images
        var builder = FilterGraphBuilder()
        let filterGraph = builder.build(from: image)

        // Compile and execute filter graph
        let compiledGraph = try await FilterGraphCompiler.shared.compile(
            image: image,
            outputRect: rect,
            device: device
        )

        // Upload all source textures
        try await uploadSourceTextures(
            filterGraph: filterGraph,
            compiledGraph: compiledGraph,
            rect: rect,
            device: device,
            queue: queue
        )

        // Execute filter chain on GPU
        try await executeFilterGraph(
            graph: compiledGraph,
            device: device,
            queue: queue
        )

        // Read back result from GPU
        let pixelData = try await readbackTexture(
            texture: compiledGraph.textures[compiledGraph.outputTextureIndex],
            width: UInt32(width),
            height: UInt32(height),
            device: device,
            queue: queue
        )

        // Release textures back to pool
        for texture in compiledGraph.textures {
            await GPUTexturePool.shared.release(
                texture,
                width: compiledGraph.width,
                height: compiledGraph.height,
                format: .rgba8unorm
            )
        }

        // Create CGImage from pixel data
        guard let cgImage = createCGImageFromPixelData(
            pixelData,
            width: width,
            height: height,
            colorSpace: colorSpace
        ) else {
            throw CIError.renderingFailed
        }

        return CIRenderResult(pixelData: pixelData, width: width, height: height, cgImage: cgImage)
    }

    func clearCaches() {
        Task {
            await GPUTexturePool.shared.clear()
            await GPUPipelineCache.shared.clear()
        }
    }

    func reclaimResources() {
        Task {
            await GPUTexturePool.shared.clear()
        }
    }

    // MARK: - Private Rendering Methods

    private func uploadSourceTextures(
        filterGraph: FilterGraph,
        compiledGraph: CompiledFilterGraph,
        rect: CGRect,
        device: GPUDevice,
        queue: GPUQueue
    ) async throws {
        let width = Int(rect.width)
        let height = Int(rect.height)

        // Upload each source texture
        for (sourceNodeId, textureIndex) in compiledGraph.sourceTextureIndices {
            guard let sourceNode = filterGraph.nodes[sourceNodeId],
                  let sourceImage = sourceNode.sourceImage else {
                continue
            }

            let texture = compiledGraph.textures[textureIndex]

            // Get pixel data from source image (may decode on-demand)
            // Handle infinite extent images (generators, CIImage(color:), etc.)
            let sourceExtent = sourceImage.extent
            let sourceWidth: Int
            let sourceHeight: Int

            if sourceExtent.isInfinite || sourceExtent.width.isInfinite || sourceExtent.height.isInfinite {
                // Use render target dimensions for infinite extent images
                sourceWidth = width
                sourceHeight = height
            } else {
                sourceWidth = Int(sourceExtent.width)
                sourceHeight = Int(sourceExtent.height)
            }

            let pixelData = try await getPixelData(
                from: sourceImage,
                sourceWidth: sourceWidth,
                sourceHeight: sourceHeight,
                targetWidth: width,
                targetHeight: height,
                targetRect: rect
            )

            // GPU textures are always RGBA8 (4 bytes per pixel)
            // The getPixelData method must convert any source format to RGBA8
            let gpuBytesPerPixel = 4

            // Convert Data to JavaScript Uint8Array for WebGPU (optimized bulk transfer)
            let jsData = JSDataTransfer.toUint8Array(pixelData)

            // Write to texture
            queue.writeTexture(
                destination: GPUImageCopyTexture(texture: texture),
                data: jsData,
                dataLayout: GPUImageDataLayout(
                    bytesPerRow: UInt32(width * gpuBytesPerPixel),
                    rowsPerImage: UInt32(height)
                ),
                size: GPUExtent3D(
                    width: UInt32(width),
                    height: UInt32(height),
                    depthOrArrayLayers: 1
                )
            )
        }
    }

    /// Gets pixel data from a CIImage, handling cropping and format conversion.
    ///
    /// - Parameters:
    ///   - image: The source CIImage.
    ///   - sourceWidth: The width of the source image in pixels.
    ///   - sourceHeight: The height of the source image in pixels.
    ///   - targetWidth: The desired output width.
    ///   - targetHeight: The desired output height.
    ///   - targetRect: The region to extract from the source image (in image coordinates).
    /// - Returns: Pixel data in RGBA8 format suitable for GPU upload.
    ///
    /// - Note: This method always returns data in RGBA8 format (4 bytes per pixel)
    ///   regardless of the source format, as GPU textures are created as rgba8unorm.
    private func getPixelData(
        from image: CIImage,
        sourceWidth: Int,
        sourceHeight: Int,
        targetWidth: Int,
        targetHeight: Int,
        targetRect: CGRect
    ) async throws -> Data {
        // Get the raw pixel data from the image
        let rawData: Data
        let rawWidth: Int
        let rawHeight: Int
        let sourceFormat: CIFormat = image._format ?? .RGBA8
        let sourceBytesPerPixel: Int = sourceFormat.bytesPerPixel

        // First priority: decoded pixel data
        if let pixelData = image._pixelData, !pixelData.isEmpty {
            rawData = pixelData
            rawWidth = sourceWidth
            rawHeight = sourceHeight
        }
        // Second priority: CGImage source
        else if let cgImage = image.cgImage {
            // extractPixelData always returns RGBA8
            rawData = extractPixelData(from: cgImage, width: cgImage.width, height: cgImage.height)
            rawWidth = cgImage.width
            rawHeight = cgImage.height
            // Skip format conversion since extractPixelData returns RGBA8
            return processAndCrop(
                rawData,
                rawWidth: rawWidth,
                rawHeight: rawHeight,
                sourceBytesPerPixel: 4,  // Already RGBA8
                sourceFormat: .RGBA8,
                targetWidth: targetWidth,
                targetHeight: targetHeight,
                targetRect: targetRect
            )
        }
        // Third priority: solid color
        else if let color = image._color {
            // For solid colors, generate at target size directly (RGBA8)
            return createSolidColorData(color: color, width: targetWidth, height: targetHeight)
        }
        // Fourth priority: decode from raw image data on-demand
        else if let rawImageData = image._data, !rawImageData.isEmpty {
            let decoded = try await ImageDecoder.decode(rawImageData)
            // ImageDecoder returns RGBA8
            return processAndCrop(
                decoded.pixelData,
                rawWidth: decoded.width,
                rawHeight: decoded.height,
                sourceBytesPerPixel: 4,  // Decoded data is RGBA8
                sourceFormat: .RGBA8,
                targetWidth: targetWidth,
                targetHeight: targetHeight,
                targetRect: targetRect
            )
        }
        // Fallback: transparent pixels (RGBA8)
        else {
            return Data(count: targetWidth * targetHeight * 4)
        }

        // Process and crop the raw data, converting to RGBA8 if needed
        return processAndCrop(
            rawData,
            rawWidth: rawWidth,
            rawHeight: rawHeight,
            sourceBytesPerPixel: sourceBytesPerPixel,
            sourceFormat: sourceFormat,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            targetRect: targetRect
        )
    }

    /// Processes pixel data: crops and converts to RGBA8 format.
    private func processAndCrop(
        _ rawData: Data,
        rawWidth: Int,
        rawHeight: Int,
        sourceBytesPerPixel: Int,
        sourceFormat: CIFormat,
        targetWidth: Int,
        targetHeight: Int,
        targetRect: CGRect
    ) -> Data {
        // Check if we need to crop
        let needsCrop = Int(targetRect.origin.x) != 0 ||
                        Int(targetRect.origin.y) != 0 ||
                        targetWidth != rawWidth ||
                        targetHeight != rawHeight

        // Check if we need format conversion
        // This includes formats with different byte order (BGRA, ARGB, ABGR) even if 4 BPP
        let needsConversion = requiresFormatConversion(sourceFormat)

        if !needsCrop && !needsConversion {
            return rawData
        }

        if needsConversion {
            // Convert to RGBA8 first, then crop
            let convertedData = convertToRGBA8(
                rawData,
                width: rawWidth,
                height: rawHeight,
                sourceFormat: sourceFormat
            )
            if !needsCrop {
                return convertedData
            }
            return cropPixelData(
                convertedData,
                sourceWidth: rawWidth,
                sourceHeight: rawHeight,
                bytesPerPixel: 4,  // Now RGBA8
                cropRect: targetRect
            )
        } else {
            // Just crop
            return cropPixelData(
                rawData,
                sourceWidth: rawWidth,
                sourceHeight: rawHeight,
                bytesPerPixel: 4,
                cropRect: targetRect
            )
        }
    }

    /// Checks if a format requires conversion to RGBA8.
    private func requiresFormatConversion(_ format: CIFormat) -> Bool {
        switch format {
        case .RGBA8:
            // Already RGBA8, no conversion needed
            return false
        default:
            // All other formats need conversion
            return true
        }
    }

    /// Converts pixel data from various formats to RGBA8.
    ///
    /// Handles all CIFormat types with proper channel reordering and bit depth conversion.
    private func convertToRGBA8(
        _ data: Data,
        width: Int,
        height: Int,
        sourceFormat: CIFormat
    ) -> Data {
        let targetBytesPerPixel = 4
        var result = Data(count: width * height * targetBytesPerPixel)
        let resultCount = result.count  // Copy to local to avoid overlapping access

        data.withUnsafeBytes { srcPtr in
            result.withUnsafeMutableBytes { destPtr in
                guard let srcBase = srcPtr.baseAddress,
                      let destBase = destPtr.baseAddress else { return }

                let srcBytes = srcBase.assumingMemoryBound(to: UInt8.self)
                let destBytes = destBase.assumingMemoryBound(to: UInt8.self)

                let sourceBytesPerPixel = sourceFormat.bytesPerPixel
                let pixelCount = width * height

                switch sourceFormat {
                // MARK: - 8-bit RGBA variants
                case .RGBA8:
                    // No conversion needed
                    memcpy(destBase, srcBase, min(data.count, resultCount))

                case .BGRA8:
                    // BGRA -> RGBA: swap B and R
                    for i in 0..<pixelCount {
                        let srcOffset = i * 4
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = srcBytes[srcOffset + 2]  // R from B
                        destBytes[destOffset + 1] = srcBytes[srcOffset + 1]  // G
                        destBytes[destOffset + 2] = srcBytes[srcOffset + 0]  // B from R
                        destBytes[destOffset + 3] = srcBytes[srcOffset + 3]  // A
                    }

                case .ARGB8:
                    // ARGB -> RGBA: rotate channels
                    for i in 0..<pixelCount {
                        let srcOffset = i * 4
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = srcBytes[srcOffset + 1]  // R
                        destBytes[destOffset + 1] = srcBytes[srcOffset + 2]  // G
                        destBytes[destOffset + 2] = srcBytes[srcOffset + 3]  // B
                        destBytes[destOffset + 3] = srcBytes[srcOffset + 0]  // A
                    }

                case .ABGR8:
                    // ABGR -> RGBA: reverse and rotate
                    for i in 0..<pixelCount {
                        let srcOffset = i * 4
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = srcBytes[srcOffset + 3]  // R from last
                        destBytes[destOffset + 1] = srcBytes[srcOffset + 2]  // G
                        destBytes[destOffset + 2] = srcBytes[srcOffset + 1]  // B
                        destBytes[destOffset + 3] = srcBytes[srcOffset + 0]  // A from first
                    }

                case .RGBX8:
                    // RGBX -> RGBA: copy RGB, set A to 255
                    for i in 0..<pixelCount {
                        let srcOffset = i * 4
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = srcBytes[srcOffset + 0]  // R
                        destBytes[destOffset + 1] = srcBytes[srcOffset + 1]  // G
                        destBytes[destOffset + 2] = srcBytes[srcOffset + 2]  // B
                        destBytes[destOffset + 3] = 255  // A = opaque
                    }

                // MARK: - 16-bit formats
                case .RGBA16:
                    // Convert 16-bit to 8-bit RGBA
                    let srcU16 = srcBase.assumingMemoryBound(to: UInt16.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 4  // 4 components per pixel
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = UInt8(srcU16[srcOffset + 0] >> 8)
                        destBytes[destOffset + 1] = UInt8(srcU16[srcOffset + 1] >> 8)
                        destBytes[destOffset + 2] = UInt8(srcU16[srcOffset + 2] >> 8)
                        destBytes[destOffset + 3] = UInt8(srcU16[srcOffset + 3] >> 8)
                    }

                case .RGBX16:
                    // Convert 16-bit to 8-bit, ignore X, set A to 255
                    let srcU16 = srcBase.assumingMemoryBound(to: UInt16.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 4
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = UInt8(srcU16[srcOffset + 0] >> 8)
                        destBytes[destOffset + 1] = UInt8(srcU16[srcOffset + 1] >> 8)
                        destBytes[destOffset + 2] = UInt8(srcU16[srcOffset + 2] >> 8)
                        destBytes[destOffset + 3] = 255
                    }

                // MARK: - Float formats
                case .RGBAf:
                    // Convert float to 8-bit RGBA
                    let srcF32 = srcBase.assumingMemoryBound(to: Float.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 4
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = floatToUInt8(srcF32[srcOffset + 0])
                        destBytes[destOffset + 1] = floatToUInt8(srcF32[srcOffset + 1])
                        destBytes[destOffset + 2] = floatToUInt8(srcF32[srcOffset + 2])
                        destBytes[destOffset + 3] = floatToUInt8(srcF32[srcOffset + 3])
                    }

                case .rgbXf:
                    // Convert float RGB to 8-bit, ignore X, set A to 255
                    let srcF32 = srcBase.assumingMemoryBound(to: Float.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 4
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = floatToUInt8(srcF32[srcOffset + 0])
                        destBytes[destOffset + 1] = floatToUInt8(srcF32[srcOffset + 1])
                        destBytes[destOffset + 2] = floatToUInt8(srcF32[srcOffset + 2])
                        destBytes[destOffset + 3] = 255
                    }

                // MARK: - Half-float formats
                case .RGBAh:
                    // Convert half-float to 8-bit RGBA
                    let srcU16 = srcBase.assumingMemoryBound(to: UInt16.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 4
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = halfToUInt8(srcU16[srcOffset + 0])
                        destBytes[destOffset + 1] = halfToUInt8(srcU16[srcOffset + 1])
                        destBytes[destOffset + 2] = halfToUInt8(srcU16[srcOffset + 2])
                        destBytes[destOffset + 3] = halfToUInt8(srcU16[srcOffset + 3])
                    }

                case .rgbXh:
                    let srcU16 = srcBase.assumingMemoryBound(to: UInt16.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 4
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = halfToUInt8(srcU16[srcOffset + 0])
                        destBytes[destOffset + 1] = halfToUInt8(srcU16[srcOffset + 1])
                        destBytes[destOffset + 2] = halfToUInt8(srcU16[srcOffset + 2])
                        destBytes[destOffset + 3] = 255
                    }

                // MARK: - Single channel formats (Luminance/Red)
                case .R8, .L8:
                    // Single channel 8-bit -> grayscale RGBA
                    for i in 0..<pixelCount {
                        let v = srcBytes[i]
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = v  // R
                        destBytes[destOffset + 1] = v  // G
                        destBytes[destOffset + 2] = v  // B
                        destBytes[destOffset + 3] = 255  // A
                    }

                case .A8:
                    // Alpha only -> transparent white with varying alpha
                    for i in 0..<pixelCount {
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = 255  // R
                        destBytes[destOffset + 1] = 255  // G
                        destBytes[destOffset + 2] = 255  // B
                        destBytes[destOffset + 3] = srcBytes[i]  // A
                    }

                case .R16, .L16:
                    // Single channel 16-bit -> grayscale RGBA
                    let srcU16 = srcBase.assumingMemoryBound(to: UInt16.self)
                    for i in 0..<pixelCount {
                        let v = UInt8(srcU16[i] >> 8)
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = v
                        destBytes[destOffset + 1] = v
                        destBytes[destOffset + 2] = v
                        destBytes[destOffset + 3] = 255
                    }

                case .Rf, .Lf:
                    // Single channel float -> grayscale RGBA
                    let srcF32 = srcBase.assumingMemoryBound(to: Float.self)
                    for i in 0..<pixelCount {
                        let v = floatToUInt8(srcF32[i])
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = v
                        destBytes[destOffset + 1] = v
                        destBytes[destOffset + 2] = v
                        destBytes[destOffset + 3] = 255
                    }

                case .Rh, .Lh:
                    // Single channel half-float -> grayscale RGBA
                    let srcU16 = srcBase.assumingMemoryBound(to: UInt16.self)
                    for i in 0..<pixelCount {
                        let v = halfToUInt8(srcU16[i])
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = v
                        destBytes[destOffset + 1] = v
                        destBytes[destOffset + 2] = v
                        destBytes[destOffset + 3] = 255
                    }

                // MARK: - Two channel formats (RG/LA)
                case .RG8:
                    // RG -> RG00 with A=255
                    for i in 0..<pixelCount {
                        let srcOffset = i * 2
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = srcBytes[srcOffset + 0]  // R
                        destBytes[destOffset + 1] = srcBytes[srcOffset + 1]  // G
                        destBytes[destOffset + 2] = 0  // B
                        destBytes[destOffset + 3] = 255  // A
                    }

                case .LA8:
                    // LA -> grayscale with alpha
                    for i in 0..<pixelCount {
                        let srcOffset = i * 2
                        let destOffset = i * 4
                        let l = srcBytes[srcOffset + 0]
                        destBytes[destOffset + 0] = l  // R
                        destBytes[destOffset + 1] = l  // G
                        destBytes[destOffset + 2] = l  // B
                        destBytes[destOffset + 3] = srcBytes[srcOffset + 1]  // A
                    }

                case .RG16:
                    let srcU16 = srcBase.assumingMemoryBound(to: UInt16.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 2
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = UInt8(srcU16[srcOffset + 0] >> 8)
                        destBytes[destOffset + 1] = UInt8(srcU16[srcOffset + 1] >> 8)
                        destBytes[destOffset + 2] = 0
                        destBytes[destOffset + 3] = 255
                    }

                case .LA16:
                    let srcU16 = srcBase.assumingMemoryBound(to: UInt16.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 2
                        let destOffset = i * 4
                        let l = UInt8(srcU16[srcOffset + 0] >> 8)
                        destBytes[destOffset + 0] = l
                        destBytes[destOffset + 1] = l
                        destBytes[destOffset + 2] = l
                        destBytes[destOffset + 3] = UInt8(srcU16[srcOffset + 1] >> 8)
                    }

                case .RGf:
                    let srcF32 = srcBase.assumingMemoryBound(to: Float.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 2
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = floatToUInt8(srcF32[srcOffset + 0])
                        destBytes[destOffset + 1] = floatToUInt8(srcF32[srcOffset + 1])
                        destBytes[destOffset + 2] = 0
                        destBytes[destOffset + 3] = 255
                    }

                case .LAf:
                    let srcF32 = srcBase.assumingMemoryBound(to: Float.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 2
                        let destOffset = i * 4
                        let l = floatToUInt8(srcF32[srcOffset + 0])
                        destBytes[destOffset + 0] = l
                        destBytes[destOffset + 1] = l
                        destBytes[destOffset + 2] = l
                        destBytes[destOffset + 3] = floatToUInt8(srcF32[srcOffset + 1])
                    }

                case .RGh:
                    let srcU16 = srcBase.assumingMemoryBound(to: UInt16.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 2
                        let destOffset = i * 4
                        destBytes[destOffset + 0] = halfToUInt8(srcU16[srcOffset + 0])
                        destBytes[destOffset + 1] = halfToUInt8(srcU16[srcOffset + 1])
                        destBytes[destOffset + 2] = 0
                        destBytes[destOffset + 3] = 255
                    }

                case .LAh:
                    let srcU16 = srcBase.assumingMemoryBound(to: UInt16.self)
                    for i in 0..<pixelCount {
                        let srcOffset = i * 2
                        let destOffset = i * 4
                        let l = halfToUInt8(srcU16[srcOffset + 0])
                        destBytes[destOffset + 0] = l
                        destBytes[destOffset + 1] = l
                        destBytes[destOffset + 2] = l
                        destBytes[destOffset + 3] = halfToUInt8(srcU16[srcOffset + 1])
                    }

                // MARK: - Packed formats
                case .RGB10:
                    // 10-bit packed RGB: 32-bit word containing 3x10-bit channels + 2 unused bits
                    // Format: [unused:2][B:10][G:10][R:10] or [A:2][B:10][G:10][R:10]
                    // Each 10-bit value (0-1023) is scaled to 8-bit (0-255) by >> 2
                    let srcU32 = srcBase.assumingMemoryBound(to: UInt32.self)
                    for i in 0..<pixelCount {
                        let packed = srcU32[i]
                        let destOffset = i * 4
                        // Extract 10-bit values and convert to 8-bit
                        let r10 = packed & 0x3FF                // bits 0-9
                        let g10 = (packed >> 10) & 0x3FF        // bits 10-19
                        let b10 = (packed >> 20) & 0x3FF        // bits 20-29
                        // Scale from 10-bit (0-1023) to 8-bit (0-255)
                        destBytes[destOffset + 0] = UInt8(r10 >> 2)
                        destBytes[destOffset + 1] = UInt8(g10 >> 2)
                        destBytes[destOffset + 2] = UInt8(b10 >> 2)
                        destBytes[destOffset + 3] = 255
                    }

                default:
                    // Unknown format - best effort copy
                    for i in 0..<pixelCount {
                        let srcOffset = i * sourceBytesPerPixel
                        let destOffset = i * 4
                        let copyBytes = min(sourceBytesPerPixel, 3)
                        for j in 0..<copyBytes {
                            destBytes[destOffset + j] = srcBytes[srcOffset + j]
                        }
                        // Fill remaining with defaults
                        for j in copyBytes..<3 {
                            destBytes[destOffset + j] = 0
                        }
                        destBytes[destOffset + 3] = 255  // A = opaque
                    }
                }
            }
        }

        return result
    }

    /// Converts a float (0.0-1.0) to UInt8 (0-255) with clamping.
    @inline(__always)
    private func floatToUInt8(_ f: Float) -> UInt8 {
        let clamped = max(0.0, min(1.0, f))
        return UInt8(clamped * 255.0)
    }

    /// Converts a half-float (16-bit) to UInt8.
    @inline(__always)
    private func halfToUInt8(_ half: UInt16) -> UInt8 {
        // Simple half-float to float conversion, then to UInt8
        // Half-float format: 1 sign, 5 exponent, 10 mantissa
        let sign = (half >> 15) & 0x1
        let exp = (half >> 10) & 0x1F
        let mant = half & 0x3FF

        var f: Float
        if exp == 0 {
            // Denormalized or zero
            f = Float(mant) / 1024.0 * pow(2.0, -14.0)
        } else if exp == 31 {
            // Inf or NaN
            f = mant == 0 ? Float.infinity : Float.nan
        } else {
            // Normalized
            f = (1.0 + Float(mant) / 1024.0) * pow(2.0, Float(Int(exp) - 15))
        }

        if sign == 1 { f = -f }

        return floatToUInt8(f)
    }

    /// Crops pixel data to the specified rectangle with zero-padding for out-of-bounds regions.
    ///
    /// When `cropRect` extends outside the source image bounds, the result is zero-padded
    /// to maintain the exact requested size (`cropRect.width * cropRect.height * bytesPerPixel`).
    /// This is critical for GPU texture uploads that expect exact buffer sizes.
    private func cropPixelData(
        _ data: Data,
        sourceWidth: Int,
        sourceHeight: Int,
        bytesPerPixel: Int,
        cropRect: CGRect
    ) -> Data {
        let targetWidth = Int(cropRect.width)
        let targetHeight = Int(cropRect.height)
        let targetBytesPerRow = targetWidth * bytesPerPixel

        // Always create a buffer of the exact requested size (zero-initialized)
        var result = Data(count: targetBytesPerRow * targetHeight)

        // Calculate the overlap region between source and cropRect
        let cropOriginX = Int(cropRect.origin.x)
        let cropOriginY = Int(cropRect.origin.y)

        // Source region that overlaps with cropRect
        let srcStartX = max(0, cropOriginX)
        let srcStartY = max(0, cropOriginY)
        let srcEndX = min(sourceWidth, cropOriginX + targetWidth)
        let srcEndY = min(sourceHeight, cropOriginY + targetHeight)

        // Check if there's any overlap
        guard srcStartX < srcEndX && srcStartY < srcEndY else {
            // No overlap - return zero-filled buffer
            return result
        }

        // Calculate where in the destination buffer to place the copied data
        let destStartX = srcStartX - cropOriginX
        let destStartY = srcStartY - cropOriginY
        let copyWidth = srcEndX - srcStartX
        let copyHeight = srcEndY - srcStartY

        let sourceBytesPerRow = sourceWidth * bytesPerPixel
        let copyBytesPerRow = copyWidth * bytesPerPixel

        result.withUnsafeMutableBytes { destPtr in
            data.withUnsafeBytes { srcPtr in
                guard let destBase = destPtr.baseAddress,
                      let srcBase = srcPtr.baseAddress else { return }

                for row in 0..<copyHeight {
                    let srcRow = srcStartY + row
                    let destRow = destStartY + row

                    let srcOffset = srcRow * sourceBytesPerRow + srcStartX * bytesPerPixel
                    let destOffset = destRow * targetBytesPerRow + destStartX * bytesPerPixel

                    // Bounds check
                    guard srcOffset + copyBytesPerRow <= data.count,
                          destOffset + copyBytesPerRow <= result.count else { continue }

                    memcpy(
                        destBase.advanced(by: destOffset),
                        srcBase.advanced(by: srcOffset),
                        copyBytesPerRow
                    )
                }
            }
        }

        return result
    }

    private func executeFilterGraph(
        graph: CompiledFilterGraph,
        device: GPUDevice,
        queue: GPUQueue
    ) async throws {
        guard !graph.nodes.isEmpty else { return }

        let commandEncoder = device.createCommandEncoder()

        for node in graph.nodes {
            let computePass = commandEncoder.beginComputePass()
            computePass.setPipeline(node.pipeline)
            computePass.setBindGroup(0, bindGroup: node.bindGroup)

            // Calculate workgroup counts
            let workgroupSizeX: UInt32 = 16
            let workgroupSizeY: UInt32 = 16
            let workgroupCountX = (graph.width + workgroupSizeX - 1) / workgroupSizeX
            let workgroupCountY = (graph.height + workgroupSizeY - 1) / workgroupSizeY

            computePass.dispatchWorkgroups(
                workgroupCountX: workgroupCountX,
                workgroupCountY: workgroupCountY,
                workgroupCountZ: 1
            )
            computePass.end()
        }

        let commandBuffer = commandEncoder.finish()
        queue.submit([commandBuffer])
    }

    private func readbackTexture(
        texture: GPUTexture,
        width: UInt32,
        height: UInt32,
        device: GPUDevice,
        queue: GPUQueue
    ) async throws -> Data {
        let bytesPerRow = width * 4
        // Align to 256 bytes (WebGPU requirement for buffer copy)
        let alignedBytesPerRow = (bytesPerRow + 255) & ~255
        let bufferSize = UInt64(alignedBytesPerRow * height)

        // Create staging buffer for readback
        let stagingBuffer = device.createBuffer(
            descriptor: GPUBufferDescriptor(
                size: bufferSize,
                usage: [.copyDst, .mapRead]
            )
        )

        // Copy texture to buffer
        let commandEncoder = device.createCommandEncoder()
        commandEncoder.copyTextureToBuffer(
            source: GPUImageCopyTexture(texture: texture),
            destination: GPUImageCopyBuffer(
                buffer: stagingBuffer,
                bytesPerRow: alignedBytesPerRow,
                rowsPerImage: height
            ),
            copySize: GPUExtent3D(width: width, height: height, depthOrArrayLayers: 1)
        )

        let commandBuffer = commandEncoder.finish()
        queue.submit([commandBuffer])

        // Map buffer and read data
        try await stagingBuffer.mapAsync(mode: .read)
        let mappedRangeJS = stagingBuffer.getMappedRange()

        // Convert JSObject (ArrayBuffer) to Data with alignment handling (optimized)
        let uint8Array = JSObject.global.Uint8Array.function!.new(mappedRangeJS)
        let pixelData = JSDataTransfer.toDataWithAlignment(
            uint8Array,
            width: Int(width),
            height: Int(height),
            alignedBytesPerRow: Int(alignedBytesPerRow),
            bytesPerPixel: 4
        )

        stagingBuffer.unmap()

        return pixelData
    }

    // MARK: - Helper Methods

    private func createSolidColorData(color: CIColor, width: Int, height: Int) -> Data {
        let r = UInt8(clamping: Int(color.red * 255))
        let g = UInt8(clamping: Int(color.green * 255))
        let b = UInt8(clamping: Int(color.blue * 255))
        let a = UInt8(clamping: Int(color.alpha * 255))

        var data = Data(capacity: width * height * 4)
        let pixel: [UInt8] = [r, g, b, a]
        for _ in 0..<(width * height) {
            data.append(contentsOf: pixel)
        }
        return data
    }

    private func extractPixelData(from cgImage: CGImage, width: Int, height: Int) -> Data {
        let bytesPerRow = width * 4
        var pixelData = Data(count: bytesPerRow * height)

        pixelData.withUnsafeMutableBytes { ptr in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            ) else { return }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        return pixelData
    }

    private func createCGImageFromPixelData(
        _ data: Data,
        width: Int,
        height: Int,
        colorSpace: CGColorSpace?
    ) -> CGImage? {
        let cs = colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let bytesPerRow = width * 4

        // On WASM, use OpenCoreGraphics which accepts Data directly
        let dataProvider = CGDataProvider(data: data)

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: cs,
            bitmapInfo: bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
#endif
