//
//  CIFormatTests.swift
//  OpenCoreImage
//
//  Tests for CIFormat functionality.
//

import Testing
@testable import OpenCoreImage

// MARK: - CIFormat Comprehensive Tests

@Suite("CIFormat")
struct CIFormatTests {

    @Test("All formats have unique raw values")
    func allFormatsHaveUniqueRawValues() {
        let allFormats: [CIFormat] = [
            // RGBA formats
            .RGBA8, .BGRA8, .ARGB8, .ABGR8, .RGBX8, .RGBA16, .RGBX16, .RGBAh, .rgbXh, .RGBAf, .rgbXf, .RGB10,
            // Red channel formats
            .R8, .R16, .Rh, .Rf,
            // Red-Green channel formats
            .RG8, .RG16, .RGh, .RGf,
            // Alpha channel formats
            .A8, .A16, .Ah, .Af,
            // Luminance formats
            .L8, .L16, .Lh, .Lf,
            // Luminance-Alpha formats
            .LA8, .LA16, .LAh, .LAf
        ]

        var seenRawValues = Set<Int32>()
        for format in allFormats {
            #expect(!seenRawValues.contains(format.rawValue), "Duplicate rawValue: \(format.rawValue)")
            seenRawValues.insert(format.rawValue)
        }

        #expect(allFormats.count == seenRawValues.count, "All formats should have unique rawValues")
    }

    @Test("RGBA formats are correctly categorized")
    func rgbaFormats() {
        // 8-bit formats
        #expect(CIFormat.RGBA8.rawValue >= 0 && CIFormat.RGBA8.rawValue < 20)
        #expect(CIFormat.BGRA8.rawValue >= 0 && CIFormat.BGRA8.rawValue < 20)
        #expect(CIFormat.ARGB8.rawValue >= 0 && CIFormat.ARGB8.rawValue < 20)
        #expect(CIFormat.ABGR8.rawValue >= 0 && CIFormat.ABGR8.rawValue < 20)
        #expect(CIFormat.RGBX8.rawValue >= 0 && CIFormat.RGBX8.rawValue < 20)

        // 16-bit and float formats
        #expect(CIFormat.RGBA16.rawValue >= 0 && CIFormat.RGBA16.rawValue < 20)
        #expect(CIFormat.RGBAh.rawValue >= 0 && CIFormat.RGBAh.rawValue < 20)
        #expect(CIFormat.RGBAf.rawValue >= 0 && CIFormat.RGBAf.rawValue < 20)
    }

    @Test("Single channel formats have appropriate ranges")
    func singleChannelFormats() {
        // Red channel formats (20-29)
        #expect(CIFormat.R8.rawValue >= 20 && CIFormat.R8.rawValue < 30)
        #expect(CIFormat.R16.rawValue >= 20 && CIFormat.R16.rawValue < 30)
        #expect(CIFormat.Rh.rawValue >= 20 && CIFormat.Rh.rawValue < 30)
        #expect(CIFormat.Rf.rawValue >= 20 && CIFormat.Rf.rawValue < 30)

        // Red-Green formats (30-39)
        #expect(CIFormat.RG8.rawValue >= 30 && CIFormat.RG8.rawValue < 40)
        #expect(CIFormat.RG16.rawValue >= 30 && CIFormat.RG16.rawValue < 40)
        #expect(CIFormat.RGh.rawValue >= 30 && CIFormat.RGh.rawValue < 40)
        #expect(CIFormat.RGf.rawValue >= 30 && CIFormat.RGf.rawValue < 40)

        // Alpha formats (40-49)
        #expect(CIFormat.A8.rawValue >= 40 && CIFormat.A8.rawValue < 50)
        #expect(CIFormat.A16.rawValue >= 40 && CIFormat.A16.rawValue < 50)
        #expect(CIFormat.Ah.rawValue >= 40 && CIFormat.Ah.rawValue < 50)
        #expect(CIFormat.Af.rawValue >= 40 && CIFormat.Af.rawValue < 50)
    }

    @Test("Luminance formats have appropriate ranges")
    func luminanceFormats() {
        // Luminance formats (50-59)
        #expect(CIFormat.L8.rawValue >= 50 && CIFormat.L8.rawValue < 60)
        #expect(CIFormat.L16.rawValue >= 50 && CIFormat.L16.rawValue < 60)
        #expect(CIFormat.Lh.rawValue >= 50 && CIFormat.Lh.rawValue < 60)
        #expect(CIFormat.Lf.rawValue >= 50 && CIFormat.Lf.rawValue < 60)

        // Luminance-Alpha formats (60-69)
        #expect(CIFormat.LA8.rawValue >= 60 && CIFormat.LA8.rawValue < 70)
        #expect(CIFormat.LA16.rawValue >= 60 && CIFormat.LA16.rawValue < 70)
        #expect(CIFormat.LAh.rawValue >= 60 && CIFormat.LAh.rawValue < 70)
        #expect(CIFormat.LAf.rawValue >= 60 && CIFormat.LAf.rawValue < 70)
    }
}

// MARK: - CIFormat Functional Tests

@Suite("CIFormat Functional")
struct CIFormatFunctionalTests {

    @Test("Format can be used with CIContext.createCGImage")
    func formatWithContext() {
        let context = CIContext()
        let ciImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Test with RGBA8
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent, format: .RGBA8, colorSpace: colorSpace)
        #expect(cgImage != nil)
        #expect(cgImage?.width == 10)
    }

    @Test("Format can be used with CIRenderDestination")
    func formatWithRenderDestination() {
        // Create pixel buffer that lives beyond the closure
        let pixelBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 10 * 10 * 4)
        defer { pixelBuffer.deallocate() }

        let destination = CIRenderDestination(
            bitmapData: pixelBuffer,
            width: 10,
            height: 10,
            bytesPerRow: 10 * 4,
            format: .RGBA8
        )
        #expect(destination.width == 10)
        #expect(destination.height == 10)
    }

    @Test("Format can be used with CIImageAccumulator")
    func formatWithImageAccumulator() {
        let accumulator = CIImageAccumulator(
            extent: CGRect(x: 0, y: 0, width: 50, height: 50),
            format: .RGBA8
        )
        #expect(accumulator != nil)
        #expect(accumulator?.format == .RGBA8)
    }

    @Test("Working format from CIContext")
    func contextWorkingFormat() {
        let context = CIContext()
        let format = context.workingFormat
        #expect(format.rawValue >= 0)
    }
}

// MARK: - CIFormat Equatable/Hashable Tests

@Suite("CIFormat Equatable and Hashable")
struct CIFormatEquatableHashableTests {

    @Test("Same formats are equal")
    func sameFormatsEqual() {
        let format1 = CIFormat.RGBA8
        let format2 = CIFormat.RGBA8
        #expect(format1 == format2)
        #expect(format1.rawValue == format2.rawValue)
    }

    @Test("Different formats are not equal")
    func differentFormatsNotEqual() {
        #expect(CIFormat.RGBA8 != CIFormat.BGRA8)
        #expect(CIFormat.R8 != CIFormat.RG8)
        #expect(CIFormat.L8 != CIFormat.LA8)
    }

    @Test("Formats work correctly in Set")
    func formatsInSet() {
        var set: Set<CIFormat> = []
        set.insert(.RGBA8)
        set.insert(.RGBA8)
        set.insert(.BGRA8)
        set.insert(.RGBAf)
        #expect(set.count == 3)
        #expect(set.contains(.RGBA8))
        #expect(set.contains(.BGRA8))
        #expect(set.contains(.RGBAf))
        #expect(!set.contains(.R8))
    }

    @Test("Formats work as Dictionary keys")
    func formatsAsDictionaryKeys() {
        var dict: [CIFormat: String] = [:]
        dict[.RGBA8] = "8-bit RGBA"
        dict[.RGBAf] = "Float RGBA"
        dict[.L8] = "Luminance 8-bit"
        #expect(dict.count == 3)
        #expect(dict[.RGBA8] == "8-bit RGBA")
        #expect(dict[.RGBAf] == "Float RGBA")
        #expect(dict[.L8] == "Luminance 8-bit")
    }
}

// MARK: - CIFormat RawRepresentable Tests

@Suite("CIFormat RawRepresentable")
struct CIFormatRawRepresentableTests {

    @Test("Create format from raw value")
    func createFromRawValue() {
        let format = CIFormat(rawValue: 0)
        #expect(format == .RGBA8)

        let format2 = CIFormat(rawValue: 1)
        #expect(format2 == .BGRA8)
    }

    @Test("Custom raw value format")
    func customRawValue() {
        let format = CIFormat(rawValue: 999)
        #expect(format.rawValue == 999)
        #expect(format != .RGBA8)
    }

    @Test("Round trip raw value")
    func roundTripRawValue() {
        let formats: [CIFormat] = [.RGBA8, .BGRA8, .R8, .RG8, .L8, .LA8, .RGBAf]
        for original in formats {
            let recreated = CIFormat(rawValue: original.rawValue)
            #expect(recreated == original, "Format \(original.rawValue) should round-trip")
        }
    }
}

// MARK: - CIFormat Sendable Tests

@Suite("CIFormat Sendable")
struct CIFormatSendableTests {

    @Test("Format is Sendable across tasks")
    func formatIsSendable() async {
        let format = CIFormat.RGBAf
        let result = await Task {
            return format
        }.value
        #expect(result == .RGBAf)
    }

    @Test("Multiple formats are Sendable")
    func multipleFormatsAreSendable() async {
        let formats: [CIFormat] = [.RGBA8, .BGRA8, .R8, .L8]
        let results = await Task {
            return formats
        }.value
        #expect(results.count == 4)
        #expect(results[0] == .RGBA8)
    }
}
