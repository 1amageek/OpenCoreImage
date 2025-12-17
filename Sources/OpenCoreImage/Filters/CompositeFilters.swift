//
//  CompositeFilters.swift
//  OpenCoreImage
//
//  Composite operation filter protocols for Core Image.
//

import Foundation

// MARK: - CICompositeOperation

/// The properties you use to configure a composite operation filter.
public protocol CICompositeOperation: CIFilterProtocol {
    /// The image to use as a foreground image.
    var inputImage: CIImage? { get set }
    /// The image to use as a background image.
    var backgroundImage: CIImage? { get set }
}
