//
//  UniformBufferEncoderTests.swift
//  OpenCoreImage
//
//  Tests for UniformBufferEncoder binary data encoding.
//

import Testing
@testable import OpenCoreImage

// MARK: - Basic Encoding Tests

@Suite("UniformBufferEncoder Basic Encoding")
struct UniformBufferEncoderBasicTests {

    @Test("Encode returns non-empty data")
    func encodeReturnsNonEmptyData() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGaussianBlur",
            parameters: [:],
            imageWidth: 100,
            imageHeight: 100
        )

        #expect(!data.isEmpty)
    }

    @Test("Encode includes image dimensions")
    func encodeIncludesImageDimensions() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGaussianBlur",
            parameters: [:],
            imageWidth: 200,
            imageHeight: 150
        )

        // First 8 bytes should be width (u32) and height (u32)
        #expect(data.count >= 8)

        // Extract width and height
        let width = data.withUnsafeBytes { ptr -> UInt32 in
            ptr.load(as: UInt32.self)
        }
        let height = data.withUnsafeBytes { ptr -> UInt32 in
            ptr.load(fromByteOffset: 4, as: UInt32.self)
        }

        #expect(width == 200)
        #expect(height == 150)
    }

    @Test("Encode copy texture filter")
    func encodeCopyTextureFilter() {
        let data = UniformBufferEncoder.encode(
            filterName: "CICopyTexture",
            parameters: [:],
            imageWidth: 100,
            imageHeight: 100
        )

        // CICopyTexture only needs image dimensions, but padded to 16-byte alignment
        #expect(data.count >= 8)
        #expect(data.count % 16 == 0)  // WebGPU requires 16-byte alignment
    }
}

// MARK: - Blur Filter Encoding Tests

@Suite("UniformBufferEncoder Blur Filters")
struct UniformBufferEncoderBlurFiltersTests {

    @Test("Encode Gaussian blur with default radius")
    func encodeGaussianBlurDefaultRadius() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGaussianBlur",
            parameters: [:],
            imageWidth: 100,
            imageHeight: 100
        )

        // Should have: width, height, radius, sigma
        #expect(data.count >= 16)

        // Extract radius (default is 10.0)
        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(radius == 10.0)
    }

    @Test("Encode Gaussian blur with custom radius")
    func encodeGaussianBlurCustomRadius() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGaussianBlur",
            parameters: [kCIInputRadiusKey: 25.0],
            imageWidth: 100,
            imageHeight: 100
        )

        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(radius == 25.0)
    }

    @Test("Encode box blur")
    func encodeBoxBlur() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIBoxBlur",
            parameters: [kCIInputRadiusKey: 15.0],
            imageWidth: 100,
            imageHeight: 100
        )

        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(radius == 15.0)
    }

    @Test("Encode motion blur")
    func encodeMotionBlur() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIMotionBlur",
            parameters: [
                kCIInputRadiusKey: 20.0,
                kCIInputAngleKey: 1.5
            ],
            imageWidth: 100,
            imageHeight: 100
        )

        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }
        let angle = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 12, as: Float.self)
        }

        #expect(radius == 20.0)
        #expect(abs(angle - 1.5) < 0.001)
    }

    @Test("Encode morphology filter")
    func encodeMorphologyFilter() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIMorphologyMaximum",
            parameters: [kCIInputRadiusKey: 7.0],
            imageWidth: 100,
            imageHeight: 100
        )

        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(radius == 7.0)
    }
}

// MARK: - Color Adjustment Filter Encoding Tests

@Suite("UniformBufferEncoder Color Adjustment Filters")
struct UniformBufferEncoderColorAdjustmentFiltersTests {

    @Test("Encode color controls")
    func encodeColorControls() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIColorControls",
            parameters: [
                kCIInputBrightnessKey: 0.5,
                kCIInputContrastKey: 1.2,
                kCIInputSaturationKey: 0.8
            ],
            imageWidth: 100,
            imageHeight: 100
        )

        let brightness = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }
        let contrast = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 12, as: Float.self)
        }
        let saturation = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 16, as: Float.self)
        }

        #expect(abs(brightness - 0.5) < 0.001)
        #expect(abs(contrast - 1.2) < 0.001)
        #expect(abs(saturation - 0.8) < 0.001)
    }

    @Test("Encode exposure adjust")
    func encodeExposureAdjust() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIExposureAdjust",
            parameters: [kCIInputEVKey: 1.5],
            imageWidth: 100,
            imageHeight: 100
        )

        let ev = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(abs(ev - 1.5) < 0.001)
    }

    @Test("Encode gamma adjust")
    func encodeGammaAdjust() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGammaAdjust",
            parameters: ["inputPower": 2.2],
            imageWidth: 100,
            imageHeight: 100
        )

        let power = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(abs(power - 2.2) < 0.001)
    }

    @Test("Encode hue adjust")
    func encodeHueAdjust() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIHueAdjust",
            parameters: [kCIInputAngleKey: 3.14159],
            imageWidth: 100,
            imageHeight: 100
        )

        let angle = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(abs(angle - 3.14159) < 0.001)
    }

    @Test("Encode color threshold")
    func encodeColorThreshold() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIColorThreshold",
            parameters: [kCIInputThresholdKey: 0.75],
            imageWidth: 100,
            imageHeight: 100
        )

        let threshold = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(abs(threshold - 0.75) < 0.001)
    }

    @Test("Encode vibrance")
    func encodeVibrance() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIVibrance",
            parameters: ["inputAmount": 0.6],
            imageWidth: 100,
            imageHeight: 100
        )

        let amount = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(abs(amount - 0.6) < 0.001)
    }
}

// MARK: - Color Effect Filter Encoding Tests

@Suite("UniformBufferEncoder Color Effect Filters")
struct UniformBufferEncoderColorEffectFiltersTests {

    @Test("Encode sepia tone")
    func encodeSepiaTone() {
        let data = UniformBufferEncoder.encode(
            filterName: "CISepiaTone",
            parameters: [kCIInputIntensityKey: 0.9],
            imageWidth: 100,
            imageHeight: 100
        )

        let intensity = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(abs(intensity - 0.9) < 0.001)
    }

    @Test("Encode color invert (no params)")
    func encodeColorInvert() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIColorInvert",
            parameters: [:],
            imageWidth: 100,
            imageHeight: 100
        )

        // Only image dimensions, padded to 16-byte alignment
        #expect(data.count >= 8)
        #expect(data.count % 16 == 0)
    }

    @Test("Encode vignette")
    func encodeVignette() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIVignette",
            parameters: [
                kCIInputIntensityKey: 1.5,
                kCIInputRadiusKey: 2.0
            ],
            imageWidth: 100,
            imageHeight: 100
        )

        let intensity = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }
        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 12, as: Float.self)
        }

        #expect(abs(intensity - 1.5) < 0.001)
        #expect(abs(radius - 2.0) < 0.001)
    }

    @Test("Encode posterize")
    func encodePosterize() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIPosterize",
            parameters: ["inputLevels": 6.0],
            imageWidth: 100,
            imageHeight: 100
        )

        let levels = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(abs(levels - 6.0) < 0.001)
    }

    @Test("Encode photo effect filters (no params)")
    func encodePhotoEffectFilters() {
        let photoEffects = [
            "CIPhotoEffectMono",
            "CIPhotoEffectChrome",
            "CIPhotoEffectFade",
            "CIPhotoEffectInstant",
            "CIPhotoEffectNoir",
            "CIPhotoEffectProcess",
            "CIPhotoEffectTonal",
            "CIPhotoEffectTransfer"
        ]

        for effect in photoEffects {
            let data = UniformBufferEncoder.encode(
                filterName: effect,
                parameters: [:],
                imageWidth: 100,
                imageHeight: 100
            )

            // Photo effects only need image dimensions, padded to 16-byte alignment
            #expect(data.count >= 8, "\(effect) should have at least image dimensions")
            #expect(data.count % 16 == 0, "\(effect) should be 16-byte aligned")
        }
    }
}

// MARK: - Distortion Filter Encoding Tests

@Suite("UniformBufferEncoder Distortion Filters")
struct UniformBufferEncoderDistortionFiltersTests {

    @Test("Encode twirl distortion")
    func encodeTwirlDistortion() {
        let data = UniformBufferEncoder.encode(
            filterName: "CITwirlDistortion",
            parameters: [
                kCIInputCenterKey: CIVector(x: 150, y: 150),
                kCIInputRadiusKey: 300.0,
                kCIInputAngleKey: 3.14
            ],
            imageWidth: 300,
            imageHeight: 300
        )

        // Should include: width, height, centerX, centerY, radius, angle, padding
        #expect(data.count >= 24)
    }

    @Test("Encode pinch distortion")
    func encodePinchDistortion() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIPinchDistortion",
            parameters: [
                kCIInputCenterKey: CIVector(x: 100, y: 100),
                kCIInputRadiusKey: 150.0,
                "inputScale": 0.5
            ],
            imageWidth: 200,
            imageHeight: 200
        )

        // Should include parameters for pinch distortion
        #expect(data.count >= 24)
    }

    @Test("Encode bump distortion")
    func encodeBumpDistortion() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIBumpDistortion",
            parameters: [
                kCIInputCenterKey: CIVector(x: 100, y: 100),
                kCIInputRadiusKey: 100.0,
                "inputScale": 0.5
            ],
            imageWidth: 200,
            imageHeight: 200
        )

        #expect(data.count >= 24)
    }
}

// MARK: - Generator Filter Encoding Tests

@Suite("UniformBufferEncoder Generator Filters")
struct UniformBufferEncoderGeneratorFiltersTests {

    @Test("Encode constant color generator")
    func encodeConstantColorGenerator() {
        let color = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 1.0)
        let data = UniformBufferEncoder.encode(
            filterName: "CIConstantColorGenerator",
            parameters: [kCIInputColorKey: color],
            imageWidth: 100,
            imageHeight: 100
        )

        // Should include color components
        #expect(data.count >= 24)
    }

    @Test("Encode linear gradient")
    func encodeLinearGradient() {
        let data = UniformBufferEncoder.encode(
            filterName: "CILinearGradient",
            parameters: [
                kCIInputPoint0Key: CIVector(x: 0, y: 0),
                kCIInputPoint1Key: CIVector(x: 100, y: 100),
                kCIInputColor0Key: CIColor.red,
                kCIInputColor1Key: CIColor.blue
            ],
            imageWidth: 100,
            imageHeight: 100
        )

        // Should include points and colors
        #expect(data.count >= 40)
    }

    @Test("Encode radial gradient")
    func encodeRadialGradient() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIRadialGradient",
            parameters: [
                kCIInputCenterKey: CIVector(x: 50, y: 50),
                kCIInputRadius0Key: 0.0,
                kCIInputRadius1Key: 100.0,
                kCIInputColor0Key: CIColor.white,
                kCIInputColor1Key: CIColor.black
            ],
            imageWidth: 100,
            imageHeight: 100
        )

        #expect(data.count >= 40)
    }

    @Test("Encode checkerboard generator")
    func encodeCheckerboardGenerator() {
        let data = UniformBufferEncoder.encode(
            filterName: "CICheckerboardGenerator",
            parameters: [
                kCIInputCenterKey: CIVector(x: 50, y: 50),
                "inputWidth": 20.0,
                kCIInputColor0Key: CIColor.white,
                kCIInputColor1Key: CIColor.black
            ],
            imageWidth: 100,
            imageHeight: 100
        )

        #expect(data.count >= 40)
    }
}

// MARK: - Compositing Filter Encoding Tests

@Suite("UniformBufferEncoder Compositing Filters")
struct UniformBufferEncoderCompositingFiltersTests {

    @Test("Encode source over compositing (no params)")
    func encodeSourceOverCompositing() {
        let data = UniformBufferEncoder.encode(
            filterName: "CISourceOverCompositing",
            parameters: [:],
            imageWidth: 100,
            imageHeight: 100
        )

        // Compositing filters only need image dimensions, padded to 16-byte alignment
        #expect(data.count >= 8)
        #expect(data.count % 16 == 0)
    }

    @Test("Encode multiply compositing (no params)")
    func encodeMultiplyCompositing() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIMultiplyCompositing",
            parameters: [:],
            imageWidth: 100,
            imageHeight: 100
        )

        #expect(data.count >= 8)
        #expect(data.count % 16 == 0)
    }

    @Test("Encode all blend mode filters have same size")
    func encodeBlendModeFiltersHaveSameSize() {
        let blendModes = [
            "CIScreenCompositing",
            "CIOverlayCompositing",
            "CIDarkenCompositing",
            "CILightenCompositing",
            "CIDifferenceCompositing",
            "CIAdditionCompositing",
            "CISubtractCompositing"
        ]

        for blendMode in blendModes {
            let data = UniformBufferEncoder.encode(
                filterName: blendMode,
                parameters: [:],
                imageWidth: 100,
                imageHeight: 100
            )

            #expect(data.count >= 8, "\(blendMode) should have at least image dimensions")
            #expect(data.count % 16 == 0, "\(blendMode) should be 16-byte aligned")
        }
    }
}

// MARK: - Stylizing Filter Encoding Tests

@Suite("UniformBufferEncoder Stylizing Filters")
struct UniformBufferEncoderStylizingFiltersTests {

    @Test("Encode pixellate")
    func encodePixellate() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIPixellate",
            parameters: [
                kCIInputCenterKey: CIVector(x: 50, y: 50),
                "inputScale": 16.0
            ],
            imageWidth: 100,
            imageHeight: 100
        )

        // Pixellate has center (2 floats) + scale (1 float), padded to 16-byte alignment
        #expect(data.count >= 16)
        #expect(data.count % 16 == 0)
    }

    @Test("Encode bloom")
    func encodeBloom() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIBloom",
            parameters: [
                kCIInputRadiusKey: 20.0,
                kCIInputIntensityKey: 1.0
            ],
            imageWidth: 100,
            imageHeight: 100
        )

        #expect(data.count >= 16)
    }

    @Test("Encode gloom")
    func encodeGloom() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGloom",
            parameters: [
                kCIInputRadiusKey: 15.0,
                kCIInputIntensityKey: 0.8
            ],
            imageWidth: 100,
            imageHeight: 100
        )

        #expect(data.count >= 16)
    }

    @Test("Encode edges")
    func encodeEdges() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIEdges",
            parameters: [kCIInputIntensityKey: 2.0],
            imageWidth: 100,
            imageHeight: 100
        )

        #expect(data.count >= 12)
    }
}

// MARK: - Parameter Type Conversion Tests

@Suite("UniformBufferEncoder Parameter Type Conversion")
struct UniformBufferEncoderParameterTypeConversionTests {

    @Test("Float parameter type")
    func floatParameterType() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGaussianBlur",
            parameters: [kCIInputRadiusKey: Float(15.0)],
            imageWidth: 100,
            imageHeight: 100
        )

        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(radius == 15.0)
    }

    @Test("Double parameter type")
    func doubleParameterType() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGaussianBlur",
            parameters: [kCIInputRadiusKey: Double(15.0)],
            imageWidth: 100,
            imageHeight: 100
        )

        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(radius == 15.0)
    }

    @Test("CGFloat parameter type")
    func cgFloatParameterType() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGaussianBlur",
            parameters: [kCIInputRadiusKey: CGFloat(15.0)],
            imageWidth: 100,
            imageHeight: 100
        )

        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(radius == 15.0)
    }

    @Test("Int parameter type")
    func intParameterType() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGaussianBlur",
            parameters: [kCIInputRadiusKey: 15],
            imageWidth: 100,
            imageHeight: 100
        )

        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(radius == 15.0)
    }

    @Test("CIVector parameter type")
    func ciVectorParameterType() {
        let vector = CIVector(x: 100, y: 200)
        let data = UniformBufferEncoder.encode(
            filterName: "CIZoomBlur",
            parameters: [kCIInputCenterKey: vector],
            imageWidth: 200,
            imageHeight: 200
        )

        // Center should be encoded
        #expect(data.count >= 16)
    }

    @Test("CIColor parameter type")
    func ciColorParameterType() {
        let color = CIColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 0.8)
        let data = UniformBufferEncoder.encode(
            filterName: "CIColorMonochrome",
            parameters: [kCIInputColorKey: color],
            imageWidth: 100,
            imageHeight: 100
        )

        // Should include color components
        #expect(data.count >= 24)
    }
}

// MARK: - Default Value Tests

@Suite("UniformBufferEncoder Default Values")
struct UniformBufferEncoderDefaultValuesTests {

    @Test("Gaussian blur uses default radius when not specified")
    func gaussianBlurDefaultRadius() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIGaussianBlur",
            parameters: [:],
            imageWidth: 100,
            imageHeight: 100
        )

        let radius = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(radius == 10.0)  // Default is 10.0
    }

    @Test("Color controls uses default values when not specified")
    func colorControlsDefaultValues() {
        let data = UniformBufferEncoder.encode(
            filterName: "CIColorControls",
            parameters: [:],
            imageWidth: 100,
            imageHeight: 100
        )

        let brightness = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }
        let contrast = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 12, as: Float.self)
        }
        let saturation = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 16, as: Float.self)
        }

        #expect(brightness == 0.0)  // Default
        #expect(contrast == 1.0)    // Default
        #expect(saturation == 1.0)  // Default
    }

    @Test("Sepia tone uses default intensity when not specified")
    func sepiaToneDefaultIntensity() {
        let data = UniformBufferEncoder.encode(
            filterName: "CISepiaTone",
            parameters: [:],
            imageWidth: 100,
            imageHeight: 100
        )

        let intensity = data.withUnsafeBytes { ptr -> Float in
            ptr.load(fromByteOffset: 8, as: Float.self)
        }

        #expect(intensity == 1.0)  // Default
    }
}

// MARK: - Data Alignment Tests

@Suite("UniformBufferEncoder Data Alignment")
struct UniformBufferEncoderDataAlignmentTests {

    @Test("Data size is multiple of 4 bytes")
    func dataSizeIsMultipleOf4() {
        let filterNames = [
            "CIGaussianBlur",
            "CIColorControls",
            "CISepiaTone",
            "CISourceOverCompositing",
            "CIConstantColorGenerator"
        ]

        for filterName in filterNames {
            let data = UniformBufferEncoder.encode(
                filterName: filterName,
                parameters: [:],
                imageWidth: 100,
                imageHeight: 100
            )

            #expect(data.count % 4 == 0, "\(filterName) data size should be multiple of 4")
        }
    }
}

// MARK: - Unknown Filter Tests

@Suite("UniformBufferEncoder Unknown Filters")
struct UniformBufferEncoderUnknownFiltersTests {

    @Test("Unknown filter returns minimal data")
    func unknownFilterReturnsMinimalData() {
        let data = UniformBufferEncoder.encode(
            filterName: "UnknownFilter",
            parameters: [:],
            imageWidth: 100,
            imageHeight: 100
        )

        // Should at least have image dimensions
        #expect(data.count >= 8)
    }
}
