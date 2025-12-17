//
//  FilterGraph.swift
//  OpenCoreImage
//
//  DAG representation of filter graphs for multi-input filter support.
//

#if arch(wasm32)
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
            properties: image._properties,
            transform: image._transform,
            filters: []  // No filters
        )
    }

    /// Creates a source node for a CIImage.
    private mutating func createSourceNode(for image: CIImage) -> Int {
        let nodeId = nextNodeId
        nextNodeId += 1

        let node = FilterGraphNode(
            id: nodeId,
            filterName: "Source",
            parameters: [:],
            inputs: [:],
            isSource: true,
            sourceImage: image
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

        let node = FilterGraphNode(
            id: nodeId,
            filterName: name,
            parameters: nonImageParams,
            inputs: inputs,
            isSource: false,
            sourceImage: nil
        )
        nodes[nodeId] = node
        return nodeId
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

// MARK: - Filter Categories

extension FilterGraphNode {
    /// Returns the filter category for bind group creation.
    var filterCategory: FilterCategory {
        switch filterName {
        case "Source":
            return .source

        case "CISourceOverCompositing", "CISourceAtopCompositing",
             "CISourceInCompositing", "CISourceOutCompositing",
             "CIDestinationOverCompositing", "CIDestinationAtopCompositing",
             "CIDestinationInCompositing", "CIDestinationOutCompositing",
             "CIMultiplyCompositing", "CIScreenCompositing",
             "CIOverlayCompositing", "CIDarkenCompositing",
             "CILightenCompositing", "CIColorDodgeCompositing",
             "CIColorBurnCompositing", "CISoftLightCompositing",
             "CIHardLightCompositing", "CIDifferenceCompositing",
             "CIExclusionCompositing", "CIAdditionCompositing",
             "CISubtractCompositing", "CIDivideCompositing",
             "CIMaximumCompositing", "CIMinimumCompositing":
            return .compositing

        case "CIConstantColorGenerator", "CICheckerboardGenerator",
             "CIStripesGenerator", "CIRandomGenerator",
             "CILinearGradient", "CIRadialGradient":
            return .generator

        default:
            return .standard
        }
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
}
#endif
