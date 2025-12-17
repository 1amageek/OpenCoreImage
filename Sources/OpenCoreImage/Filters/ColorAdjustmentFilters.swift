//
//  ColorAdjustmentFilters.swift
//  OpenCoreImage
//
//  Color adjustment filter protocols for Core Image.
//

import Foundation

// MARK: - CIColorAbsoluteDifference

/// The properties you use to configure a color absolute difference filter.
public protocol CIColorAbsoluteDifference: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The second input image for comparison.
    var inputImage2: CIImage? { get set }
}

// MARK: - CIColorClamp

/// The properties you use to configure a color clamp filter.
public protocol CIColorClamp: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The minimum color components.
    var minComponents: CIVector { get set }
    /// The maximum color components.
    var maxComponents: CIVector { get set }
}

// MARK: - CIColorControls

/// The properties you use to configure a color controls filter.
public protocol CIColorControls: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The amount of brightness to apply.
    var brightness: Float { get set }
    /// The amount of contrast to apply.
    var contrast: Float { get set }
    /// The amount of saturation to apply.
    var saturation: Float { get set }
}

// MARK: - CIColorMatrix

/// The properties you use to configure a color matrix filter.
public protocol CIColorMatrix: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The red vector.
    var rVector: CIVector { get set }
    /// The green vector.
    var gVector: CIVector { get set }
    /// The blue vector.
    var bVector: CIVector { get set }
    /// The alpha vector.
    var aVector: CIVector { get set }
    /// The bias vector.
    var biasVector: CIVector { get set }
}

// MARK: - CIColorPolynomial

/// The properties you use to configure a color polynomial filter.
public protocol CIColorPolynomial: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The red coefficients.
    var redCoefficients: CIVector { get set }
    /// The green coefficients.
    var greenCoefficients: CIVector { get set }
    /// The blue coefficients.
    var blueCoefficients: CIVector { get set }
    /// The alpha coefficients.
    var alphaCoefficients: CIVector { get set }
}

// MARK: - CIColorThreshold

/// The properties you use to configure a color threshold filter.
public protocol CIColorThreshold: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The threshold value.
    var threshold: Float { get set }
}

// MARK: - CIColorThresholdOtsu

/// The properties you use to configure a color threshold Otsu filter.
public protocol CIColorThresholdOtsu: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIDepthToDisparity

/// The properties you use to configure a depth-to-disparity filter.
public protocol CIDepthToDisparity: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIDisparityToDepth

/// The properties you use to configure a disparity-to-depth filter.
public protocol CIDisparityToDepth: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIExposureAdjust

/// The properties you use to configure an exposure adjust filter.
public protocol CIExposureAdjust: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The exposure value (EV) adjustment.
    var ev: Float { get set }
}

// MARK: - CIGammaAdjust

/// The properties you use to configure a gamma adjust filter.
public protocol CIGammaAdjust: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The gamma value.
    var power: Float { get set }
}

// MARK: - CIHueAdjust

/// The properties you use to configure a hue adjust filter.
public protocol CIHueAdjust: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The hue angle adjustment, in radians.
    var angle: Float { get set }
}

// MARK: - CILinearToSRGBToneCurve

/// The properties you use to configure a linear-to-sRGB filter.
public protocol CILinearToSRGBToneCurve: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CISRGBToneCurveToLinear

/// The properties you use to configure an sRGB-to-linear filter.
public protocol CISRGBToneCurveToLinear: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CISystemToneMap

/// The protocol for the System Tone Map filter.
public protocol CISystemToneMap: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CITemperatureAndTint

/// The properties you use to configure a temperature and tint filter.
public protocol CITemperatureAndTint: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The neutral temperature and tint values.
    var neutral: CIVector { get set }
    /// The target neutral temperature and tint values.
    var targetNeutral: CIVector { get set }
}

// MARK: - CIToneCurve

/// The properties you use to configure a tone curve filter.
public protocol CIToneCurve: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The first control point.
    var point0: CIVector { get set }
    /// The second control point.
    var point1: CIVector { get set }
    /// The third control point.
    var point2: CIVector { get set }
    /// The fourth control point.
    var point3: CIVector { get set }
    /// The fifth control point.
    var point4: CIVector { get set }
}

// MARK: - CIVibrance

/// The properties you use to configure a vibrance filter.
public protocol CIVibrance: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The amount of vibrance to apply.
    var amount: Float { get set }
}

// MARK: - CIWhitePointAdjust

/// The properties you use to configure a white-point adjust filter.
public protocol CIWhitePointAdjust: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The target white point color.
    var color: CIColor { get set }
}

// MARK: - CIToneMapHeadroom

/// The properties you use to configure a tone map headroom filter.
public protocol CIToneMapHeadroom: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The source headroom value.
    var sourceHeadroom: Float { get set }
    /// The target headroom value.
    var targetHeadroom: Float { get set }
}
