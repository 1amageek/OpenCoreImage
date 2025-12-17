//
//  CIColorTests.swift
//  OpenCoreImage
//
//  Tests for CIColor functionality.
//

import Testing
@testable import OpenCoreImage

// MARK: - CIColor Initialization Tests

@Suite("CIColor Initialization")
struct CIColorInitializationTests {

    @Test("Initialize with RGB values")
    func initWithRGB() {
        let color = CIColor(red: 1.0, green: 0.5, blue: 0.25)
        #expect(color.red == 1.0)
        #expect(color.green == 0.5)
        #expect(color.blue == 0.25)
        #expect(color.alpha == 1.0)  // Default alpha
    }

    @Test("Initialize with RGBA values")
    func initWithRGBA() {
        let color = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.75)
        #expect(color.red == 1.0)
        #expect(color.green == 0.5)
        #expect(color.blue == 0.25)
        #expect(color.alpha == 0.75)
    }

    @Test("Initialize with CGColor")
    func initWithCGColor() {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        var components: [CGFloat] = [0.5, 0.6, 0.7, 0.8]
        let cgColor = CGColor(colorSpace: colorSpace, components: &components)!
        let ciColor = CIColor(cgColor: cgColor)

        #expect(ciColor.red == 0.5)
        #expect(ciColor.green == 0.6)
        #expect(ciColor.blue == 0.7)
        #expect(ciColor.alpha == 0.8)
    }

    @Test("Initialize with color space")
    func initWithColorSpace() {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let color = CIColor(red: 0.3, green: 0.4, blue: 0.5, colorSpace: colorSpace)
        #expect(color != nil)
        #expect(color?.red == 0.3)
        #expect(color?.green == 0.4)
        #expect(color?.blue == 0.5)
        #expect(color?.alpha == 1.0)
    }

    @Test("Initialize with color space and alpha")
    func initWithColorSpaceAndAlpha() {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let color = CIColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 0.6, colorSpace: colorSpace)
        #expect(color != nil)
        #expect(color?.red == 0.3)
        #expect(color?.green == 0.4)
        #expect(color?.blue == 0.5)
        #expect(color?.alpha == 0.6)
    }
}

// MARK: - CIColor String Initialization Tests

@Suite("CIColor String Initialization")
struct CIColorStringInitializationTests {

    @Test("Initialize from valid RGBA string")
    func initFromValidRGBAString() {
        let color = CIColor(string: "1.0 0.5 0.25 0.75")
        #expect(color.red == 1.0)
        #expect(color.green == 0.5)
        #expect(color.blue == 0.25)
        #expect(color.alpha == 0.75)
    }

    @Test("Initialize from RGB string (alpha defaults to 1)")
    func initFromRGBString() {
        let color = CIColor(string: "0.5 0.6 0.7")
        #expect(color.red == 0.5)
        #expect(color.green == 0.6)
        #expect(color.blue == 0.7)
        #expect(color.alpha == 1.0)
    }

    @Test("Initialize from partial string")
    func initFromPartialString() {
        let color = CIColor(string: "0.5")
        #expect(color.red == 0.5)
        #expect(color.green == 0)
        #expect(color.blue == 0)
        #expect(color.alpha == 1.0)
    }

    @Test("Initialize from empty string")
    func initFromEmptyString() {
        let color = CIColor(string: "")
        #expect(color.red == 0)
        #expect(color.green == 0)
        #expect(color.blue == 0)
        #expect(color.alpha == 1.0)
    }
}

// MARK: - CIColor Preset Tests

@Suite("CIColor Presets")
struct CIColorPresetTests {

    @Test("Black color")
    func blackColor() {
        let color = CIColor.black
        #expect(color.red == 0)
        #expect(color.green == 0)
        #expect(color.blue == 0)
        #expect(color.alpha == 1.0)
    }

    @Test("White color")
    func whiteColor() {
        let color = CIColor.white
        #expect(color.red == 1.0)
        #expect(color.green == 1.0)
        #expect(color.blue == 1.0)
        #expect(color.alpha == 1.0)
    }

    @Test("Red color")
    func redColor() {
        let color = CIColor.red
        #expect(color.red == 1.0)
        #expect(color.green == 0)
        #expect(color.blue == 0)
        #expect(color.alpha == 1.0)
    }

    @Test("Green color")
    func greenColor() {
        let color = CIColor.green
        #expect(color.red == 0)
        #expect(color.green == 1.0)
        #expect(color.blue == 0)
        #expect(color.alpha == 1.0)
    }

    @Test("Blue color")
    func blueColor() {
        let color = CIColor.blue
        #expect(color.red == 0)
        #expect(color.green == 0)
        #expect(color.blue == 1.0)
        #expect(color.alpha == 1.0)
    }

    @Test("Clear color")
    func clearColor() {
        let color = CIColor.clear
        #expect(color.red == 0)
        #expect(color.green == 0)
        #expect(color.blue == 0)
        #expect(color.alpha == 0)
    }

    @Test("Cyan color")
    func cyanColor() {
        let color = CIColor.cyan
        #expect(color.red == 0)
        #expect(color.green == 1.0)
        #expect(color.blue == 1.0)
        #expect(color.alpha == 1.0)
    }

    @Test("Magenta color")
    func magentaColor() {
        let color = CIColor.magenta
        #expect(color.red == 1.0)
        #expect(color.green == 0)
        #expect(color.blue == 1.0)
        #expect(color.alpha == 1.0)
    }

    @Test("Yellow color")
    func yellowColor() {
        let color = CIColor.yellow
        #expect(color.red == 1.0)
        #expect(color.green == 1.0)
        #expect(color.blue == 0)
        #expect(color.alpha == 1.0)
    }

    @Test("Gray color")
    func grayColor() {
        let color = CIColor.gray
        #expect(color.red == 0.5)
        #expect(color.green == 0.5)
        #expect(color.blue == 0.5)
        #expect(color.alpha == 1.0)
    }
}

// MARK: - CIColor Properties Tests

@Suite("CIColor Properties")
struct CIColorPropertiesTests {

    @Test("Number of components")
    func numberOfComponents() {
        let color = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.75)
        #expect(color.numberOfComponents == 4)
    }

    @Test("Color space exists")
    func colorSpaceExists() {
        let color = CIColor(red: 1.0, green: 0.5, blue: 0.25)
        #expect(color.colorSpace != nil)
    }

    @Test("String representation format")
    func stringRepresentationFormat() {
        let color = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.75)
        let str = color.stringRepresentation
        #expect(str.contains("1"))
        #expect(str.contains("0.5"))
        #expect(str.contains("0.25"))
        #expect(str.contains("0.75"))
    }
}

// MARK: - CIColor Equatable/Hashable Tests

@Suite("CIColor Equatable and Hashable")
struct CIColorEquatableHashableTests {

    @Test("Equal colors are equal")
    func equalColors() {
        let c1 = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.75)
        let c2 = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.75)
        #expect(c1 == c2)
    }

    @Test("Different colors are not equal")
    func differentColors() {
        let c1 = CIColor(red: 1.0, green: 0.5, blue: 0.25)
        let c2 = CIColor(red: 1.0, green: 0.5, blue: 0.3)
        #expect(c1 != c2)
    }

    @Test("Colors with different alpha are not equal")
    func differentAlpha() {
        let c1 = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 1.0)
        let c2 = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.5)
        #expect(c1 != c2)
    }

    @Test("Equal colors have same hash")
    func equalHashValues() {
        let c1 = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.75)
        let c2 = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.75)
        #expect(c1.hashValue == c2.hashValue)
    }

    @Test("Colors can be used in Set")
    func colorsInSet() {
        let c1 = CIColor(red: 1.0, green: 0.0, blue: 0.0)
        let c2 = CIColor(red: 1.0, green: 0.0, blue: 0.0)
        let c3 = CIColor(red: 0.0, green: 1.0, blue: 0.0)

        var set: Set<CIColor> = []
        set.insert(c1)
        set.insert(c2)
        set.insert(c3)

        #expect(set.count == 2)
    }
}

// MARK: - CIColor Description Tests

@Suite("CIColor Description")
struct CIColorDescriptionTests {

    @Test("Description includes RGBA values")
    func descriptionIncludesRGBA() {
        let color = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.75)
        let desc = color.description
        #expect(desc.contains("red"))
        #expect(desc.contains("green"))
        #expect(desc.contains("blue"))
        #expect(desc.contains("alpha"))
    }

    @Test("Debug description matches description")
    func debugDescriptionMatchesDescription() {
        let color = CIColor(red: 1.0, green: 0.5, blue: 0.25, alpha: 0.75)
        #expect(color.debugDescription == color.description)
    }
}

// MARK: - CIColor Edge Cases Tests

@Suite("CIColor Edge Cases")
struct CIColorEdgeCaseTests {

    @Test("Color with zero values")
    func colorWithZeroValues() {
        let color = CIColor(red: 0, green: 0, blue: 0, alpha: 0)
        #expect(color.red == 0)
        #expect(color.green == 0)
        #expect(color.blue == 0)
        #expect(color.alpha == 0)
    }

    @Test("Color with maximum values")
    func colorWithMaxValues() {
        let color = CIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        #expect(color.red == 1.0)
        #expect(color.green == 1.0)
        #expect(color.blue == 1.0)
        #expect(color.alpha == 1.0)
    }

    @Test("Color with values greater than 1 (HDR)")
    func colorWithHDRValues() {
        let color = CIColor(red: 2.0, green: 1.5, blue: 0.5, alpha: 1.0)
        #expect(color.red == 2.0)
        #expect(color.green == 1.5)
        #expect(color.blue == 0.5)
    }

    @Test("Color with negative values")
    func colorWithNegativeValues() {
        let color = CIColor(red: -0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        #expect(color.red == -0.5)
    }
}
