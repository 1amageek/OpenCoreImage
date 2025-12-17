//
//  BlurFilters.swift
//  OpenCoreImage
//
//  Blur filter protocols for Core Image.
//

import Foundation

// MARK: - CIBokehBlur

/// The properties you use to configure a bokeh blur filter.
public protocol CIBokehBlur: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the blur, in pixels.
    var radius: Float { get set }
    /// The amount of extra emphasis at the ring of the bokeh.
    var ringAmount: Float { get set }
    /// The size of extra emphasis at the ring of the bokeh.
    var ringSize: Float { get set }
    /// The softness of the bokeh effect.
    var softness: Float { get set }
}

// MARK: - CIBoxBlur

/// The properties you use to configure a box blur filter.
public protocol CIBoxBlur: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the blur, in pixels.
    var radius: Float { get set }
}

// MARK: - CIDiscBlur

/// The properties you use to configure a disc blur filter.
public protocol CIDiscBlur: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the blur, in pixels.
    var radius: Float { get set }
}

// MARK: - CIGaussianBlur

/// The properties you use to configure a Gaussian blur filter.
public protocol CIGaussianBlur: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the blur, in pixels.
    var radius: Float { get set }
}

// MARK: - CIMaskedVariableBlur

/// The properties you use to configure a masked variable blur filter.
public protocol CIMaskedVariableBlur: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// A grayscale mask image that controls blur amount.
    var mask: CIImage? { get set }
    /// The radius of the blur, in pixels.
    var radius: Float { get set }
}

// MARK: - CIMedian

/// The properties you use to configure a median filter.
public protocol CIMedian: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
}

// MARK: - CIMorphologyGradient

/// The properties you use to configure a morphology gradient filter.
public protocol CIMorphologyGradient: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the morphology operation.
    var radius: Float { get set }
}

// MARK: - CIMorphologyMaximum

/// The properties you use to configure a morphology maximum filter.
public protocol CIMorphologyMaximum: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the morphology operation.
    var radius: Float { get set }
}

// MARK: - CIMorphologyMinimum

/// The properties you use to configure a morphology minimum filter.
public protocol CIMorphologyMinimum: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the morphology operation.
    var radius: Float { get set }
}

// MARK: - CIMorphologyRectangleMaximum

/// The properties you use to configure a morphology rectangle maximum filter.
public protocol CIMorphologyRectangleMaximum: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The width of the morphology operation.
    var width: Float { get set }
    /// The height of the morphology operation.
    var height: Float { get set }
}

// MARK: - CIMorphologyRectangleMinimum

/// The properties you use to configure a morphology rectangle minimum filter.
public protocol CIMorphologyRectangleMinimum: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The width of the morphology operation.
    var width: Float { get set }
    /// The height of the morphology operation.
    var height: Float { get set }
}

// MARK: - CIMotionBlur

/// The properties you use to configure a motion blur filter.
public protocol CIMotionBlur: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The radius of the blur, in pixels.
    var radius: Float { get set }
    /// The angle of motion, in radians.
    var angle: Float { get set }
}

// MARK: - CINoiseReduction

/// The properties you use to configure a noise reduction filter.
public protocol CINoiseReduction: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The noise level of the image.
    var noiseLevel: Float { get set }
    /// The sharpness level.
    var sharpness: Float { get set }
}

// MARK: - CIZoomBlur

/// The properties you use to configure a zoom blur filter.
public protocol CIZoomBlur: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center point of the zoom blur.
    var center: CGPoint { get set }
    /// The amount of blur.
    var amount: Float { get set }
}
