#if arch(wasm32)
import SwiftWebGPU

/// Errors produced while connecting a Core Image transition filter to externally owned textures.
@_spi(WebGPUInterop)
public enum CIWebGPUTransitionError: Error, Equatable {
    case unsupportedFilter(String)
    case invalidTextureSize
    case uniformDataTooLarge(Int)
    case invalidatedExecution
}

/// A reusable transition-filter dispatch bound to source, target, and output textures.
@MainActor
@_spi(WebGPUInterop)
public final class CIWebGPUTransitionExecution {
    /// The filtered texture written by each call to ``encode(progress:commandEncoder:)``.
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
        width: UInt32,
        height: UInt32,
        device: GPUDevice,
        pipeline: GPUComputePipeline,
        sourceTexture: GPUTexture,
        targetTexture: GPUTexture
    ) {
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
        self.bindGroup = device.createBindGroup(descriptor: GPUBindGroupDescriptor(
            layout: pipeline.getBindGroupLayout(index: 0),
            entries: [
                GPUBindGroupEntry(binding: 0, resource: .textureView(sourceTexture.createView())),
                GPUBindGroupEntry(binding: 1, resource: .textureView(targetTexture.createView())),
                GPUBindGroupEntry(binding: 2, resource: .textureView(outputTexture.createView())),
                GPUBindGroupEntry(
                    binding: 3,
                    resource: .bufferBinding(GPUBufferBinding(buffer: uniformBuffer))
                ),
            ]
        ))
    }

    /// Encodes one transition-filter dispatch into the caller's command encoder.
    public func encode(
        progress: Float,
        commandEncoder: GPUCommandEncoder
    ) throws(CIWebGPUTransitionError) {
        guard !isInvalidated else {
            throw .invalidatedExecution
        }

        var parameters: [String: Any] = [:]
        for key in filter.inputKeys where key != kCIInputImageKey && key != kCIInputTargetImageKey {
            if let value = filter.value(forKey: key) {
                parameters[key] = value
            }
        }
        parameters[kCIInputTimeKey] = max(0, min(1, progress))
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

    /// Releases the resources owned by this execution.
    public func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
        outputTexture.destroy()
        uniformBuffer.destroy()
    }
}

/// Creates transition executions on a GPU device owned by another renderer.
@MainActor
@_spi(WebGPUInterop)
public final class CIWebGPUTransitionProcessor {
    private let device: GPUDevice
    private var pipelines: [String: GPUComputePipeline] = [:]

    public init(device: GPUDevice) {
        self.device = device
    }

    /// Returns whether this processor has an executable shader for the filter.
    public func supports(_ filter: CIFilter) -> Bool {
        WGSLShaderRegistry.transitionFilterNames.contains(filter.name)
            && WGSLShaderRegistry.hasShader(for: filter.name)
    }

    /// Binds a supported filter to equally sized source and target textures.
    public func makeExecution(
        filter: CIFilter,
        sourceTexture: GPUTexture,
        targetTexture: GPUTexture,
        width: UInt32,
        height: UInt32
    ) throws(CIWebGPUTransitionError) -> CIWebGPUTransitionExecution {
        guard width > 0, height > 0 else {
            throw .invalidTextureSize
        }
        guard supports(filter), let shader = WGSLShaderRegistry.getShader(for: filter.name) else {
            throw .unsupportedFilter(filter.name)
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

        return CIWebGPUTransitionExecution(
            filter: filter,
            width: width,
            height: height,
            device: device,
            pipeline: pipeline,
            sourceTexture: sourceTexture,
            targetTexture: targetTexture
        )
    }

    public func invalidate() {
        pipelines.removeAll(keepingCapacity: false)
    }
}
#endif
