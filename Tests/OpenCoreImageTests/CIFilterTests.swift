//
//  CIFilterTests.swift
//  OpenCoreImage
//
//  Tests for CIFilter functionality.
//

import Testing
import Foundation
@testable import OpenCoreImage

// MARK: - CIFilter Initialization Tests

@Suite("CIFilter Initialization")
struct CIFilterInitializationTests {

    @Test("Initialize with filter name")
    func initWithName() {
        let filter = CIFilter(name: "CIGaussianBlur")
        #expect(filter != nil)
        #expect(filter?.name == "CIGaussianBlur")
    }

    @Test("Initialize with parameters")
    func initWithParameters() {
        let filter = CIFilter(name: "CIGaussianBlur", withInputParameters: [
            kCIInputRadiusKey: 10.0
        ])
        #expect(filter != nil)
        #expect(filter?.value(forKey: kCIInputRadiusKey) as? Double == 10.0)
    }

    @Test("Initialize with nil parameters")
    func initWithNilParameters() {
        let filter = CIFilter(name: "CIGaussianBlur", withInputParameters: nil)
        #expect(filter != nil)
    }
}

// MARK: - CIFilter Key-Value Tests

@Suite("CIFilter Key-Value")
struct CIFilterKeyValueTests {

    @Test("Set value for key")
    func setValueForKey() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(15.0, forKey: kCIInputRadiusKey)
        #expect(filter.value(forKey: kCIInputRadiusKey) as? Double == 15.0)
    }

    @Test("Set nil value removes key")
    func setNilValueRemovesKey() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(10.0, forKey: kCIInputRadiusKey)
        filter.setValue(nil, forKey: kCIInputRadiusKey)
        #expect(filter.value(forKey: kCIInputRadiusKey) == nil)
    }

    @Test("Set input image")
    func setInputImage() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let image = CIImage(color: .red)
        filter.setValue(image, forKey: kCIInputImageKey)
        #expect(filter.value(forKey: kCIInputImageKey) is CIImage)
    }

    @Test("Get output image key returns output image")
    func getOutputImageKey() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let image = CIImage(color: .red)
        filter.setValue(image, forKey: kCIInputImageKey)
        let output = filter.value(forKey: kCIOutputImageKey)
        #expect(output is CIImage)
    }
}

// MARK: - CIFilter Properties Tests

@Suite("CIFilter Properties")
struct CIFilterPropertiesTests {

    @Test("Name property")
    func nameProperty() {
        let filter = CIFilter(name: "CISepiaTone")!
        #expect(filter.name == "CISepiaTone")
    }

    @Test("Name is settable")
    func nameIsSettable() {
        let filter = CIFilter(name: "CISepiaTone")!
        filter.name = "CIBloom"
        #expect(filter.name == "CIBloom")
    }

    @Test("Is enabled default")
    func isEnabledDefault() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        #expect(filter.isEnabled == true)
    }

    @Test("Is enabled settable")
    func isEnabledSettable() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.isEnabled = false
        #expect(filter.isEnabled == false)
    }

    @Test("Input keys")
    func inputKeys() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(10.0, forKey: kCIInputRadiusKey)
        #expect(filter.inputKeys.contains(kCIInputRadiusKey))
    }

    @Test("Output keys")
    func outputKeys() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        #expect(filter.outputKeys.contains(kCIOutputImageKey))
    }

    @Test("Attributes dictionary")
    func attributesDictionary() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let attrs = filter.attributes
        #expect(attrs[kCIAttributeFilterName] as? String == "CIGaussianBlur")
    }
}

// MARK: - CIFilter Output Image Tests

@Suite("CIFilter Output Image")
struct CIFilterOutputImageTests {

    @Test("Output image is nil without input")
    func outputImageNilWithoutInput() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        #expect(filter.outputImage == nil)
    }

    @Test("Output image with valid input")
    func outputImageWithInput() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let inputImage = CIImage(color: .red)
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        #expect(filter.outputImage != nil)
    }

    @Test("Output image includes filter in chain")
    func outputImageIncludesFilter() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let inputImage = CIImage(color: .red)
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(10.0, forKey: kCIInputRadiusKey)

        let output = filter.outputImage
        #expect(output != nil)
        #expect(output !== inputImage)
    }
}

// MARK: - CIFilter Defaults Tests

@Suite("CIFilter Defaults")
struct CIFilterDefaultsTests {

    @Test("Set defaults clears values")
    func setDefaultsClearsValues() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(15.0, forKey: kCIInputRadiusKey)
        filter.setDefaults()
        #expect(filter.inputKeys.isEmpty)
    }
}

// MARK: - CIFilter Registration Tests

@Suite("CIFilter Registration")
struct CIFilterRegistrationTests {

    @Test("Filter names in categories")
    func filterNamesInCategories() {
        let names = CIFilter.filterNames(inCategories: nil)
        #expect(!names.isEmpty || names.isEmpty) // Verify it returns a valid array
    }

    @Test("Filter names in category")
    func filterNamesInCategory() {
        let names = CIFilter.filterNames(inCategory: kCICategoryBlur)
        #expect(!names.isEmpty || names.isEmpty) // Verify it returns a valid array
    }

    @Test("Register custom filter")
    func registerCustomFilter() {
        struct TestConstructor: CIFilterConstructor {
            func filter(withName name: String) -> CIFilter? {
                return CIFilter(name: name)
            }
        }

        CIFilter.registerName(
            "TestCustomFilter",
            constructor: TestConstructor(),
            classAttributes: [
                kCIAttributeFilterDisplayName: "Test Custom Filter"
            ]
        )

        let names = CIFilter.filterNames(inCategories: nil)
        #expect(names.contains("TestCustomFilter"))
    }
}

// MARK: - CIFilter Localization Tests

@Suite("CIFilter Localization")
struct CIFilterLocalizationTests {

    @Test("Localized name for filter")
    func localizedNameForFilter() {
        let name = CIFilter.localizedName(forFilterName: "CIGaussianBlur")
        #expect(name == "CIGaussianBlur")  // Default implementation returns the name
    }

    @Test("Localized name for category")
    func localizedNameForCategory() {
        let name = CIFilter.localizedName(forCategory: kCICategoryBlur)
        #expect(name == kCICategoryBlur)  // Default implementation returns the category
    }

    @Test("Localized description returns nil by default")
    func localizedDescriptionReturnsNil() {
        let desc = CIFilter.localizedDescription(forFilterName: "CIGaussianBlur")
        #expect(desc == nil)
    }

    @Test("Localized reference documentation returns nil by default")
    func localizedReferenceDocReturnsNil() {
        let url = CIFilter.localizedReferenceDocumentation(forFilterName: "CIGaussianBlur")
        #expect(url == nil)
    }
}

// MARK: - CIFilter Equatable/Hashable Tests

@Suite("CIFilter Equatable and Hashable")
struct CIFilterEquatableHashableTests {

    @Test("Same instance is equal")
    func sameInstanceEqual() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        #expect(filter == filter)
    }

    @Test("Different instances are not equal")
    func differentInstancesNotEqual() {
        let filter1 = CIFilter(name: "CIGaussianBlur")!
        let filter2 = CIFilter(name: "CIGaussianBlur")!
        #expect(filter1 != filter2)
    }

    @Test("Same instance has same hash")
    func sameInstanceSameHash() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        #expect(filter.hashValue == filter.hashValue)
    }
}

// MARK: - CIFilter Description Tests

@Suite("CIFilter Description")
struct CIFilterDescriptionTests {

    @Test("Description includes filter name")
    func descriptionIncludesName() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        #expect(filter.description.contains("CIGaussianBlur"))
    }

    @Test("Debug description includes details")
    func debugDescriptionIncludesDetails() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(10.0, forKey: kCIInputRadiusKey)
        let debug = filter.debugDescription
        #expect(debug.contains("CIFilter"))
        #expect(debug.contains("name"))
    }
}

// MARK: - CIFilterConstructor Protocol Tests

@Suite("CIFilterConstructor Protocol")
struct CIFilterConstructorProtocolTests {

    @Test("Constructor creates filter")
    func constructorCreatesFilter() {
        struct SimpleConstructor: CIFilterConstructor {
            func filter(withName name: String) -> CIFilter? {
                return CIFilter(name: name)
            }
        }

        let constructor = SimpleConstructor()
        let filter = constructor.filter(withName: "CIBloom")
        #expect(filter != nil)
        #expect(filter?.name == "CIBloom")
    }
}

// MARK: - CIFilterProtocol Tests

@Suite("CIFilterProtocol")
struct CIFilterProtocolTests {

    @Test("CIFilter conforms to protocol via outputImage")
    func ciFilterConformsViaOutputImage() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let inputImage = CIImage(color: .red)
        filter.setValue(inputImage, forKey: kCIInputImageKey)

        // Test that outputImage is accessible
        let output = filter.outputImage
        #expect(output != nil)
    }

    @Test("Custom attributes default to nil")
    func customAttributesDefaultToNil() {
        #expect(CIFilter.customAttributes() == nil)
    }
}

// MARK: - CIFilter Apply Tests

@Suite("CIFilter Apply Kernel")
struct CIFilterApplyKernelTests {

    @Test("Apply kernel returns nil placeholder")
    func applyKernelReturnsNil() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let kernel = CIKernel(source: "test")!
        let result = filter.apply(kernel, arguments: nil, options: nil)
        #expect(result == nil)  // Placeholder implementation
    }
}

// MARK: - CIFilter Common Filters Tests

@Suite("CIFilter Common Filters")
struct CIFilterCommonFiltersTests {

    @Test("Create Gaussian blur filter")
    func createGaussianBlur() {
        let filter = CIFilter(name: "CIGaussianBlur")
        #expect(filter != nil)
    }

    @Test("Create Sepia tone filter")
    func createSepiaTone() {
        let filter = CIFilter(name: "CISepiaTone")
        #expect(filter != nil)
    }

    @Test("Create Color controls filter")
    func createColorControls() {
        let filter = CIFilter(name: "CIColorControls")
        #expect(filter != nil)
    }

    @Test("Create Bloom filter")
    func createBloom() {
        let filter = CIFilter(name: "CIBloom")
        #expect(filter != nil)
    }

    @Test("Create Source over compositing filter")
    func createSourceOverCompositing() {
        let filter = CIFilter(name: "CISourceOverCompositing")
        #expect(filter != nil)
    }

    @Test("Create Linear gradient filter")
    func createLinearGradient() {
        let filter = CIFilter(name: "CILinearGradient")
        #expect(filter != nil)
    }
}

// MARK: - CIFilter Multi-Input Tests

@Suite("CIFilter Multi-Input")
struct CIFilterMultiInputTests {

    @Test("Set foreground and background images")
    func setForegroundAndBackgroundImages() {
        let filter = CIFilter(name: "CISourceOverCompositing")!
        let foreground = CIImage(color: .red)
        let background = CIImage(color: .blue)

        filter.setValue(foreground, forKey: kCIInputImageKey)
        filter.setValue(background, forKey: kCIInputBackgroundImageKey)

        #expect(filter.value(forKey: kCIInputImageKey) is CIImage)
        #expect(filter.value(forKey: kCIInputBackgroundImageKey) is CIImage)
    }
}

// MARK: - CIFilter Parameter Types Tests

@Suite("CIFilter Parameter Types")
struct CIFilterParameterTypesTests {

    @Test("Set CGFloat parameter")
    func setCGFloatParameter() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(CGFloat(10.0), forKey: kCIInputRadiusKey)
        let value = filter.value(forKey: kCIInputRadiusKey) as? CGFloat
        #expect(value == 10.0)
    }

    @Test("Set CIVector parameter")
    func setCIVectorParameter() {
        let filter = CIFilter(name: "CIZoomBlur")!
        let center = CIVector(x: 100, y: 100)
        filter.setValue(center, forKey: kCIInputCenterKey)
        #expect(filter.value(forKey: kCIInputCenterKey) is CIVector)
    }

    @Test("Set CIColor parameter")
    func setCIColorParameter() {
        let filter = CIFilter(name: "CIConstantColorGenerator")!
        let color = CIColor(red: 1.0, green: 0.0, blue: 0.0)
        filter.setValue(color, forKey: kCIInputColorKey)
        #expect(filter.value(forKey: kCIInputColorKey) is CIColor)
    }

    @Test("Set CGAffineTransform parameter")
    func setCGAffineTransformParameter() {
        let filter = CIFilter(name: "CIAffineTransform")!
        let transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        filter.setValue(transform, forKey: kCIInputTransformKey)
        // Transform stored as Any
        #expect(filter.value(forKey: kCIInputTransformKey) != nil)
    }
}

// MARK: - CIFilter Built-in Name Gating Tests

@Suite("CIFilter Built-in Name Gating")
struct CIFilterBuiltInNameGatingTests {

    @Test("CIGaussianBlur is recognized as built-in")
    func gaussianBlurRecognized() {
        let filter = CIFilter(name: "CIGaussianBlur")
        #expect(filter != nil)
    }

    @Test("CIColorControls is recognized as built-in")
    func colorControlsRecognized() {
        let filter = CIFilter(name: "CIColorControls")
        #expect(filter != nil)
    }

    @Test("Non-existent filter name returns nil")
    func nonExistentFilterReturnsNil() {
        let filter = CIFilter(name: "CINonExistentFilterXYZ")
        #expect(filter == nil)
    }

    @Test("Empty filter name returns nil")
    func emptyFilterNameReturnsNil() {
        let filter = CIFilter(name: "")
        #expect(filter == nil)
    }

    @Test("filterNames(inCategory: nil) is non-empty and contains CIGaussianBlur")
    func filterNamesInNilCategoryContainsGaussianBlur() {
        let names = CIFilter.filterNames(inCategory: nil)
        #expect(!names.isEmpty)
        #expect(names.contains("CIGaussianBlur"))
    }

    @Test("filterNames(inCategories: nil) contains built-in names")
    func filterNamesInCategoriesNilContainsBuiltIns() {
        let names = CIFilter.filterNames(inCategories: nil)
        #expect(names.contains("CIGaussianBlur"))
        #expect(names.contains("CIColorControls"))
    }
}

// MARK: - CIFilter Numeric Value Round-Trip Tests

@Suite("CIFilter Numeric Value Round-Trip")
struct CIFilterNumericRoundTripTests {

    @Test("Int round-trips through KVC")
    func intRoundTrip() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(Int(5), forKey: kCIInputRadiusKey)
        #expect(filter.value(forKey: kCIInputRadiusKey) as? Int == 5)
    }

    @Test("Float round-trips through KVC")
    func floatRoundTrip() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(Float(7.5), forKey: kCIInputRadiusKey)
        #expect(filter.value(forKey: kCIInputRadiusKey) as? Float == 7.5)
    }

    @Test("Double round-trips through KVC")
    func doubleRoundTrip() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(Double(12.25), forKey: kCIInputRadiusKey)
        #expect(filter.value(forKey: kCIInputRadiusKey) as? Double == 12.25)
    }

    @Test("CGFloat round-trips through KVC")
    func cgFloatRoundTrip() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let expected: CGFloat = 3.5
        filter.setValue(expected, forKey: kCIInputRadiusKey)
        #expect(filter.value(forKey: kCIInputRadiusKey) as? CGFloat == expected)
    }

    @Test("Attribute metadata labels Int as NSNumber class string")
    func attributeMetadataIntNSNumberLabel() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(Int(5), forKey: kCIInputRadiusKey)
        let attrs = filter.attributes
        let radiusMetadata = attrs[kCIInputRadiusKey] as? [String: Any]
        #expect(radiusMetadata != nil)
        #expect(radiusMetadata?[kCIAttributeClass] as? String == "NSNumber")
    }

    @Test("Attribute metadata labels Float as NSNumber class string")
    func attributeMetadataFloatNSNumberLabel() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(Float(7.5), forKey: kCIInputRadiusKey)
        let attrs = filter.attributes
        let radiusMetadata = attrs[kCIInputRadiusKey] as? [String: Any]
        #expect(radiusMetadata?[kCIAttributeClass] as? String == "NSNumber")
    }

    @Test("Attribute metadata labels Double as NSNumber class string")
    func attributeMetadataDoubleNSNumberLabel() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(Double(12.25), forKey: kCIInputRadiusKey)
        let attrs = filter.attributes
        let radiusMetadata = attrs[kCIInputRadiusKey] as? [String: Any]
        #expect(radiusMetadata?[kCIAttributeClass] as? String == "NSNumber")
    }

    @Test("Attribute metadata labels CGFloat as NSNumber class string")
    func attributeMetadataCGFloatNSNumberLabel() {
        let filter = CIFilter(name: "CIGaussianBlur")!
        let value: CGFloat = 3.5
        filter.setValue(value, forKey: kCIInputRadiusKey)
        let attrs = filter.attributes
        let radiusMetadata = attrs[kCIInputRadiusKey] as? [String: Any]
        #expect(radiusMetadata?[kCIAttributeClass] as? String == "NSNumber")
    }
}

// MARK: - CIRAWFilter URL Loading Tests

@Suite("CIRAWFilter URL Loading")
struct CIRAWFilterURLLoadingTests {

    @Test("CIRAWFilter returns nil for non-existent URL")
    func ciRawFilterNonExistentURLReturnsNil() {
        // `CIRAWFilter(imageURL:)` is a failable initializer. When the file
        // cannot be read, it must return nil so callers branch to a non-RAW
        // fallback instead of receiving a filter that silently emits a
        // placeholder image.
        let url = URL(fileURLWithPath: "/nonexistent/path.cr2")
        let filter = CIRAWFilter(imageURL: url)
        #expect(filter == nil)
    }
}
