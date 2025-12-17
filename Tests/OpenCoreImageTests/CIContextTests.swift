//
//  CIContextTests.swift
//  OpenCoreImage
//
//  Tests for CIContext functionality.
//

import Testing
import Foundation
@testable import OpenCoreImage

// MARK: - CIContext Initialization Tests

@Suite("CIContext Initialization")
struct CIContextInitializationTests {

    @Test("Initialize default context")
    func initDefaultContext() {
        let context = CIContext()
        #expect(context.workingColorSpace != nil)
    }

    @Test("Initialize with options")
    func initWithOptions() {
        let options: [CIContextOption: Any] = [
            .highQualityDownsample: true,
            .priorityRequestLow: true
        ]
        let context = CIContext(options: options)
        #expect(context != nil)
    }

    @Test("Offline GPU count is non-negative")
    func offlineGPUCountNonNegative() {
        #expect(CIContext.offlineGPUCount() >= 0)
    }
}

// MARK: - CIContext Properties Tests

@Suite("CIContext Properties")
struct CIContextPropertiesTests {

    @Test("Working color space")
    func workingColorSpace() {
        let context = CIContext()
        #expect(context.workingColorSpace != nil)
    }

    @Test("Working format")
    func workingFormat() {
        let context = CIContext()
        let format = context.workingFormat
        #expect(format.rawValue >= 0)
    }
}

// MARK: - CIContext CGImage Creation Tests

@Suite("CIContext CGImage Creation")
struct CIContextCGImageCreationTests {

    @Test("Create CGImage from CIImage with color")
    func createCGImageFromColor() {
        let context = CIContext()
        let ciImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        #expect(cgImage != nil)
        #expect(cgImage?.width == 100)
        #expect(cgImage?.height == 100)
    }

    @Test("Create CGImage with format")
    func createCGImageWithFormat() {
        let context = CIContext()
        let ciImage = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 50, height: 50))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent, format: .RGBA8, colorSpace: colorSpace)
        #expect(cgImage != nil)
    }

    @Test("Create CGImage with deferred")
    func createCGImageDeferred() {
        let context = CIContext()
        let ciImage = CIImage(color: .green).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent, format: .RGBA8, colorSpace: colorSpace, deferred: true)
        #expect(cgImage != nil)
    }
}

// MARK: - CIContext Pixel Value Verification Tests

@Suite("CIContext Pixel Value Verification")
struct CIContextPixelValueTests {

    @Test("Solid red image renders correct pixel values")
    func solidRedImagePixels() {
        let context = CIContext()
        let ciImage = CIImage(color: CIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
            .cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            Issue.record("Failed to create CGImage")
            return
        }

        // Extract pixel data from CGImage
        let width = cgImage.width
        let height = cgImage.height
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let cgContext = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            Issue.record("Failed to create CGContext")
            return
        }

        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Check first pixel is red (R=255, G=0, B=0, A=255)
        #expect(pixelData[0] == 255, "Red channel should be 255")
        #expect(pixelData[1] == 0, "Green channel should be 0")
        #expect(pixelData[2] == 0, "Blue channel should be 0")
        #expect(pixelData[3] == 255, "Alpha channel should be 255")
    }

    @Test("Solid green image renders correct pixel values")
    func solidGreenImagePixels() {
        let context = CIContext()
        let ciImage = CIImage(color: CIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0))
            .cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            Issue.record("Failed to create CGImage")
            return
        }

        let width = cgImage.width
        let height = cgImage.height
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let cgContext = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            Issue.record("Failed to create CGContext")
            return
        }

        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Check first pixel is green (R=0, G=255, B=0, A=255)
        #expect(pixelData[0] == 0, "Red channel should be 0")
        #expect(pixelData[1] == 255, "Green channel should be 255")
        #expect(pixelData[2] == 0, "Blue channel should be 0")
        #expect(pixelData[3] == 255, "Alpha channel should be 255")
    }

    @Test("Semi-transparent image renders correct alpha")
    func semiTransparentImagePixels() {
        let context = CIContext()
        let ciImage = CIImage(color: CIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5))
            .cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            Issue.record("Failed to create CGImage")
            return
        }

        let width = cgImage.width
        let height = cgImage.height
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let cgContext = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            Issue.record("Failed to create CGContext")
            return
        }

        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Alpha should be approximately 128 (0.5 * 255)
        // Premultiplied: RGB values should also be approximately 128
        let alpha = pixelData[3]
        #expect(alpha >= 120 && alpha <= 135, "Alpha should be approximately 128, got \(alpha)")
    }
}

// MARK: - CIContext Image Limits Tests

@Suite("CIContext Image Limits")
struct CIContextImageLimitsTests {

    @Test("Input image maximum size")
    func inputImageMaxSize() {
        let context = CIContext()
        let size = context.inputImageMaximumSize()
        #expect(size.width > 0)
        #expect(size.height > 0)
    }

    @Test("Output image maximum size")
    func outputImageMaxSize() {
        let context = CIContext()
        let size = context.outputImageMaximumSize()
        #expect(size.width > 0)
        #expect(size.height > 0)
    }
}

// MARK: - CIContext Caching Tests

@Suite("CIContext Caching")
struct CIContextCachingTests {

    @Test("Clear caches allows subsequent rendering")
    func clearCachesAllowsRendering() {
        let context = CIContext()

        // First render
        let image1 = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))
        let result1 = context.createCGImage(image1, from: image1.extent)
        #expect(result1 != nil)

        // Clear caches
        context.clearCaches()

        // Second render should still work
        let image2 = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))
        let result2 = context.createCGImage(image2, from: image2.extent)
        #expect(result2 != nil)
    }

    @Test("Reclaim resources allows subsequent rendering")
    func reclaimResourcesAllowsRendering() {
        let context = CIContext()

        // First render
        let image1 = CIImage(color: .green).cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))
        let result1 = context.createCGImage(image1, from: image1.extent)
        #expect(result1 != nil)

        // Reclaim
        context.reclaimResources()

        // Second render should still work
        let image2 = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))
        let result2 = context.createCGImage(image2, from: image2.extent)
        #expect(result2 != nil)
    }
}

// MARK: - CIContext HDR Stats Tests

@Suite("CIContext HDR Stats")
struct CIContextHDRStatsTests {

    @Test("Calculate HDR stats returns image")
    func calculateHDRStats() {
        let context = CIContext()
        let image = CIImage(color: .red)
        let result = context.calculateHDRStats(for: image)
        #expect(result != nil)
    }
}

// MARK: - CIContextOption Tests

@Suite("CIContextOption")
struct CIContextOptionTests {

    @Test("Output color space option")
    func outputColorSpaceOption() {
        #expect(CIContextOption.outputColorSpace.rawValue == "kCIContextOutputColorSpace")
    }

    @Test("Working color space option")
    func workingColorSpaceOption() {
        #expect(CIContextOption.workingColorSpace.rawValue == "kCIContextWorkingColorSpace")
    }

    @Test("Working format option")
    func workingFormatOption() {
        #expect(CIContextOption.workingFormat.rawValue == "kCIContextWorkingFormat")
    }

    @Test("High quality downsample option")
    func highQualityDownsampleOption() {
        #expect(CIContextOption.highQualityDownsample.rawValue == "kCIContextHighQualityDownsample")
    }

    @Test("Cache intermediates option")
    func cacheIntermediatesOption() {
        #expect(CIContextOption.cacheIntermediates.rawValue == "kCIContextCacheIntermediates")
    }

    @Test("Uses software renderer option")
    func usesSoftwareRendererOption() {
        #expect(CIContextOption.useSoftwareRenderer.rawValue == "kCIContextUseSoftwareRenderer")
    }

    @Test("Priority request low option")
    func priorityRequestLowOption() {
        #expect(CIContextOption.priorityRequestLow.rawValue == "kCIContextPriorityRequestLow")
    }

    @Test("Allow low power option")
    func allowLowPowerOption() {
        #expect(CIContextOption.allowLowPower.rawValue == "kCIContextAllowLowPower")
    }

    @Test("Name option")
    func nameOption() {
        #expect(CIContextOption.name.rawValue == "kCIContextName")
    }

    @Test("Options are equatable")
    func optionsEquatable() {
        #expect(CIContextOption.name == CIContextOption.name)
        #expect(CIContextOption.name != CIContextOption.workingFormat)
    }

    @Test("Options are hashable")
    func optionsHashable() {
        var set: Set<CIContextOption> = []
        set.insert(.name)
        set.insert(.name)
        set.insert(.workingFormat)
        #expect(set.count == 2)
    }
}

// MARK: - CIContext Equatable/Hashable Tests

@Suite("CIContext Equatable and Hashable")
struct CIContextEquatableHashableTests {

    @Test("Same instance is equal")
    func sameInstanceEqual() {
        let context = CIContext()
        #expect(context == context)
    }

    @Test("Different instances are not equal")
    func differentInstancesNotEqual() {
        let context1 = CIContext()
        let context2 = CIContext()
        #expect(context1 != context2)
    }

    @Test("Same instance has same hash")
    func sameInstanceSameHash() {
        let context = CIContext()
        #expect(context.hashValue == context.hashValue)
    }
}

// MARK: - CIError Tests

@Suite("CIError")
struct CIErrorTests {

    @Test("CIError not implemented")
    func ciErrorNotImplemented() {
        let error = CIError.notImplemented
        #expect(error == .notImplemented)
    }

    @Test("CIError rendering failed")
    func ciErrorRenderFailed() {
        let error = CIError.renderingFailed
        #expect(error == .renderingFailed)
    }

    @Test("CIError invalid argument")
    func ciErrorInvalidArgument() {
        let error = CIError.invalidArgument
        #expect(error == .invalidArgument)
    }

    @Test("CIError out of memory")
    func ciErrorOutOfMemory() {
        let error = CIError.outOfMemory
        #expect(error == .outOfMemory)
    }
}

// MARK: - CIImageRepresentationOption Tests

@Suite("CIImageRepresentationOption")
struct CIImageRepresentationOptionTests {

    @Test("JPEG quality option")
    func jpegQualityOption() {
        #expect(CIImageRepresentationOption.jpegQuality.rawValue == "kCGImageDestinationLossyCompressionQuality")
    }

    @Test("HDR image option")
    func hdrImageOption() {
        #expect(CIImageRepresentationOption.hdrImage.rawValue == "kCIImageRepresentationHDRImage")
    }

    @Test("Options are equatable")
    func optionsEquatable() {
        #expect(CIImageRepresentationOption.jpegQuality == CIImageRepresentationOption.jpegQuality)
        #expect(CIImageRepresentationOption.jpegQuality != CIImageRepresentationOption.hdrImage)
    }
}
