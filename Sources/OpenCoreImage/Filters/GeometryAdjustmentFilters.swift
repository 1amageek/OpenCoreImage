//
//  GeometryAdjustmentFilters.swift
//  OpenCoreImage
//
//  Geometry adjustment filter protocols for Core Image.
//

import Foundation

// MARK: - CIFourCoordinateGeometryFilter

/// The properties you use to configure a geometry adjustment filter that requires four coordinates.
public protocol CIFourCoordinateGeometryFilter: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The top-left coordinate.
    var topLeft: CGPoint { get set }
    /// The top-right coordinate.
    var topRight: CGPoint { get set }
    /// The bottom-right coordinate.
    var bottomRight: CGPoint { get set }
    /// The bottom-left coordinate.
    var bottomLeft: CGPoint { get set }
}

// MARK: - CIBicubicScaleTransform

/// The properties you use to configure a bicubic scale transform filter.
public protocol CIBicubicScaleTransform: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The scale factor.
    var scale: Float { get set }
    /// The aspect ratio.
    var aspectRatio: Float { get set }
    /// The B value for the bicubic equation.
    var parameterB: Float { get set }
    /// The C value for the bicubic equation.
    var parameterC: Float { get set }
}

// MARK: - CIEdgePreserveUpsample

/// The properties you use to configure an edge preserve upsample filter.
public protocol CIEdgePreserveUpsample: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The small image.
    var smallImage: CIImage? { get set }
    /// The spatial sigma.
    var spatialSigma: Float { get set }
    /// The luma sigma.
    var lumaSigma: Float { get set }
}

// MARK: - CIKeystoneCorrectionCombined

/// The properties you use to configure a keystone correction combined filter.
public protocol CIKeystoneCorrectionCombined: CIFourCoordinateGeometryFilter {
    /// The focal length.
    var focalLength: Float { get set }
}

// MARK: - CIKeystoneCorrectionHorizontal

/// The properties you use to configure a keystone correction horizontal filter.
public protocol CIKeystoneCorrectionHorizontal: CIFourCoordinateGeometryFilter {
    /// The focal length.
    var focalLength: Float { get set }
}

// MARK: - CIKeystoneCorrectionVertical

/// The properties you use to configure a keystone correction vertical filter.
public protocol CIKeystoneCorrectionVertical: CIFourCoordinateGeometryFilter {
    /// The focal length.
    var focalLength: Float { get set }
}

// MARK: - CILanczosScaleTransform

/// The properties you use to configure a Lanczos scale transform filter.
public protocol CILanczosScaleTransform: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The scale factor.
    var scale: Float { get set }
    /// The aspect ratio.
    var aspectRatio: Float { get set }
}

// MARK: - CIPerspectiveCorrection

/// The properties you use to configure a perspective correction filter.
public protocol CIPerspectiveCorrection: CIFourCoordinateGeometryFilter {
    /// Whether to crop the output.
    var crop: Bool { get set }
}

// MARK: - CIPerspectiveRotate

/// The properties you use to configure a perspective rotate filter.
public protocol CIPerspectiveRotate: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The focal length.
    var focalLength: Float { get set }
    /// The pitch angle.
    var pitch: Float { get set }
    /// The yaw angle.
    var yaw: Float { get set }
    /// The roll angle.
    var roll: Float { get set }
}

// MARK: - CIPerspectiveTransform

/// The properties you use to configure a perspective transform filter.
public protocol CIPerspectiveTransform: CIFourCoordinateGeometryFilter {
}

// MARK: - CIPerspectiveTransformWithExtent

/// The properties you use to configure a perspective transform with extent filter.
public protocol CIPerspectiveTransformWithExtent: CIFourCoordinateGeometryFilter {
    /// The extent of the output.
    var extent: CGRect { get set }
}

// MARK: - CIStraighten

/// The properties you use to configure a straighten filter.
public protocol CIStraighten: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The rotation angle.
    var angle: Float { get set }
}

// MARK: - CIMaximumScaleTransform

/// The properties you use to configure a maximum scale transform filter.
public protocol CIMaximumScaleTransform: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The scale factor.
    var scale: Float { get set }
    /// The aspect ratio.
    var aspectRatio: Float { get set }
}
