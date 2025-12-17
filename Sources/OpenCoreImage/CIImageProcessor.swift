//
//  CIImageProcessor.swift
//  OpenCoreImage
//
//  Custom image processor kernel and related protocols.
//

import Foundation

// MARK: - CIImageProcessorInput

/// A container of image data and information for use in a custom image processor.
///
/// Your app does not define classes that adopt this protocol; Core Image provides an object
/// of this type when applying a custom image processor you create with a `CIImageProcessorKernel` subclass.
public protocol CIImageProcessorInput {

    /// The base address of CPU memory that your Core Image Processor Kernel can read pixels from.
    var baseAddress: UnsafeRawPointer { get }

    /// The rectangular region of the input image that your Core Image Processor Kernel can use to provide the output.
    var region: CGRect { get }

    /// The bytes per row of the CPU memory that your Core Image Processor Kernel can read pixels from.
    var bytesPerRow: Int { get }

    /// The pixel format of the CPU memory that your Core Image Processor Kernel can read pixels from.
    var format: CIFormat { get }

    /// A 64-bit digest that uniquely describes the contents of the input to a processor.
    var digest: UInt64 { get }

    /// This property tells a tiled-input processor how many input tiles will be processed.
    var roiTileCount: Int { get }

    /// This property tells a tiled-input processor which input tile index is being processed.
    var roiTileIndex: Int { get }
}

// MARK: - CIImageProcessorOutput

/// A container for writing image data and information produced by a custom image processor.
///
/// Your app does not define classes that adopt this protocol; Core Image provides an object
/// of this type when applying a custom image processor you create with a `CIImageProcessorKernel` subclass.
public protocol CIImageProcessorOutput {

    /// The base address of CPU memory that your Core Image Processor Kernel can write pixels to.
    var baseAddress: UnsafeMutableRawPointer { get }

    /// The rectangular region of the output image that your Core Image Processor Kernel must provide.
    var region: CGRect { get }

    /// The bytes per row of the CPU memory that your Core Image Processor Kernel can write pixels to.
    var bytesPerRow: Int { get }

    /// The pixel format of the CPU memory that your Core Image Processor Kernel can write pixels to.
    var format: CIFormat { get }

    /// A 64-bit digest that uniquely describes the contents of the output of a processor.
    var digest: UInt64 { get }
}

// MARK: - CIImageProcessorKernel

/// The abstract class you extend to create custom image processors that can integrate with Core Image workflows.
///
/// Unlike the `CIKernel` class and its other subclasses that allow you to create new image-processing
/// effects with the Core Image Kernel Language, the `CIImageProcessorKernel` class provides direct
/// access to the underlying bitmap image data for a step in the Core Image processing pipeline.
/// As such, you can create subclasses of this class to integrate other image-processing technologies—such
/// as Metal compute shaders, Metal Performance Shaders, Accelerate vImage operations, or your own
/// CPU-based image-processing routines—with a Core Image filter chain.
///
/// ## Subclassing Notes
///
/// The `CIImageProcessorKernel` class is abstract; to create a custom image processor, you define
/// a subclass of this class.
///
/// You do not directly create instances of a custom `CIImageProcessorKernel` subclass. Image processors
/// must not carry or use state specific to any single invocation of the processor, so all methods
/// (and accessors for readonly properties) of an image processor kernel class are class methods.
///
/// Your subclass should override at least the `process(with:arguments:output:)` method to perform
/// its image processing.
open class CIImageProcessorKernel: @unchecked Sendable {

    // MARK: - Initialization

    /// Do not create instances of this class directly.
    public init() {}

    // MARK: - Type Properties

    /// Override this class property if you want your processor's output to be in a specific pixel format.
    open class var outputFormat: CIFormat {
        .BGRA8
    }

    /// Override this class property if your processor's output stores 1.0 into the alpha channel
    /// of all pixels within the output extent.
    open class var outputIsOpaque: Bool {
        false
    }

    /// Override this class property to return false if you want your processor to be given
    /// input objects that have not been synchronized for CPU access.
    open class var synchronizeInputs: Bool {
        true
    }

    // MARK: - Type Methods

    /// Call this method on your Core Image Processor Kernel subclass to create a new image of the specified extent.
    open class func apply(
        withExtent extent: CGRect,
        inputs: [CIImage]?,
        arguments: [String: Any]?
    ) throws -> CIImage {
        // Placeholder implementation
        CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0)).cropped(to: extent)
    }

    /// Call this method on your multiple-output Core Image Processor Kernel subclass to create
    /// an array of new image objects given the specified array of extents.
    open class func apply(
        withExtents extents: [CIVector],
        inputs: [CIImage]?,
        arguments: [String: Any]?
    ) throws -> [CIImage] {
        // Placeholder implementation
        extents.map { vector in
            let extent = CGRect(x: CGFloat(vector.x),
                              y: CGFloat(vector.y),
                              width: CGFloat(vector.z),
                              height: CGFloat(vector.w))
            return CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0)).cropped(to: extent)
        }
    }

    /// Override this class method if you want any of the inputs to be in a specific pixel format.
    open class func formatForInput(at input: Int32) -> CIFormat {
        .BGRA8
    }

    /// Override this class method if your processor has more than one output and you want your
    /// processor's output to be in a specific supported CIPixelFormat.
    open class func outputFormat(at index: Int32, arguments: [String: Any]?) -> CIFormat {
        outputFormat
    }

    /// Override this class method to implement your Core Image Processor Kernel subclass.
    open class func process(
        with inputs: [CIImageProcessorInput]?,
        arguments: [String: Any]?,
        output: CIImageProcessorOutput
    ) throws {
        // Subclasses must override this method
        throw CIError.notImplemented
    }

    /// Override this class method of your Core Image Processor Kernel subclass if it needs
    /// to produce multiple outputs.
    open class func process(
        with inputs: [CIImageProcessorInput]?,
        arguments: [String: Any]?,
        outputs: [CIImageProcessorOutput]
    ) throws {
        // Subclasses can override this method for multiple outputs
        throw CIError.notImplemented
    }

    /// Override this class method to implement your processor's ROI callback.
    open class func roi(
        forInput input: Int32,
        arguments: [String: Any]?,
        outputRect: CGRect
    ) -> CGRect {
        outputRect
    }

    /// Override this class method to implement your processor's tiled ROI callback.
    open class func roiTileArray(
        forInput input: Int32,
        arguments: [String: Any]?,
        outputRect: CGRect
    ) -> [CIVector] {
        [CIVector(cgRect: outputRect)]
    }
}

// MARK: - Equatable

extension CIImageProcessorKernel: Equatable {
    public static func == (lhs: CIImageProcessorKernel, rhs: CIImageProcessorKernel) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIImageProcessorKernel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
