//
//  FilterGraphTests.swift
//  OpenCoreImage
//
//  Tests for FilterGraph DAG construction and traversal.
//

import Testing
@testable import OpenCoreImage

// MARK: - FilterGraphNode Tests

@Suite("FilterGraphNode")
struct FilterGraphNodeTests {

    @Test("Source node properties")
    func sourceNodeProperties() {
        let extent = CGRect(x: 0, y: 0, width: 100, height: 100)
        let node = FilterGraphNode(
            id: 0,
            filterName: "Source",
            parameters: [:],
            inputs: [:],
            isSource: true,
            sourceImage: nil,
            inputExtent: extent,
            outputExtent: extent
        )

        #expect(node.id == 0)
        #expect(node.filterName == "Source")
        #expect(node.isSource == true)
        #expect(node.inputs.isEmpty)
        #expect(node.parameters.isEmpty)
        #expect(node.inputExtent == extent)
        #expect(node.outputExtent == extent)
    }

    @Test("Filter node properties")
    func filterNodeProperties() {
        let inputExtent = CGRect(x: 0, y: 0, width: 100, height: 100)
        let node = FilterGraphNode(
            id: 1,
            filterName: "CIGaussianBlur",
            parameters: [kCIInputRadiusKey: 10.0],
            inputs: [kCIInputImageKey: .node(0)],
            isSource: false,
            sourceImage: nil,
            inputExtent: inputExtent,
            outputExtent: inputExtent
        )

        #expect(node.id == 1)
        #expect(node.filterName == "CIGaussianBlur")
        #expect(node.isSource == false)
        #expect(node.parameters[kCIInputRadiusKey] as? Double == 10.0)

        if case .node(let inputNodeId) = node.inputs[kCIInputImageKey] {
            #expect(inputNodeId == 0)
        } else {
            Issue.record("Expected node input")
        }
    }

    @Test("Node identifiable conformance")
    func nodeIdentifiable() {
        let node = FilterGraphNode(
            id: 42,
            filterName: "Source",
            parameters: [:],
            inputs: [:],
            isSource: true,
            sourceImage: nil,
            inputExtent: .zero,
            outputExtent: .zero
        )

        #expect(node.id == 42)
    }
}

// MARK: - FilterGraphInput Tests

@Suite("FilterGraphInput")
struct FilterGraphInputTests {

    @Test("Node input case")
    func nodeInputCase() {
        let input = FilterGraphInput.node(5)

        if case .node(let nodeId) = input {
            #expect(nodeId == 5)
        } else {
            Issue.record("Expected node case")
        }
    }

    @Test("Source image input case")
    func sourceImageInputCase() {
        let image = CIImage(color: .red)
        let input = FilterGraphInput.sourceImage(image)

        if case .sourceImage(let img) = input {
            #expect(img === image)
        } else {
            Issue.record("Expected sourceImage case")
        }
    }
}

// MARK: - FilterGraph Tests

@Suite("FilterGraph")
struct FilterGraphTests {

    @Test("Graph with single source node")
    func singleSourceNode() {
        let node = FilterGraphNode(
            id: 0,
            filterName: "Source",
            parameters: [:],
            inputs: [:],
            isSource: true,
            sourceImage: nil,
            inputExtent: CGRect(x: 0, y: 0, width: 100, height: 100),
            outputExtent: CGRect(x: 0, y: 0, width: 100, height: 100)
        )

        let graph = FilterGraph(
            nodes: [0: node],
            outputNodeId: 0,
            sourceNodeIds: [0],
            executionOrder: [0]
        )

        #expect(graph.nodes.count == 1)
        #expect(graph.outputNodeId == 0)
        #expect(graph.sourceNodeIds == [0])
        #expect(graph.executionOrder == [0])
    }

    @Test("Graph execution order is valid")
    func executionOrderIsValid() {
        // Source -> Filter1 -> Filter2 (output)
        let sourceNode = FilterGraphNode(
            id: 0,
            filterName: "Source",
            parameters: [:],
            inputs: [:],
            isSource: true,
            sourceImage: nil,
            inputExtent: .zero,
            outputExtent: .zero
        )

        let filter1Node = FilterGraphNode(
            id: 1,
            filterName: "CIGaussianBlur",
            parameters: [:],
            inputs: [kCIInputImageKey: .node(0)],
            isSource: false,
            sourceImage: nil,
            inputExtent: .zero,
            outputExtent: .zero
        )

        let filter2Node = FilterGraphNode(
            id: 2,
            filterName: "CISepiaTone",
            parameters: [:],
            inputs: [kCIInputImageKey: .node(1)],
            isSource: false,
            sourceImage: nil,
            inputExtent: .zero,
            outputExtent: .zero
        )

        let graph = FilterGraph(
            nodes: [0: sourceNode, 1: filter1Node, 2: filter2Node],
            outputNodeId: 2,
            sourceNodeIds: [0],
            executionOrder: [0, 1, 2]
        )

        #expect(graph.executionOrder.count == 3)
        // Source must come before filters that depend on it
        let sourceIndex = graph.executionOrder.firstIndex(of: 0)!
        let filter1Index = graph.executionOrder.firstIndex(of: 1)!
        let filter2Index = graph.executionOrder.firstIndex(of: 2)!
        #expect(sourceIndex < filter1Index)
        #expect(filter1Index < filter2Index)
    }
}

// MARK: - FilterGraphBuilder Tests

@Suite("FilterGraphBuilder")
struct FilterGraphBuilderTests {

    @Test("Build graph from source image")
    func buildFromSourceImage() {
        let image = CIImage(color: .red)
        var builder = FilterGraphBuilder()
        let graph = builder.build(from: image)

        #expect(graph.nodes.count == 1)
        #expect(graph.sourceNodeIds.count == 1)
        #expect(graph.executionOrder.count == 1)

        let sourceNode = graph.nodes[graph.outputNodeId]
        #expect(sourceNode?.isSource == true)
        #expect(sourceNode?.filterName == "Source")
    }

    @Test("Build graph from image with single filter")
    func buildWithSingleFilter() {
        let sourceImage = CIImage(color: .red)
        let filteredImage = sourceImage.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 10.0])

        var builder = FilterGraphBuilder()
        let graph = builder.build(from: filteredImage)

        #expect(graph.nodes.count == 2)  // Source + filter
        #expect(graph.sourceNodeIds.count == 1)
        #expect(graph.executionOrder.count == 2)

        // Output node should be the filter
        let outputNode = graph.nodes[graph.outputNodeId]
        #expect(outputNode?.filterName == "CIGaussianBlur")
        #expect(outputNode?.isSource == false)
    }

    @Test("Build graph from image with filter chain")
    func buildWithFilterChain() {
        let sourceImage = CIImage(color: .red)
        let step1 = sourceImage.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 5.0])
        let step2 = step1.applyingFilter("CISepiaTone", parameters: [kCIInputIntensityKey: 0.8])

        var builder = FilterGraphBuilder()
        let graph = builder.build(from: step2)

        #expect(graph.nodes.count == 3)  // Source + 2 filters
        #expect(graph.sourceNodeIds.count == 1)
        #expect(graph.executionOrder.count == 3)

        // Verify execution order: source must come first
        let sourceNodeId = graph.sourceNodeIds.first!
        #expect(graph.executionOrder.first == sourceNodeId)

        // Output should be sepia tone
        let outputNode = graph.nodes[graph.outputNodeId]
        #expect(outputNode?.filterName == "CISepiaTone")
    }

    @Test("Build graph with compositing filter")
    func buildWithCompositingFilter() {
        let foreground = CIImage(color: .red)
        let background = CIImage(color: .blue)

        let composited = foreground.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: background
        ])

        var builder = FilterGraphBuilder()
        let graph = builder.build(from: composited)

        // Should have: foreground source, background source, compositing filter
        #expect(graph.nodes.count == 3)
        #expect(graph.sourceNodeIds.count == 2)

        // Output should be the compositing filter
        let outputNode = graph.nodes[graph.outputNodeId]
        #expect(outputNode?.filterName == "CISourceOverCompositing")
        #expect(outputNode?.inputs.count == 2)  // inputImage + inputBackgroundImage
    }

    @Test("Build graph with multiple branches from same source")
    func buildWithMultipleBranches() {
        let sharedSource = CIImage(color: .green)
        let filtered1 = sharedSource.applyingFilter("CIGaussianBlur", parameters: [:])
        let filtered2 = sharedSource.applyingFilter("CISepiaTone", parameters: [:])

        // Combine both filtered images
        let combined = filtered1.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: filtered2
        ])

        var builder = FilterGraphBuilder()
        let graph = builder.build(from: combined)

        // Each filter chain creates its own base image, resulting in 2 source nodes
        // (one for each branch: blur and sepia)
        #expect(graph.sourceNodeIds.count == 2)

        // The graph should have: 2 sources + blur + sepia + compositing = 5 nodes
        #expect(graph.nodes.count == 5)

        // Output should be the compositing filter
        let outputNode = graph.nodes[graph.outputNodeId]
        #expect(outputNode?.filterName == "CISourceOverCompositing")
    }

    @Test("Topological sort produces valid order")
    func topologicalSortOrder() {
        let source = CIImage(color: .red)
        let blur = source.applyingFilter("CIGaussianBlur", parameters: [:])
        let sepia = blur.applyingFilter("CISepiaTone", parameters: [:])
        let bloom = sepia.applyingFilter("CIBloom", parameters: [:])

        var builder = FilterGraphBuilder()
        let graph = builder.build(from: bloom)

        // Verify all dependencies are satisfied in execution order
        var processed: Set<Int> = []
        for nodeId in graph.executionOrder {
            let node = graph.nodes[nodeId]!
            for input in node.inputs.values {
                if case .node(let inputId) = input {
                    #expect(processed.contains(inputId), "Node \(nodeId) depends on \(inputId) which hasn't been processed yet")
                }
            }
            processed.insert(nodeId)
        }
    }

    @Test("Output extent for crop filter")
    func outputExtentForCrop() {
        let source = CIImage(color: .red)
        let cropped = source.applyingFilter("CICrop", parameters: [
            "inputRectangle": CIVector(cgRect: CGRect(x: 10, y: 10, width: 50, height: 50))
        ])

        var builder = FilterGraphBuilder()
        let graph = builder.build(from: cropped)

        let outputNode = graph.nodes[graph.outputNodeId]
        // Crop intersects infinite extent with crop rect
        #expect(outputNode?.outputExtent.width == 50)
        #expect(outputNode?.outputExtent.height == 50)
    }

    @Test("Output extent for generator filter")
    func outputExtentForGenerator() {
        // Generator filters produce infinite extent
        let generator = CIImage(color: .red)  // CIConstantColorGenerator equivalent
            .applyingFilter("CIConstantColorGenerator", parameters: [
                kCIInputColorKey: CIColor.red
            ])

        var builder = FilterGraphBuilder()
        let graph = builder.build(from: generator)

        let outputNode = graph.nodes[graph.outputNodeId]
        #expect(outputNode?.outputExtent.isInfinite == true)
    }

    @Test("Output extent for scale transform")
    func outputExtentForScaleTransform() {
        // Create a finite extent source
        let source = CIImage(cgImage: createTestCGImage(width: 100, height: 100))
        let scaled = source.applyingFilter("CILanczosScaleTransform", parameters: [
            "inputScale": 2.0
        ])

        var builder = FilterGraphBuilder()
        let graph = builder.build(from: scaled)

        let outputNode = graph.nodes[graph.outputNodeId]
        #expect(outputNode?.outputExtent.width == 200)
        #expect(outputNode?.outputExtent.height == 200)
    }

    // Helper to create a test CGImage
    private func createTestCGImage(width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }
}

// MARK: - FilterCategory Tests

@Suite("FilterCategory")
struct FilterCategoryTests {

    @Test("All filter categories exist")
    func allCategoriesExist() {
        let categories: [FilterCategory] = [
            .source,
            .standard,
            .compositing,
            .generator,
            .transition,
            .blendWithMask,
            .reduction,
            .displacement
        ]

        #expect(categories.count == 8)
    }

    @Test("Categories are distinct")
    func categoriesAreDistinct() {
        let source = FilterCategory.source
        let standard = FilterCategory.standard
        let compositing = FilterCategory.compositing

        // Using pattern matching to verify distinctness
        switch source {
        case .source:
            break  // Expected
        default:
            Issue.record("source should match .source")
        }

        switch standard {
        case .standard:
            break  // Expected
        default:
            Issue.record("standard should match .standard")
        }

        switch compositing {
        case .compositing:
            break  // Expected
        default:
            Issue.record("compositing should match .compositing")
        }
    }
}
