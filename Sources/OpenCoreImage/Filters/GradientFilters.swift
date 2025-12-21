//
//  GradientFilters.swift
//  OpenCoreImage
//
//  Gradient filter protocols for Core Image.
//

import Foundation
import OpenCoreGraphics

// MARK: - CIGaussianGradient

/// The properties you use to configure a Gaussian gradient filter.
public protocol CIGaussianGradient: CIFilterProtocol {
    /// The center of the gradient.
    var center: CGPoint { get set }
    /// The first color.
    var color0: CIColor { get set }
    /// The second color.
    var color1: CIColor { get set }
    /// The radius of the gradient.
    var radius: Float { get set }
}

// MARK: - CIHueSaturationValueGradient

/// The properties you use to configure a hue-saturation-value gradient filter.
public protocol CIHueSaturationValueGradient: CIFilterProtocol {
    /// The value component.
    var value: Float { get set }
    /// The radius of the gradient.
    var radius: Float { get set }
    /// The softness of the gradient.
    var softness: Float { get set }
    /// The dither amount.
    var dither: Float { get set }
    /// The color space.
    var colorSpace: CGColorSpace { get set }
}

// MARK: - CILinearGradient

/// The properties you use to configure a linear gradient filter.
public protocol CILinearGradient: CIFilterProtocol {
    /// The starting position of the gradient.
    var point0: CGPoint { get set }
    /// The ending position of the gradient.
    var point1: CGPoint { get set }
    /// The first color to use in the gradient.
    var color0: CIColor { get set }
    /// The second color to use in the gradient.
    var color1: CIColor { get set }
}

// MARK: - CIRadialGradient

/// The properties you use to configure a radial gradient filter.
public protocol CIRadialGradient: CIFilterProtocol {
    /// The center of the gradient.
    var center: CGPoint { get set }
    /// The inner radius.
    var radius0: Float { get set }
    /// The outer radius.
    var radius1: Float { get set }
    /// The first color.
    var color0: CIColor { get set }
    /// The second color.
    var color1: CIColor { get set }
}

// MARK: - CISmoothLinearGradient

/// The properties you use to configure a smooth linear gradient filter.
public protocol CISmoothLinearGradient: CIFilterProtocol {
    /// The starting position of the gradient.
    var point0: CGPoint { get set }
    /// The ending position of the gradient.
    var point1: CGPoint { get set }
    /// The first color.
    var color0: CIColor { get set }
    /// The second color.
    var color1: CIColor { get set }
}
