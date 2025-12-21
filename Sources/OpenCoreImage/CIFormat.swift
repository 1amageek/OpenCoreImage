//
//  CIFormat.swift
//  OpenCoreImage
//
//  Pixel data formats for image input, output, and processing.
//

import Foundation
import OpenCoreGraphics

/// Pixel data formats for image input, output, and processing.
public struct CIFormat: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: Int32

    @inlinable
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    // MARK: - RGBA Formats

    /// A 32-bit-per-pixel, fixed-point pixel format in which the red, green, and blue color components precede the alpha value.
    public static let RGBA8 = CIFormat(rawValue: 0)

    /// A 32-bit-per-pixel, fixed-point pixel format in which the blue, green, and red color components precede the alpha value.
    public static let BGRA8 = CIFormat(rawValue: 1)

    /// A 32-bit-per-pixel, fixed-point pixel format in which the alpha value precedes the red, green, and blue color components.
    public static let ARGB8 = CIFormat(rawValue: 2)

    /// A 32-bit-per-pixel, fixed-point pixel format in which the alpha value precedes the blue, green, and red color components.
    public static let ABGR8 = CIFormat(rawValue: 3)

    /// A 32-bit-per-pixel, fixed-point pixel format with no alpha, where red, green, and blue are followed by an unused byte.
    public static let RGBX8 = CIFormat(rawValue: 4)

    /// A 64-bit-per-pixel, fixed-point pixel format.
    public static let RGBA16 = CIFormat(rawValue: 5)

    /// A 64-bit-per-pixel, fixed-point pixel format with no alpha.
    public static let RGBX16 = CIFormat(rawValue: 6)

    /// A 64-bit-per-pixel, floating-point pixel format.
    public static let RGBAh = CIFormat(rawValue: 7)

    /// A 64-bit-per-pixel, floating-point pixel format with no alpha.
    public static let rgbXh = CIFormat(rawValue: 8)

    /// A 128-bit-per-pixel, floating-point pixel format.
    public static let RGBAf = CIFormat(rawValue: 9)

    /// A 128-bit-per-pixel, floating-point pixel format with no alpha.
    public static let rgbXf = CIFormat(rawValue: 10)

    /// A 32-bit-per-pixel, fixed-point pixel format with 10-bit RGB components.
    public static let RGB10 = CIFormat(rawValue: 11)

    // MARK: - Red Channel Formats

    /// An 8-bit-per-pixel, fixed-point pixel format in which the sole component is a red color value.
    public static let R8 = CIFormat(rawValue: 20)

    /// A 16-bit-per-pixel, fixed-point pixel format in which the sole component is a red color value.
    public static let R16 = CIFormat(rawValue: 21)

    /// A 16-bit-per-pixel, floating-point pixel format in which the sole component is a red color value.
    public static let Rh = CIFormat(rawValue: 22)

    /// A 32-bit-per-pixel, floating-point pixel format in which the sole component is a red color value.
    public static let Rf = CIFormat(rawValue: 23)

    // MARK: - Red-Green Channel Formats

    /// A 16-bit-per-pixel, fixed-point pixel format with only red and green color components.
    public static let RG8 = CIFormat(rawValue: 30)

    /// A 32-bit-per-pixel, fixed-point pixel format with only red and green color components.
    public static let RG16 = CIFormat(rawValue: 31)

    /// A 32-bit-per-pixel, floating-point pixel format with only red and green color components.
    public static let RGh = CIFormat(rawValue: 32)

    /// A 64-bit-per-pixel, floating-point pixel format with only red and green color components.
    public static let RGf = CIFormat(rawValue: 33)

    // MARK: - Alpha Channel Formats

    /// An 8-bit-per-pixel, fixed-point pixel format in which the sole component is alpha.
    public static let A8 = CIFormat(rawValue: 40)

    /// A 16-bit-per-pixel, fixed-point pixel format in which the sole component is alpha.
    public static let A16 = CIFormat(rawValue: 41)

    /// A 16-bit-per-pixel, half-width floating-point pixel format in which the sole component is alpha.
    public static let Ah = CIFormat(rawValue: 42)

    /// A 32-bit-per-pixel, full-width floating-point pixel format in which the sole component is alpha.
    public static let Af = CIFormat(rawValue: 43)

    // MARK: - Luminance Formats

    /// An 8-bit-per-pixel, fixed-point pixel format in which the sole component is luminance.
    public static let L8 = CIFormat(rawValue: 50)

    /// A 16-bit-per-pixel, fixed-point pixel format in which the sole component is luminance.
    public static let L16 = CIFormat(rawValue: 51)

    /// A 16-bit-per-pixel, half-width floating-point pixel format in which the sole component is luminance.
    public static let Lh = CIFormat(rawValue: 52)

    /// A 32-bit-per-pixel, full-width floating-point pixel format in which the sole component is luminance.
    public static let Lf = CIFormat(rawValue: 53)

    // MARK: - Luminance-Alpha Formats

    /// A 16-bit-per-pixel, fixed-point pixel format with only 8-bit luminance and alpha components.
    public static let LA8 = CIFormat(rawValue: 60)

    /// A 32-bit-per-pixel, fixed-point pixel format with only 16-bit luminance and alpha components.
    public static let LA16 = CIFormat(rawValue: 61)

    /// A 32-bit-per-pixel, half-width floating-point pixel format with 16-bit luminance and alpha components.
    public static let LAh = CIFormat(rawValue: 62)

    /// A 64-bit-per-pixel, full-width floating-point pixel format with 32-bit luminance and alpha components.
    public static let LAf = CIFormat(rawValue: 63)
}
