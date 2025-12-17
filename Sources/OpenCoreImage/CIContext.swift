//
//  CIContext.swift
//  OpenCoreImage
//
//  The Core Image context class provides an evaluation context for Core Image processing.
//

import Foundation

#if arch(wasm32)
import JavaScriptKit
import SwiftWebGPU
#endif

/// The Core Image context class provides an evaluation context for Core Image processing.
///
/// You use a `CIContext` instance to render a `CIImage` instance which represents a graph
/// of image processing operations which are built using other Core Image classes.
///
/// `CIContext` and `CIImage` instances are immutable, so multiple threads can use the same
/// `CIContext` instance to render `CIImage` instances.
public final class CIContext: @unchecked Sendable {

    // MARK: - Internal Storage

    internal let _options: [CIContextOption: Any]
    internal let _workingColorSpace: CGColorSpace?
    internal let _workingFormat: CIFormat

    #if arch(wasm32)
    /// Cached GPU device for rendering.
    private var _gpuDevice: GPUDevice?

    /// Task for GPU initialization.
    private var _gpuInitTask: Task<GPUDevice, Error>?
    #endif

    // MARK: - Initialization

    /// Initializes a context without a specific rendering destination, using default options.
    public init() {
        self._options = [:]
        self._workingColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        self._workingFormat = .RGBAf
        #if arch(wasm32)
        startGPUInitialization()
        #endif
    }

    /// Initializes a context without a specific rendering destination, using the specified options.
    public init(options: [CIContextOption: Any]?) {
        self._options = options ?? [:]
        if let colorSpace = options?[.workingColorSpace] {
            self._workingColorSpace = (colorSpace as! CGColorSpace)
        } else {
            self._workingColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        }
        self._workingFormat = options?[.workingFormat] as? CIFormat ?? .RGBAf
        #if arch(wasm32)
        startGPUInitialization()
        #endif
    }

    /// Creates a Core Image context from a Quartz context, using the specified options.
    public init(cgContext: CGContext, options: [CIContextOption: Any]?) {
        self._options = options ?? [:]
        if let colorSpace = options?[.workingColorSpace] {
            self._workingColorSpace = (colorSpace as! CGColorSpace)
        } else {
            self._workingColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        }
        self._workingFormat = options?[.workingFormat] as? CIFormat ?? .RGBAf
        #if arch(wasm32)
        startGPUInitialization()
        #endif
    }

    #if arch(wasm32)
    /// Starts GPU initialization in the background.
    private func startGPUInitialization() {
        _gpuInitTask = Task {
            try await GPUContextManager.shared.getDevice()
        }
    }

    /// Returns the GPU device, waiting for initialization if needed.
    private func getGPUDevice() async throws -> GPUDevice {
        if let device = _gpuDevice {
            return device
        }
        if let task = _gpuInitTask {
            _gpuDevice = try await task.value
            return _gpuDevice!
        }
        _gpuDevice = try await GPUContextManager.shared.getDevice()
        return _gpuDevice!
    }
    #endif

    // MARK: - Properties

    /// The working color space of the Core Image context.
    public var workingColorSpace: CGColorSpace? {
        _workingColorSpace
    }

    /// The working pixel format of the Core Image context.
    public var workingFormat: CIFormat {
        _workingFormat
    }

    // MARK: - Rendering Images

    /// Creates a Core Graphics image from a region of a Core Image image instance.
    public func createCGImage(_ image: CIImage, from fromRect: CGRect) -> CGImage? {
        createCGImage(image, from: fromRect, format: CIFormat.RGBA8, colorSpace: _workingColorSpace)
    }

    /// Creates a Core Graphics image from a region of a Core Image image instance
    /// with an option for controlling the pixel format and color space of the `CGImage`.
    public func createCGImage(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) -> CGImage? {
        createCGImage(image, from: fromRect, format: format, colorSpace: colorSpace, deferred: false)
    }

    /// Creates a Core Graphics image from a region of a Core Image image instance
    /// with an option for controlling when the image is rendered.
    public func createCGImage(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?,
        deferred: Bool
    ) -> CGImage? {
        // If the image has a CGImage source and no filters, return it directly
        if let cgImage = image.cgImage, image._filters.isEmpty {
            return cgImage
        }

        let width = Int(fromRect.width)
        let height = Int(fromRect.height)
        guard width > 0 && height > 0 else { return nil }

        // For solid color images without filters
        if let color = image._color, image._filters.isEmpty {
            return createSolidColorCGImage(
                color: color,
                width: width,
                height: height,
                colorSpace: colorSpace
            )
        }

        #if arch(wasm32)
        // Use WebGPU rendering for filter chains
        // Note: For synchronous API compatibility, we use a blocking approach
        // Prefer using createCGImageAsync for async contexts
        let box = UncheckedSendableBox<CGImage?>(nil)
        let semaphore = DispatchSemaphore(value: 0)

        Task { @MainActor in
            do {
                let rendered = try await self.renderToCGImageAsync(
                    image: image,
                    fromRect: fromRect,
                    format: format,
                    colorSpace: colorSpace
                )
                box.value = rendered
            } catch {
                // Rendering failed, value stays nil
            }
            semaphore.signal()
        }

        semaphore.wait()
        return box.value
        #else
        // Non-WASM: filter chain rendering not available
        return nil
        #endif
    }

    #if arch(wasm32)
    // MARK: - Async Rendering API

    /// Asynchronously creates a Core Graphics image from a Core Image image.
    /// - Parameters:
    ///   - image: The CIImage to render.
    ///   - fromRect: The region to render.
    ///   - format: The pixel format.
    ///   - colorSpace: The color space.
    /// - Returns: The rendered CGImage.
    public func createCGImageAsync(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat = .RGBA8,
        colorSpace: CGColorSpace? = nil
    ) async throws -> CGImage {
        try await renderToCGImageAsync(
            image: image,
            fromRect: fromRect,
            format: format,
            colorSpace: colorSpace ?? _workingColorSpace
        )
    }

    // MARK: - Private Rendering Implementation

    private func renderToCGImageAsync(
        image: CIImage,
        fromRect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) async throws -> CGImage {
        let device = try await getGPUDevice()
        let queue = try await GPUContextManager.shared.getQueue()

        let width = Int(fromRect.width)
        let height = Int(fromRect.height)

        // Handle solid color images
        if let color = image._color, image._filters.isEmpty {
            guard let cgImage = createSolidColorCGImage(
                color: color,
                width: width,
                height: height,
                colorSpace: colorSpace
            ) else {
                throw CIError.renderingFailed
            }
            return cgImage
        }

        // Handle direct CGImage source with no filters
        if let cgImage = image.cgImage, image._filters.isEmpty {
            return cgImage
        }

        // Build filter graph DAG to get source images
        var builder = FilterGraphBuilder()
        let filterGraph = builder.build(from: image)

        // Compile and execute filter graph
        let compiledGraph = try await FilterGraphCompiler.shared.compile(
            image: image,
            outputRect: fromRect,
            device: device
        )

        // Upload all source textures
        try await uploadSourceTextures(
            filterGraph: filterGraph,
            compiledGraph: compiledGraph,
            rect: fromRect,
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

        return cgImage
    }

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

            // Get pixel data from source image
            let pixelData = getPixelData(from: sourceImage, width: width, height: height)

            // Convert Data to JavaScript Uint8Array for WebGPU (optimized bulk transfer)
            let jsData = JSDataTransfer.toUint8Array(pixelData)

            // Write to texture
            queue.writeTexture(
                destination: GPUImageCopyTexture(texture: texture),
                data: jsData,
                dataLayout: GPUImageDataLayout(
                    bytesPerRow: UInt32(width * 4),
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

    private func getPixelData(from image: CIImage, width: Int, height: Int) -> Data {
        if let cgImage = image.cgImage {
            return extractPixelData(from: cgImage, width: width, height: height)
        } else if let color = image._color {
            return createSolidColorData(color: color, width: width, height: height)
        } else if let sourceData = image._data {
            return sourceData
        } else {
            // Create transparent pixels as fallback
            return Data(count: width * height * 4)
        }
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
    #endif

    // MARK: - Helper Methods

    private func createSolidColorCGImage(
        color: CIColor,
        width: Int,
        height: Int,
        colorSpace: CGColorSpace?
    ) -> CGImage? {
        let pixelData = createSolidColorData(color: color, width: width, height: height)
        return createCGImageFromPixelData(pixelData, width: width, height: height, colorSpace: colorSpace)
    }

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
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
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

        #if canImport(CoreGraphics)
        // On native platforms, CGDataProvider expects CFData (toll-free bridged with Data)
        guard let dataProvider = CGDataProvider(data: data as CFData) else {
            return nil
        }
        #else
        // On WASM, use OpenCoreGraphics which accepts Data directly
        guard let dataProvider = CGDataProvider(data: data) else {
            return nil
        }
        #endif

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

    /// Creates a Core Graphics image from a region of a Core Image image instance
    /// with an option for calculating HDR statistics.
    public func createCGImage(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?,
        deferred: Bool,
        calculateHDRStats: Bool
    ) -> CGImage? {
        createCGImage(image, from: fromRect, format: format, colorSpace: colorSpace, deferred: deferred)
    }

    /// Renders to the given bitmap.
    public func render(
        _ image: CIImage,
        toBitmap data: UnsafeMutableRawPointer,
        rowBytes: Int,
        bounds: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) {
        // Placeholder implementation
        // In a full implementation, this would render the image to the bitmap
    }

    // MARK: - Drawing Images

    /// Renders a region of an image to a rectangle in the context destination.
    public func draw(_ image: CIImage, in inRect: CGRect, from fromRect: CGRect) {
        // Placeholder implementation
        // In a full implementation, this would draw the image
    }

    // MARK: - Determining the Allowed Extents for Images

    /// Returns the maximum size allowed for any image rendered into the context.
    public func inputImageMaximumSize() -> CGSize {
        CGSize(width: 16384, height: 16384)
    }

    /// Returns the maximum size allowed for any image created by the context.
    public func outputImageMaximumSize() -> CGSize {
        CGSize(width: 16384, height: 16384)
    }

    // MARK: - Managing Resources

    /// Frees any cached data, such as temporary images, associated with the context and runs the garbage collector.
    public func clearCaches() {
        #if arch(wasm32)
        Task {
            await GPUTexturePool.shared.clear()
            await GPUPipelineCache.shared.clear()
        }
        #endif
    }

    /// Runs the garbage collector to reclaim any resources that the context no longer requires.
    public func reclaimResources() {
        #if arch(wasm32)
        Task {
            await GPUTexturePool.shared.clear()
        }
        #endif
    }

    /// Returns the number of GPUs not currently driving a display.
    public class func offlineGPUCount() -> UInt32 {
        0
    }

    // MARK: - Rendering Images for Data or File Export

    /// Renders the image and exports the resulting image data in TIFF format.
    public func tiffRepresentation(
        of image: CIImage,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) -> Data? {
        // Placeholder implementation
        nil
    }

    /// Renders the image and exports the resulting image data in JPEG format.
    public func jpegRepresentation(
        of image: CIImage,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) -> Data? {
        // Placeholder implementation
        nil
    }

    /// Renders the image and exports the resulting image data in PNG format.
    public func pngRepresentation(
        of image: CIImage,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) -> Data? {
        // Placeholder implementation
        nil
    }

    /// Renders the image and exports the resulting image data in HEIF format.
    public func heifRepresentation(
        of image: CIImage,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) -> Data? {
        // Placeholder implementation
        nil
    }

    /// Renders the image and exports the resulting image data in HEIF10 format.
    public func heif10Representation(
        of image: CIImage,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws -> Data {
        // Placeholder implementation
        throw CIError.notImplemented
    }

    /// Renders the image and exports the resulting image data in open EXR format.
    public func openEXRRepresentation(
        of image: CIImage,
        options: [CIImageRepresentationOption: Any]
    ) throws -> Data {
        // Placeholder implementation
        throw CIError.notImplemented
    }

    /// Renders the image and exports the resulting image data as a file in TIFF format.
    public func writeTIFFRepresentation(
        of image: CIImage,
        to url: URL,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        guard let data = tiffRepresentation(of: image, format: format, colorSpace: colorSpace, options: options) else {
            throw CIError.renderingFailed
        }
        try data.write(to: url)
    }

    /// Renders the image and exports the resulting image data as a file in JPEG format.
    public func writeJPEGRepresentation(
        of image: CIImage,
        to url: URL,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        guard let data = jpegRepresentation(of: image, colorSpace: colorSpace, options: options) else {
            throw CIError.renderingFailed
        }
        try data.write(to: url)
    }

    /// Renders the image and exports the resulting image data as a file in PNG format.
    public func writePNGRepresentation(
        of image: CIImage,
        to url: URL,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        guard let data = pngRepresentation(of: image, format: format, colorSpace: colorSpace, options: options) else {
            throw CIError.renderingFailed
        }
        try data.write(to: url)
    }

    /// Renders the image and exports the resulting image data as a file in HEIF format.
    public func writeHEIFRepresentation(
        of image: CIImage,
        to url: URL,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        guard let data = heifRepresentation(of: image, format: format, colorSpace: colorSpace, options: options) else {
            throw CIError.renderingFailed
        }
        try data.write(to: url)
    }

    /// Renders the image and exports the resulting image data as a file in HEIF10 format.
    public func writeHEIF10Representation(
        of image: CIImage,
        to url: URL,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        let data = try heif10Representation(of: image, colorSpace: colorSpace, options: options)
        try data.write(to: url)
    }

    /// Renders the image and exports the resulting image data as a file in open EXR format.
    public func writeOpenEXRRepresentation(
        of image: CIImage,
        to url: URL,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        let data = try openEXRRepresentation(of: image, options: options)
        try data.write(to: url)
    }

    // MARK: - HDR Statistics

    /// Given a Core Image image, calculate its HDR statistics.
    public func calculateHDRStats(for image: CIImage) -> CIImage? {
        image
    }
}

// MARK: - Equatable

extension CIContext: Equatable {
    public static func == (lhs: CIContext, rhs: CIContext) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIContext: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CIContextOption

/// An enum string type that your code can use to select different options when creating a Core Image context.
public struct CIContextOption: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A key for the color space to use for the context's working color space.
    public static let workingColorSpace = CIContextOption(rawValue: "kCIContextWorkingColorSpace")

    /// A key for the working pixel format of the context.
    public static let workingFormat = CIContextOption(rawValue: "kCIContextWorkingFormat")

    /// A key for a boolean value that specifies whether to use high-quality downsampling.
    public static let highQualityDownsample = CIContextOption(rawValue: "kCIContextHighQualityDownsample")

    /// A key for the output color space of the context.
    public static let outputColorSpace = CIContextOption(rawValue: "kCIContextOutputColorSpace")

    /// A key for a boolean value that specifies whether to cache intermediates.
    public static let cacheIntermediates = CIContextOption(rawValue: "kCIContextCacheIntermediates")

    /// A key for a boolean value that specifies whether to use software rendering.
    public static let useSoftwareRenderer = CIContextOption(rawValue: "kCIContextUseSoftwareRenderer")

    /// A key for a boolean value that specifies whether to prioritize lower power consumption.
    public static let priorityRequestLow = CIContextOption(rawValue: "kCIContextPriorityRequestLow")

    /// A key for a boolean value that specifies whether to allow low power rendering.
    public static let allowLowPower = CIContextOption(rawValue: "kCIContextAllowLowPower")

    /// A key for the name of the context.
    public static let name = CIContextOption(rawValue: "kCIContextName")
}

// MARK: - CIImageRepresentationOption

/// Options for image representation export.
public struct CIImageRepresentationOption: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A key for a float value that specifies the JPEG quality (0.0 to 1.0).
    public static let jpegQuality = CIImageRepresentationOption(rawValue: "kCGImageDestinationLossyCompressionQuality")

    /// A key for a boolean value that specifies whether to use HDR.
    public static let hdrImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationHDRImage")

    /// A key for depth data to include in the image.
    public static let depthImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationDepthImage")

    /// A key for disparity data to include in the image.
    public static let disparityImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationDisparityImage")

    /// A key for portrait effects matte data to include in the image.
    public static let portraitEffectsMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationPortraitEffectsMatteImage")

    /// A key for semantic segmentation matte images to include.
    public static let semanticSegmentationSkinMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationSkinMatteImage")

    /// A key for semantic segmentation hair matte images to include.
    public static let semanticSegmentationHairMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationHairMatteImage")

    /// A key for semantic segmentation teeth matte images to include.
    public static let semanticSegmentationTeethMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationTeethMatteImage")

    /// A key for semantic segmentation glasses matte images to include.
    public static let semanticSegmentationGlassesMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationGlassesMatteImage")

    /// A key for semantic segmentation sky matte images to include.
    public static let semanticSegmentationSkyMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationSkyMatteImage")

    /// A key for HDR gain map data to include in the image.
    public static let hdrGainMapImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationHDRGainMapImage")
}

// MARK: - CIError

/// Errors that can occur during Core Image operations.
public enum CIError: Error {
    case notImplemented
    case renderingFailed
    case invalidArgument
    case outOfMemory
}

// MARK: - UncheckedSendableBox

/// A box that wraps a value and is marked as Sendable without compiler checks.
/// Used for bridging synchronous APIs with async code where safety is manually verified.
/// This is necessary for Swift 6 strict concurrency when using semaphores
/// to block on async results from synchronous methods.
internal final class UncheckedSendableBox<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}
