#if arch(wasm32)
import JavaScriptKit
import SwiftWebGPU

/// The external texture inputs consumed by a Core Image WebGPU execution.
@_spi(WebGPUInterop)
public enum CIWebGPUFilterInputMode: Sendable {
    case singleInput
    case foregroundAndBackground
}

/// Errors produced while connecting a Core Image filter to externally owned textures.
@_spi(WebGPUInterop)
public enum CIWebGPUFilterError: Error, Equatable {
    case unsupportedFilter(String)
    case incompatibleInputMode(String)
    case missingBackgroundTexture
    case invalidTextureSize
    case uniformDataTooLarge(Int)
    case invalidatedExecution
}

/// A reusable filter dispatch bound to externally owned straight-alpha input textures.
///
/// The output texture also contains straight-alpha RGBA values. External compositors that
/// store premultiplied pixels must explicitly convert at this boundary.
@MainActor
@_spi(WebGPUInterop)
public final class CIWebGPUFilterExecution {
    /// The filtered texture written by each call to ``encode(commandEncoder:)``.
    public let outputTexture: GPUTexture

    private let filter: CIFilter
    private let filterName: String
    private let width: UInt32
    private let height: UInt32
    private let device: GPUDevice
    private let pipeline: GPUComputePipeline
    private let bindGroup: GPUBindGroup
    private let uniformBuffer: GPUBuffer
    private var isInvalidated = false

    fileprivate init(
        filter: CIFilter,
        inputMode: CIWebGPUFilterInputMode,
        inputTexture: GPUTexture,
        backgroundTexture: GPUTexture?,
        width: UInt32,
        height: UInt32,
        device: GPUDevice,
        pipeline: GPUComputePipeline
    ) throws(CIWebGPUFilterError) {
        self.filter = filter
        self.filterName = filter.name
        self.width = width
        self.height = height
        self.device = device
        self.pipeline = pipeline
        self.outputTexture = device.createTexture(descriptor: GPUTextureDescriptor(
            size: GPUExtent3D(width: width, height: height, depthOrArrayLayers: 1),
            format: .rgba8unorm,
            usage: [.storageBinding, .textureBinding, .copySrc]
        ))
        self.uniformBuffer = device.createBuffer(descriptor: GPUBufferDescriptor(
            size: 256,
            usage: [.uniform, .copyDst]
        ))

        let entries: [GPUBindGroupEntry]
        switch inputMode {
        case .singleInput:
            entries = [
                GPUBindGroupEntry(binding: 0, resource: .textureView(inputTexture.createView())),
                GPUBindGroupEntry(binding: 1, resource: .textureView(outputTexture.createView())),
                GPUBindGroupEntry(
                    binding: 2,
                    resource: .bufferBinding(GPUBufferBinding(buffer: uniformBuffer))
                ),
            ]
        case .foregroundAndBackground:
            guard let backgroundTexture else {
                outputTexture.destroy()
                uniformBuffer.destroy()
                throw .missingBackgroundTexture
            }
            entries = [
                GPUBindGroupEntry(binding: 0, resource: .textureView(inputTexture.createView())),
                GPUBindGroupEntry(binding: 1, resource: .textureView(backgroundTexture.createView())),
                GPUBindGroupEntry(binding: 2, resource: .textureView(outputTexture.createView())),
                GPUBindGroupEntry(
                    binding: 3,
                    resource: .bufferBinding(GPUBufferBinding(buffer: uniformBuffer))
                ),
            ]
        }

        self.bindGroup = device.createBindGroup(descriptor: GPUBindGroupDescriptor(
            layout: pipeline.getBindGroupLayout(index: 0),
            entries: entries
        ))
    }

    /// Encodes this filter without submitting the caller's command buffer.
    public func encode(
        commandEncoder: GPUCommandEncoder
    ) throws(CIWebGPUFilterError) {
        guard !isInvalidated else {
            throw .invalidatedExecution
        }

        var parameters: [String: Any] = [:]
        for key in filter.inputKeys
        where key != kCIInputImageKey && key != kCIInputBackgroundImageKey {
            if let value = filter.value(forKey: key) {
                parameters[key] = value
            }
        }
        let uniformData = UniformBufferEncoder.encode(
            filterName: filterName,
            parameters: parameters,
            imageWidth: Int(width),
            imageHeight: Int(height),
            inputExtent: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        )
        guard uniformData.count <= 256 else {
            throw .uniformDataTooLarge(uniformData.count)
        }
        device.queue.writeBuffer(
            uniformBuffer,
            bufferOffset: 0,
            data: JSDataTransfer.toUint8Array(uniformData)
        )

        let computePass = commandEncoder.beginComputePass()
        computePass.setPipeline(pipeline)
        computePass.setBindGroup(0, bindGroup: bindGroup)
        computePass.dispatchWorkgroups(
            workgroupCountX: (width + 15) / 16,
            workgroupCountY: (height + 15) / 16,
            workgroupCountZ: 1
        )
        computePass.end()
    }

    /// Releases resources owned by this execution.
    public func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
        outputTexture.destroy()
        uniformBuffer.destroy()
    }
}

/// Creates single-input and foreground/background filter executions for external renderers.
@MainActor
@_spi(WebGPUInterop)
public final class CIWebGPUFilterProcessor {
    private let device: GPUDevice
    private var pipelines: [String: GPUComputePipeline] = [:]

    public init(device: GPUDevice) {
        self.device = device
    }

    /// Returns whether the filter has executable WGSL with the requested binding contract.
    public func supports(_ filter: CIFilter, inputMode: CIWebGPUFilterInputMode) -> Bool {
        guard WGSLShaderRegistry.hasShader(for: filter.name) else { return false }
        let category = FilterGraphCompiler.category(for: filter.name)
        switch inputMode {
        case .singleInput:
            return category == .standard || category == .reduction
        case .foregroundAndBackground:
            return category == .compositing
        }
    }

    /// Binds a supported filter to one or two equally sized straight-alpha external textures.
    public func makeExecution(
        filter: CIFilter,
        inputMode: CIWebGPUFilterInputMode,
        inputTexture: GPUTexture,
        backgroundTexture: GPUTexture? = nil,
        width: UInt32,
        height: UInt32
    ) throws(CIWebGPUFilterError) -> CIWebGPUFilterExecution {
        guard width > 0, height > 0 else {
            throw .invalidTextureSize
        }
        guard supports(filter, inputMode: inputMode),
              let shader = WGSLShaderRegistry.getShader(for: filter.name) else {
            throw .incompatibleInputMode(filter.name)
        }
        if case .foregroundAndBackground = inputMode, backgroundTexture == nil {
            throw .missingBackgroundTexture
        }

        let pipeline: GPUComputePipeline
        if let cached = pipelines[filter.name] {
            pipeline = cached
        } else {
            let module = device.createShaderModule(descriptor: GPUShaderModuleDescriptor(code: shader))
            pipeline = device.createComputePipeline(descriptor: GPUComputePipelineDescriptor(
                compute: GPUProgrammableStage(module: module, entryPoint: "main"),
                layout: .auto
            ))
            pipelines[filter.name] = pipeline
        }

        return try CIWebGPUFilterExecution(
            filter: filter,
            inputMode: inputMode,
            inputTexture: inputTexture,
            backgroundTexture: backgroundTexture,
            width: width,
            height: height,
            device: device,
            pipeline: pipeline
        )
    }

    public func invalidate() {
        pipelines.removeAll(keepingCapacity: false)
    }
}
#endif
