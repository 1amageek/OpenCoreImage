//
//  CIImage.swift
//  OpenCoreImage
//
//  A representation of an image to be processed or produced by Core Image filters.
//

import Foundation
import OpenCoreGraphics


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
    internal let _pixelData: Data?  // Decoded RGBA pixel data for GPU upload
    internal let _bytesPerRow: Int?  // Bytes per row for pixel data (for proper stride handling)
    internal let _format: CIFormat?  // Pixel format for pixel data
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
        pixelData: Data? = nil,
        bytesPerRow: Int? = nil,
        format: CIFormat? = nil,
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
        self._pixelData = pixelData
        self._bytesPerRow = bytesPerRow
        self._format = format
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

        // Try to detect image dimensions from file headers
        var extent = CIImage.detectImageExtent(from: data)

        // Extract options
        let colorSpace = options?[.colorSpace] as? CGColorSpace
        let samplingMode: SamplingMode = (options?[.nearestSampling] as? Bool == true)
            ? .nearest
            : .linear
        let shouldApplyOrientation = options?[.applyOrientationProperty] as? Bool ?? false
        let (headroom, averageLightLevel) = CIImage.extractHDROptions(from: options)

        // Build properties dictionary (store all options for compatibility)
        var properties: [String: Any] = [:]
        options?.forEach { key, value in
            properties[key.rawValue] = value
        }

        // Detect and apply EXIF orientation if requested
        var filters: [(name: String, parameters: [String: Any])] = []
        if shouldApplyOrientation, let orientation = CIImage.detectJPEGOrientation(from: data) {
            // For orientations 5-8 (90° rotations), swap width and height
            if orientation.rawValue >= 5 && orientation.rawValue <= 8 {
                extent = CGRect(x: 0, y: 0, width: extent.height, height: extent.width)
            }
            // Add orientation transform as a filter
            if orientation != .up {
                filters.append((
                    name: "CIAffineTransform",
                    parameters: [kCIInputTransformKey: CIImage.orientationTransformForInit(
                        orientation: orientation,
                        width: extent.width,
                        height: extent.height
                    )]
                ))
            }
        }

        self.init(
            extent: extent,
            colorSpace: colorSpace,
            url: url,
            data: data,
            properties: properties,
            filters: filters,
            samplingMode: samplingMode,
            contentHeadroom: headroom,
            contentAverageLightLevel: averageLightLevel
        )
    }

    /// Initializes an image object with a Quartz 2D image.
    public convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, options: nil)
    }

    /// Initializes an image object with a Quartz 2D image, using the specified options.
    public convenience init(cgImage: CGImage, options: [CIImageOption: Any]?) {
        let extent = CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))

        // Extract options
        // If colorSpace option is provided, use it; otherwise use the CGImage's color space
        let colorSpace = (options?[.colorSpace] as? CGColorSpace) ?? cgImage.colorSpace
        let samplingMode: SamplingMode = (options?[.nearestSampling] as? Bool == true)
            ? .nearest
            : .linear
        let (headroom, averageLightLevel) = CIImage.extractHDROptions(from: options)

        // Build properties dictionary (store all options for compatibility)
        var properties: [String: Any] = [:]
        options?.forEach { key, value in
            properties[key.rawValue] = value
        }

        // Note: applyOrientationProperty is not applicable for CGImage sources
        // since CGImage doesn't carry EXIF metadata in a parseable format.
        // Use oriented(forExifOrientation:) method if orientation correction is needed.

        self.init(
            extent: extent,
            colorSpace: colorSpace,
            cgImage: cgImage,
            properties: properties,
            samplingMode: samplingMode,
            contentHeadroom: headroom,
            contentAverageLightLevel: averageLightLevel
        )
    }

    /// Initializes an image object with the supplied image data.
    public convenience init?(data: Data) {
        self.init(data: data, options: nil)
    }

    /// Initializes an image object with the supplied image data, using the specified options.
    public convenience init?(data: Data, options: [CIImageOption: Any]?) {
        // Try to detect image dimensions from file headers
        var extent = CIImage.detectImageExtent(from: data)

        // Extract options
        let colorSpace = options?[.colorSpace] as? CGColorSpace
        let samplingMode: SamplingMode = (options?[.nearestSampling] as? Bool == true)
            ? .nearest
            : .linear
        let shouldApplyOrientation = options?[.applyOrientationProperty] as? Bool ?? false
        let (headroom, averageLightLevel) = CIImage.extractHDROptions(from: options)

        // Build properties dictionary (store all options for compatibility)
        var properties: [String: Any] = [:]
        options?.forEach { key, value in
            properties[key.rawValue] = value
        }

        // Detect and apply EXIF orientation if requested
        var filters: [(name: String, parameters: [String: Any])] = []
        if shouldApplyOrientation, let orientation = CIImage.detectJPEGOrientation(from: data) {
            // For orientations 5-8 (90° rotations), swap width and height
            if orientation.rawValue >= 5 && orientation.rawValue <= 8 {
                extent = CGRect(x: 0, y: 0, width: extent.height, height: extent.width)
            }
            // Add orientation transform as a filter
            if orientation != .up {
                filters.append((
                    name: "CIAffineTransform",
                    parameters: [kCIInputTransformKey: CIImage.orientationTransformForInit(
                        orientation: orientation,
                        width: extent.width,
                        height: extent.height
                    )]
                ))
            }
        }

        self.init(
            extent: extent,
            colorSpace: colorSpace,
            data: data,
            properties: properties,
            filters: filters,
            samplingMode: samplingMode,
            contentHeadroom: headroom,
            contentAverageLightLevel: averageLightLevel
        )
    }

    /// Initializes an image object with bitmap data.
    ///
    /// The bitmap data should be raw, uncompressed pixel data in the specified format.
    /// This data is stored directly as pixel data (not encoded image data) and can be
    /// used directly by the GPU renderer without decoding.
    ///
    /// - Parameters:
    ///   - data: The raw pixel data.
    ///   - bytesPerRow: The number of bytes per row in the data. This may include padding.
    ///   - size: The size of the image in pixels.
    ///   - format: The pixel format of the data (e.g., `.RGBA8`, `.RGBAf`).
    ///   - colorSpace: The color space of the image data.
    public convenience init(
        bitmapData data: Data,
        bytesPerRow: Int,
        size: CGSize,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) {
        let extent = CGRect(origin: .zero, size: size)

        // Normalize the pixel data if bytesPerRow doesn't match expected stride
        let width = Int(size.width)
        let height = Int(size.height)
        let expectedBytesPerRow = width * format.bytesPerPixel

        let normalizedData: Data
        if bytesPerRow == expectedBytesPerRow {
            // Data is already packed, use as-is
            normalizedData = data
        } else {
            // Data has padding, need to strip it for proper GPU upload
            var packed = Data(capacity: expectedBytesPerRow * height)
            data.withUnsafeBytes { srcPtr in
                guard let srcBase = srcPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
                for row in 0..<height {
                    let srcOffset = row * bytesPerRow
                    let rowData = Data(bytes: srcBase.advanced(by: srcOffset), count: expectedBytesPerRow)
                    packed.append(rowData)
                }
            }
            normalizedData = packed
        }

        self.init(
            extent: extent,
            colorSpace: colorSpace,
            pixelData: normalizedData,
            bytesPerRow: expectedBytesPerRow,  // Store the normalized bytes per row
            format: format  // Store the format for later use
        )
    }

    /// Initializes an image of infinite extent whose entire content is the specified color.
    public convenience init(color: CIColor) {
        self.init(
            extent: CGRect.infinite,
            color: color
        )
    }

    /// Initializes an image object from a CVPixelBuffer.
    ///
    /// - Parameter pixelBuffer: The CVPixelBuffer containing the image data.
    ///
    /// - Note: In WASM environments, this creates a CIImage with the pixel buffer's
    ///         dimensions but without actual pixel data, as CVPixelBuffer is a stub type.
    public convenience init(cvPixelBuffer pixelBuffer: CVPixelBuffer) {
        self.init(cvPixelBuffer: pixelBuffer, options: nil)
    }

    /// Initializes an image object from a CVPixelBuffer with options.
    ///
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data.
    ///   - options: A dictionary of options for creating the image.
    ///
    /// - Note: In WASM environments, this creates a CIImage with the pixel buffer's
    ///         dimensions but without actual pixel data, as CVPixelBuffer is a stub type.
    public convenience init(cvPixelBuffer pixelBuffer: CVPixelBuffer, options: [CIImageOption: Any]?) {
        let extent = CGRect(x: 0, y: 0, width: CGFloat(pixelBuffer.width), height: CGFloat(pixelBuffer.height))

        // Extract options
        let colorSpace = options?[.colorSpace] as? CGColorSpace
        let samplingMode: SamplingMode = (options?[.nearestSampling] as? Bool == true)
            ? .nearest
            : .linear
        let (headroom, averageLightLevel) = CIImage.extractHDROptions(from: options)

        // Build properties dictionary
        var properties: [String: Any] = [:]
        options?.forEach { key, value in
            properties[key.rawValue] = value
        }

        self.init(
            extent: extent,
            colorSpace: colorSpace,
            properties: properties,
            samplingMode: samplingMode,
            contentHeadroom: headroom,
            contentAverageLightLevel: averageLightLevel
        )
    }

    /// Initializes an image from depth data.
    ///
    /// - Parameter data: The AVDepthData containing the depth information.
    ///
    /// - Note: In WASM environments, this returns the depth data map if available,
    ///         otherwise creates an empty image.
    public convenience init(depthData data: AVDepthData) {
        self.init(depthData: data, options: nil)
    }

    /// Initializes an image from depth data with options.
    ///
    /// - Parameters:
    ///   - data: The AVDepthData containing the depth information.
    ///   - options: A dictionary of options for creating the image.
    ///
    /// - Note: In WASM environments, this returns the depth data map if available,
    ///         otherwise creates an empty image.
    public convenience init(depthData data: AVDepthData, options: [CIImageOption: Any]?) {
        if let depthMap = data.depthDataMap {
            let colorSpace = (options?[.colorSpace] as? CGColorSpace) ?? depthMap.colorSpace
            let (headroom, averageLightLevel) = CIImage.extractHDROptions(from: options)

            self.init(
                extent: depthMap.extent,
                colorSpace: colorSpace,
                contentHeadroom: headroom,
                contentAverageLightLevel: averageLightLevel
            )
        } else {
            self.init(extent: .zero)
        }
    }

    /// Initializes an image from a portrait effects matte.
    ///
    /// - Parameter matte: The AVPortraitEffectsMatte containing the matte information.
    ///
    /// - Note: In WASM environments, this returns the matte image if available,
    ///         otherwise creates an empty image.
    public convenience init(portraitEffectsMatte matte: AVPortraitEffectsMatte) {
        self.init(portraitEffectsMatte: matte, options: nil)
    }

    /// Initializes an image from a portrait effects matte with options.
    ///
    /// - Parameters:
    ///   - matte: The AVPortraitEffectsMatte containing the matte information.
    ///   - options: A dictionary of options for creating the image.
    ///
    /// - Note: In WASM environments, this returns the matte image if available,
    ///         otherwise creates an empty image.
    public convenience init(portraitEffectsMatte matte: AVPortraitEffectsMatte, options: [CIImageOption: Any]?) {
        if let matteImage = matte.mattingImage {
            let colorSpace = (options?[.colorSpace] as? CGColorSpace) ?? matteImage.colorSpace
            let (headroom, averageLightLevel) = CIImage.extractHDROptions(from: options)

            self.init(
                extent: matteImage.extent,
                colorSpace: colorSpace,
                contentHeadroom: headroom,
                contentAverageLightLevel: averageLightLevel
            )
        } else {
            self.init(extent: .zero)
        }
    }

    /// Initializes an image from a semantic segmentation matte.
    ///
    /// - Parameter matte: The AVSemanticSegmentationMatte containing the matte information.
    ///
    /// - Note: In WASM environments, this returns the matte image if available,
    ///         otherwise creates an empty image.
    public convenience init(semanticSegmentationMatte matte: AVSemanticSegmentationMatte) {
        self.init(semanticSegmentationMatte: matte, options: nil)
    }

    /// Initializes an image from a semantic segmentation matte with options.
    ///
    /// - Parameters:
    ///   - matte: The AVSemanticSegmentationMatte containing the matte information.
    ///   - options: A dictionary of options for creating the image.
    ///
    /// - Note: In WASM environments, this returns the matte image if available,
    ///         otherwise creates an empty image.
    public convenience init(semanticSegmentationMatte matte: AVSemanticSegmentationMatte, options: [CIImageOption: Any]?) {
        if let matteImage = matte.mattingImage {
            let colorSpace = (options?[.colorSpace] as? CGColorSpace) ?? matteImage.colorSpace
            let (headroom, averageLightLevel) = CIImage.extractHDROptions(from: options)

            self.init(
                extent: matteImage.extent,
                colorSpace: colorSpace,
                contentHeadroom: headroom,
                contentAverageLightLevel: averageLightLevel
            )
        } else {
            self.init(extent: .zero)
        }
    }

    // MARK: - Async Factory Methods (WASM)

    #if arch(wasm32)
    /// Asynchronously creates a CIImage from encoded image data.
    /// This method fully decodes the image data using browser APIs.
    ///
    /// - Parameter data: The encoded image data (JPEG, PNG, WebP, etc.).
    /// - Returns: A CIImage with decoded pixel data ready for GPU processing.
    /// - Throws: An error if decoding fails.
    public static func decoded(from data: Data) async throws -> CIImage {
        let decoded = try await ImageDecoder.decode(data)
        let extent = CGRect(x: 0, y: 0, width: CGFloat(decoded.width), height: CGFloat(decoded.height))

        return CIImage(
            extent: extent,
            data: data,
            pixelData: decoded.pixelData
        )
    }

    /// Asynchronously creates a CIImage from a URL.
    /// This method fully decodes the image using browser APIs.
    ///
    /// - Parameter url: The URL of the image file.
    /// - Returns: A CIImage with decoded pixel data ready for GPU processing.
    /// - Throws: An error if loading or decoding fails.
    public static func decoded(contentsOf url: URL) async throws -> CIImage {
        let data = try Data(contentsOf: url)
        let decoded = try await ImageDecoder.decode(data)
        let extent = CGRect(x: 0, y: 0, width: CGFloat(decoded.width), height: CGFloat(decoded.height))

        return CIImage(
            extent: extent,
            url: url,
            data: data,
            pixelData: decoded.pixelData
        )
    }
    #endif

    // MARK: - Image Dimension Detection

    /// Detects image dimensions from file header bytes.
    /// Supports PNG, JPEG, GIF, WebP, and BMP formats.
    internal static func detectImageExtent(from data: Data) -> CGRect {
        if let dims = detectPNGDimensions(from: data) {
            return CGRect(x: 0, y: 0, width: CGFloat(dims.width), height: CGFloat(dims.height))
        }
        if let dims = detectJPEGDimensions(from: data) {
            return CGRect(x: 0, y: 0, width: CGFloat(dims.width), height: CGFloat(dims.height))
        }
        if let dims = detectGIFDimensions(from: data) {
            return CGRect(x: 0, y: 0, width: CGFloat(dims.width), height: CGFloat(dims.height))
        }
        if let dims = detectWebPDimensions(from: data) {
            return CGRect(x: 0, y: 0, width: CGFloat(dims.width), height: CGFloat(dims.height))
        }
        if let dims = detectBMPDimensions(from: data) {
            return CGRect(x: 0, y: 0, width: CGFloat(dims.width), height: CGFloat(dims.height))
        }
        return .zero
    }

    /// Detects PNG image dimensions from header.
    private static func detectPNGDimensions(from data: Data) -> (width: Int, height: Int)? {
        // PNG signature: 89 50 4E 47 0D 0A 1A 0A
        guard data.count >= 24 else { return nil }

        let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        for (i, byte) in signature.enumerated() {
            guard data[i] == byte else { return nil }
        }

        // IHDR chunk: bytes 16-19 = width, bytes 20-23 = height (big-endian)
        let width = Int(data[16]) << 24 | Int(data[17]) << 16 | Int(data[18]) << 8 | Int(data[19])
        let height = Int(data[20]) << 24 | Int(data[21]) << 16 | Int(data[22]) << 8 | Int(data[23])

        guard width > 0 && height > 0 else { return nil }
        return (width, height)
    }

    /// Detects JPEG image dimensions from header.
    private static func detectJPEGDimensions(from data: Data) -> (width: Int, height: Int)? {
        guard data.count >= 2, data[0] == 0xFF, data[1] == 0xD8 else { return nil }

        var offset = 2
        while offset < data.count - 8 {
            guard data[offset] == 0xFF else {
                offset += 1
                continue
            }

            let marker = data[offset + 1]

            if marker == 0xFF {
                offset += 1
                continue
            }

            // SOF markers contain dimensions
            if marker >= 0xC0 && marker <= 0xC3 {
                guard offset + 9 < data.count else { return nil }
                let height = Int(data[offset + 5]) << 8 | Int(data[offset + 6])
                let width = Int(data[offset + 7]) << 8 | Int(data[offset + 8])
                guard width > 0 && height > 0 else { return nil }
                return (width, height)
            }

            // Skip to next marker
            if marker == 0xD8 || marker == 0xD9 || (marker >= 0xD0 && marker <= 0xD7) {
                offset += 2
            } else {
                guard offset + 3 < data.count else { return nil }
                let length = Int(data[offset + 2]) << 8 | Int(data[offset + 3])
                offset += 2 + length
            }
        }
        return nil
    }

    /// Detects GIF image dimensions from header.
    private static func detectGIFDimensions(from data: Data) -> (width: Int, height: Int)? {
        // GIF87a or GIF89a
        guard data.count >= 10 else { return nil }
        guard data[0] == 0x47, data[1] == 0x49, data[2] == 0x46,
              data[3] == 0x38, (data[4] == 0x37 || data[4] == 0x39), data[5] == 0x61 else {
            return nil
        }
        // Width and height are at bytes 6-7 and 8-9 (little-endian)
        let width = Int(data[6]) | Int(data[7]) << 8
        let height = Int(data[8]) | Int(data[9]) << 8
        guard width > 0 && height > 0 else { return nil }
        return (width, height)
    }

    /// Detects WebP image dimensions from header.
    private static func detectWebPDimensions(from data: Data) -> (width: Int, height: Int)? {
        // RIFF....WEBP
        guard data.count >= 30 else { return nil }
        guard data[0] == 0x52, data[1] == 0x49, data[2] == 0x46, data[3] == 0x46,
              data[8] == 0x57, data[9] == 0x45, data[10] == 0x42, data[11] == 0x50 else {
            return nil
        }

        // Check for VP8 (lossy), VP8L (lossless), or VP8X (extended)
        if data[12] == 0x56, data[13] == 0x50, data[14] == 0x38 {
            if data[15] == 0x20 { // VP8 (lossy)
                guard data.count >= 30 else { return nil }
                // Skip to frame header
                let width = (Int(data[26]) | Int(data[27]) << 8) & 0x3FFF
                let height = (Int(data[28]) | Int(data[29]) << 8) & 0x3FFF
                guard width > 0 && height > 0 else { return nil }
                return (width, height)
            } else if data[15] == 0x4C { // VP8L (lossless)
                guard data.count >= 25 else { return nil }
                let b0 = Int(data[21])
                let b1 = Int(data[22])
                let b2 = Int(data[23])
                let b3 = Int(data[24])
                let width = ((b1 & 0x3F) << 8 | b0) + 1
                let height = ((b3 & 0x0F) << 10 | b2 << 2 | (b1 >> 6)) + 1
                guard width > 0 && height > 0 else { return nil }
                return (width, height)
            } else if data[15] == 0x58 { // VP8X (extended)
                guard data.count >= 30 else { return nil }
                let width = (Int(data[24]) | Int(data[25]) << 8 | Int(data[26]) << 16) + 1
                let height = (Int(data[27]) | Int(data[28]) << 8 | Int(data[29]) << 16) + 1
                guard width > 0 && height > 0 else { return nil }
                return (width, height)
            }
        }
        return nil
    }

    /// Detects BMP image dimensions from header.
    private static func detectBMPDimensions(from data: Data) -> (width: Int, height: Int)? {
        // BM signature
        guard data.count >= 26, data[0] == 0x42, data[1] == 0x4D else { return nil }
        // Width at bytes 18-21, height at bytes 22-25 (little-endian, signed for height)
        let width = Int(data[18]) | Int(data[19]) << 8 | Int(data[20]) << 16 | Int(data[21]) << 24
        var height = Int(data[22]) | Int(data[23]) << 8 | Int(data[24]) << 16 | Int(data[25]) << 24
        // Height can be negative (top-down DIB)
        if height < 0 { height = -height }
        guard width > 0 && height > 0 else { return nil }
        return (width, height)
    }

    // MARK: - EXIF Orientation Detection

    /// Detects EXIF orientation from JPEG image data.
    ///
    /// This function parses the JPEG APP1 segment to find EXIF metadata and extract
    /// the orientation tag (0x0112).
    ///
    /// - Parameter data: The JPEG image data.
    /// - Returns: The orientation value, or `nil` if not found or not a JPEG.
    internal static func detectJPEGOrientation(from data: Data) -> CGImagePropertyOrientation? {
        // Check JPEG signature (SOI marker: 0xFF 0xD8)
        guard data.count >= 2, data[0] == 0xFF, data[1] == 0xD8 else { return nil }

        var offset = 2
        while offset < data.count - 4 {
            guard data[offset] == 0xFF else {
                offset += 1
                continue
            }

            let marker = data[offset + 1]

            // Skip padding bytes
            if marker == 0xFF {
                offset += 1
                continue
            }

            // APP1 marker (EXIF)
            if marker == 0xE1 {
                guard offset + 4 < data.count else { return nil }
                let length = Int(data[offset + 2]) << 8 | Int(data[offset + 3])
                let exifStart = offset + 4

                // Check "Exif\0\0" header (6 bytes)
                guard exifStart + 6 <= data.count,
                      data[exifStart] == 0x45,     // E
                      data[exifStart + 1] == 0x78, // x
                      data[exifStart + 2] == 0x69, // i
                      data[exifStart + 3] == 0x66, // f
                      data[exifStart + 4] == 0x00,
                      data[exifStart + 5] == 0x00 else {
                    offset += 2 + length
                    continue
                }

                // Parse TIFF header and find orientation tag (0x0112)
                return parseExifOrientation(data: data, tiffStart: exifStart + 6)
            }

            // Skip other markers
            if marker == 0xD8 || marker == 0xD9 || (marker >= 0xD0 && marker <= 0xD7) {
                offset += 2
            } else {
                guard offset + 3 < data.count else { return nil }
                let length = Int(data[offset + 2]) << 8 | Int(data[offset + 3])
                offset += 2 + length
            }
        }
        return nil
    }

    /// Parses EXIF orientation from TIFF IFD structure.
    ///
    /// - Parameters:
    ///   - data: The full image data.
    ///   - tiffStart: The offset where the TIFF header begins.
    /// - Returns: The orientation value, or `nil` if not found.
    private static func parseExifOrientation(data: Data, tiffStart: Int) -> CGImagePropertyOrientation? {
        guard tiffStart + 8 <= data.count else { return nil }

        // Byte order: "II" = little endian (Intel), "MM" = big endian (Motorola)
        let isLittleEndian = data[tiffStart] == 0x49 && data[tiffStart + 1] == 0x49

        func readUInt16(at offset: Int) -> UInt16 {
            guard offset + 1 < data.count else { return 0 }
            let b0 = UInt16(data[offset])
            let b1 = UInt16(data[offset + 1])
            return isLittleEndian ? (b1 << 8 | b0) : (b0 << 8 | b1)
        }

        func readUInt32(at offset: Int) -> UInt32 {
            guard offset + 3 < data.count else { return 0 }
            let b0 = UInt32(data[offset])
            let b1 = UInt32(data[offset + 1])
            let b2 = UInt32(data[offset + 2])
            let b3 = UInt32(data[offset + 3])
            return isLittleEndian
                ? (b3 << 24 | b2 << 16 | b1 << 8 | b0)
                : (b0 << 24 | b1 << 16 | b2 << 8 | b3)
        }

        // Verify TIFF magic number (42)
        let magic = readUInt16(at: tiffStart + 2)
        guard magic == 42 else { return nil }

        // IFD0 offset (usually 8)
        let ifdOffset = Int(readUInt32(at: tiffStart + 4))
        let ifdStart = tiffStart + ifdOffset
        guard ifdStart + 2 <= data.count else { return nil }

        let entryCount = Int(readUInt16(at: ifdStart))

        // Search for orientation tag (0x0112)
        for i in 0..<entryCount {
            let entryOffset = ifdStart + 2 + i * 12
            guard entryOffset + 12 <= data.count else { break }

            let tagId = readUInt16(at: entryOffset)
            if tagId == 0x0112 {  // Orientation tag
                // Type should be SHORT (3) and count should be 1
                let value = readUInt16(at: entryOffset + 8)
                if value >= 1 && value <= 8 {
                    return CGImagePropertyOrientation(rawValue: UInt32(value))
                }
            }
        }
        return nil
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

    /// The CVPixelBuffer from which this image was created, if applicable.
    ///
    /// - Note: In WASM environments, this property always returns `nil`
    ///         as CVPixelBuffer is not natively supported.
    public var pixelBuffer: CVPixelBuffer? {
        nil
    }

    /// The depth data associated with the image.
    ///
    /// - Note: In WASM environments, this property always returns `nil`
    ///         as AVDepthData is not natively supported.
    public var depthData: AVDepthData? {
        nil
    }

    /// The portrait effects matte associated with the image.
    ///
    /// - Note: In WASM environments, this property always returns `nil`
    ///         as AVPortraitEffectsMatte is not natively supported.
    public var portraitEffectsMatte: AVPortraitEffectsMatte? {
        nil
    }

    /// Returns the semantic segmentation matte of the specified type.
    ///
    /// - Parameter type: The type of semantic segmentation matte to retrieve.
    /// - Returns: The semantic segmentation matte, or `nil` if not available.
    ///
    /// - Note: In WASM environments, this method always returns `nil`
    ///         as AVSemanticSegmentationMatte is not natively supported.
    public func semanticSegmentationMatte(ofType type: AVSemanticSegmentationMatteType) -> AVSemanticSegmentationMatte? {
        nil
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
            pixelData: _pixelData,
            properties: _properties,
            transform: _transform,
            filters: newFilters
        )
    }

    /// Retrieves a numeric value from a dictionary, supporting CGFloat, Double, Float, and Int types.
    ///
    /// This helper function handles the type bridging issue where Swift's `as? CGFloat` fails
    /// for boxed `Double` values passed through `[String: Any]` dictionaries.
    ///
    /// - Parameters:
    ///   - dict: The dictionary to retrieve the value from.
    ///   - key: The key to look up.
    ///   - defaultValue: The default value to return if the key is not found or the value is not numeric.
    /// - Returns: The numeric value as CGFloat, or the default value.
    private static func numericValue(from dict: [String: Any], key: String, default defaultValue: CGFloat) -> CGFloat {
        guard let value = dict[key] else { return defaultValue }

        if let v = value as? CGFloat { return v }
        if let v = value as? Double { return CGFloat(v) }
        if let v = value as? Float { return CGFloat(v) }
        if let v = value as? Int { return CGFloat(v) }
        #if !arch(wasm32)
        if let v = value as? NSNumber { return CGFloat(v.doubleValue) }
        #endif

        return defaultValue
    }

    /// Extracts HDR-related options from the options dictionary.
    ///
    /// This helper function extracts contentHeadroom and contentAverageLightLevel
    /// from the options dictionary, handling various numeric types.
    ///
    /// - Parameter options: The options dictionary to extract values from.
    /// - Returns: A tuple containing (headroom, averageLightLevel) with defaults of 1.0.
    private static func extractHDROptions(from options: [CIImageOption: Any]?) -> (headroom: Float, averageLightLevel: Float) {
        let headroom: Float = {
            if let value = options?[.contentHeadroom] {
                if let f = value as? Float { return f }
                if let d = value as? Double { return Float(d) }
                if let cg = value as? CGFloat { return Float(cg) }
            }
            return 1.0
        }()

        let averageLightLevel: Float = {
            if let value = options?[.contentAverageLightLevel] {
                if let f = value as? Float { return f }
                if let d = value as? Double { return Float(d) }
                if let cg = value as? CGFloat { return Float(cg) }
            }
            return 1.0
        }()

        return (headroom, averageLightLevel)
    }

    /// Calculates the output extent for a filter based on its type and parameters.
    private static func calculateExtent(
        for filterName: String,
        parameters: [String: Any],
        inputExtent: CGRect
    ) -> CGRect {
        // Handle blur filters - they expand the extent by the blur radius
        if filterName.contains("Blur") {
            let radius = numericValue(from: parameters, key: kCIInputRadiusKey, default: 10.0)
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
            let scale = numericValue(from: parameters, key: kCIInputScaleKey, default: 1.0)
            let aspectRatio = numericValue(from: parameters, key: kCIInputAspectRatioKey, default: 1.0)
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
        applyingFilter("CIAffineTransform", parameters: [
            kCIInputTransformKey: matrix
        ])
    }

    /// Returns a new image that represents the original image after applying an affine transform.
    public func transformed(by matrix: CGAffineTransform, highQualityDownsample: Bool) -> CIImage {
        transformed(by: matrix)
    }

    /// Returns a new image with a cropped portion of the original image.
    public func cropped(to rect: CGRect) -> CIImage {
        applyingFilter("CICrop", parameters: [
            "inputRectangle": CIVector(cgRect: rect)
        ])
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
            pixelData: _pixelData,
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
            pixelData: _pixelData,
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
            pixelData: _pixelData,
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
            pixelData: _pixelData,
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
            pixelData: _pixelData,
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
        CIImage.orientationTransformForInit(
            orientation: CGImagePropertyOrientation(rawValue: UInt32(orientation)) ?? .up,
            width: _extent.width,
            height: _extent.height
        )
    }

    /// Static helper to compute orientation transform for use during initialization.
    ///
    /// - Parameters:
    ///   - orientation: The EXIF orientation value.
    ///   - width: The image width (after any dimension swap for 90° rotations).
    ///   - height: The image height (after any dimension swap for 90° rotations).
    /// - Returns: The affine transform to apply.
    internal static func orientationTransformForInit(
        orientation: CGImagePropertyOrientation,
        width: CGFloat,
        height: CGFloat
    ) -> CGAffineTransform {
        switch orientation {
        case .up: // 1
            return .identity
        case .upMirrored: // 2
            return CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -width, y: 0)
        case .down: // 3
            return CGAffineTransform(translationX: width, y: height).rotated(by: .pi)
        case .downMirrored: // 4
            return CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -height)
        case .leftMirrored: // 5
            return CGAffineTransform(scaleX: -1, y: 1).rotated(by: -.pi / 2)
        case .right: // 6
            return CGAffineTransform(translationX: height, y: 0).rotated(by: .pi / 2)
        case .rightMirrored: // 7
            return CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -height, y: 0).rotated(by: .pi / 2)
        case .left: // 8
            return CGAffineTransform(translationX: 0, y: width).rotated(by: -.pi / 2)
        @unknown default:
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
            pixelData: _pixelData,
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
            pixelData: _pixelData,
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
            pixelData: _pixelData,
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
            pixelData: _pixelData,
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

    /// A key for a boolean value that specifies whether to expand the image to HDR using the gain map.
    public static let expandToHDR = CIImageOption(rawValue: "kCIImageExpandToHDR")

    /// A key for a boolean value that specifies whether to cache the image immediately.
    public static let cacheImmediately = CIImageOption(rawValue: "kCIImageCacheImmediately")

    /// A key for a CGSize value that specifies the tile size for ImageProvider.
    public static let providerTileSize = CIImageOption(rawValue: "kCIImageProviderTileSize")

    /// A key for user info to pass to ImageProvider.
    public static let providerUserInfo = CIImageOption(rawValue: "kCIImageProviderUserInfo")

    /// A key for a float value that specifies the content headroom.
    public static let contentHeadroom = CIImageOption(rawValue: "kCIImageContentHeadroom")

    /// A key for a float value that specifies the content average light level.
    public static let contentAverageLightLevel = CIImageOption(rawValue: "kCIImageContentAverageLightLevel")

    /// A key for a boolean value that specifies whether to apply the clean aperture from CVPixelBuffer.
    public static let applyCleanAperture = CIImageOption(rawValue: "kCIImageApplyCleanAperture")
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
