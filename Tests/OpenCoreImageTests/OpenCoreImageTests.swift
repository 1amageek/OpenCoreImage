//
//  OpenCoreImageTests.swift
//  OpenCoreImage
//
//  Integration tests that verify components work together correctly.
//

import Testing
@testable import OpenCoreImage

// MARK: - Integration Tests

@Suite("OpenCoreImage Integration")
struct OpenCoreImageIntegrationTests {

    @Test("Complete filter pipeline: CIImage -> CIFilter -> CIContext")
    func completeFilterPipeline() {
        // Create source image
        let sourceImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(sourceImage.extent.width == 100)

        // Apply filter
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(sourceImage, forKey: kCIInputImageKey)
        filter.setValue(10.0, forKey: kCIInputRadiusKey)

        let outputImage = filter.outputImage
        #expect(outputImage != nil)

        #if arch(wasm32)
        // Render with context (requires WebGPU)
        let context = CIContext()
        let cgImage = context.createCGImage(outputImage!, from: sourceImage.extent)
        #expect(cgImage != nil)
        #endif
    }

    @Test("Filter chaining via CIImage convenience methods")
    func filterChainingConvenience() {
        // Test filter chaining with non-extent-modifying filters
        let image = CIImage(color: .blue)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
            .applyingFilter("CISepiaTone", parameters: [kCIInputIntensityKey: 0.8])
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 1.2])
            .transformed(by: CGAffineTransform(scaleX: 0.5, y: 0.5))

        #expect(image.extent.width == 50)
        #expect(image.extent.height == 50)
    }

    @Test("Blur filter expands extent")
    func blurFilterExpandsExtent() {
        let image = CIImage(color: .blue)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 10.0])

        // Blur expands extent by radius * 3 on each side
        // 100 + (10 * 3 * 2) = 160
        #expect(image.extent.width == 160)
        #expect(image.extent.height == 160)
    }

    @Test("Compositing two images")
    func compositingImages() {
        let foreground = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let background = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let composite = foreground.composited(over: background)
        #expect(composite.extent.width >= 100)
    }

    @Test("CIVector and CIColor interop with filters")
    func vectorColorInteropWithFilters() {
        let center = CIVector(x: 50, y: 50)
        let color = CIColor(red: 1.0, green: 0.5, blue: 0.0)

        // Test that CIVector and CIColor can be set on filters
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(center, forKey: kCIInputCenterKey)

        // Create an image with a solid color and apply filter
        let inputImage = CIImage(color: color).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(10.0, forKey: kCIInputRadiusKey)

        let output = filter.outputImage
        #expect(output != nil)
    }

    @Test("CIKernel apply produces valid output")
    func ciKernelApply() {
        let kernel = CIColorKernel(source: "testKernel")!
        let result = kernel.apply(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            arguments: nil
        )
        #expect(result != nil)
        #expect(result?.extent.width == 100)
    }

    @Test("CIBlendKernel compositing")
    func blendKernelCompositing() {
        let foreground = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let background = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let result = CIBlendKernel.multiply.apply(foreground: foreground, background: background)
        #expect(result != nil)
    }

    @Test("CIImageAccumulator feedback loop")
    func imageAccumulatorFeedback() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 100, height: 100),
            format: .RGBA8
        )!

        // Initial state
        let initial = CIImage(color: .red).cropped(to: accumulator.extent)
        accumulator.setImage(initial)

        // Feedback loop
        for _ in 0..<3 {
            let current = accumulator.image()
            let blurred = current.applyingGaussianBlur(sigma: 1.0)
            accumulator.setImage(blurred)
        }

        let final = accumulator.image()
        #expect(final !== initial)
    }

    @Test("CIRenderDestination workflow")
    func renderDestinationWorkflow() {
        var pixelData = [UInt8](repeating: 0, count: 50 * 50 * 4)
        let destination = pixelData.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 50,
                height: 50,
                bytesPerRow: 50 * 4,
                format: .RGBA8
            )
        }

        destination.alphaMode = .premultiplied
        destination.isDithered = false

        // Verify destination properties
        #expect(destination.width == 50)
        #expect(destination.height == 50)
        #expect(destination.alphaMode == .premultiplied)
        #expect(destination.isDithered == false)
    }
}

// MARK: - Type Safety Tests

@Suite("Type Safety")
struct TypeSafetyTests {

    @Test("CIFormat is Sendable")
    func formatSendable() async {
        let format = CIFormat.RGBA8
        let result = await Task { format }.value
        #expect(result == .RGBA8)
    }

    @Test("CIVector is Sendable")
    func vectorSendable() async {
        let vector = CIVector(x: 1.0, y: 2.0)
        let result = await Task { vector }.value
        #expect(result.x == 1.0)
    }

    @Test("CIColor is Sendable")
    func colorSendable() async {
        let color = CIColor.red
        let result = await Task { color }.value
        #expect(result.red == 1.0)
    }
}

// MARK: - Round-Trip Rendering Tests
// These tests require WebGPU for filter chain rendering

#if arch(wasm32)
@Suite("Round-Trip Rendering")
struct RoundTripRenderingTests {

    /// Helper to extract pixel data from CGImage
    private func extractPixels(from cgImage: CGImage) -> [UInt8]? {
        let width = cgImage.width
        let height = cgImage.height
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelData
    }

    @Test("Round-trip: CIImage color -> CGImage -> verify pixels")
    func roundTripColorImage() {
        // Create red CIImage
        let ciImage = CIImage(color: CIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
            .cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))

        // Render to CGImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            Issue.record("Failed to create CGImage")
            return
        }

        // Verify dimensions
        #expect(cgImage.width == 10)
        #expect(cgImage.height == 10)

        // Verify pixel values
        guard let pixels = extractPixels(from: cgImage) else {
            Issue.record("Failed to extract pixels")
            return
        }

        // First pixel should be red
        #expect(pixels[0] == 255, "Red channel")
        #expect(pixels[1] == 0, "Green channel")
        #expect(pixels[2] == 0, "Blue channel")
        #expect(pixels[3] == 255, "Alpha channel")

        // Last pixel should also be red (uniform color)
        let lastPixelIndex = (10 * 10 - 1) * 4
        #expect(pixels[lastPixelIndex] == 255, "Last pixel red channel")
    }

    @Test("Round-trip: Filter application preserves image dimensions")
    func roundTripFilterPreservesDimensions() {
        let ciImage = CIImage(color: .blue)
            .cropped(to: CGRect(x: 0, y: 0, width: 50, height: 50))
            .applyingFilter("CISepiaTone", parameters: [kCIInputIntensityKey: 0.8])

        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: 50, height: 50)) else {
            Issue.record("Failed to create CGImage")
            return
        }

        #expect(cgImage.width == 50)
        #expect(cgImage.height == 50)
    }

    @Test("Round-trip: Transform scales image correctly")
    func roundTripTransformScales() {
        let ciImage = CIImage(color: .green)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
            .transformed(by: CGAffineTransform(scaleX: 0.5, y: 0.5))

        // Extent should be 50x50
        #expect(ciImage.extent.width == 50)
        #expect(ciImage.extent.height == 50)

        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            Issue.record("Failed to create CGImage")
            return
        }

        #expect(cgImage.width == 50)
        #expect(cgImage.height == 50)
    }

    @Test("Round-trip: Multiple filter chain produces valid output")
    func roundTripMultipleFilters() {
        let ciImage = CIImage(color: CIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
            .cropped(to: CGRect(x: 0, y: 0, width: 20, height: 20))
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.0,
                kCIInputBrightnessKey: 0.2
            ])
            .applyingFilter("CIExposureAdjust", parameters: [
                kCIInputEVKey: 0.5
            ])

        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: 20, height: 20)) else {
            Issue.record("Failed to create CGImage")
            return
        }

        #expect(cgImage.width == 20)
        #expect(cgImage.height == 20)

        // Verify we got valid pixel data
        guard let pixels = extractPixels(from: cgImage) else {
            Issue.record("Failed to extract pixels")
            return
        }

        // At minimum, alpha should be 255 for opaque image
        #expect(pixels[3] == 255, "Alpha should be 255")
    }

    @Test("Round-trip: Compositing blends two images")
    func roundTripCompositing() {
        let foreground = CIImage(color: CIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5))
            .cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))
        let background = CIImage(color: CIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
            .cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))

        let composite = foreground.composited(over: background)

        let context = CIContext()
        guard let cgImage = context.createCGImage(composite, from: CGRect(x: 0, y: 0, width: 10, height: 10)) else {
            Issue.record("Failed to create CGImage")
            return
        }

        guard let pixels = extractPixels(from: cgImage) else {
            Issue.record("Failed to extract pixels")
            return
        }

        // Result should be a blend - not pure red, not pure blue
        // With source-over compositing of 50% red over blue, we expect:
        // R = 0.5*1.0 + 0.5*0.0 = 0.5, G = 0, B = 0.5*0.0 + 0.5*1.0 = 0.5
        // In premultiplied form, the exact values depend on alpha handling
        // Just verify we have both red and blue components
        let r = pixels[0]
        let b = pixels[2]
        let a = pixels[3]

        #expect(a == 255, "Alpha should be 255 (fully opaque result)")
        #expect(r > 0, "Should have some red component from foreground")
        #expect(b > 0, "Should have some blue component from background")
    }
}
#endif

// MARK: - Edge Case Tests

@Suite("Edge Cases")
struct EdgeCaseTests {

    @Test("Empty CIImage has zero extent")
    func emptyImageZeroExtent() {
        let empty = CIImage.empty()
        #expect(empty.extent == .zero)
    }

    @Test("Color image has infinite extent")
    func colorImageInfiniteExtent() {
        let color = CIImage(color: .red)
        #expect(color.extent.isInfinite)
    }

    @Test("Cropping infinite to finite")
    func croppingInfiniteToFinite() {
        let infinite = CIImage(color: .red)
        let finite = infinite.cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(finite.extent.width == 100)
        #expect(!finite.extent.isInfinite)
    }

    @Test("CIVector with large count")
    func vectorWithLargeCount() {
        var values = [CGFloat](repeating: 1.0, count: 100)
        let vector = CIVector(values: &values, count: 100)
        #expect(vector.count == 100)
    }

    @Test("CIFilter with unknown name still creates")
    func filterWithUnknownName() {
        let filter = CIFilter(name: "CIUnknownFilter12345")
        #expect(filter != nil)
    }

    @Test("Zero-size crop produces zero extent")
    func zeroSizeCrop() {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 0, height: 0))
        #expect(image.extent.width == 0)
        #expect(image.extent.height == 0)
    }

    @Test("Negative origin crop works correctly")
    func negativeOriginCrop() {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: -50, y: -50, width: 100, height: 100))
        #expect(image.extent.origin.x == -50)
        #expect(image.extent.origin.y == -50)
        #expect(image.extent.width == 100)
    }

    @Test("Very large extent is handled")
    func veryLargeExtent() {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 10000, height: 10000))
        #expect(image.extent.width == 10000)
        #expect(image.extent.height == 10000)
    }
}
