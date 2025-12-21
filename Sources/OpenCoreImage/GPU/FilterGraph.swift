//
//  FilterGraph.swift
//  OpenCoreImage
//
//  DAG representation of filter graphs for multi-input filter support.
//

import Foundation

/// Represents a node in the filter graph DAG.
internal struct FilterGraphNode: Identifiable {
    /// Unique identifier for this node.
    let id: Int

    /// The filter name (e.g., "CIGaussianBlur").
    let filterName: String

    /// Filter parameters (excluding CIImage references).
    let parameters: [String: Any]

    /// Input connections: parameter key -> source node ID.
    /// For standard filters, kCIInputImageKey maps to the previous node.
    /// For compositing, both kCIInputImageKey and kCIInputBackgroundImageKey are used.
    var inputs: [String: FilterGraphInput]

    /// Whether this node is a source (has image data, not just filters).
    let isSource: Bool

    /// Source image data (only for source nodes).
    let sourceImage: CIImage?

    /// The extent of the primary input for this node (for coordinate transformations).
    /// For source nodes, this is the source image extent.
    /// For filter nodes, this is the output extent of the primary input node.
    let inputExtent: CGRect

    /// The output extent of this node after applying the filter.
    let outputExtent: CGRect
}

/// Represents an input to a filter node.
internal enum FilterGraphInput {
    /// Input comes from another node's output.
    case node(Int)

    /// Input is the original source image of a CIImage.
    case sourceImage(CIImage)
}

/// Represents a complete filter graph as a DAG.
internal struct FilterGraph {
    /// All nodes in the graph, indexed by ID.
    let nodes: [Int: FilterGraphNode]

    /// The root node ID (final output).
    let outputNodeId: Int

    /// All source node IDs (nodes that need texture upload).
    let sourceNodeIds: [Int]

    /// Execution order (topologically sorted).
    let executionOrder: [Int]
}

/// Builds a filter graph DAG from a CIImage.
internal struct FilterGraphBuilder {

    // MARK: - State

    private var nodes: [Int: FilterGraphNode] = [:]
    private var nextNodeId: Int = 0
    private var imageToNodeId: [ObjectIdentifier: Int] = [:]

    // MARK: - Public Interface

    /// Builds a filter graph from a CIImage.
    /// - Parameter image: The output CIImage.
    /// - Returns: A FilterGraph representing the DAG.
    mutating func build(from image: CIImage) -> FilterGraph {
        // Reset state
        nodes = [:]
        nextNodeId = 0
        imageToNodeId = [:]

        // Build graph recursively
        let outputNodeId = processImage(image)

        // Find all source nodes
        let sourceNodeIds = nodes.values
            .filter { $0.isSource }
            .map { $0.id }

        // Topological sort for execution order
        let executionOrder = topologicalSort(outputNodeId: outputNodeId)

        return FilterGraph(
            nodes: nodes,
            outputNodeId: outputNodeId,
            sourceNodeIds: sourceNodeIds,
            executionOrder: executionOrder
        )
    }

    // MARK: - Private Helpers

    /// Processes a CIImage and returns its node ID.
    private mutating func processImage(_ image: CIImage) -> Int {
        // Check if we've already processed this exact image instance
        let imageId = ObjectIdentifier(image)
        if let existingNodeId = imageToNodeId[imageId] {
            return existingNodeId
        }

        // If image has no filters, create a source node
        if image._filters.isEmpty {
            let nodeId = createSourceNode(for: image)
            imageToNodeId[imageId] = nodeId
            return nodeId
        }

        // Process the base image (image without filters) first
        let baseImage = createBaseImage(from: image)
        var currentInputNodeId = processImage(baseImage)

        // Process each filter in the chain
        for filter in image._filters {
            currentInputNodeId = processFilter(
                name: filter.name,
                parameters: filter.parameters,
                primaryInputNodeId: currentInputNodeId
            )
        }

        imageToNodeId[imageId] = currentInputNodeId
        return currentInputNodeId
    }

    /// Creates a base image (without filters) from a CIImage.
    private func createBaseImage(from image: CIImage) -> CIImage {
        CIImage(
            extent: image._extent,
            colorSpace: image._colorSpace,
            cgImage: image._cgImage,
            color: image._color,
            url: image._url,
            data: image._data,
            pixelData: image._pixelData,
            properties: image._properties,
            transform: image._transform,
            filters: []  // No filters
        )
    }

    /// Creates a source node for a CIImage.
    private mutating func createSourceNode(for image: CIImage) -> Int {
        let nodeId = nextNodeId
        nextNodeId += 1

        let extent = image._extent

        let node = FilterGraphNode(
            id: nodeId,
            filterName: "Source",
            parameters: [:],
            inputs: [:],
            isSource: true,
            sourceImage: image,
            inputExtent: extent,
            outputExtent: extent
        )
        nodes[nodeId] = node
        return nodeId
    }

    /// Processes a filter and returns its node ID.
    private mutating func processFilter(
        name: String,
        parameters: [String: Any],
        primaryInputNodeId: Int
    ) -> Int {
        let nodeId = nextNodeId
        nextNodeId += 1

        // Separate CIImage parameters from other parameters
        var nonImageParams: [String: Any] = [:]
        var inputs: [String: FilterGraphInput] = [:]

        // Primary input (from filter chain)
        inputs[kCIInputImageKey] = .node(primaryInputNodeId)

        for (key, value) in parameters {
            if let inputImage = value as? CIImage {
                // This is a CIImage reference - process it recursively
                let inputNodeId = processImage(inputImage)
                inputs[key] = .node(inputNodeId)
            } else {
                // Regular parameter
                nonImageParams[key] = value
            }
        }

        // Get the input extent from the primary input node
        let inputExtent = nodes[primaryInputNodeId]?.outputExtent ?? .zero

        // Calculate output extent based on filter type
        let outputExtent = calculateOutputExtent(
            filterName: name,
            parameters: nonImageParams,
            inputExtent: inputExtent
        )

        let node = FilterGraphNode(
            id: nodeId,
            filterName: name,
            parameters: nonImageParams,
            inputs: inputs,
            isSource: false,
            sourceImage: nil,
            inputExtent: inputExtent,
            outputExtent: outputExtent
        )
        nodes[nodeId] = node
        return nodeId
    }

    /// Calculates the output extent for a filter based on its type and parameters.
    private func calculateOutputExtent(
        filterName: String,
        parameters: [String: Any],
        inputExtent: CGRect
    ) -> CGRect {
        switch filterName {
        case "CICrop":
            // Crop output extent is the intersection of input extent and crop rect
            if let rect = parameters["inputRectangle"] as? CIVector, rect.count >= 4 {
                let cropRect = CGRect(
                    x: rect.value(at: 0),
                    y: rect.value(at: 1),
                    width: rect.value(at: 2),
                    height: rect.value(at: 3)
                )
                return inputExtent.intersection(cropRect)
            }
            return inputExtent

        case "CIAffineTransform":
            // Transform output extent is the input extent transformed by the matrix
            if let transform = parameters[kCIInputTransformKey] as? CGAffineTransform {
                return inputExtent.applying(transform)
            }
            return inputExtent

        case "CIStraighten":
            // Straighten rotates the image, which may change the bounding box
            // For simplicity, we preserve the extent (actual bounds depend on angle)
            return inputExtent

        case "CIPerspectiveTransform", "CIPerspectiveCorrection":
            // Perspective transforms can significantly change the output extent
            // For now, preserve the input extent (proper implementation would compute
            // the bounding box of the transformed quad)
            return inputExtent

        case "CILanczosScaleTransform":
            // Scale transform changes the output extent based on scale factor
            if let scale = parameters["inputScale"] as? Double {
                let aspectRatio = (parameters["inputAspectRatio"] as? Double) ?? 1.0
                return CGRect(
                    x: inputExtent.origin.x,
                    y: inputExtent.origin.y,
                    width: inputExtent.width * CGFloat(scale),
                    height: inputExtent.height * CGFloat(scale / aspectRatio)
                )
            }
            return inputExtent

        case "CIConstantColorGenerator", "CICheckerboardGenerator",
             "CIStripesGenerator", "CIRandomGenerator",
             "CILinearGradient", "CIRadialGradient",
             "CIRoundedRectangleGenerator", "CIStarShineGenerator",
             "CISunbeamsGenerator":
            // Generator filters produce infinite extent
            return CGRect.infinite

        default:
            // Most filters preserve the input extent
            return inputExtent
        }
    }

    /// Performs topological sort starting from output node.
    private func topologicalSort(outputNodeId: Int) -> [Int] {
        var visited: Set<Int> = []
        var result: [Int] = []

        func visit(_ nodeId: Int) {
            guard !visited.contains(nodeId) else { return }
            visited.insert(nodeId)

            if let node = nodes[nodeId] {
                // Visit all input nodes first
                for input in node.inputs.values {
                    if case .node(let inputNodeId) = input {
                        visit(inputNodeId)
                    }
                }
            }

            result.append(nodeId)
        }

        visit(outputNodeId)
        return result
    }
}

/// Categories of filters based on their input/output requirements.
internal enum FilterCategory {
    /// Source node - has image data, no processing.
    case source

    /// Standard filter - 1 input, 1 output.
    case standard

    /// Compositing filter - 2 inputs (foreground + background), 1 output.
    case compositing

    /// Generator filter - 0 inputs, 1 output.
    case generator

    /// Transition filter - 2 inputs (source + target), 1 output.
    case transition

    /// Blend with mask filter - 3 inputs (input + background + mask), 1 output.
    case blendWithMask

    /// Reduction filter - 1 input, reduced output (single pixel or row/column).
    case reduction

    /// Displacement filter - 2 inputs (input + displacement texture), 1 output.
    case displacement
}
