//
//  TileEffectFilters.swift
//  OpenCoreImage
//
//  Tile effect filter protocols for Core Image.
//

import Foundation
import OpenCoreGraphics

// MARK: - CIAffineClamp

/// The properties you use to configure an affine clamp filter.
public protocol CIAffineClamp: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The transform to apply.
    var transform: CGAffineTransform { get set }
}

// MARK: - CIAffineTile

/// The properties you use to configure an affine tile filter.
public protocol CIAffineTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The transform to apply.
    var transform: CGAffineTransform { get set }
}

// MARK: - CIEightfoldReflectedTile

/// The properties you use to configure an eightfold reflected tile filter.
public protocol CIEightfoldReflectedTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the tile.
    var center: CGPoint { get set }
    /// The angle of the tile.
    var angle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}

// MARK: - CIFourfoldReflectedTile

/// The properties you use to configure a fourfold reflected tile filter.
public protocol CIFourfoldReflectedTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the tile.
    var center: CGPoint { get set }
    /// The angle of the tile.
    var angle: Float { get set }
    /// The acute angle.
    var acuteAngle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}

// MARK: - CIFourfoldRotatedTile

/// The properties you use to configure a fourfold rotated tile filter.
public protocol CIFourfoldRotatedTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the tile.
    var center: CGPoint { get set }
    /// The angle of the tile.
    var angle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}

// MARK: - CIFourfoldTranslatedTile

/// The properties you use to configure a fourfold translated tile filter.
public protocol CIFourfoldTranslatedTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the tile.
    var center: CGPoint { get set }
    /// The angle of the tile.
    var angle: Float { get set }
    /// The acute angle.
    var acuteAngle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}

// MARK: - CIGlideReflectedTile

/// The properties you use to configure a glide reflected tile filter.
public protocol CIGlideReflectedTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the tile.
    var center: CGPoint { get set }
    /// The angle of the tile.
    var angle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}

// MARK: - CIKaleidoscope

/// The properties you use to configure a kaleidoscope filter.
public protocol CIKaleidoscope: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The number of reflections in the pattern.
    var count: Int { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The angle of the reflection.
    var angle: Float { get set }
}

// MARK: - CIOpTile

/// The properties you use to configure an optical tile filter.
public protocol CIOpTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The scale of the effect.
    var scale: Float { get set }
    /// The angle of the effect.
    var angle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}

// MARK: - CIParallelogramTile

/// The properties you use to configure a parallelogram tile filter.
public protocol CIParallelogramTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the tile.
    var center: CGPoint { get set }
    /// The angle of the tile.
    var angle: Float { get set }
    /// The acute angle.
    var acuteAngle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}

// MARK: - CIPerspectiveTile

/// The properties you use to configure a perspective tile filter.
public protocol CIPerspectiveTile: CIFilterProtocol {
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

// MARK: - CISixfoldReflectedTile

/// The properties you use to configure a sixfold reflected tile filter.
public protocol CISixfoldReflectedTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the tile.
    var center: CGPoint { get set }
    /// The angle of the tile.
    var angle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}

// MARK: - CISixfoldRotatedTile

/// The properties you use to configure a sixfold rotated tile filter.
public protocol CISixfoldRotatedTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the tile.
    var center: CGPoint { get set }
    /// The angle of the tile.
    var angle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}

// MARK: - CITriangleKaleidoscope

/// The properties you use to configure a triangle kaleidoscope filter.
public protocol CITriangleKaleidoscope: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The point of the triangle.
    var point: CGPoint { get set }
    /// The size of the triangle.
    var size: Float { get set }
    /// The rotation of the triangle.
    var rotation: Float { get set }
    /// The decay of the effect.
    var decay: Float { get set }
}

// MARK: - CITriangleTile

/// The properties you use to configure a triangle tile filter.
public protocol CITriangleTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the tile.
    var center: CGPoint { get set }
    /// The angle of the tile.
    var angle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}

// MARK: - CITwelvefoldReflectedTile

/// The properties you use to configure a twelvefold reflected tile filter.
public protocol CITwelvefoldReflectedTile: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The center of the tile.
    var center: CGPoint { get set }
    /// The angle of the tile.
    var angle: Float { get set }
    /// The width of the tile.
    var width: Float { get set }
}
