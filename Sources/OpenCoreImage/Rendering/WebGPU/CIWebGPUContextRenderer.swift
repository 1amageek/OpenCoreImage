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
            let pixelData = try await getPixelData(from: sourceImage, width: width, height: height)

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

    private func getPixelData(from image: CIImage, width: Int, height: Int) async throws -> Data {
        // First priority: decoded pixel data (already RGBA)
        if let pixelData = image._pixelData, !pixelData.isEmpty {
            return pixelData
        }
        // Second priority: CGImage source
        if let cgImage = image.cgImage {
            return extractPixelData(from: cgImage, width: width, height: height)
        }
        // Third priority: solid color
        if let color = image._color {
            return createSolidColorData(color: color, width: width, height: height)
        }
        // Fourth priority: decode from raw image data on-demand
        if let rawData = image._data, !rawData.isEmpty {
            let decoded = try await ImageDecoder.decode(rawData)
            return decoded.pixelData
        }
        // Fallback: transparent pixels
        return Data(count: width * height * 4)
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
