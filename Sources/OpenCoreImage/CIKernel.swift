//
//  CIKernel.swift
//  OpenCoreImage
//
//  A GPU-based image-processing routine used to create custom Core Image filters.
//


// MARK: - CIKernelError

/// Errors that can occur when working with CIKernel.
public enum CIKernelError: Error, Sendable {
    /// The kernel function name was not found in the Metal library.
    case functionNotFound(String)

    /// The Metal library data is invalid or corrupted.
    case invalidMetalLibrary

    /// The kernel source code is invalid.
    case invalidKernelSource

    /// A compilation error occurred.
    case compilationFailed(String)
}

/// A GPU-based image-processing routine used to create custom Core Image filters.
///
/// Use `CIKernel` and its subclasses to create custom image-processing effects
/// by writing your own kernel code.
public class CIKernel {

    // MARK: - Private Storage

    private let _name: String?
    fileprivate let _source: String?
    private let _outputFormat: CIFormat?

    // MARK: - Initialization

    /// Creates a kernel object from the specified kernel source code.
    // FIXME(INCOMPLETE_IMPLEMENTATION): Portable Metal-library kernel loading is not implemented and this failable initializer always rejects callers.
    // Applications can reach this initializer directly; rejection must remain explicit rather than publishing a kernel that cannot execute.
    // Remove this marker only after library validation, function lookup, execution, and malformed-library tests exist.
    public init?(functionName name: String, fromMetalLibraryData data: Data) {
        return nil
    }

    /// Creates a kernel object from the specified kernel source code with an output pixel format.
    ///
    /// - Parameters:
    ///   - name: The name of the kernel function in the Metal library.
    ///   - data: The compiled Metal library data.
    ///   - format: The pixel format for the output image.
    /// - Throws: `CIKernelError` if the kernel cannot be created.
    // FIXME(INCOMPLETE_IMPLEMENTATION): Portable Metal-library kernel loading with an output format is not implemented.
    // Applications reach this throwing initializer directly and currently receive a compilation failure instead of an executable kernel.
    // Remove this marker only after format validation, function lookup, execution, and failure-path tests exist.
    public init(functionName name: String, fromMetalLibraryData data: Data, outputPixelFormat format: CIFormat) throws {
        throw CIKernelError.compilationFailed("Metal library kernels are unavailable on WebAssembly")
    }

    /// Creates a kernel object from the specified kernel source code.
    // FIXME(INCOMPLETE_IMPLEMENTATION): Core Image Kernel Language parsing and compilation are not implemented.
    // Applications can reach this failable initializer directly; it must not return a non-executable placeholder.
    // Remove this marker only after parsing, compilation, renderer integration, and invalid-source tests exist.
    public init?(source: String) {
        return nil
    }

    fileprivate init(builtInName: String) {
        self._name = nil
        self._source = builtInName
        self._outputFormat = nil
    }

    // MARK: - Properties

    /// The name of the kernel.
    public var name: String {
        _name ?? _source ?? "CIKernel"
    }

    /// The output pixel format of the kernel.
    public var outputFormat: CIFormat? {
        _outputFormat
    }

    // MARK: - Class Methods

    /// Returns the names of all kernel functions in the Metal library data.
    ///
    /// - Parameter data: The compiled Metal library data.
    /// - Returns: An array of kernel function names found in the library.
    ///
    /// - Note: In WASM environments, Metal libraries cannot be parsed directly.
    ///         This method returns an empty array as Metal is not available.
    // FIXME(INCOMPLETE_IMPLEMENTATION): Metal library symbol enumeration is not implemented and currently returns no names.
    // Applications reach this class method directly, so the empty result must not be treated as proof that a valid library contains no kernels.
    // Remove this marker only after validated library parsing distinguishes valid-empty, valid-nonempty, and malformed inputs.
    public class func kernelNames(fromMetalLibraryData data: Data) -> [String] {
        // Metal libraries are not available in WASM environment.
        // Return empty array as we cannot parse Metal library format.
        return []
    }

    /// Creates an array of kernel objects from Metal Shading Language source code.
    ///
    /// - Parameter source: The Metal Shading Language source code.
    /// - Returns: An array of `CIKernel` objects for each kernel found in the source.
    /// - Throws: `CIKernelError` if the source cannot be compiled.
    ///
    /// - Note: In WASM environments, Metal source cannot be compiled directly,
    ///         so this method throws `CIKernelError.compilationFailed`.
    // FIXME(INCOMPLETE_IMPLEMENTATION): Metal source compilation is unavailable in the portable renderer.
    // Applications reach this method directly and receive an explicit failure rather than an empty successful compilation.
    // Remove this marker only after source compilation, multi-kernel discovery, execution, and diagnostic tests exist.
    public class func kernels(withMetalString source: String) throws -> [CIKernel] {
        guard !source.isEmpty else {
            throw CIKernelError.invalidKernelSource
        }
        throw CIKernelError.compilationFailed("Metal compilation is not available in WASM environment. Use WGSL shaders instead.")
    }

    // MARK: - Applying the Kernel

    /// Creates a new image by applying the kernel's image-processing routine.
    ///
    /// Custom Core Image Kernel Language and Metal kernels cannot be compiled
    /// by the WebAssembly backend, so unsupported kernels return `nil`.
    // FIXME(INCOMPLETE_IMPLEMENTATION): General CIKernel execution is not connected to the filter graph compiler.
    // Custom filters reach this method directly and must receive nil until ROI, arguments, and shader execution are implemented.
    // Remove this marker only after ROI invocation, argument binding, output rendering, and failure tests exist.
    public func apply(
        extent: CGRect,
        roiCallback: @escaping (Int, CGRect) -> CGRect,
        arguments: [Any]?
    ) -> CIImage? {
        nil
    }
}

// MARK: - CIColorKernel

/// A GPU-based image-processing routine that processes only the color information in images,
/// used to create custom Core Image filters.
public class CIColorKernel: CIKernel {

    /// Applies the kernel to the specified image.
    ///
    // FIXME(INCOMPLETE_IMPLEMENTATION): General CIColorKernel execution is not connected to the filter graph compiler.
    // Custom color filters reach this method directly and must receive nil until argument binding and shader execution are implemented.
    // Remove this marker only after color-kernel output and invalid-argument behavior are tested.
    public func apply(extent: CGRect, arguments: [Any]?) -> CIImage? {
        nil
    }
}

// MARK: - CIWarpKernel

/// A GPU-based image-processing routine that processes only the geometry information in an image,
/// used to create custom Core Image filters.
public class CIWarpKernel: CIKernel {

    /// Applies the kernel to the specified image.
    ///
    // FIXME(INCOMPLETE_IMPLEMENTATION): General CIWarpKernel execution is not connected to the filter graph compiler.
    // Custom warp filters reach this method directly and must receive nil until ROI and coordinate mapping execute.
    // Remove this marker only after warp output, ROI callback, and invalid-argument behavior are tested.
    public func apply(
        extent: CGRect,
        roiCallback: @escaping (Int, CGRect) -> CGRect,
        image: CIImage,
        arguments: [Any]?
    ) -> CIImage? {
        nil
    }
}

// MARK: - CIBlendKernel

/// A GPU-based image-processing routine that is optimized for blending two images.
public class CIBlendKernel: CIColorKernel {

    /// Applies the kernel to blend the foreground and background images.
    ///
    public func apply(foreground: CIImage, background: CIImage) -> CIImage? {
        // FIXME(INCOMPLETE_IMPLEMENTATION): Several public built-in blend kernels do not yet map to an executable portable filter.
        // Every built-in CIBlendKernel reaches this lookup; unmapped kernels must return nil rather than fabricate a blended image.
        // Remove this marker only after every public kernel has a semantically tested filter mapping or a documented platform exclusion.
        guard let filterName = Self.filterNameByKernelIdentifier[_source ?? ""] else {
            return nil
        }
        return foreground.applyingFilter(
            filterName,
            parameters: [kCIInputBackgroundImageKey: background]
        )
    }

    /// Applies the kernel to blend the foreground and background images with a color match.
    public func apply(foreground: CIImage, background: CIImage, colorSpace: CGColorSpace) -> CIImage? {
        apply(foreground: foreground, background: background)
    }

    // MARK: - Built-in Blend Kernels
    //
    private static let filterNameByKernelIdentifier: [String: String] = [
        "sourceOver": "CISourceOverCompositing",
        "sourceIn": "CISourceInCompositing",
        "sourceOut": "CISourceOutCompositing",
        "sourceAtop": "CISourceAtopCompositing",
        "multiply": "CIMultiplyBlendMode",
        "screen": "CIScreenBlendMode",
        "overlay": "CIOverlayBlendMode",
        "darken": "CIDarkenBlendMode",
        "lighten": "CILightenBlendMode",
        "colorDodge": "CIColorDodgeBlendMode",
        "colorBurn": "CIColorBurnBlendMode",
        "hardLight": "CIHardLightBlendMode",
        "softLight": "CISoftLightBlendMode",
        "difference": "CIDifferenceBlendMode",
        "exclusion": "CIExclusionBlendMode",
        "hue": "CIHueBlendMode",
        "saturation": "CISaturationBlendMode",
        "color": "CIColorBlendMode",
        "luminosity": "CILuminosityBlendMode",
        "pinLight": "CIPinLightBlendMode",
        "linearBurn": "CILinearBurnBlendMode",
        "linearDodge": "CILinearDodgeBlendMode",
        "divide": "CIDivideBlendMode",
    ]

    /// Source over compositing blend kernel.
    public static var sourceOver: CIBlendKernel { CIBlendKernel(builtInName: "sourceOver") }

    /// Source in compositing blend kernel.
    public static var sourceIn: CIBlendKernel { CIBlendKernel(builtInName: "sourceIn") }

    /// Source out compositing blend kernel.
    public static var sourceOut: CIBlendKernel { CIBlendKernel(builtInName: "sourceOut") }

    /// Source atop compositing blend kernel.
    public static var sourceAtop: CIBlendKernel { CIBlendKernel(builtInName: "sourceAtop") }

    /// Destination over compositing blend kernel.
    public static var destinationOver: CIBlendKernel { CIBlendKernel(builtInName: "destinationOver") }

    /// Destination in compositing blend kernel.
    public static var destinationIn: CIBlendKernel { CIBlendKernel(builtInName: "destinationIn") }

    /// Destination out compositing blend kernel.
    public static var destinationOut: CIBlendKernel { CIBlendKernel(builtInName: "destinationOut") }

    /// Destination atop compositing blend kernel.
    public static var destinationAtop: CIBlendKernel { CIBlendKernel(builtInName: "destinationAtop") }

    /// Exclusive or compositing blend kernel.
    public static var exclusiveOr: CIBlendKernel { CIBlendKernel(builtInName: "exclusiveOr") }

    /// Multiply blend kernel.
    public static var multiply: CIBlendKernel { CIBlendKernel(builtInName: "multiply") }

    /// Screen blend kernel.
    public static var screen: CIBlendKernel { CIBlendKernel(builtInName: "screen") }

    /// Overlay blend kernel.
    public static var overlay: CIBlendKernel { CIBlendKernel(builtInName: "overlay") }

    /// Darken blend kernel.
    public static var darken: CIBlendKernel { CIBlendKernel(builtInName: "darken") }

    /// Lighten blend kernel.
    public static var lighten: CIBlendKernel { CIBlendKernel(builtInName: "lighten") }

    /// Color dodge blend kernel.
    public static var colorDodge: CIBlendKernel { CIBlendKernel(builtInName: "colorDodge") }

    /// Color burn blend kernel.
    public static var colorBurn: CIBlendKernel { CIBlendKernel(builtInName: "colorBurn") }

    /// Hard light blend kernel.
    public static var hardLight: CIBlendKernel { CIBlendKernel(builtInName: "hardLight") }

    /// Soft light blend kernel.
    public static var softLight: CIBlendKernel { CIBlendKernel(builtInName: "softLight") }

    /// Difference blend kernel.
    public static var difference: CIBlendKernel { CIBlendKernel(builtInName: "difference") }

    /// Exclusion blend kernel.
    public static var exclusion: CIBlendKernel { CIBlendKernel(builtInName: "exclusion") }

    /// Hue blend kernel.
    public static var hue: CIBlendKernel { CIBlendKernel(builtInName: "hue") }

    /// Saturation blend kernel.
    public static var saturation: CIBlendKernel { CIBlendKernel(builtInName: "saturation") }

    /// Color blend kernel.
    public static var color: CIBlendKernel { CIBlendKernel(builtInName: "color") }

    /// Luminosity blend kernel.
    public static var luminosity: CIBlendKernel { CIBlendKernel(builtInName: "luminosity") }

    /// Clear blend kernel.
    public static var clear: CIBlendKernel { CIBlendKernel(builtInName: "clear") }

    /// Copy blend kernel.
    public static var copy: CIBlendKernel { CIBlendKernel(builtInName: "copy") }

    /// Component add blend kernel.
    public static var componentAdd: CIBlendKernel { CIBlendKernel(builtInName: "componentAdd") }

    /// Component multiply blend kernel.
    public static var componentMultiply: CIBlendKernel { CIBlendKernel(builtInName: "componentMultiply") }

    /// Component min blend kernel.
    public static var componentMin: CIBlendKernel { CIBlendKernel(builtInName: "componentMin") }

    /// Component max blend kernel.
    public static var componentMax: CIBlendKernel { CIBlendKernel(builtInName: "componentMax") }

    /// Linear burn blend kernel.
    public static var linearBurn: CIBlendKernel { CIBlendKernel(builtInName: "linearBurn") }

    /// Linear dodge blend kernel.
    public static var linearDodge: CIBlendKernel { CIBlendKernel(builtInName: "linearDodge") }

    /// Linear light blend kernel.
    public static var linearLight: CIBlendKernel { CIBlendKernel(builtInName: "linearLight") }

    /// Pin light blend kernel.
    public static var pinLight: CIBlendKernel { CIBlendKernel(builtInName: "pinLight") }

    /// Vivid light blend kernel.
    public static var vividLight: CIBlendKernel { CIBlendKernel(builtInName: "vividLight") }

    /// Hard mix blend kernel.
    public static var hardMix: CIBlendKernel { CIBlendKernel(builtInName: "hardMix") }

    /// Darker color blend kernel.
    public static var darkerColor: CIBlendKernel { CIBlendKernel(builtInName: "darkerColor") }

    /// Lighter color blend kernel.
    public static var lighterColor: CIBlendKernel { CIBlendKernel(builtInName: "lighterColor") }

    /// Subtract blend kernel.
    public static var subtract: CIBlendKernel { CIBlendKernel(builtInName: "subtract") }

    /// Divide blend kernel.
    public static var divide: CIBlendKernel { CIBlendKernel(builtInName: "divide") }
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
public final class CIFilterShape: Sendable {

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
