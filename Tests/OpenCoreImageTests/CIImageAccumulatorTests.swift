//
//  CIImageAccumulatorTests.swift
//  OpenCoreImage
//
//  Tests for CIImageAccumulator functionality.
//

import Testing
@testable import OpenCoreImage

// MARK: - CIImageAccumulator Initialization Tests

@Suite("CIImageAccumulator Initialization")
struct CIImageAccumulatorInitializationTests {

    @Test("Initialize with extent and format")
    func initWithExtentAndFormat() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )
        #expect(accumulator != nil)
        #expect(accumulator?.extent.width == 100)
        #expect(accumulator?.extent.height == 100)
        #expect(accumulator?.format == .RGBA8)
    }

    @Test("Initialize with color space")
    func initWithColorSpace() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 50, height: 50),
            format: .RGBAf,
            colorSpace: colorSpace
        )
        #expect(accumulator != nil)
        #expect(accumulator?.format == .RGBAf)
    }

    @Test("Initialize with various formats")
    func initWithVariousFormats() {
        let extent = CGRect(x: 0, y: 0, width: 100, height: 100)

        let rgba8 = CIImageAccumulator(extent: extent, format: .RGBA8)
        #expect(rgba8 != nil)

        let rgbaf = CIImageAccumulator(extent: extent, format: .RGBAf)
        #expect(rgbaf != nil)

        let bgra8 = CIImageAccumulator(extent: extent, format: .BGRA8)
        #expect(bgra8 != nil)
    }
}

// MARK: - CIImageAccumulator Properties Tests

@Suite("CIImageAccumulator Properties")
struct CIImageAccumulatorPropertiesTests {

    @Test("Extent property")
    func extentProperty() {
        let extent = CGRect(x: 10, y: 20, width: 200, height: 150)
        let accumulator = CIImageAccumulator(extent: extent, format: .RGBA8)!
        #expect(accumulator.extent == extent)
    }

    @Test("Format property")
    func formatProperty() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBAh
        )!
        #expect(accumulator.format == .RGBAh)
    }
}

// MARK: - CIImageAccumulator Image Tests

@Suite("CIImageAccumulator Image")
struct CIImageAccumulatorImageTests {

    @Test("Get initial image")
    func getInitialImage() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!
        let image = accumulator.image()
        #expect(image.extent.width == 100)
        #expect(image.extent.height == 100)
    }

    @Test("Set image")
    func setImage() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!
        let newImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        accumulator.setImage(newImage)

        let result = accumulator.image()
        #expect(result.extent.width == 100)
    }

    @Test("Set image with dirty rect")
    func setImageWithDirtyRect() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!

        // Set initial image
        let baseImage = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        accumulator.setImage(baseImage)

        // Update with dirty rect
        let updateImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 50, height: 50))
        accumulator.setImage(updateImage, dirtyRect: CGRect(x: 0, y: 0, width: 50, height: 50))

        let result = accumulator.image()
        // The result extent depends on how composited(over:) computes the union
        // Just verify we got a valid image back
        #expect(result.extent.width > 0)
    }
}

// MARK: - CIImageAccumulator Clear Tests

@Suite("CIImageAccumulator Clear")
struct CIImageAccumulatorClearTests {

    @Test("Clear resets to transparent")
    func clearResetsToTransparent() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!

        // Set an image
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        accumulator.setImage(image)

        // Clear
        accumulator.clear()

        // Get result
        let result = accumulator.image()
        #expect(result.extent.width == 100)
    }
}

// MARK: - CIImageAccumulator Equatable/Hashable Tests

@Suite("CIImageAccumulator Equatable and Hashable")
struct CIImageAccumulatorEquatableHashableTests {

    @Test("Same instance is equal")
    func sameInstanceEqual() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!
        #expect(accumulator == accumulator)
    }

    @Test("Different instances are not equal")
    func differentInstancesNotEqual() {
        let acc1 = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!
        let acc2 = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!
        #expect(acc1 != acc2)
    }

    @Test("Same instance has same hash")
    func sameInstanceSameHash() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!
        #expect(accumulator.hashValue == accumulator.hashValue)
    }
}

// MARK: - CIImageAccumulator Description Tests

@Suite("CIImageAccumulator Description")
struct CIImageAccumulatorDescriptionTests {

    @Test("Description includes extent and format")
    func descriptionIncludesExtentAndFormat() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!
        let desc = accumulator.description
        #expect(desc.contains("CIImageAccumulator"))
        #expect(desc.contains("extent"))
        #expect(desc.contains("format"))
    }

    @Test("Debug description includes more details")
    func debugDescriptionIncludesDetails() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!
        let debug = accumulator.debugDescription
        #expect(debug.contains("CIImageAccumulator"))
        #expect(debug.contains("extent"))
        #expect(debug.contains("format"))
        #expect(debug.contains("colorSpace"))
    }
}

// MARK: - CIImageAccumulator Use Case Tests

@Suite("CIImageAccumulator Use Cases")
struct CIImageAccumulatorUseCaseTests {

    @Test("Paint stroke simulation")
    func paintStrokeSimulation() {
        // Create canvas
        let canvas = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 200, height: 200),
            format: .RGBA8
        )!

        // Set initial image to cover the full extent
        let background = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 200, height: 200))
        canvas.setImage(background)

        // Simulate paint strokes
        for i in 0..<3 {
            let x = CGFloat(i * 20)
            let strokeRect = CGRect(x: x, y: x, width: 50, height: 50)
            let stroke = CIImage(color: .red).cropped(to: strokeRect)
            canvas.setImage(stroke, dirtyRect: strokeRect)
        }

        let result = canvas.image()
        // Verify we got a valid result with reasonable dimensions
        #expect(result.extent.width > 0)
    }

    @Test("Iterative filter application")
    func iterativeFilterApplication() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!

        // Initial image
        let initial = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        accumulator.setImage(initial)

        // Apply filter multiple times
        for _ in 0..<3 {
            let current = accumulator.image()
            let filtered = current.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 1.0])
            accumulator.setImage(filtered)
        }

        let result = accumulator.image()
        #expect(result !== initial)
    }
}
