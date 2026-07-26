//
//  TypeAliases.swift
//  OpenCoreImage
//
//  Conditional imports for CoreGraphics types.
//  On Apple platforms, use native CoreGraphics.
//  On WASM, use OpenCoreGraphics.
//


/// Image orientation values matching EXIF specification.
/// Used for transforming images to correct orientation.
public enum CGImagePropertyOrientation: UInt32, Sendable {
    case up = 1
    case upMirrored = 2
    case down = 3
    case downMirrored = 4
    case leftMirrored = 5
    case right = 6
    case rightMirrored = 7
    case left = 8
}


// CoreGraphics C-style color space creation functions.
// These are always available because OpenCoreImage uses OpenCoreGraphics
// (pure Swift) on every platform — it never imports Apple's CoreGraphics,
// so the C-style bridges must be provided here regardless of arch.

/// Creates a device RGB color space.
public func CGColorSpaceCreateDeviceRGB() -> CGColorSpace {
    .deviceRGB
}

/// Creates a device gray color space.
public func CGColorSpaceCreateDeviceGray() -> CGColorSpace {
    .deviceGray
}

/// Creates a device CMYK color space.
public func CGColorSpaceCreateDeviceCMYK() -> CGColorSpace {
    .deviceCMYK
}


// MARK: - Apple Framework Type Stubs for WASM

// These types exist in Apple frameworks but are not available in WASM.
// They are defined as stubs to maintain API compatibility.

/// A stub type representing Core Video pixel buffer.
///
/// On Apple platforms, this would be `CVPixelBuffer` from CoreVideo.
/// In WASM, this is a placeholder type for API compatibility.
// FIXME(INCOMPLETE_IMPLEMENTATION): This compatibility value carries dimensions and format but no pixel storage or access coordination.
// CIImage(cvPixelBuffer:) reaches this type and must not be treated as having renderable pixels.
// Remove this marker only after integration with the portable Core Video owner/lease contract and zero-copy behavior tests.
public struct CVPixelBuffer: Sendable {
    /// The width of the pixel buffer.
    public let width: Int

    /// The height of the pixel buffer.
    public let height: Int

    /// The pixel format of the buffer.
    public let pixelFormat: UInt32

    /// Creates a CVPixelBuffer stub.
    public init(width: Int, height: Int, pixelFormat: UInt32 = 0x42475241 /* BGRA */) {
        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat
    }
}

/// A stub type representing AVFoundation depth data.
///
/// On Apple platforms, this would be `AVDepthData` from AVFoundation.
/// In WASM, this is a placeholder type for API compatibility.
// FIXME(INCOMPLETE_IMPLEMENTATION): This compatibility value does not implement AVDepthData calibration, conversion, or ownership semantics.
// CIImage(depthData:) reaches this type and currently carries only an optional image reference.
// Remove this marker only after portable depth metadata, pixel ownership, conversion, and failure behavior are tested.
public struct AVDepthData {
    /// The depth data as a CIImage.
    public let depthDataMap: CIImage?

    /// Whether the depth data is filtered.
    public let isDepthDataFiltered: Bool

    /// Creates an AVDepthData stub.
    public init(depthDataMap: CIImage? = nil, isDepthDataFiltered: Bool = false) {
        self.depthDataMap = depthDataMap
        self.isDepthDataFiltered = isDepthDataFiltered
    }
}

/// A stub type representing AVFoundation portrait effects matte.
///
/// On Apple platforms, this would be `AVPortraitEffectsMatte` from AVFoundation.
/// In WASM, this is a placeholder type for API compatibility.
// FIXME(INCOMPLETE_IMPLEMENTATION): This compatibility value does not implement matte metadata, pixel ownership, or format conversion.
// CIImage(portraitEffectsMatte:) reaches this type and currently carries only an optional image reference.
// Remove this marker only after the portable media matte contract and success/failure behavior are tested.
public struct AVPortraitEffectsMatte {
    /// The matte image.
    public let mattingImage: CIImage?

    /// Creates an AVPortraitEffectsMatte stub.
    public init(mattingImage: CIImage? = nil) {
        self.mattingImage = mattingImage
    }
}

/// The type of semantic segmentation matte.
public struct AVSemanticSegmentationMatteType: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Skin matte type.
    public static let skin = AVSemanticSegmentationMatteType(rawValue: "skin")

    /// Hair matte type.
    public static let hair = AVSemanticSegmentationMatteType(rawValue: "hair")

    /// Teeth matte type.
    public static let teeth = AVSemanticSegmentationMatteType(rawValue: "teeth")

    /// Glasses matte type.
    public static let glasses = AVSemanticSegmentationMatteType(rawValue: "glasses")

    /// Sky matte type.
    public static let sky = AVSemanticSegmentationMatteType(rawValue: "sky")
}

/// A stub type representing AVFoundation semantic segmentation matte.
///
/// On Apple platforms, this would be `AVSemanticSegmentationMatte` from AVFoundation.
/// In WASM, this is a placeholder type for API compatibility.
// FIXME(INCOMPLETE_IMPLEMENTATION): This compatibility value does not implement matte metadata, pixel ownership, or format conversion.
// CIImage(semanticSegmentationMatte:) reaches this type and currently carries only type and optional image references.
// Remove this marker only after the portable media matte contract and success/failure behavior are tested.
public struct AVSemanticSegmentationMatte {
    /// The matte type.
    public let matteType: AVSemanticSegmentationMatteType

    /// The matte image.
    public let mattingImage: CIImage?

    /// Creates an AVSemanticSegmentationMatte stub.
    public init(matteType: AVSemanticSegmentationMatteType, mattingImage: CIImage? = nil) {
        self.matteType = matteType
        self.mattingImage = mattingImage
    }
}
