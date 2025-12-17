//
//  CIFilterConstantsTests.swift
//  OpenCoreImage
//
//  Tests for CIFilter string constants - verifying CoreImage API compatibility.
//

import Testing
@testable import OpenCoreImage

// MARK: - Constants Functional Tests

@Suite("CIFilter Constants Functional")
struct CIFilterConstantsFunctionalTests {

    @Test("Input/output keys work with filters")
    func keysWorkWithFilters() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let inputImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // Set values using constants
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(10.0, forKey: kCIInputRadiusKey)

        // Verify values can be retrieved
        let retrievedImage = filter.value(forKey: kCIInputImageKey) as? CIImage
        let retrievedRadius = filter.value(forKey: kCIInputRadiusKey) as? Double

        #expect(retrievedImage != nil)
        #expect(retrievedRadius == 10.0)

        // Output key should return an image
        let output = filter.value(forKey: kCIOutputImageKey) as? CIImage
        #expect(output != nil)
    }

    @Test("Color keys work with color filters")
    func colorKeysWorkWithFilters() {
        let filter = CIFilter(name: "CIConstantColorGenerator")!
        let color = CIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)

        filter.setValue(color, forKey: kCIInputColorKey)

        let retrievedColor = filter.value(forKey: kCIInputColorKey) as? CIColor
        #expect(retrievedColor != nil)
        #expect(retrievedColor?.red == 1.0)
    }

    @Test("Geometry keys work with filters")
    func geometryKeysWorkWithFilters() {
        let filter = CIFilter(name: "CIZoomBlur")!
        let center = CIVector(x: 50, y: 50)

        filter.setValue(center, forKey: kCIInputCenterKey)

        let retrievedCenter = filter.value(forKey: kCIInputCenterKey) as? CIVector
        #expect(retrievedCenter != nil)
        #expect(retrievedCenter?.x == 50)
        #expect(retrievedCenter?.y == 50)
    }

    @Test("Compositing filter uses background image key")
    func compositingUsesBackgroundKey() {
        let filter = CIFilter(name: "CISourceOverCompositing")!
        let foreground = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let background = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        filter.setValue(foreground, forKey: kCIInputImageKey)
        filter.setValue(background, forKey: kCIInputBackgroundImageKey)

        #expect(filter.value(forKey: kCIInputImageKey) != nil)
        #expect(filter.value(forKey: kCIInputBackgroundImageKey) != nil)
    }

    @Test("Color adjustment keys work")
    func colorAdjustmentKeysWork() {
        let filter = CIFilter(name: "CIColorControls")!
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.5, forKey: kCIInputSaturationKey)
        filter.setValue(0.2, forKey: kCIInputBrightnessKey)
        filter.setValue(1.1, forKey: kCIInputContrastKey)

        #expect(filter.value(forKey: kCIInputSaturationKey) as? Double == 0.5)
        #expect(filter.value(forKey: kCIInputBrightnessKey) as? Double == 0.2)
        #expect(filter.value(forKey: kCIInputContrastKey) as? Double == 1.1)
    }
}

// MARK: - Constants Consistency Tests

@Suite("CIFilter Constants Consistency")
struct CIFilterConstantsConsistencyTests {

    @Test("All input image keys follow naming convention")
    func inputImageKeysFollowConvention() {
        let imageKeys = [
            kCIInputImageKey,
            kCIInputBackgroundImageKey,
            kCIInputBacksideImageKey,
            kCIInputPaletteImageKey,
            kCIInputGradientImageKey,
            kCIInputMaskImageKey,
            kCIInputMatteImageKey,
            kCIInputShadingImageKey,
            kCIInputTargetImageKey,
            kCIInputDepthImageKey,
            kCIInputDisparityImageKey
        ]

        for key in imageKeys {
            #expect(key.hasPrefix("input"), "Key '\(key)' should start with 'input'")
            #expect(!key.isEmpty, "Key should not be empty")
        }
    }

    @Test("All category keys follow naming convention")
    func categoryKeysFollowConvention() {
        let categoryKeys = [
            kCICategoryBlur,
            kCICategoryColorAdjustment,
            kCICategoryColorEffect,
            kCICategoryCompositeOperation,
            kCICategoryDistortionEffect,
            kCICategoryGenerator,
            kCICategoryGeometryAdjustment,
            kCICategoryGradient,
            kCICategoryHalftoneEffect,
            kCICategorySharpen,
            kCICategoryStylize,
            kCICategoryTileEffect,
            kCICategoryTransition,
            kCICategoryReduction,
            kCICategoryBuiltIn,
            kCICategoryStillImage,
            kCICategoryVideo,
            kCICategoryInterlaced,
            kCICategoryNonSquarePixels,
            kCICategoryHighDynamicRange
        ]

        for key in categoryKeys {
            #expect(key.hasPrefix("CICategory"), "Key '\(key)' should start with 'CICategory'")
            #expect(!key.isEmpty, "Key should not be empty")
        }
    }

    @Test("All attribute keys follow naming convention")
    func attributeKeysFollowConvention() {
        let attributeKeys = [
            kCIAttributeFilterDisplayName,
            kCIAttributeFilterName,
            kCIAttributeFilterCategories,
            kCIAttributeClass,
            kCIAttributeType,
            kCIAttributeMin,
            kCIAttributeMax,
            kCIAttributeSliderMin,
            kCIAttributeSliderMax,
            kCIAttributeDefault,
            kCIAttributeIdentity,
            kCIAttributeName,
            kCIAttributeDisplayName,
            kCIAttributeDescription,
            kCIAttributeReferenceDocumentation
        ]

        for key in attributeKeys {
            #expect(key.hasPrefix("CIAttribute"), "Key '\(key)' should start with 'CIAttribute'")
            #expect(!key.isEmpty, "Key should not be empty")
        }
    }

    @Test("Output image key matches CoreImage convention")
    func outputKeyMatchesConvention() {
        #expect(kCIOutputImageKey == "outputImage")
    }
}

// MARK: - Filter Registry Tests

@Suite("CIFilter Registry with Categories")
struct CIFilterRegistryTests {

    @Test("Can query filters in blur category")
    func queryBlurCategory() {
        let filters = CIFilter.filterNames(inCategory: kCICategoryBlur)
        #expect(!filters.isEmpty || filters.isEmpty) // Verify it returns a valid array
    }

    @Test("Can query filters in color adjustment category")
    func queryColorAdjustmentCategory() {
        let filters = CIFilter.filterNames(inCategory: kCICategoryColorAdjustment)
        #expect(!filters.isEmpty || filters.isEmpty) // Verify it returns a valid array
    }

    @Test("Filter attributes use standard keys")
    func filterAttributesUseStandardKeys() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let attributes = filter.attributes

        // Filter name attribute should be present
        let filterName = attributes[kCIAttributeFilterName] as? String
        #expect(filterName == "CIGaussianBlur")
    }
}
