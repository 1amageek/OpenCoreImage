//
//  ColorEffectFilters.swift
//  OpenCoreImage
//
//  Color effect filter protocols for Core Image.
//

import Foundation

// MARK: - CIColorCrossPolynomial

/// The properties you use to configure a color cross-polynomial filter.
public protocol CIColorCrossPolynomial: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The red coefficients.
    var redCoefficients: CIVector { get set }
    /// The green coefficients.
    var greenCoefficients: CIVector { get set }
    /// The blue coefficients.
    var blueCoefficients: CIVector { get set }
}

// MARK: - CIColorCube

/// The properties you use to configure a color cube filter.
public protocol CIColorCube: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The dimension of the color cube.
    var cubeDimension: Float { get set }
    /// The color cube data.
    var cubeData: Data { get set }
}

// MARK: - CIColorCubeWithColorSpace

/// The properties you use to configure a color cube with color space filter.
public protocol CIColorCubeWithColorSpace: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The dimension of the color cube.
    var cubeDimension: Float { get set }
    /// The color cube data.
    var cubeData: Data { get set }
    /// The color space to use.
    var colorSpace: CGColorSpace { get set }
}

// MARK: - CIColorCubesMixedWithMask

/// The properties you use to configure a color cube mixed with mask filter.
public protocol CIColorCubesMixedWithMask: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The mask image.
    var maskImage: CIImage? { get set }
    /// The dimension of the color cube.
    var cubeDimension: Float { get set }
    /// The color cube data for cube 0.
    var cube0Data: Data { get set }
    /// The color cube data for cube 1.
    var cube1Data: Data { get set }
    /// The color space to use.
    var colorSpace: CGColorSpace { get set }
}

// MARK: - CIColorCurves

/// The properties you use to configure a color curves filter.
public protocol CIColorCurves: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The curves data.
    var curvesData: Data { get set }
    /// The curves domain.
    var curvesDomain: CIVector { get set }
    /// The color space to use.
    var colorSpace: CGColorSpace { get set }
}

// MARK: - CIColorInvert

/// The properties you use to configure a color invert filter.
public protocol CIColorInvert: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIColorMap

/// The properties you use to configure a color map filter.
public protocol CIColorMap: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The gradient image to use as a color map.
    var gradientImage: CIImage? { get set }
}

// MARK: - CIColorMonochrome

/// The properties you use to configure a color monochrome filter.
public protocol CIColorMonochrome: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The monochrome color.
    var color: CIColor { get set }
    /// The intensity of the effect.
    var intensity: Float { get set }
}

// MARK: - CIColorPosterize

/// The properties you use to configure a color posterize filter.
public protocol CIColorPosterize: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The number of color levels.
    var levels: Float { get set }
}

// MARK: - CIConvertLab

/// The properties you use to configure a Lab color space conversion filter.
public protocol CIConvertLab: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// Whether to normalize the output.
    var normalize: Bool { get set }
}

// MARK: - CIDither

/// The properties you use to configure a dither filter.
public protocol CIDither: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The intensity of the dithering effect.
    var intensity: Float { get set }
}

// MARK: - CIDocumentEnhancer

/// The properties you use to configure a document enhancer filter.
public protocol CIDocumentEnhancer: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The amount of enhancement.
    var amount: Float { get set }
}

// MARK: - CIFalseColor

/// The properties you use to configure a false color filter.
public protocol CIFalseColor: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The first color.
    var color0: CIColor { get set }
    /// The second color.
    var color1: CIColor { get set }
}

// MARK: - CILabDeltaE

/// The properties you use to configure a Lab Delta E filter.
public protocol CILabDeltaE: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The second input image for comparison.
    var image2: CIImage? { get set }
}

// MARK: - CIMaskToAlpha

/// The properties you use to configure a mask-to-alpha filter.
public protocol CIMaskToAlpha: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIMaximumComponent

/// The properties you use to configure a maximum component filter.
public protocol CIMaximumComponent: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIMinimumComponent

/// The properties you use to configure a minimum component filter.
public protocol CIMinimumComponent: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIPaletteCentroid

/// The properties you use to configure a palette centroid filter.
public protocol CIPaletteCentroid: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The palette image.
    var paletteImage: CIImage? { get set }
    /// Whether to use perceptual color space.
    var perceptual: Bool { get set }
}

// MARK: - CIPalettize

/// The properties you use to configure a palettize filter.
public protocol CIPalettize: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The palette image.
    var paletteImage: CIImage? { get set }
    /// Whether to use perceptual color space.
    var perceptual: Bool { get set }
}

// MARK: - CIPhotoEffect

/// The properties you use to configure a photo-effect filter.
public protocol CIPhotoEffect: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CISepiaTone

/// The properties you use to configure a sepia-tone filter.
public protocol CISepiaTone: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The intensity of the sepia effect.
    var intensity: Float { get set }
}

// MARK: - CIThermal

/// The properties you use to configure a thermal filter.
public protocol CIThermal: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIVignette

/// The properties you use to configure a vignette filter.
public protocol CIVignette: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The intensity of the vignette effect.
    var intensity: Float { get set }
    /// The radius of the vignette effect.
    var radius: Float { get set }
}

// MARK: - CIVignetteEffect

/// The properties you use to configure a vignette-effect filter.
public protocol CIVignetteEffect: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the vignette effect.
    var center: CGPoint { get set }
    /// The radius of the vignette effect.
    var radius: Float { get set }
    /// The intensity of the vignette effect.
    var intensity: Float { get set }
    /// The falloff of the vignette effect.
    var falloff: Float { get set }
}

// MARK: - CIXRay

/// The properties you use to configure an X-ray filter.
public protocol CIXRay: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}
