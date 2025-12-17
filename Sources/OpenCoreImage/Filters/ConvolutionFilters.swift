//
//  ConvolutionFilters.swift
//  OpenCoreImage
//
//  Convolution filter protocols for Core Image.
//

import Foundation

// MARK: - CIConvolution

/// The properties you use to configure a convolution filter.
public protocol CIConvolution: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The convolution kernel.
    var weights: CIVector { get set }
    /// A value that's added to each output pixel.
    var bias: Float { get set }
}
