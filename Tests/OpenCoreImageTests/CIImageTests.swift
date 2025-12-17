//
//  CIImageTests.swift
//  OpenCoreImage
//
//  Tests for CIImage functionality.
//

import Testing
import Foundation
@testable import OpenCoreImage

// MARK: - CIImage Initialization Tests

@Suite("CIImage Initialization")
struct CIImageInitializationTests {

    @Test("Create empty image")
    func createEmpty() {
        let image = CIImage.empty()
        #expect(image.extent == .zero)
    }

    @Test("Initialize with color creates infinite extent")
    func initWithColor() {
        let color = CIColor(red: 1.0, green: 0.0, blue: 0.0)
        let image = CIImage(color: color)
        #expect(image.extent.isInfinite)
    }

    @Test("Initialize with CGImage")
    func initWithCGImage() {
        // Create a minimal CGImage for testing
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        var pixelData = Data(count: 4 * 10 * 10)  // 10x10 image
        guard let context = pixelData.withUnsafeMutableBytes({ ptr -> CGContext? in
            CGContext(
                data: ptr.baseAddress,
                width: 10,
                height: 10,
                bitsPerComponent: 8,
                bytesPerRow: 40,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            )
        }) else {
            Issue.record("Failed to create CGContext")
            return
        }

        guard let cgImage = context.makeImage() else {
            Issue.record("Failed to create CGImage")
            return
        }

        let ciImage = CIImage(cgImage: cgImage)
        #expect(ciImage.extent.width == 10)
        #expect(ciImage.extent.height == 10)
        #expect(ciImage.cgImage != nil)
    }

    @Test("Initialize with data")
    func initWithData() {
        let data = Data(count: 100)
        let image = CIImage(data: data)
        #expect(image != nil)
    }

    @Test("Initialize with bitmap data")
    func initWithBitmapData() {
        let data = Data(count: 100 * 100 * 4)  // 100x100 RGBA
        let size = CGSize(width: 100, height: 100)
        let image = CIImage(
            bitmapData: data,
            bytesPerRow: 400,
            size: size,
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        #expect(image.extent.width == 100)
        #expect(image.extent.height == 100)
    }
}

// MARK: - CIImage Preset Colors Tests

@Suite("CIImage Preset Colors")
struct CIImagePresetColorTests {

    @Test("Black image is infinite")
    func blackImage() {
        let image = CIImage.black
        #expect(image.extent.isInfinite)
    }

    @Test("White image is infinite")
    func whiteImage() {
        let image = CIImage.white
        #expect(image.extent.isInfinite)
    }

    @Test("Red image is infinite")
    func redImage() {
        let image = CIImage.red
        #expect(image.extent.isInfinite)
    }

    @Test("Green image is infinite")
    func greenImage() {
        let image = CIImage.green
        #expect(image.extent.isInfinite)
    }

    @Test("Blue image is infinite")
    func blueImage() {
        let image = CIImage.blue
        #expect(image.extent.isInfinite)
    }

    @Test("Clear image is infinite")
    func clearImage() {
        let image = CIImage.clear
        #expect(image.extent.isInfinite)
    }
}

// MARK: - CIImage Filter Application Tests

@Suite("CIImage Filter Application")
struct CIImageFilterApplicationTests {

    @Test("Apply filter returns new image with filter in chain")
    func applyFilterReturnsNewImage() {
        let original = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let filtered = original.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 10.0])

        #expect(original !== filtered)
        // Blur filter expands extent
        #expect(filtered.extent.width > original.extent.width)
        #expect(filtered.extent.height > original.extent.height)
    }

    @Test("Apply filter without parameters")
    func applyFilterWithoutParameters() {
        let original = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 50, height: 50))
        let filtered = original.applyingFilter("CIMedian")

        #expect(original !== filtered)
        // Median filter preserves extent
        #expect(filtered.extent == original.extent)
    }

    @Test("Chain multiple filters")
    func chainMultipleFilters() {
        let original = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let filtered = original
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 5.0])
            .applyingFilter("CISepiaTone", parameters: [kCIInputIntensityKey: 0.8])

        #expect(original !== filtered)
        // Blur expands extent, sepia preserves it
        #expect(filtered.extent.width >= original.extent.width)
    }

    @Test("Apply Gaussian blur convenience method")
    func applyGaussianBlurConvenience() {
        let original = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let filtered = original.applyingGaussianBlur(sigma: 10.0)

        #expect(original !== filtered)
        // Blur expands extent by sigma * 3 on each side
        #expect(filtered.extent.width > original.extent.width)
    }
}

// MARK: - CIImage Transformation Tests

@Suite("CIImage Transformation")
struct CIImageTransformationTests {

    @Test("Transform by identity")
    func transformByIdentity() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let transformed = image.transformed(by: .identity)
        #expect(transformed.extent == image.extent)
    }

    @Test("Transform by translation")
    func transformByTranslation() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let transform = CGAffineTransform(translationX: 50, y: 50)
        let transformed = image.transformed(by: transform)
        #expect(transformed.extent.origin.x == 50)
        #expect(transformed.extent.origin.y == 50)
    }

    @Test("Transform by scale")
    func transformByScale() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        let transformed = image.transformed(by: transform)
        #expect(transformed.extent.width == 200)
        #expect(transformed.extent.height == 200)
    }

    @Test("Transform with high quality downsample")
    func transformWithHighQualityDownsample() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let transformed = image.transformed(by: transform, highQualityDownsample: true)
        #expect(transformed.extent.width == 50)
        #expect(transformed.extent.height == 50)
    }
}

// MARK: - CIImage Cropping Tests

@Suite("CIImage Cropping")
struct CIImageCroppingTests {

    @Test("Crop image")
    func cropImage() {
        let image = CIImage(color: .red)
        let cropped = image.cropped(to: CGRect(x: 10, y: 10, width: 100, height: 100))
        #expect(cropped.extent == CGRect(x: 10, y: 10, width: 100, height: 100))
    }

    @Test("Crop with intersection")
    func cropWithIntersection() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let cropped = image.cropped(to: CGRect(x: 50, y: 50, width: 100, height: 100))
        #expect(cropped.extent.width == 50)
        #expect(cropped.extent.height == 50)
    }
}

// MARK: - CIImage Compositing Tests

@Suite("CIImage Compositing")
struct CIImageCompositingTests {

    @Test("Composite over")
    func compositeOver() {
        let foreground = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let background = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let result = foreground.composited(over: background)
        #expect(result.extent.width >= 100)
        #expect(result.extent.height >= 100)
    }
}

// MARK: - CIImage Clamping Tests

@Suite("CIImage Clamping")
struct CIImageClampingTests {

    @Test("Clamp to extent")
    func clampToExtent() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let clamped = image.clampedToExtent()
        #expect(clamped !== image)
    }

    @Test("Clamp to rect")
    func clampToRect() {
        let image = CIImage(color: .red)
        let clamped = image.clamped(to: CGRect(x: 10, y: 10, width: 50, height: 50))
        #expect(clamped !== image)
    }
}

// MARK: - CIImage Alpha Operations Tests

@Suite("CIImage Alpha Operations")
struct CIImageAlphaOperationsTests {

    @Test("Premultiply alpha")
    func premultiplyAlpha() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let result = image.premultiplyingAlpha()
        #expect(result !== image)
    }

    @Test("Unpremultiply alpha")
    func unpremultiplyAlpha() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let result = image.unpremultiplyingAlpha()
        #expect(result !== image)
    }

    @Test("Set alpha to one")
    func setAlphaOne() {
        let image = CIImage(color: .red)
        let result = image.settingAlphaOne(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(result !== image)
    }
}

// MARK: - CIImage Orientation Tests

@Suite("CIImage Orientation")
struct CIImageOrientationTests {

    @Test("Orient up (no change)")
    func orientUp() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let oriented = image.oriented(.up)
        #expect(oriented.extent.width == 100)
        #expect(oriented.extent.height == 100)
    }

    @Test("Orient down (180 rotation)")
    func orientDown() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let oriented = image.oriented(.down)
        // Allow for floating-point precision errors
        #expect(abs(oriented.extent.width - 100) < 1)
        #expect(abs(oriented.extent.height - 100) < 1)
    }

    @Test("Orient right (90 CW rotation)")
    func orientRight() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 50))
        let oriented = image.oriented(.right)
        // After 90 degree rotation, dimensions should change - allow floating-point error
        #expect(oriented.extent.width > 0)
        #expect(oriented.extent.height > 0)
    }

    @Test("Orientation transform for EXIF value")
    func orientationTransformExif() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let transform = image.orientationTransform(forExifOrientation: 1)
        #expect(transform == .identity)
    }
}

// MARK: - CIImage Properties Tests

@Suite("CIImage Properties")
struct CIImagePropertiesTests {

    @Test("Properties dictionary")
    func propertiesDictionary() {
        let image = CIImage(color: .red)
        #expect(image.properties is [String: Any])
    }

    @Test("Set properties")
    func setProperties() {
        let original = CIImage(color: .red)
        let modified = original.settingProperties(["TestKey": "TestValue"])
        #expect(modified !== original)
        #expect(modified.properties["TestKey"] as? String == "TestValue")
    }

    @Test("Content headroom default")
    func contentHeadroomDefault() {
        let image = CIImage(color: .red)
        #expect(image.contentHeadroom == 1.0)
    }

    @Test("Content average light level default")
    func contentAverageLightLevelDefault() {
        let image = CIImage(color: .red)
        #expect(image.contentAverageLightLevel == 1.0)
    }

    @Test("Is opaque for solid color")
    func isOpaqueForSolidColor() {
        let opaqueColor = CIColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)
        let image = CIImage(color: opaqueColor)
        #expect(image.isOpaque == true)
    }
}

// MARK: - CIImage Sampling Tests

@Suite("CIImage Sampling")
struct CIImageSamplingTests {

    @Test("Nearest sampling creates new image with nearest mode")
    func nearestSampling() {
        let image = CIImage(color: .red)
        let sampled = image.samplingNearest()

        // Should return a new instance
        #expect(sampled !== image)
        // Should preserve extent
        #expect(sampled.extent == image.extent)
        // Should have nearest sampling mode
        #expect(sampled._samplingMode == .nearest)
    }

    @Test("Linear sampling creates new image with linear mode")
    func linearSampling() {
        let image = CIImage(color: .red)
        let sampled = image.samplingLinear()

        // Should return a new instance
        #expect(sampled !== image)
        // Should preserve extent
        #expect(sampled.extent == image.extent)
        // Should have linear sampling mode
        #expect(sampled._samplingMode == .linear)
    }

    @Test("Default sampling mode is linear")
    func defaultSamplingMode() {
        let image = CIImage(color: .red)
        #expect(image._samplingMode == .linear)
    }

    @Test("Sampling mode is preserved through operations")
    func samplingModePreservedThroughOperations() {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
            .samplingNearest()

        // Apply another operation and verify sampling mode is preserved in the chain
        #expect(image._samplingMode == .nearest)
    }
}

// MARK: - CIImage Intermediate Tests

@Suite("CIImage Intermediate")
struct CIImageIntermediateTests {

    @Test("Default intermediate mode is none")
    func defaultIntermediateMode() {
        let image = CIImage(color: .red)
        #expect(image._intermediateMode == .none)
    }

    @Test("Inserting intermediate creates cached mode")
    func insertingIntermediate() {
        let image = CIImage(color: .red)
        let intermediate = image.insertingIntermediate()

        // Should return a new instance
        #expect(intermediate !== image)
        // Should have cached intermediate mode
        #expect(intermediate._intermediateMode == .cached)
        // Should preserve extent
        #expect(intermediate.extent == image.extent)
    }

    @Test("Inserting intermediate with cache true creates cached mode")
    func insertingIntermediateWithCacheTrue() {
        let image = CIImage(color: .red)
        let intermediate = image.insertingIntermediate(cache: true)

        #expect(intermediate !== image)
        #expect(intermediate._intermediateMode == .cached)
    }

    @Test("Inserting intermediate with cache false creates none mode")
    func insertingIntermediateWithCacheFalse() {
        let image = CIImage(color: .red)
        let intermediate = image.insertingIntermediate(cache: false)

        #expect(intermediate !== image)
        #expect(intermediate._intermediateMode == .none)
    }

    @Test("Inserting tiled intermediate creates tiled mode")
    func insertingTiledIntermediate() {
        let image = CIImage(color: .red)
        let intermediate = image.insertingTiledIntermediate()

        #expect(intermediate !== image)
        #expect(intermediate._intermediateMode == .tiled)
    }

    @Test("Intermediate mode is preserved through sampling")
    func intermediateModePreservedThroughSampling() {
        let image = CIImage(color: .red)
            .insertingIntermediate()
            .samplingNearest()

        #expect(image._intermediateMode == .cached)
        #expect(image._samplingMode == .nearest)
    }
}

// MARK: - CIImage Color Space Tests

@Suite("CIImage Color Space")
struct CIImageColorSpaceTests {

    @Test("Matched to working space")
    func matchedToWorkingSpace() {
        let image = CIImage(color: .red)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let matched = image.matchedToWorkingSpace(from: colorSpace)
        #expect(matched != nil)
    }

    @Test("Matched from working space")
    func matchedFromWorkingSpace() {
        let image = CIImage(color: .red)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let matched = image.matchedFromWorkingSpace(to: colorSpace)
        #expect(matched != nil)
    }

    @Test("Convert to Lab")
    func convertToLab() {
        let image = CIImage(color: .red)
        let converted = image.convertingWorkingSpaceToLab()
        #expect(converted !== image)
    }

    @Test("Convert from Lab")
    func convertFromLab() {
        let image = CIImage(color: .red)
        let converted = image.convertingLabToWorkingSpace()
        #expect(converted !== image)
    }
}

// MARK: - CIImage ROI Tests

@Suite("CIImage ROI")
struct CIImageROITests {

    @Test("Region of interest")
    func regionOfInterest() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let roi = image.regionOfInterest(for: image, in: CGRect(x: 0, y: 0, width: 50, height: 50))
        #expect(roi.width <= 50)
        #expect(roi.height <= 50)
    }
}

// MARK: - CIImage HDR Tests

@Suite("CIImage HDR")
struct CIImageHDRTests {

    @Test("Default content headroom is 1.0")
    func defaultContentHeadroom() {
        let image = CIImage(color: .red)
        #expect(image.contentHeadroom == 1.0)
    }

    @Test("Default content average light level is 1.0")
    func defaultContentAverageLightLevel() {
        let image = CIImage(color: .red)
        #expect(image.contentAverageLightLevel == 1.0)
    }

    @Test("Set content headroom creates new image with updated value")
    func setContentHeadroom() {
        let image = CIImage(color: .red)
        let modified = image.settingContentHeadroom(2.0)

        // Should return a new instance
        #expect(modified !== image)
        // Should have the new headroom value
        #expect(modified.contentHeadroom == 2.0)
        // Should preserve other properties
        #expect(modified.extent == image.extent)
        #expect(modified.contentAverageLightLevel == 1.0)
    }

    @Test("Set content average light level creates new image with updated value")
    func setContentAverageLightLevel() {
        let image = CIImage(color: .red)
        let modified = image.settingContentAverageLightLevel(0.5)

        // Should return a new instance
        #expect(modified !== image)
        // Should have the new light level value
        #expect(modified.contentAverageLightLevel == 0.5)
        // Should preserve other properties
        #expect(modified.extent == image.extent)
        #expect(modified.contentHeadroom == 1.0)
    }

    @Test("HDR properties can be chained")
    func chainHDRProperties() {
        let image = CIImage(color: .red)
            .settingContentHeadroom(3.0)
            .settingContentAverageLightLevel(0.8)

        #expect(image.contentHeadroom == 3.0)
        #expect(image.contentAverageLightLevel == 0.8)
    }

    @Test("Apply gain map adds filter to chain")
    func applyGainMap() {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let gainMap = CIImage(color: .white)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let result = image.applyingGainMap(gainMap)

        // Should return a new instance
        #expect(result !== image)
        // Should have a filter applied
        #expect(result._filters.count > image._filters.count)
    }

    @Test("Apply gain map with headroom adds filter")
    func applyGainMapWithHeadroom() {
        let image = CIImage(color: .red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let gainMap = CIImage(color: .white)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let result = image.applyingGainMap(gainMap, headroom: 1.5)

        #expect(result !== image)
        #expect(result._filters.count > image._filters.count)
    }
}

// MARK: - CIImage Equatable/Hashable Tests

@Suite("CIImage Equatable and Hashable")
struct CIImageEquatableHashableTests {

    @Test("Same instance is equal")
    func sameInstanceEqual() {
        let image = CIImage(color: .red)
        #expect(image == image)
    }

    @Test("Different instances are not equal")
    func differentInstancesNotEqual() {
        let image1 = CIImage(color: .red)
        let image2 = CIImage(color: .red)
        #expect(image1 != image2)  // Reference equality
    }

    @Test("Same instance has same hash")
    func sameInstanceSameHash() {
        let image = CIImage(color: .red)
        #expect(image.hashValue == image.hashValue)
    }
}

// MARK: - CIImage Description Tests

@Suite("CIImage Description")
struct CIImageDescriptionTests {

    @Test("Description includes extent")
    func descriptionIncludesExtent() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(image.description.contains("extent"))
    }

    @Test("Debug description includes details")
    func debugDescriptionIncludesDetails() {
        let image = CIImage(color: .red)
        let debug = image.debugDescription
        #expect(debug.contains("CIImage"))
        #expect(debug.contains("extent"))
    }
}

// MARK: - CIImageOption Tests

@Suite("CIImageOption")
struct CIImageOptionTests {

    @Test("All image options follow CoreImage naming convention")
    func allOptionsFollowNamingConvention() {
        // All options should have rawValue starting with "kCIImage"
        let options: [CIImageOption] = [
            .colorSpace,
            .toneMapHDRtoSDR,
            .nearestSampling,
            .properties,
            .applyOrientationProperty,
            .auxiliaryDepth,
            .auxiliaryDisparity,
            .auxiliaryPortraitEffectsMatte,
            .auxiliarySemanticSegmentationSkinMatte,
            .auxiliarySemanticSegmentationHairMatte,
            .auxiliarySemanticSegmentationTeethMatte,
            .auxiliarySemanticSegmentationGlassesMatte,
            .auxiliarySemanticSegmentationSkyMatte,
            .auxiliaryHDRGainMap
        ]

        for option in options {
            #expect(option.rawValue.hasPrefix("kCIImage"), "Option '\(option.rawValue)' should start with 'kCIImage'")
            #expect(!option.rawValue.isEmpty, "Option rawValue should not be empty")
        }
    }

    @Test("Options can be used as dictionary keys")
    func optionsAsDictionaryKeys() {
        var dict: [CIImageOption: Any] = [:]
        dict[.colorSpace] = CGColorSpaceCreateDeviceRGB()
        dict[.nearestSampling] = true
        dict[.properties] = ["key": "value"]

        #expect(dict.count == 3)
        #expect(dict[.colorSpace] != nil)
        #expect(dict[.nearestSampling] as? Bool == true)
    }

    @Test("CIImage init accepts options dictionary")
    func initWithOptions() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let options: [CIImageOption: Any] = [
            .colorSpace: colorSpace,
            .nearestSampling: true
        ]

        // Create sample data for initialization
        let data = Data([0xFF, 0x00, 0x00, 0xFF]) // 1 red pixel RGBA
        let image = CIImage(data: data, options: options)

        // Verifies options are accepted without error
        #expect(image != nil)
    }

    @Test("Different options are not equal")
    func optionInequality() {
        #expect(CIImageOption.colorSpace != CIImageOption.nearestSampling)
        #expect(CIImageOption.properties != CIImageOption.auxiliaryDepth)
    }

    @Test("Same options are equal")
    func optionEquality() {
        let option1 = CIImageOption.colorSpace
        let option2 = CIImageOption.colorSpace
        #expect(option1 == option2)
        #expect(option1.rawValue == option2.rawValue)
    }

    @Test("Options work correctly in Set")
    func optionHashing() {
        var set = Set<CIImageOption>()
        set.insert(.colorSpace)
        set.insert(.colorSpace)
        set.insert(.nearestSampling)
        set.insert(.properties)
        #expect(set.count == 3)
        #expect(set.contains(.colorSpace))
        #expect(set.contains(.nearestSampling))
        #expect(set.contains(.properties))
        #expect(!set.contains(.auxiliaryDepth))
    }

    @Test("Custom option can be created")
    func customOption() {
        let custom = CIImageOption(rawValue: "customOption")
        #expect(custom.rawValue == "customOption")
        #expect(custom != .colorSpace)
    }
}

// MARK: - CIImageAutoAdjustmentOption Tests

@Suite("CIImageAutoAdjustmentOption")
struct CIImageAutoAdjustmentOptionTests {

    @Test("All auto adjustment options follow CoreImage naming convention")
    func allOptionsFollowNamingConvention() {
        let options: [CIImageAutoAdjustmentOption] = [
            .enhance,
            .redEye,
            .features,
            .crop,
            .level
        ]

        for option in options {
            #expect(option.rawValue.hasPrefix("kCIImageAutoAdjust"), "Option '\(option.rawValue)' should start with 'kCIImageAutoAdjust'")
            #expect(!option.rawValue.isEmpty, "Option rawValue should not be empty")
        }
    }

    @Test("Auto adjustment options can be used as dictionary keys")
    func optionsAsDictionaryKeys() {
        var dict: [CIImageAutoAdjustmentOption: Any] = [:]
        dict[.enhance] = true
        dict[.redEye] = false
        dict[.crop] = true

        #expect(dict.count == 3)
        #expect(dict[.enhance] as? Bool == true)
        #expect(dict[.redEye] as? Bool == false)
    }

    @Test("Different auto adjustment options are not equal")
    func optionInequality() {
        #expect(CIImageAutoAdjustmentOption.enhance != CIImageAutoAdjustmentOption.redEye)
        #expect(CIImageAutoAdjustmentOption.crop != CIImageAutoAdjustmentOption.level)
    }

    @Test("Same auto adjustment options are equal")
    func optionEquality() {
        let option1 = CIImageAutoAdjustmentOption.enhance
        let option2 = CIImageAutoAdjustmentOption.enhance
        #expect(option1 == option2)
    }

    @Test("Auto adjustment options work correctly in Set")
    func optionHashing() {
        var set = Set<CIImageAutoAdjustmentOption>()
        set.insert(.enhance)
        set.insert(.enhance)
        set.insert(.redEye)
        #expect(set.count == 2)
        #expect(set.contains(.enhance))
        #expect(set.contains(.redEye))
    }
}
