//
//  FilterGraphCompiler.swift
//  OpenCoreImage
//
//  Compiles CIImage filter graphs (DAG) into GPU execution plans.
//

#if arch(wasm32)
import Foundation
import JavaScriptKit
import SwiftWebGPU

/// Represents a compiled filter node ready for GPU execution.
internal struct CompiledFilterNode {
    /// The name of the filter.
    let filterName: String

    /// The compiled compute pipeline.
    let pipeline: GPUComputePipeline

    /// The bind group containing all resources for this filter.
    let bindGroup: GPUBindGroup

    /// The input texture indices (multiple for compositing filters).
    let inputTextureIndices: [String: Int]

    /// The index of the output texture in the texture array.
    let outputTextureIndex: Int
}

/// Represents a compiled filter graph ready for GPU execution.
internal struct CompiledFilterGraph {
    /// The compiled filter nodes in execution order.
    let nodes: [CompiledFilterNode]

    /// All textures used in the filter graph.
    let textures: [GPUTexture]

    /// All texture views corresponding to textures.
    let textureViews: [GPUTextureView]

    /// All uniform buffers used.
    let uniformBuffers: [GPUBuffer]

    /// Source texture indices mapped by source node ID.
    /// These textures need image data uploaded before execution.
    let sourceTextureIndices: [Int: Int]

    /// Index of the final output texture.
    let outputTextureIndex: Int

    /// Width of the output.
    let width: UInt32

    /// Height of the output.
    let height: UInt32
}

/// Compiles CIImage filter graphs (DAG) into GPU execution plans.
internal actor FilterGraphCompiler {

    // MARK: - Singleton

    /// Shared instance of the filter graph compiler.
    static let shared = FilterGraphCompiler()

    // MARK: - Initialization

    private init() {}

    // MARK: - Configuration

    /// Threshold radius above which to use separable blur (2-pass)
    private let separableBlurThreshold: Float = 3.0

    // MARK: - Infinite Extent Handling

    /// Resolves an extent to finite dimensions, using render target size for infinite extents.
    /// - Parameters:
    ///   - extent: The extent to resolve.
    ///   - renderWidth: The width of the render target.
    ///   - renderHeight: The height of the render target.
    /// - Returns: A finite CGRect.
    private func resolveFiniteExtent(_ extent: CGRect, renderWidth: UInt32, renderHeight: UInt32) -> CGRect {
        if extent.isInfinite || extent.width.isInfinite || extent.height.isInfinite {
            // Use render target dimensions for infinite extent
            return CGRect(x: 0, y: 0, width: CGFloat(renderWidth), height: CGFloat(renderHeight))
        }
        return extent
    }

    /// Checks if a filter produces infinite extent output.
    /// - Parameter filterName: The name of the filter.
    /// - Returns: True if the filter produces infinite extent.
    private func producesInfiniteExtent(_ filterName: String) -> Bool {
        switch filterName {
        case "CIConstantColorGenerator", "CICheckerboardGenerator",
             "CIStripesGenerator", "CILinearGradient", "CIRadialGradient",
             "CIRandomGenerator", "CIRoundedRectangleGenerator",
             "CIStarShineGenerator", "CISunbeamsGenerator",
             "CIGaussianGradient", "CISmoothLinearGradient",
             "CIHueSaturationValueGradient", "CILenticularHaloGenerator",
             "CIAffineClamp":
            return true
        default:
            return false
        }
    }

    // MARK: - Public Interface

    /// Compiles a CIImage's filter graph into a GPU-executable graph.
    /// - Parameters:
    ///   - image: The CIImage with filter chain to compile.
    ///   - outputRect: The rectangle defining the output dimensions.
    ///   - device: The GPU device to create resources on.
    /// - Throws: GPUError if compilation fails.
    /// - Returns: A compiled filter graph ready for execution.
    func compile(
        image: CIImage,
        outputRect: CGRect,
        device: GPUDevice
    ) async throws -> CompiledFilterGraph {
        let width = UInt32(outputRect.width)
        let height = UInt32(outputRect.height)

        // Build the filter graph DAG
        var builder = FilterGraphBuilder()
        let filterGraph = builder.build(from: image)

        // If only source node (no filters), return pass-through
        if filterGraph.executionOrder.count == 1,
           let node = filterGraph.nodes[filterGraph.executionOrder[0]],
           node.isSource {
            return try await compilePassThrough(
                width: width,
                height: height,
                device: device,
                sourceNodeId: node.id
            )
        }

        // Compile the DAG
        return try await compileDAG(
            filterGraph: filterGraph,
            width: width,
            height: height,
            device: device
        )
    }

    // MARK: - DAG Compilation

    private func compileDAG(
        filterGraph: FilterGraph,
        width: UInt32,
        height: UInt32,
        device: GPUDevice
    ) async throws -> CompiledFilterGraph {
        var textures: [GPUTexture] = []
        var textureViews: [GPUTextureView] = []
        var uniformBuffers: [GPUBuffer] = []
        var compiledNodes: [CompiledFilterNode] = []

        // Map from filter graph node ID to texture index
        var nodeToTextureIndex: [Int: Int] = [:]

        // Map from source node ID to texture index (for uploading)
        var sourceTextureIndices: [Int: Int] = [:]

        do {
            // Process nodes in topological order
            for nodeId in filterGraph.executionOrder {
                guard let node = filterGraph.nodes[nodeId] else { continue }

                if node.isSource {
                    // Source node - create texture for upload
                    let texture = await GPUTexturePool.shared.acquire(
                        device: device,
                        width: width,
                        height: height,
                        format: .rgba8unorm
                    )
                    let textureIndex = textures.count
                    textures.append(texture)
                    textureViews.append(texture.createView())

                    nodeToTextureIndex[nodeId] = textureIndex
                    sourceTextureIndices[nodeId] = textureIndex
                } else {
                    // Filter node - compile and create output texture
                    let compiledNode = try await compileFilterNode(
                        node: node,
                        nodeToTextureIndex: nodeToTextureIndex,
                        textures: &textures,
                        textureViews: &textureViews,
                        uniformBuffers: &uniformBuffers,
                        width: width,
                        height: height,
                        device: device
                    )

                    nodeToTextureIndex[nodeId] = compiledNode.outputTextureIndex
                    compiledNodes.append(compiledNode)
                }
            }

            let outputTextureIndex = nodeToTextureIndex[filterGraph.outputNodeId] ?? 0

            return CompiledFilterGraph(
                nodes: compiledNodes,
                textures: textures,
                textureViews: textureViews,
                uniformBuffers: uniformBuffers,
                sourceTextureIndices: sourceTextureIndices,
                outputTextureIndex: outputTextureIndex,
                width: width,
                height: height
            )
        } catch {
            // Release all acquired textures if compilation fails
            // Copy to local array to avoid capture issues
            let texturesToRelease = textures
            for texture in texturesToRelease {
                await GPUTexturePool.shared.release(texture, width: width, height: height, format: .rgba8unorm)
            }
            throw error
        }
    }

    private func compileFilterNode(
        node: FilterGraphNode,
        nodeToTextureIndex: [Int: Int],
        textures: inout [GPUTexture],
        textureViews: inout [GPUTextureView],
        uniformBuffers: inout [GPUBuffer],
        width: UInt32,
        height: UInt32,
        device: GPUDevice
    ) async throws -> CompiledFilterNode {
        // Expand filter if needed (e.g., separable blur)
        let expandedFilters = expandFilter(name: node.filterName, parameters: node.parameters)

        // For multi-pass filters, we need to chain them
        var currentInputIndices = resolveInputTextureIndices(node: node, nodeToTextureIndex: nodeToTextureIndex)
        var lastCompiledNode: CompiledFilterNode?

        for (index, filter) in expandedFilters.enumerated() {
            let isLastPass = (index == expandedFilters.count - 1)

            // Check if filter is supported
            guard WGSLShaderRegistry.hasShader(for: filter.name) else {
                throw GPUError.unsupportedFilter(filter.name)
            }

            // Get pipeline
            let pipeline = try await GPUPipelineCache.shared.getPipeline(
                for: filter.name,
                device: device
            )

            // Create output texture
            let outputTexture = await GPUTexturePool.shared.acquire(
                device: device,
                width: width,
                height: height,
                format: .rgba8unorm
            )
            let outputTextureView = outputTexture.createView()
            let outputIndex = textures.count
            textures.append(outputTexture)
            textureViews.append(outputTextureView)

            // Create uniform buffer
            // For the first pass, use the node's input extent for coordinate transformations
            // For subsequent passes (e.g., separable blur), the intermediate textures have
            // the same extent as the output, so we can use the node's output extent
            //
            // Resolve infinite extents to render target dimensions
            let rawExtent = (index == 0) ? node.inputExtent : node.outputExtent
            let extentForEncoding = resolveFiniteExtent(rawExtent, renderWidth: width, renderHeight: height)
            let uniformData = UniformBufferEncoder.encode(
                filterName: filter.name,
                parameters: filter.parameters,
                imageWidth: Int(width),
                imageHeight: Int(height),
                inputExtent: extentForEncoding
            )
            let uniformBuffer = createUniformBuffer(device: device, data: uniformData)
            uniformBuffers.append(uniformBuffer)

            // Create bind group based on filter category
            let category = getFilterCategory(filter.name)
            let bindGroup = createBindGroupForCategory(
                category: category,
                device: device,
                pipeline: pipeline,
                inputTextureIndices: currentInputIndices,
                textureViews: textureViews,
                outputTextureView: outputTextureView,
                uniformBuffer: uniformBuffer
            )

            lastCompiledNode = CompiledFilterNode(
                filterName: filter.name,
                pipeline: pipeline,
                bindGroup: bindGroup,
                inputTextureIndices: currentInputIndices,
                outputTextureIndex: outputIndex
            )

            // For multi-pass, chain the output to next pass input
            if !isLastPass {
                currentInputIndices = [kCIInputImageKey: outputIndex]
            }
        }

        return lastCompiledNode!
    }

    private func resolveInputTextureIndices(
        node: FilterGraphNode,
        nodeToTextureIndex: [Int: Int]
    ) -> [String: Int] {
        var result: [String: Int] = [:]

        for (key, input) in node.inputs {
            switch input {
            case .node(let inputNodeId):
                if let textureIndex = nodeToTextureIndex[inputNodeId] {
                    result[key] = textureIndex
                }
            case .sourceImage:
                // Source images should have been processed as source nodes
                break
            }
        }

        return result
    }

    // MARK: - Bind Group Creation

    private func createBindGroupForCategory(
        category: FilterCategory,
        device: GPUDevice,
        pipeline: GPUComputePipeline,
        inputTextureIndices: [String: Int],
        textureViews: [GPUTextureView],
        outputTextureView: GPUTextureView,
        uniformBuffer: GPUBuffer
    ) -> GPUBindGroup {
        let bindGroupLayout = pipeline.getBindGroupLayout(index: 0)

        switch category {
        case .source:
            fatalError("Source nodes should not create bind groups")

        case .standard, .generator:
            // Standard layout: input(0), output(1), uniform(2)
            let inputIndex = inputTextureIndices[kCIInputImageKey] ?? 0
            return device.createBindGroup(
                descriptor: GPUBindGroupDescriptor(
                    layout: bindGroupLayout,
                    entries: [
                        GPUBindGroupEntry(
                            binding: 0,
                            resource: .textureView(textureViews[inputIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 1,
                            resource: .textureView(outputTextureView)
                        ),
                        GPUBindGroupEntry(
                            binding: 2,
                            resource: .bufferBinding(GPUBufferBinding(buffer: uniformBuffer))
                        ),
                    ]
                )
            )

        case .compositing:
            // Compositing layout: foreground(0), background(1), output(2), uniform(3)
            let foregroundIndex = inputTextureIndices[kCIInputImageKey] ?? 0
            let backgroundIndex = inputTextureIndices[kCIInputBackgroundImageKey] ?? 0
            return device.createBindGroup(
                descriptor: GPUBindGroupDescriptor(
                    layout: bindGroupLayout,
                    entries: [
                        GPUBindGroupEntry(
                            binding: 0,
                            resource: .textureView(textureViews[foregroundIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 1,
                            resource: .textureView(textureViews[backgroundIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 2,
                            resource: .textureView(outputTextureView)
                        ),
                        GPUBindGroupEntry(
                            binding: 3,
                            resource: .bufferBinding(GPUBufferBinding(buffer: uniformBuffer))
                        ),
                    ]
                )
            )

        case .transition:
            // Transition layout: input(0), target(1), output(2), uniform(3)
            let inputIndex = inputTextureIndices[kCIInputImageKey] ?? 0
            let targetIndex = inputTextureIndices[kCIInputTargetImageKey] ?? 0
            return device.createBindGroup(
                descriptor: GPUBindGroupDescriptor(
                    layout: bindGroupLayout,
                    entries: [
                        GPUBindGroupEntry(
                            binding: 0,
                            resource: .textureView(textureViews[inputIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 1,
                            resource: .textureView(textureViews[targetIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 2,
                            resource: .textureView(outputTextureView)
                        ),
                        GPUBindGroupEntry(
                            binding: 3,
                            resource: .bufferBinding(GPUBufferBinding(buffer: uniformBuffer))
                        ),
                    ]
                )
            )

        case .blendWithMask:
            // Blend with mask layout: input(0), background(1), mask(2), output(3), uniform(4)
            let inputIndex = inputTextureIndices[kCIInputImageKey] ?? 0
            let backgroundIndex = inputTextureIndices[kCIInputBackgroundImageKey] ?? 0
            let maskIndex = inputTextureIndices["inputMaskImage"] ?? 0
            return device.createBindGroup(
                descriptor: GPUBindGroupDescriptor(
                    layout: bindGroupLayout,
                    entries: [
                        GPUBindGroupEntry(
                            binding: 0,
                            resource: .textureView(textureViews[inputIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 1,
                            resource: .textureView(textureViews[backgroundIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 2,
                            resource: .textureView(textureViews[maskIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 3,
                            resource: .textureView(outputTextureView)
                        ),
                        GPUBindGroupEntry(
                            binding: 4,
                            resource: .bufferBinding(GPUBufferBinding(buffer: uniformBuffer))
                        ),
                    ]
                )
            )

        case .reduction:
            // Reduction layout: same as standard (input(0), output(1), uniform(2))
            // Output is typically a 1x1 or 1xN texture
            let inputIndex = inputTextureIndices[kCIInputImageKey] ?? 0
            return device.createBindGroup(
                descriptor: GPUBindGroupDescriptor(
                    layout: bindGroupLayout,
                    entries: [
                        GPUBindGroupEntry(
                            binding: 0,
                            resource: .textureView(textureViews[inputIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 1,
                            resource: .textureView(outputTextureView)
                        ),
                        GPUBindGroupEntry(
                            binding: 2,
                            resource: .bufferBinding(GPUBufferBinding(buffer: uniformBuffer))
                        ),
                    ]
                )
            )

        case .displacement:
            // Displacement layout: input(0), displacementTexture(1), output(2), uniform(3)
            let inputIndex = inputTextureIndices[kCIInputImageKey] ?? 0
            let displacementIndex = inputTextureIndices["inputTexture"] ?? inputTextureIndices["inputDisplacementImage"] ?? 0
            return device.createBindGroup(
                descriptor: GPUBindGroupDescriptor(
                    layout: bindGroupLayout,
                    entries: [
                        GPUBindGroupEntry(
                            binding: 0,
                            resource: .textureView(textureViews[inputIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 1,
                            resource: .textureView(textureViews[displacementIndex])
                        ),
                        GPUBindGroupEntry(
                            binding: 2,
                            resource: .textureView(outputTextureView)
                        ),
                        GPUBindGroupEntry(
                            binding: 3,
                            resource: .bufferBinding(GPUBufferBinding(buffer: uniformBuffer))
                        ),
                    ]
                )
            )
        }
    }

    private func getFilterCategory(_ filterName: String) -> FilterCategory {
        switch filterName {
        // Compositing filters (Porter-Duff and blend modes)
        case "CISourceOverCompositing", "CISourceAtopCompositing",
             "CISourceInCompositing", "CISourceOutCompositing",
             "CIMultiplyCompositing", "CIScreenCompositing",
             "CIOverlayCompositing", "CIAdditionCompositing",
             "CISubtractCompositing", "CIDarkenCompositing",
             "CILightenCompositing", "CIDifferenceCompositing",
             "CIMaximumCompositing", "CIMinimumCompositing",
             // Blend modes
             "CIColorBurnBlendMode", "CIColorDodgeBlendMode",
             "CISoftLightBlendMode", "CIHardLightBlendMode",
             "CIExclusionBlendMode", "CIHueBlendMode",
             "CISaturationBlendMode", "CIColorBlendMode",
             "CILuminosityBlendMode", "CIPinLightBlendMode",
             "CILinearBurnBlendMode", "CILinearDodgeBlendMode",
             "CIDivideBlendMode",
             // Mix filter (also uses 2 textures)
             "CIMix":
            return .compositing

        // Transition filters
        case "CIDissolveTransition", "CISwipeTransition",
             "CIBarsSwipeTransition", "CIModTransition",
             "CIFlashTransition", "CICopyMachineTransition",
             "CIRippleTransition":
            return .transition

        // Generator filters
        case "CIConstantColorGenerator", "CICheckerboardGenerator",
             "CIStripesGenerator", "CILinearGradient", "CIRadialGradient",
             "CIRandomGenerator", "CIRoundedRectangleGenerator",
             "CIStarShineGenerator", "CISunbeamsGenerator",
             "CIGaussianGradient", "CISmoothLinearGradient",
             "CIHueSaturationValueGradient", "CILenticularHaloGenerator":
            return .generator

        // Blend with mask filters
        case "CIBlendWithMask", "CIBlendWithAlphaMask",
             "CIBlendWithRedMask", "CIBlendWithBlueMask":
            return .blendWithMask

        // Reduction filters
        case "CIAreaAverage", "CIAreaMaximum", "CIAreaMinimum",
             "CIAreaMaximumAlpha", "CIAreaMinimumAlpha",
             "CIAreaMinMax", "CIAreaMinMaxRed",
             "CIRowAverage", "CIColumnAverage",
             "CIAreaHistogram", "CIHistogramDisplayFilter":
            return .reduction

        // Displacement filters
        case "CIGlassDistortion", "CIDisplacementDistortion":
            return .displacement

        default:
            return .standard
        }
    }

    // MARK: - Pass-Through

    private func compilePassThrough(
        width: UInt32,
        height: UInt32,
        device: GPUDevice,
        sourceNodeId: Int
    ) async throws -> CompiledFilterGraph {
        let sourceTexture = await GPUTexturePool.shared.acquire(
            device: device,
            width: width,
            height: height,
            format: .rgba8unorm
        )

        return CompiledFilterGraph(
            nodes: [],
            textures: [sourceTexture],
            textureViews: [sourceTexture.createView()],
            uniformBuffers: [],
            sourceTextureIndices: [sourceNodeId: 0],
            outputTextureIndex: 0,
            width: width,
            height: height
        )
    }

    // MARK: - Uniform Buffer

    private func createUniformBuffer(device: GPUDevice, data: Data) -> GPUBuffer {
        let buffer = device.createBuffer(
            descriptor: GPUBufferDescriptor(
                size: UInt64(data.count),
                usage: [.uniform, .copyDst]
            )
        )

        let jsData = JSDataTransfer.toUint8Array(data)
        device.queue.writeBuffer(buffer, bufferOffset: 0, data: jsData)

        return buffer
    }

    // MARK: - Filter Expansion

    private typealias FilterInfo = (name: String, parameters: [String: Any])

    private func expandFilter(name: String, parameters: [String: Any]) -> [FilterInfo] {
        switch name {
        case "CIGaussianBlur":
            let radius = getFloatParameter(parameters[kCIInputRadiusKey]) ?? 10.0
            if radius > separableBlurThreshold {
                return [
                    (name: "CIGaussianBlurHorizontal", parameters: parameters),
                    (name: "CIGaussianBlurVertical", parameters: parameters)
                ]
            }
            return [(name: name, parameters: parameters)]

        case "CIBoxBlur":
            let radius = getFloatParameter(parameters[kCIInputRadiusKey]) ?? 10.0
            if radius > separableBlurThreshold {
                return [
                    (name: "CIBoxBlurHorizontal", parameters: parameters),
                    (name: "CIBoxBlurVertical", parameters: parameters)
                ]
            }
            return [(name: name, parameters: parameters)]

        default:
            return [(name: name, parameters: parameters)]
        }
    }

    private func getFloatParameter(_ value: Any?) -> Float? {
        if let f = value as? Float { return f }
        if let d = value as? Double { return Float(d) }
        if let cg = value as? CGFloat { return Float(cg) }
        if let i = value as? Int { return Float(i) }
        if let n = value as? NSNumber { return n.floatValue }
        return nil
    }
}
#endif
