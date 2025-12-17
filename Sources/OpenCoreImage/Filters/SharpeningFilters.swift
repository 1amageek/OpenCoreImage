//
//  SharpeningFilters.swift
//  OpenCoreImage
//
//  Sharpening filter protocols for Core Image.
//

import Foundation

// MARK: - CISharpenLuminance

/// The properties you use to configure a sharpen luminance filter.
public protocol CISharpenLuminance: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The sharpness amount.
    var sharpness: Float { get set }
    /// The radius of the sharpening.
    var radius: Float { get set }
}

// MARK: - CIUnsharpMask

/// The properties you use to configure an unsharp mask filter.
public protocol CIUnsharpMask: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the effect.
    var radius: Float { get set }
    /// The intensity of the effect.
    var intensity: Float { get set }
}
