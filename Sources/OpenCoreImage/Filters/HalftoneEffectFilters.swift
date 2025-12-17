//
//  HalftoneEffectFilters.swift
//  OpenCoreImage
//
//  Halftone effect filter protocols for Core Image.
//

import Foundation

// MARK: - CICircularScreen

/// The properties you use to configure a circular screen filter.
public protocol CICircularScreen: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The width of the circles.
    var width: Float { get set }
    /// The sharpness of the pattern.
    var sharpness: Float { get set }
}

// MARK: - CICMYKHalftone

/// The properties you use to configure a CMYK halftone filter.
public protocol CICMYKHalftone: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The width of the halftone dots.
    var width: Float { get set }
    /// The angle of the halftone pattern.
    var angle: Float { get set }
    /// The sharpness of the pattern.
    var sharpness: Float { get set }
    /// The gray component replacement.
    var gCR: Float { get set }
    /// The under color removal.
    var uCR: Float { get set }
}

// MARK: - CIDotScreen

/// The properties you use to configure a dot screen filter.
public protocol CIDotScreen: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The angle of the pattern.
    var angle: Float { get set }
    /// The width of the dots.
    var width: Float { get set }
    /// The sharpness of the pattern.
    var sharpness: Float { get set }
}

// MARK: - CIHatchedScreen

/// The properties you use to configure a hatched screen filter.
public protocol CIHatchedScreen: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The angle of the pattern.
    var angle: Float { get set }
    /// The width of the hatching.
    var width: Float { get set }
    /// The sharpness of the pattern.
    var sharpness: Float { get set }
}

// MARK: - CILineScreen

/// The properties you use to configure a line screen filter.
public protocol CILineScreen: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The angle of the pattern.
    var angle: Float { get set }
    /// The width of the lines.
    var width: Float { get set }
    /// The sharpness of the pattern.
    var sharpness: Float { get set }
}
