//
//  StylizingFilters.swift
//  OpenCoreImage
//
//  Stylizing filter protocols for Core Image.
//

import Foundation

// MARK: - CIBlendWithMask

/// The properties you use to configure a blend with mask filter.
public protocol CIBlendWithMask: CIFilterProtocol {
    /// The image to use as a foreground image.
    var inputImage: CIImage? { get set }
    /// The image to use as a background image.
    var backgroundImage: CIImage? { get set }
    /// A grayscale mask that defines the blend.
    var maskImage: CIImage? { get set }
}

// MARK: - CIBloom

/// The properties you use to configure a bloom filter.
public protocol CIBloom: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the bloom effect.
    var radius: Float { get set }
    /// The intensity of the bloom effect.
    var intensity: Float { get set }
}

// MARK: - CICannyEdgeDetector

/// The properties you use to configure a Canny edge detector filter.
public protocol CICannyEdgeDetector: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The Gaussian sigma.
    var gaussianSigma: Float { get set }
    /// Whether to use perceptual color space.
    var perceptual: Bool { get set }
    /// The low threshold.
    var thresholdLow: Float { get set }
    /// The high threshold.
    var thresholdHigh: Float { get set }
    /// The hysteresis passes.
    var hysteresisPasses: Int { get set }
}

// MARK: - CIComicEffect

/// The properties you use to configure a comic effect filter.
public protocol CIComicEffect: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CICoreMLModel

#if canImport(CoreML)
import CoreML

/// The properties you use to configure a Core ML model filter.
public protocol CICoreMLModel: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The Core ML model.
    var model: MLModel { get set }
    /// The head index.
    var headIndex: Float { get set }
    /// Whether to use software renderer.
    var softwareRenderer: Bool { get set }
}
#else
/// The properties you use to configure a Core ML model filter.
/// Note: CoreML is not available on this platform. This protocol is provided for API compatibility.
public protocol CICoreMLModel: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The head index.
    var headIndex: Float { get set }
    /// Whether to use software renderer.
    var softwareRenderer: Bool { get set }
}
#endif

// MARK: - CICrystallize

/// The properties you use to configure a crystallize filter.
public protocol CICrystallize: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the crystallize effect.
    var radius: Float { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
}

// MARK: - CIDepthOfField

/// The properties you use to configure a depth-of-field filter.
public protocol CIDepthOfField: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The first point defining the in-focus region.
    var point0: CGPoint { get set }
    /// The second point defining the in-focus region.
    var point1: CGPoint { get set }
    /// The saturation of the effect.
    var saturation: Float { get set }
    /// The radius of the unsharp mask.
    var unsharpMaskRadius: Float { get set }
    /// The intensity of the unsharp mask.
    var unsharpMaskIntensity: Float { get set }
    /// The radius of the effect.
    var radius: Float { get set }
}

// MARK: - CIEdges

/// The properties you use to configure an edges filter.
public protocol CIEdges: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The intensity of the edges effect.
    var intensity: Float { get set }
}

// MARK: - CIEdgeWork

/// The properties you use to configure an edge-work filter.
public protocol CIEdgeWork: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the effect.
    var radius: Float { get set }
}

// MARK: - CIGaborGradients

/// The properties you use to configure a Gabor gradients filter.
public protocol CIGaborGradients: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIGloom

/// The properties you use to configure a gloom filter.
public protocol CIGloom: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the gloom effect.
    var radius: Float { get set }
    /// The intensity of the gloom effect.
    var intensity: Float { get set }
}

// MARK: - CIHeightFieldFromMask

/// The properties you use to configure a height-field-from-mask filter.
public protocol CIHeightFieldFromMask: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the effect.
    var radius: Float { get set }
}

// MARK: - CIHexagonalPixellate

/// The properties you use to configure a hexagonal pixellate filter.
public protocol CIHexagonalPixellate: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The scale of the hexagons.
    var scale: Float { get set }
}

// MARK: - CIHighlightShadowAdjust

/// The properties you use to configure a highlight-shadow adjust filter.
public protocol CIHighlightShadowAdjust: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The highlight amount.
    var highlightAmount: Float { get set }
    /// The shadow amount.
    var shadowAmount: Float { get set }
    /// The radius of the effect.
    var radius: Float { get set }
}

// MARK: - CILineOverlay

/// The properties you use to configure a line overlay filter.
public protocol CILineOverlay: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The noise level for noise reduction.
    var nRNoiseLevel: Float { get set }
    /// The sharpness for noise reduction.
    var nRSharpness: Float { get set }
    /// The edge intensity.
    var edgeIntensity: Float { get set }
    /// The threshold.
    var threshold: Float { get set }
    /// The contrast.
    var contrast: Float { get set }
}

// MARK: - CIMix

/// The properties you use to configure a mix filter.
public protocol CIMix: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The background image.
    var backgroundImage: CIImage? { get set }
    /// The amount to mix.
    var amount: Float { get set }
}

// MARK: - CIPersonSegmentation

/// The properties you use to configure a person segmentation filter.
public protocol CIPersonSegmentation: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The quality level.
    var qualityLevel: Int { get set }
}

// MARK: - CIPixellate

/// The properties you use to configure a pixellate filter.
public protocol CIPixellate: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The scale of the pixels.
    var scale: Float { get set }
}

// MARK: - CIPointillize

/// The properties you use to configure a pointillize filter.
public protocol CIPointillize: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the points.
    var radius: Float { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
}

// MARK: - CISaliencyMap

/// The properties you use to configure a saliency map filter.
public protocol CISaliencyMap: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIShadedMaterial

/// The properties you use to configure a shaded material filter.
public protocol CIShadedMaterial: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The shading image.
    var shadingImage: CIImage? { get set }
    /// The scale of the effect.
    var scale: Float { get set }
}

// MARK: - CISobelGradients

/// The properties you use to configure a Sobel gradients filter.
public protocol CISobelGradients: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CISpotColor

/// The properties you use to configure a spot color filter.
public protocol CISpotColor: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The first center color.
    var centerColor1: CIColor { get set }
    /// The first replacement color.
    var replacementColor1: CIColor { get set }
    /// The first closeness value.
    var closeness1: Float { get set }
    /// The first contrast value.
    var contrast1: Float { get set }
    /// The second center color.
    var centerColor2: CIColor { get set }
    /// The second replacement color.
    var replacementColor2: CIColor { get set }
    /// The second closeness value.
    var closeness2: Float { get set }
    /// The second contrast value.
    var contrast2: Float { get set }
    /// The third center color.
    var centerColor3: CIColor { get set }
    /// The third replacement color.
    var replacementColor3: CIColor { get set }
    /// The third closeness value.
    var closeness3: Float { get set }
    /// The third contrast value.
    var contrast3: Float { get set }
}

// MARK: - CISpotLight

/// The properties you use to configure a spotlight filter.
public protocol CISpotLight: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The position of the light.
    var lightPosition: CIVector { get set }
    /// The point the light is pointing at.
    var lightPointsAt: CIVector { get set }
    /// The brightness of the light.
    var brightness: Float { get set }
    /// The concentration of the light.
    var concentration: Float { get set }
    /// The color of the light.
    var color: CIColor { get set }
}

// MARK: - CIDistanceGradientFromRedMask

/// The properties you use to configure a distance gradient from red mask filter.
/// Produces an infinite image where the red channel contains the distance in pixels from each pixel to the mask.
public protocol CIDistanceGradientFromRedMask: CIFilterProtocol {
    /// The input image whose red channel defines a mask.
    /// If the red channel pixel value is greater than 0.5 then the point is considered in the mask.
    var inputImage: CIImage? { get set }
    /// The maximum distance to the mask that can be measured.
    /// Distances between zero and the maximum will be normalized to zero and one.
    var maximumDistance: Float { get set }
}

// MARK: - CISignedDistanceGradientFromRedMask

/// The properties you use to configure a signed distance gradient from red mask filter.
/// Produces an infinite image where the red channel contains the signed distance in pixels from each pixel to the mask.
public protocol CISignedDistanceGradientFromRedMask: CIFilterProtocol {
    /// The input image whose red channel defines a mask.
    /// If the red channel pixel value is greater than 0.5 then the point is considered in the mask.
    var inputImage: CIImage? { get set }
    /// The maximum distance to the mask that can be measured.
    /// Distances between zero and the maximum will be normalized to negative one and one.
    var maximumDistance: Float { get set }
}
