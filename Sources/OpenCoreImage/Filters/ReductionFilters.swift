//
//  ReductionFilters.swift
//  OpenCoreImage
//
//  Reduction filter protocols for Core Image.
//

import Foundation

// MARK: - CIAreaReductionFilter

/// The properties you use to configure an area reduction filter.
public protocol CIAreaReductionFilter: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The extent of the region to process.
    var extent: CGRect { get set }
}

// MARK: - CIAreaAverage

/// The properties you use to configure an area average filter.
public protocol CIAreaAverage: CIAreaReductionFilter {
}

// MARK: - CIAreaHistogram

/// The properties you use to configure an area histogram filter.
public protocol CIAreaHistogram: CIAreaReductionFilter {
    /// The number of histogram bins.
    var count: Float { get set }
    /// The scale of the histogram.
    var scale: Float { get set }
}

// MARK: - CIAreaLogarithmicHistogram

/// The properties you use to configure an area logarithmic histogram filter.
public protocol CIAreaLogarithmicHistogram: CIAreaReductionFilter {
    /// The number of histogram bins.
    var count: Float { get set }
    /// The scale of the histogram.
    var scale: Float { get set }
    /// The minimum stop.
    var minimumStop: Float { get set }
    /// The maximum stop.
    var maximumStop: Float { get set }
}

// MARK: - CIAreaMaximum

/// The properties you use to configure an area maximum filter.
public protocol CIAreaMaximum: CIAreaReductionFilter {
}

// MARK: - CIAreaMaximumAlpha

/// The properties you use to configure an area maximum alpha filter.
public protocol CIAreaMaximumAlpha: CIAreaReductionFilter {
}

// MARK: - CIAreaMinimum

/// The properties you use to configure an area minimum filter.
public protocol CIAreaMinimum: CIAreaReductionFilter {
}

// MARK: - CIAreaMinimumAlpha

/// The properties you use to configure an area minimum alpha filter.
public protocol CIAreaMinimumAlpha: CIAreaReductionFilter {
}

// MARK: - CIAreaMinMax

/// The properties you use to configure an area min-max filter.
public protocol CIAreaMinMax: CIAreaReductionFilter {
}

// MARK: - CIAreaMinMaxRed

/// The properties you use to configure an area min-max red filter.
public protocol CIAreaMinMaxRed: CIAreaReductionFilter {
}

// MARK: - CIColumnAverage

/// The properties you use to configure a column average filter.
public protocol CIColumnAverage: CIAreaReductionFilter {
}

// MARK: - CIRowAverage

/// The properties you use to configure a row average filter.
public protocol CIRowAverage: CIAreaReductionFilter {
}

// MARK: - CIAreaAverageMaximumRed

/// The properties you use to configure an area average and maximum red filter.
/// Calculates the average and maximum red component value for the specified area in an image.
public protocol CIAreaAverageMaximumRed: CIAreaReductionFilter {
}

// MARK: - CIAreaBoundsRed

/// The properties you use to configure an area bounds red filter.
public protocol CIAreaBoundsRed: CIAreaReductionFilter {
}

// MARK: - CIHistogramDisplay

/// The properties you use to configure a histogram display filter.
public protocol CIHistogramDisplay: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The height of the histogram.
    var height: Float { get set }
    /// The high limit.
    var highLimit: Float { get set }
    /// The low limit.
    var lowLimit: Float { get set }
}

// MARK: - CIKMeans

/// The properties you use to configure a k-means filter.
public protocol CIKMeans: CIAreaReductionFilter {
    /// The means image.
    var means: CIImage? { get set }
    /// The number of clusters.
    var count: Float { get set }
    /// The number of passes.
    var passes: Float { get set }
    /// Whether to use perceptual color space.
    var perceptual: Bool { get set }
}
