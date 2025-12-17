//
//  CIImage.swift
//  OpenCoreImage
//
//  A representation of an image to be processed or produced by Core Image filters.
//

import Foundation

/// A representation of an image to be processed or produced by Core Image filters.
///
/// You use `CIImage` objects in conjunction with other Core Image classes—such as
/// `CIFilter`, `CIContext`, `CIVector`, and `CIColor`—to take advantage of the
/// built-in Core Image filters when processing images.
///
/// Although a `CIImage` object has image data associated with it, it is not an image.
/// You can think of a `CIImage` object as an image "recipe." A `CIImage` object has
/// all the information necessary to produce an image, but Core Image doesn't actually
/// render an image until it is told to do so. This lazy evaluation allows Core Image
/// to operate as efficiently as possible.
public final class CIImage: @unchecked Sendable {

    // MARK: - Internal Storage

    internal let _extent: CGRect
    internal let _colorSpace: CGColorSpace?
    internal let _cgImage: CGImage?
    internal let _color: CIColor?
    internal let _url: URL?
    internal let _data: Data?
    internal let _properties: [String: Any]
    internal let _transform: CGAffineTransform
    internal let _filters: [(name: String, parameters: [String: Any])]
    internal let _samplingMode: SamplingMode
    internal let _intermediateMode: IntermediateMode
    internal let _contentHeadroom: Float
    internal let _contentAverageLightLevel: Float

    /// Sampling mode for image interpolation.
    internal enum SamplingMode: Sendable {
        case nearest
        case linear
    }

    /// Intermediate caching mode for render optimization.
    internal enum IntermediateMode: Sendable {
        case none
        case cached
        case tiled
    }

    // MARK: - Creating an Empty Image

    /// Creates and returns an empty image object.
    public class func empty() -> CIImage {
        CIImage(extent: .zero)
    }

    // MARK: - Initializers

    /// Internal initializer with all parameters.
    internal init(
        extent: CGRect,
        colorSpace: CGColorSpace? = nil,
        cgImage: CGImage? = nil,
        color: CIColor? = nil,
        url: URL? = nil,
        data: Data? = nil,
        properties: [String: Any] = [:],
        transform: CGAffineTransform = .identity,
        filters: [(name: String, parameters: [String: Any])] = [],
        samplingMode: SamplingMode = .linear,
        intermediateMode: IntermediateMode = .none,
        contentHeadroom: Float = 1.0,
        contentAverageLightLevel: Float = 1.0
    ) {
        self._extent = extent
        self._colorSpace = colorSpace
        self._cgImage = cgImage
        self._color = color
        self._url = url
        self._data = data
        self._properties = properties
        self._transform = transform
        self._filters = filters
        self._samplingMode = samplingMode
        self._intermediateMode = intermediateMode
        self._contentHeadroom = contentHeadroom
        self._contentAverageLightLevel = contentAverageLightLevel
    }

    /// Initializes an image object by reading an image from a URL.
    public convenience init?(contentsOf url: URL) {
        self.init(contentsOf: url, options: nil)
    }

    /// Initializes an image object by reading an image from a URL, using the specified options.
    public convenience init?(contentsOf url: URL, options: [CIImageOption: Any]?) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(
            extent: CGRect(x: 0, y: 0, width: 0, height: 0),
            url: url,
            data: data,
            properties: options?.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value } ?? [:]
        )
    }

    /// Initializes an image object with a Quartz 2D image.
    public convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, options: nil)
    }

    /// Initializes an image object with a Quartz 2D image, using the specified options.
    public convenience init(cgImage: CGImage, options: [CIImageOption: Any]?) {
        let extent = CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        self.init(
            extent: extent,
            colorSpace: cgImage.colorSpace,
            cgImage: cgImage,
            properties: options?.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value } ?? [:]
        )
    }

    /// Initializes an image object with the supplied image data.
    public convenience init?(data: Data) {
        self.init(data: data, options: nil)
    }

    /// Initializes an image object with the supplied image data, using the specified options.
    public convenience init?(data: Data, options: [CIImageOption: Any]?) {
        self.init(
            extent: CGRect(x: 0, y: 0, width: 0, height: 0),
            data: data,
            properties: options?.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value } ?? [:]
        )
    }

    /// Initializes an image object with bitmap data.
    public convenience init(
        bitmapData data: Data,
        bytesPerRow: Int,
        size: CGSize,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) {
        let extent = CGRect(origin: .zero, size: size)
        self.init(
            extent: extent,
            colorSpace: colorSpace,
            data: data
        )
    }

    /// Initializes an image of infinite extent whose entire content is the specified color.
    public convenience init(color: CIColor) {
        self.init(
            extent: CGRect.infinite,
            color: color
        )
    }

    // MARK: - Getting Image Information

    /// A rectangle that specifies the extent of the image.
    public var extent: CGRect {
        _extent
    }

    /// Returns the metadata properties dictionary of the image.
    public var properties: [String: Any] {
        _properties
    }

    /// The URL from which the image was loaded.
    public var url: URL? {
        _url
    }

    /// The color space of the image.
    public var colorSpace: CGColorSpace? {
        _colorSpace
    }

    /// The CoreGraphics image object this image was created from, if applicable.
    public var cgImage: CGImage? {
        _cgImage
    }

    /// Returns YES if the image is known to have an alpha value of 1.0 over the entire image extent.
    public var isOpaque: Bool {
        _color?.alpha == 1.0
    }

    /// Returns the content headroom of the image.
    public var contentHeadroom: Float {
        _contentHeadroom
    }

    /// Returns the content average light level of the image.
    public var contentAverageLightLevel: Float {
        _contentAverageLightLevel
    }

    // MARK: - Creating an Image by Modifying an Existing Image

    /// Returns a new image created by applying a filter to the original image with the specified name and parameters.
    public func applyingFilter(_ filterName: String, parameters: [String: Any]) -> CIImage {
        var newFilters = _filters
        newFilters.append((name: filterName, parameters: parameters))

        // Calculate new extent based on filter type
        let newExtent = CIImage.calculateExtent(
            for: filterName,
            parameters: parameters,
            inputExtent: _extent
        )

        return CIImage(
            extent: newExtent,
            colorSpace: _colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: _transform,
            filters: newFilters
        )
    }

    /// Calculates the output extent for a filter based on its type and parameters.
    private static func calculateExtent(
        for filterName: String,
        parameters: [String: Any],
        inputExtent: CGRect
    ) -> CGRect {
        // Handle blur filters - they expand the extent by the blur radius
        if filterName.contains("Blur") {
            let radius = (parameters[kCIInputRadiusKey] as? CGFloat) ?? 10.0
            return inputExtent.insetBy(dx: -radius * 3, dy: -radius * 3)
        }

        // Handle crop filter - output is the intersection
        if filterName == "CICrop" {
            if let rectVector = parameters["inputRectangle"] as? CIVector, rectVector.count >= 4 {
                let cropRect = CGRect(
                    x: rectVector.value(at: 0),
                    y: rectVector.value(at: 1),
                    width: rectVector.value(at: 2),
                    height: rectVector.value(at: 3)
                )
                return inputExtent.intersection(cropRect)
            }
        }

        // Handle compositing filters - union of foreground and background
        if filterName.contains("Compositing") || filterName.contains("Blend") {
            if let backgroundImage = parameters[kCIInputBackgroundImageKey] as? CIImage {
                return inputExtent.union(backgroundImage.extent)
            }
        }

        // Handle transform filters
        if filterName == "CIAffineTransform" {
            if let transform = parameters[kCIInputTransformKey] as? CGAffineTransform {
                return inputExtent.applying(transform)
            }
        }

        // Handle lanczos scale - same extent
        if filterName == "CILanczosScaleTransform" {
            let scale = (parameters[kCIInputScaleKey] as? CGFloat) ?? 1.0
            let aspectRatio = (parameters[kCIInputAspectRatioKey] as? CGFloat) ?? 1.0
            return CGRect(
                x: inputExtent.origin.x,
                y: inputExtent.origin.y,
                width: inputExtent.width * scale * aspectRatio,
                height: inputExtent.height * scale
            )
        }

        // Default: preserve input extent
        return inputExtent
    }

    /// Applies the filter to an image and returns the output.
    public func applyingFilter(_ filterName: String) -> CIImage {
        applyingFilter(filterName, parameters: [:])
    }

    /// Returns a new image that represents the original image after applying an affine transform.
    public func transformed(by matrix: CGAffineTransform) -> CIImage {
        let newTransform = _transform.concatenating(matrix)
        let newExtent = _extent.applying(matrix)
        return CIImage(
            extent: newExtent,
            colorSpace: _colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: newTransform,
            filters: _filters
        )
    }

    /// Returns a new image that represents the original image after applying an affine transform.
    public func transformed(by matrix: CGAffineTransform, highQualityDownsample: Bool) -> CIImage {
        transformed(by: matrix)
    }

    /// Returns a new image with a cropped portion of the original image.
    public func cropped(to rect: CGRect) -> CIImage {
        let newExtent = _extent.intersection(rect)
        return CIImage(
            extent: newExtent,
            colorSpace: _colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: _transform,
            filters: _filters
        )
    }

    /// Returns a new image created by transforming the original image to the specified EXIF orientation.
    public func oriented(forExifOrientation orientation: Int32) -> CIImage {
        let cgOrientation = CGImagePropertyOrientation(rawValue: UInt32(orientation)) ?? .up
        return oriented(cgOrientation)
    }

    /// Transforms the original image by a given orientation.
    public func oriented(_ orientation: CGImagePropertyOrientation) -> CIImage {
        let transform = orientationTransform(for: orientation)
        return transformed(by: transform)
    }

    /// Returns a new image created by making the pixel colors along its edges extend infinitely in all directions.
    public func clampedToExtent() -> CIImage {
        applyingFilter("CIAffineClamp", parameters: [kCIInputTransformKey: CGAffineTransform.identity])
    }

    /// Returns a new image created by cropping to a specified area, then making the pixel colors
    /// along the edges of the cropped image extend infinitely in all directions.
    public func clamped(to rect: CGRect) -> CIImage {
        cropped(to: rect).clampedToExtent()
    }

    /// Returns a new image created by compositing the original image over the specified destination image.
    public func composited(over dest: CIImage) -> CIImage {
        applyingFilter("CISourceOverCompositing", parameters: [kCIInputBackgroundImageKey: dest])
    }

    /// Returns a new image created by multiplying the image's RGB values by its alpha values.
    public func premultiplyingAlpha() -> CIImage {
        applyingFilter("CIPremultiply")
    }

    /// Returns a new image created by dividing the image's RGB values by its alpha values.
    public func unpremultiplyingAlpha() -> CIImage {
        applyingFilter("CIUnpremultiply")
    }

    /// Returns a new image created by setting all alpha values to 1.0 within the specified rectangle
    /// and to 0.0 outside of that area.
    public func settingAlphaOne(in rect: CGRect) -> CIImage {
        applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ]).cropped(to: rect)
    }

    /// Create an image by applying a gaussian blur to the receiver.
    public func applyingGaussianBlur(sigma: Double) -> CIImage {
        applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: sigma])
    }

    /// Return a new image by changing the receiver's metadata properties.
    public func settingProperties(_ properties: [AnyHashable: Any]) -> CIImage {
        var newProperties = _properties
        for (key, value) in properties {
            if let stringKey = key as? String {
                newProperties[stringKey] = value
            }
        }
        return CIImage(
            extent: _extent,
            colorSpace: _colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: newProperties,
            transform: _transform,
            filters: _filters
        )
    }

    /// Create an image that inserts an intermediate that is cacheable.
    public func insertingIntermediate() -> CIImage {
        insertingIntermediate(cache: true)
    }

    /// Create an image that inserts an intermediate that is cacheable.
    public func insertingIntermediate(cache: Bool) -> CIImage {
        CIImage(
            extent: _extent,
            colorSpace: _colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: _transform,
            filters: _filters,
            samplingMode: _samplingMode,
            intermediateMode: cache ? .cached : .none
        )
    }

    /// Create an image that inserts an intermediate that is cached in tiles.
    public func insertingTiledIntermediate() -> CIImage {
        CIImage(
            extent: _extent,
            colorSpace: _colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: _transform,
            filters: _filters,
            samplingMode: _samplingMode,
            intermediateMode: .tiled
        )
    }

    // MARK: - Color Space Conversion

    /// Returns a new image created by color matching from the specified color space to the context's working color space.
    public func matchedToWorkingSpace(from colorSpace: CGColorSpace) -> CIImage? {
        CIImage(
            extent: _extent,
            colorSpace: colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: _transform,
            filters: _filters
        )
    }

    /// Returns a new image created by color matching from the context's working color space to the specified color space.
    public func matchedFromWorkingSpace(to colorSpace: CGColorSpace) -> CIImage? {
        CIImage(
            extent: _extent,
            colorSpace: colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: _transform,
            filters: _filters
        )
    }

    /// Converts the image from the working color space to Lab color space.
    public func convertingWorkingSpaceToLab() -> CIImage {
        applyingFilter("CIConvertWorkingSpaceToLab")
    }

    /// Converts the image from Lab color space to the working color space.
    public func convertingLabToWorkingSpace() -> CIImage {
        applyingFilter("CIConvertLabToWorkingSpace")
    }

    // MARK: - Working with Orientation

    /// The affine transform for changing the image to the given orientation.
    public func orientationTransform(for orientation: CGImagePropertyOrientation) -> CGAffineTransform {
        orientationTransform(forExifOrientation: Int32(orientation.rawValue))
    }

    /// Returns the transformation needed to reorient the image to the specified orientation.
    public func orientationTransform(forExifOrientation orientation: Int32) -> CGAffineTransform {
        let width = _extent.width
        let height = _extent.height

        switch orientation {
        case 1: // Up
            return .identity
        case 2: // Up Mirrored
            return CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -width.native, y: 0)
        case 3: // Down
            return CGAffineTransform(translationX: width.native, y: height.native).rotated(by: .pi)
        case 4: // Down Mirrored
            return CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -height.native)
        case 5: // Left Mirrored
            return CGAffineTransform(scaleX: -1, y: 1).rotated(by: -.pi / 2)
        case 6: // Right
            return CGAffineTransform(translationX: height.native, y: 0).rotated(by: .pi / 2)
        case 7: // Right Mirrored
            return CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -height.native, y: 0).rotated(by: .pi / 2)
        case 8: // Left
            return CGAffineTransform(translationX: 0, y: width.native).rotated(by: -.pi / 2)
        default:
            return .identity
        }
    }

    // MARK: - Sampling the Image

    /// Create an image by changing the receiver's sample mode to nearest neighbor.
    public func samplingNearest() -> CIImage {
        CIImage(
            extent: _extent,
            colorSpace: _colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: _transform,
            filters: _filters,
            samplingMode: .nearest,
            intermediateMode: _intermediateMode
        )
    }

    /// Create an image by changing the receiver's sample mode to bilinear interpolation.
    public func samplingLinear() -> CIImage {
        CIImage(
            extent: _extent,
            colorSpace: _colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: _transform,
            filters: _filters,
            samplingMode: .linear,
            intermediateMode: _intermediateMode
        )
    }

    // MARK: - Working with Filter Regions of Interest

    /// Returns the region of interest for the filter chain that generates the image.
    public func regionOfInterest(for image: CIImage, in rect: CGRect) -> CGRect {
        rect.intersection(_extent)
    }

    // MARK: - HDR

    /// Create an image by changing the receiver's contentHeadroom property.
    public func settingContentHeadroom(_ headroom: Float) -> CIImage {
        CIImage(
            extent: _extent,
            colorSpace: _colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: _transform,
            filters: _filters,
            samplingMode: _samplingMode,
            intermediateMode: _intermediateMode,
            contentHeadroom: headroom,
            contentAverageLightLevel: _contentAverageLightLevel
        )
    }

    /// Create an image by changing the receiver's contentAverageLightLevel property.
    public func settingContentAverageLightLevel(_ level: Float) -> CIImage {
        CIImage(
            extent: _extent,
            colorSpace: _colorSpace,
            cgImage: _cgImage,
            color: _color,
            url: _url,
            data: _data,
            properties: _properties,
            transform: _transform,
            filters: _filters,
            samplingMode: _samplingMode,
            intermediateMode: _intermediateMode,
            contentHeadroom: _contentHeadroom,
            contentAverageLightLevel: level
        )
    }

    /// Create an image that applies a gain map Core Image image to the received Core Image image.
    public func applyingGainMap(_ gainMap: CIImage) -> CIImage {
        applyingFilter("CIGainMap", parameters: ["inputGainMap": gainMap])
    }

    /// Create an image that applies a gain map Core Image image with a specified headroom to the received Core Image image.
    public func applyingGainMap(_ gainMap: CIImage, headroom: Float) -> CIImage {
        applyingFilter("CIGainMap", parameters: ["inputGainMap": gainMap, "inputHeadroom": headroom])
    }

    // MARK: - Preset Color Images

    /// A solid black image.
    public static let black = CIImage(color: .black)

    /// A solid blue image.
    public static let blue = CIImage(color: .blue)

    /// A transparent (clear) image.
    public static let clear = CIImage(color: .clear)

    /// A solid cyan image.
    public static let cyan = CIImage(color: .cyan)

    /// A solid gray image.
    public static let gray = CIImage(color: .gray)

    /// A solid green image.
    public static let green = CIImage(color: .green)

    /// A solid magenta image.
    public static let magenta = CIImage(color: .magenta)

    /// A solid red image.
    public static let red = CIImage(color: .red)

    /// A solid white image.
    public static let white = CIImage(color: .white)

    /// A solid yellow image.
    public static let yellow = CIImage(color: .yellow)
}

// MARK: - Equatable

extension CIImage: Equatable {
    public static func == (lhs: CIImage, rhs: CIImage) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIImage: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CustomStringConvertible

extension CIImage: CustomStringConvertible {
    public var description: String {
        "CIImage(extent: \(extent))"
    }
}

// MARK: - CustomDebugStringConvertible

extension CIImage: CustomDebugStringConvertible {
    public var debugDescription: String {
        var desc = "CIImage:\n"
        desc += "  extent: \(extent)\n"
        if let url = url {
            desc += "  url: \(url)\n"
        }
        if let colorSpace = colorSpace {
            desc += "  colorSpace: \(colorSpace)\n"
        }
        if !_filters.isEmpty {
            desc += "  filters: \(_filters.map { $0.name })\n"
        }
        return desc
    }
}

// MARK: - CIImageOption

/// Options for initializing a CIImage.
public struct CIImageOption: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A key for the color space to use for an image.
    public static let colorSpace = CIImageOption(rawValue: "kCIImageColorSpace")

    /// A key for a boolean value that indicates whether to apply tone mapping to the image.
    public static let toneMapHDRtoSDR = CIImageOption(rawValue: "kCIImageToneMapHDRtoSDR")

    /// A key for a boolean value indicating whether the image should be created using the nearest sampling mode.
    public static let nearestSampling = CIImageOption(rawValue: "kCIImageNearestSampling")

    /// A key for a dictionary of metadata properties for the image.
    public static let properties = CIImageOption(rawValue: "kCIImageProperties")

    /// A key for a boolean value that determines whether a Core Graphics image should be created lazily.
    public static let applyOrientationProperty = CIImageOption(rawValue: "kCIImageApplyOrientationProperty")

    /// A key for auxiliary depth data.
    public static let auxiliaryDepth = CIImageOption(rawValue: "kCIImageAuxiliaryDepth")

    /// A key for auxiliary disparity data.
    public static let auxiliaryDisparity = CIImageOption(rawValue: "kCIImageAuxiliaryDisparity")

    /// A key for auxiliary portrait effects matte.
    public static let auxiliaryPortraitEffectsMatte = CIImageOption(rawValue: "kCIImageAuxiliaryPortraitEffectsMatte")

    /// A key for auxiliary semantic segmentation skin matte.
    public static let auxiliarySemanticSegmentationSkinMatte = CIImageOption(rawValue: "kCIImageAuxiliarySemanticSegmentationSkinMatte")

    /// A key for auxiliary semantic segmentation hair matte.
    public static let auxiliarySemanticSegmentationHairMatte = CIImageOption(rawValue: "kCIImageAuxiliarySemanticSegmentationHairMatte")

    /// A key for auxiliary semantic segmentation teeth matte.
    public static let auxiliarySemanticSegmentationTeethMatte = CIImageOption(rawValue: "kCIImageAuxiliarySemanticSegmentationTeethMatte")

    /// A key for auxiliary semantic segmentation glasses matte.
    public static let auxiliarySemanticSegmentationGlassesMatte = CIImageOption(rawValue: "kCIImageAuxiliarySemanticSegmentationGlassesMatte")

    /// A key for auxiliary semantic segmentation sky matte.
    public static let auxiliarySemanticSegmentationSkyMatte = CIImageOption(rawValue: "kCIImageAuxiliarySemanticSegmentationSkyMatte")

    /// A key for auxiliary HDR gain map.
    public static let auxiliaryHDRGainMap = CIImageOption(rawValue: "kCIImageAuxiliaryHDRGainMap")
}

// MARK: - CIImageAutoAdjustmentOption

/// Constants used as keys in the options dictionary for the auto adjustment filters method.
public struct CIImageAutoAdjustmentOption: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A key for a boolean value that specifies whether to apply enhancements.
    public static let enhance = CIImageAutoAdjustmentOption(rawValue: "kCIImageAutoAdjustEnhance")

    /// A key for a boolean value that specifies whether to apply red-eye correction.
    public static let redEye = CIImageAutoAdjustmentOption(rawValue: "kCIImageAutoAdjustRedEye")

    /// A key for an array of face feature objects.
    public static let features = CIImageAutoAdjustmentOption(rawValue: "kCIImageAutoAdjustFeatures")

    /// A key for a boolean value that specifies whether the image should be cropped.
    public static let crop = CIImageAutoAdjustmentOption(rawValue: "kCIImageAutoAdjustCrop")

    /// A key for a boolean value that specifies whether the image should be leveled.
    public static let level = CIImageAutoAdjustmentOption(rawValue: "kCIImageAutoAdjustLevel")
}
