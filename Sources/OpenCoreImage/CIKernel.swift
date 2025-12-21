//
//  CIKernel.swift
//  OpenCoreImage
//
//  A GPU-based image-processing routine used to create custom Core Image filters.
//

import Foundation
import OpenCoreGraphics


/// A GPU-based image-processing routine used to create custom Core Image filters.
///
/// Use `CIKernel` and its subclasses to create custom image-processing effects
/// by writing your own kernel code.
public class CIKernel {

    // MARK: - Private Storage

    private let _name: String?
    private let _source: String?

    // MARK: - Initialization

    /// Creates a kernel object from the specified kernel source code.
    public init?(functionName name: String, fromMetalLibraryData data: Data) {
        self._name = name
        self._source = nil
    }

    /// Creates a kernel object from the specified kernel source code.
    public init?(source: String) {
        self._name = nil
        self._source = source
    }

    // MARK: - Properties

    /// The name of the kernel.
    public var name: String {
        _name ?? _source ?? "CIKernel"
    }

    // MARK: - Applying the Kernel

    /// Creates a new image by applying the kernel's image-processing routine.
    public func apply(
        extent: CGRect,
        roiCallback: @escaping (Int, CGRect) -> CGRect,
        arguments: [Any]?
    ) -> CIImage? {
        CIImage(extent: extent)
    }
}

// MARK: - CIColorKernel

/// A GPU-based image-processing routine that processes only the color information in images,
/// used to create custom Core Image filters.
public class CIColorKernel: CIKernel {

    /// Applies the kernel to the specified image.
    public func apply(extent: CGRect, arguments: [Any]?) -> CIImage? {
        CIImage(extent: extent)
    }
}

// MARK: - CIWarpKernel

/// A GPU-based image-processing routine that processes only the geometry information in an image,
/// used to create custom Core Image filters.
public class CIWarpKernel: CIKernel {

    /// Applies the kernel to the specified image.
    public func apply(
        extent: CGRect,
        roiCallback: @escaping (Int, CGRect) -> CGRect,
        image: CIImage,
        arguments: [Any]?
    ) -> CIImage? {
        CIImage(extent: extent)
    }
}

// MARK: - CIBlendKernel

/// A GPU-based image-processing routine that is optimized for blending two images.
public class CIBlendKernel: CIColorKernel {

    /// Applies the kernel to blend the foreground and background images.
    public func apply(foreground: CIImage, background: CIImage) -> CIImage? {
        let extent = foreground.extent.union(background.extent)
        return CIImage(extent: extent)
    }

    /// Applies the kernel to blend the foreground and background images with a color match.
    public func apply(foreground: CIImage, background: CIImage, colorSpace: CGColorSpace) -> CIImage? {
        apply(foreground: foreground, background: background)
    }

    // MARK: - Built-in Blend Kernels

    /// Source over compositing blend kernel.
    nonisolated(unsafe) public static let sourceOver = CIBlendKernel(source: "sourceOver")!

    /// Source in compositing blend kernel.
    nonisolated(unsafe) public static let sourceIn = CIBlendKernel(source: "sourceIn")!

    /// Source out compositing blend kernel.
    nonisolated(unsafe) public static let sourceOut = CIBlendKernel(source: "sourceOut")!

    /// Source atop compositing blend kernel.
    nonisolated(unsafe) public static let sourceAtop = CIBlendKernel(source: "sourceAtop")!

    /// Destination over compositing blend kernel.
    nonisolated(unsafe) public static let destinationOver = CIBlendKernel(source: "destinationOver")!

    /// Destination in compositing blend kernel.
    nonisolated(unsafe) public static let destinationIn = CIBlendKernel(source: "destinationIn")!

    /// Destination out compositing blend kernel.
    nonisolated(unsafe) public static let destinationOut = CIBlendKernel(source: "destinationOut")!

    /// Destination atop compositing blend kernel.
    nonisolated(unsafe) public static let destinationAtop = CIBlendKernel(source: "destinationAtop")!

    /// Exclusive or compositing blend kernel.
    nonisolated(unsafe) public static let exclusiveOr = CIBlendKernel(source: "exclusiveOr")!

    /// Multiply blend kernel.
    nonisolated(unsafe) public static let multiply = CIBlendKernel(source: "multiply")!

    /// Screen blend kernel.
    nonisolated(unsafe) public static let screen = CIBlendKernel(source: "screen")!

    /// Overlay blend kernel.
    nonisolated(unsafe) public static let overlay = CIBlendKernel(source: "overlay")!

    /// Darken blend kernel.
    nonisolated(unsafe) public static let darken = CIBlendKernel(source: "darken")!

    /// Lighten blend kernel.
    nonisolated(unsafe) public static let lighten = CIBlendKernel(source: "lighten")!

    /// Color dodge blend kernel.
    nonisolated(unsafe) public static let colorDodge = CIBlendKernel(source: "colorDodge")!

    /// Color burn blend kernel.
    nonisolated(unsafe) public static let colorBurn = CIBlendKernel(source: "colorBurn")!

    /// Hard light blend kernel.
    nonisolated(unsafe) public static let hardLight = CIBlendKernel(source: "hardLight")!

    /// Soft light blend kernel.
    nonisolated(unsafe) public static let softLight = CIBlendKernel(source: "softLight")!

    /// Difference blend kernel.
    nonisolated(unsafe) public static let difference = CIBlendKernel(source: "difference")!

    /// Exclusion blend kernel.
    nonisolated(unsafe) public static let exclusion = CIBlendKernel(source: "exclusion")!

    /// Hue blend kernel.
    nonisolated(unsafe) public static let hue = CIBlendKernel(source: "hue")!

    /// Saturation blend kernel.
    nonisolated(unsafe) public static let saturation = CIBlendKernel(source: "saturation")!

    /// Color blend kernel.
    nonisolated(unsafe) public static let color = CIBlendKernel(source: "color")!

    /// Luminosity blend kernel.
    nonisolated(unsafe) public static let luminosity = CIBlendKernel(source: "luminosity")!

    /// Clear blend kernel.
    nonisolated(unsafe) public static let clear = CIBlendKernel(source: "clear")!

    /// Copy blend kernel.
    nonisolated(unsafe) public static let copy = CIBlendKernel(source: "copy")!

    /// Component add blend kernel.
    nonisolated(unsafe) public static let componentAdd = CIBlendKernel(source: "componentAdd")!

    /// Component multiply blend kernel.
    nonisolated(unsafe) public static let componentMultiply = CIBlendKernel(source: "componentMultiply")!

    /// Component min blend kernel.
    nonisolated(unsafe) public static let componentMin = CIBlendKernel(source: "componentMin")!

    /// Component max blend kernel.
    nonisolated(unsafe) public static let componentMax = CIBlendKernel(source: "componentMax")!

    /// Linear burn blend kernel.
    nonisolated(unsafe) public static let linearBurn = CIBlendKernel(source: "linearBurn")!

    /// Linear dodge blend kernel.
    nonisolated(unsafe) public static let linearDodge = CIBlendKernel(source: "linearDodge")!

    /// Linear light blend kernel.
    nonisolated(unsafe) public static let linearLight = CIBlendKernel(source: "linearLight")!

    /// Pin light blend kernel.
    nonisolated(unsafe) public static let pinLight = CIBlendKernel(source: "pinLight")!

    /// Vivid light blend kernel.
    nonisolated(unsafe) public static let vividLight = CIBlendKernel(source: "vividLight")!

    /// Hard mix blend kernel.
    nonisolated(unsafe) public static let hardMix = CIBlendKernel(source: "hardMix")!

    /// Darker color blend kernel.
    nonisolated(unsafe) public static let darkerColor = CIBlendKernel(source: "darkerColor")!

    /// Lighter color blend kernel.
    nonisolated(unsafe) public static let lighterColor = CIBlendKernel(source: "lighterColor")!

    /// Subtract blend kernel.
    nonisolated(unsafe) public static let subtract = CIBlendKernel(source: "subtract")!

    /// Divide blend kernel.
    nonisolated(unsafe) public static let divide = CIBlendKernel(source: "divide")!
}

// MARK: - CISampler

/// An object that retrieves pixel samples for processing by a filter kernel.
public class CISampler {

    // MARK: - Private Storage

    private let _image: CIImage

    // MARK: - Initialization

    /// Creates a sampler object for the specified image.
    public init(image: CIImage) {
        self._image = image
    }

    /// Creates a sampler object for the specified image with options.
    public init(image: CIImage, options: [CISamplerOption: Any]?) {
        self._image = image
    }

    // MARK: - Properties

    /// The image associated with this sampler.
    public var image: CIImage {
        _image
    }

    /// The extent of the sampler.
    public var extent: CGRect {
        _image.extent
    }
}

// MARK: - CISamplerOption

/// Options for creating a CISampler.
public struct CISamplerOption: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A key for the affine transform to apply to the sampler.
    public static let affineMatrix = CISamplerOption(rawValue: "kCISamplerAffineMatrix")

    /// A key for the wrap mode of the sampler.
    public static let wrapMode = CISamplerOption(rawValue: "kCISamplerWrapMode")

    /// A key for the filter mode of the sampler.
    public static let filterMode = CISamplerOption(rawValue: "kCISamplerFilterMode")

    /// A key for the color space of the sampler.
    public static let colorSpace = CISamplerOption(rawValue: "kCISamplerColorSpace")
}

// MARK: - CIFilterShape

/// A description of the bounding shape of a filter and the domain of definition for a filter operation.
public final class CIFilterShape: @unchecked Sendable {

    // MARK: - Private Storage

    private let _extent: CGRect

    // MARK: - Initialization

    /// Creates a filter shape with the specified extent.
    public init(rect: CGRect) {
        self._extent = rect
    }

    // MARK: - Properties

    /// The extent of the filter shape.
    public var extent: CGRect {
        _extent
    }

    // MARK: - Creating Shapes

    /// Creates a union of the current shape with the specified shape.
    public func union(with other: CIFilterShape) -> CIFilterShape {
        CIFilterShape(rect: _extent.union(other._extent))
    }

    /// Creates a union of the current shape with the specified rectangle.
    public func union(with rect: CGRect) -> CIFilterShape {
        CIFilterShape(rect: _extent.union(rect))
    }

    /// Creates an intersection of the current shape with the specified shape.
    public func intersect(with other: CIFilterShape) -> CIFilterShape {
        CIFilterShape(rect: _extent.intersection(other._extent))
    }

    /// Creates an intersection of the current shape with the specified rectangle.
    public func intersect(with rect: CGRect) -> CIFilterShape {
        CIFilterShape(rect: _extent.intersection(rect))
    }

    /// Creates a shape by insetting the current shape.
    public func inset(byX dx: Int, y dy: Int) -> CIFilterShape {
        CIFilterShape(rect: _extent.insetBy(dx: CGFloat(dx), dy: CGFloat(dy)))
    }

    /// Creates a shape by applying a transformation to the current shape.
    public func transformed(by matrix: CGAffineTransform) -> CIFilterShape {
        CIFilterShape(rect: _extent.applying(matrix))
    }
}

// MARK: - Equatable

extension CIFilterShape: Equatable {
    public static func == (lhs: CIFilterShape, rhs: CIFilterShape) -> Bool {
        lhs._extent == rhs._extent
    }
}

// MARK: - Hashable

extension CIFilterShape: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_extent.origin.x)
        hasher.combine(_extent.origin.y)
        hasher.combine(_extent.size.width)
        hasher.combine(_extent.size.height)
    }
}
