//
//  DistortionFilters.swift
//  OpenCoreImage
//
//  Distortion filter protocols for Core Image.
//

import Foundation

// MARK: - CIBumpDistortion

/// The properties you use to configure a bump distortion filter.
public protocol CIBumpDistortion: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the bump effect.
    var center: CGPoint { get set }
    /// The radius of the bump effect.
    var radius: Float { get set }
    /// The scale of the bump effect.
    var scale: Float { get set }
}

// MARK: - CIBumpDistortionLinear

/// The properties you use to configure a linear bump distortion filter.
public protocol CIBumpDistortionLinear: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the bump effect.
    var center: CGPoint { get set }
    /// The radius of the bump effect.
    var radius: Float { get set }
    /// The angle of the bump effect.
    var angle: Float { get set }
    /// The scale of the bump effect.
    var scale: Float { get set }
}

// MARK: - CICircleSplashDistortion

/// The properties you use to configure a circle splash distortion filter.
public protocol CICircleSplashDistortion: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The radius of the effect.
    var radius: Float { get set }
}

// MARK: - CICircularWrap

/// The properties you use to configure a circular wrap filter.
public protocol CICircularWrap: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The radius of the effect.
    var radius: Float { get set }
    /// The angle of the effect.
    var angle: Float { get set }
}

// MARK: - CIDisplacementDistortion

/// The properties you use to configure a displacement distortion filter.
public protocol CIDisplacementDistortion: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The displacement image.
    var displacementImage: CIImage? { get set }
    /// The scale of the displacement.
    var scale: Float { get set }
}

// MARK: - CIDroste

/// The properties you use to configure a Droste filter.
public protocol CIDroste: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The first inset point.
    var insetPoint0: CGPoint { get set }
    /// The second inset point.
    var insetPoint1: CGPoint { get set }
    /// The number of strands.
    var strands: Float { get set }
    /// The periodicity of the effect.
    var periodicity: Float { get set }
    /// The rotation of the effect.
    var rotation: Float { get set }
    /// The zoom factor.
    var zoom: Float { get set }
}

// MARK: - CIGlassDistortion

/// The properties you use to configure a glass distortion filter.
public protocol CIGlassDistortion: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The texture image.
    var textureImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The scale of the effect.
    var scale: Float { get set }
}

// MARK: - CIGlassLozenge

/// The properties you use to configure a glass lozenge filter.
public protocol CIGlassLozenge: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The first point.
    var point0: CGPoint { get set }
    /// The second point.
    var point1: CGPoint { get set }
    /// The radius of the effect.
    var radius: Float { get set }
    /// The refraction value.
    var refraction: Float { get set }
}

// MARK: - CIHoleDistortion

/// The properties you use to configure a hole distortion filter.
public protocol CIHoleDistortion: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The radius of the effect.
    var radius: Float { get set }
}

// MARK: - CILightTunnel

/// The properties you use to configure a light tunnel filter.
public protocol CILightTunnel: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The rotation of the effect.
    var rotation: Float { get set }
    /// The radius of the effect.
    var radius: Float { get set }
}

// MARK: - CINinePartStretched

/// The properties you use to configure a nine-part stretched filter.
public protocol CINinePartStretched: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The first breakpoint.
    var breakpoint0: CGPoint { get set }
    /// The second breakpoint.
    var breakpoint1: CGPoint { get set }
    /// Whether to grow only.
    var growAmount: CGPoint { get set }
}

// MARK: - CINinePartTiled

/// The properties you use to configure a nine-part tiled filter.
public protocol CINinePartTiled: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The first breakpoint.
    var breakpoint0: CGPoint { get set }
    /// The second breakpoint.
    var breakpoint1: CGPoint { get set }
    /// Whether to flip Y and tile.
    var flipYTiles: Bool { get set }
    /// The grow amount.
    var growAmount: CGPoint { get set }
}

// MARK: - CIPinchDistortion

/// The properties you use to configure a pinch distortion filter.
public protocol CIPinchDistortion: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The radius of the effect.
    var radius: Float { get set }
    /// The scale of the effect.
    var scale: Float { get set }
}

// MARK: - CIStretchCrop

/// The properties you use to configure a stretch crop filter.
public protocol CIStretchCrop: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The target size.
    var size: CGPoint { get set }
    /// The crop amount.
    var cropAmount: Float { get set }
    /// The center stretch amount.
    var centerStretchAmount: Float { get set }
}

// MARK: - CITorusLensDistortion

/// The properties you use to configure a torus lens distortion filter.
public protocol CITorusLensDistortion: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The radius of the effect.
    var radius: Float { get set }
    /// The width of the torus.
    var width: Float { get set }
    /// The refraction value.
    var refraction: Float { get set }
}

// MARK: - CITwirlDistortion

/// The properties you use to configure a twirl distortion filter.
public protocol CITwirlDistortion: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The radius of the effect.
    var radius: Float { get set }
    /// The angle of the effect.
    var angle: Float { get set }
}

// MARK: - CIVortexDistortion

/// The properties you use to configure a vortex distortion filter.
public protocol CIVortexDistortion: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The radius of the effect.
    var radius: Float { get set }
    /// The angle of the effect.
    var angle: Float { get set }
}
