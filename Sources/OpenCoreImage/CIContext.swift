//
//  CIContext.swift
//  OpenCoreImage
//
//  The Core Image context class provides an evaluation context for Core Image processing.
//

import Foundation
import OpenCoreGraphics

/// The Core Image context class provides an evaluation context for Core Image processing.
///
/// You use a `CIContext` instance to render a `CIImage` instance which represents a graph
/// of image processing operations which are built using other Core Image classes.
///
/// `CIContext` and `CIImage` instances are immutable, so multiple threads can use the same
/// `CIContext` instance to render `CIImage` instances.
public final class CIContext: @unchecked Sendable {

    // MARK: - Internal Storage

    internal let _options: [CIContextOption: Any]
    internal let _workingColorSpace: CGColorSpace?
    internal let _workingFormat: CIFormat

    // MARK: - Renderer

    /// The internal renderer that executes GPU operations.
    ///
    /// This is created internally based on the target architecture.
    /// On WASM, `CIWebGPUContextRenderer` is used automatically.
    private let renderer: CIContextRenderer

    // MARK: - Initialization

    /// Initializes a context without a specific rendering destination, using default options.
    public init() {
        self._options = [:]
        self._workingColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        self._workingFormat = .RGBAf
        self.renderer = Self.createRenderer(options: nil)
    }

    /// Initializes a context without a specific rendering destination, using the specified options.
    public init(options: [CIContextOption: Any]?) {
        self._options = options ?? [:]
        // Use safe cast to avoid crash on type mismatch
        if let colorSpace = options?[.workingColorSpace] as? CGColorSpace {
            self._workingColorSpace = colorSpace
        } else {
            self._workingColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        }
        self._workingFormat = options?[.workingFormat] as? CIFormat ?? .RGBAf
        self.renderer = Self.createRenderer(options: options)
    }

    /// Creates a Core Image context from a Quartz context, using the specified options.
    public init(cgContext: CGContext, options: [CIContextOption: Any]?) {
        self._options = options ?? [:]
        // Use safe cast to avoid crash on type mismatch
        if let colorSpace = options?[.workingColorSpace] as? CGColorSpace {
            self._workingColorSpace = colorSpace
        } else {
            self._workingColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        }
        self._workingFormat = options?[.workingFormat] as? CIFormat ?? .RGBAf
        self.renderer = Self.createRenderer(options: options)
    }

    // MARK: - Renderer Factory

    /// Creates the appropriate renderer for the current platform.
    ///
    /// This is called internally during initialization.
    /// On WASM, `CIWebGPUContextRenderer` is created.
    /// On other platforms, a stub renderer is used for testing.
    private static func createRenderer(options: [CIContextOption: Any]?) -> CIContextRenderer {
        #if arch(wasm32)
        return CIWebGPUContextRenderer(options: options)
        #else
        return CIStubContextRenderer(options: options)
        #endif
    }

    // MARK: - Properties

    /// The working color space of the Core Image context.
    public var workingColorSpace: CGColorSpace? {
        _workingColorSpace
    }

    /// The working pixel format of the Core Image context.
    public var workingFormat: CIFormat {
        _workingFormat
    }

    // MARK: - Rendering Images

    /// Creates a Core Graphics image from a region of a Core Image image instance.
    public func createCGImage(_ image: CIImage, from fromRect: CGRect) -> CGImage? {
        createCGImage(image, from: fromRect, format: CIFormat.RGBA8, colorSpace: _workingColorSpace)
    }

    /// Creates a Core Graphics image from a region of a Core Image image instance
    /// with an option for controlling the pixel format and color space of the `CGImage`.
    public func createCGImage(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) -> CGImage? {
        createCGImage(image, from: fromRect, format: format, colorSpace: colorSpace, deferred: false)
    }

    /// Creates a Core Graphics image from a region of a Core Image image instance
    /// with an option for controlling when the image is rendered.
    public func createCGImage(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?,
        deferred: Bool
    ) -> CGImage? {
        // If the image has a CGImage source and no filters, crop and return it
        if let cgImage = image.cgImage, image._filters.isEmpty {
            // Check if fromRect matches the full image size
            let imageRect = CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
            if fromRect == imageRect {
                return cgImage
            }
            // Crop to the requested region
            return cgImage.cropping(to: fromRect)
        }

        let width = Int(fromRect.width)
        let height = Int(fromRect.height)
        guard width > 0 && height > 0 else { return nil }

        // For solid color images - check if it's a pure color or only has CICrop filters
        // (cropping a solid color still produces a solid color)
        if let color = image._color, isSolidColorImage(image) {
            return createSolidColorCGImage(
                color: color,
                width: width,
                height: height,
                colorSpace: colorSpace
            )
        }

        #if arch(wasm32)
        // On WASM, synchronous rendering with filter chains is not supported
        // because DispatchSemaphore is not available in single-threaded WASM.
        // Use createCGImageAsync() for filter chain rendering instead.
        // For images without filters, the early returns above will handle them.
        return nil
        #else
        // Non-WASM: filter chain rendering not available
        return nil
        #endif
    }

    /// Checks if the image is effectively a solid color image.
    /// A solid color image has a color set and either no filters or only CICrop filters.
    private func isSolidColorImage(_ image: CIImage) -> Bool {
        if image._filters.isEmpty {
            return true
        }
        // Check if all filters are CICrop (cropping a solid color is still solid)
        return image._filters.allSatisfy { $0.name == "CICrop" }
    }

    // MARK: - Async Rendering API

    /// Asynchronously creates a Core Graphics image from a Core Image image.
    /// - Parameters:
    ///   - image: The CIImage to render.
    ///   - fromRect: The region to render.
    ///   - format: The pixel format.
    ///   - colorSpace: The color space.
    /// - Returns: The rendered CGImage.
    public func createCGImageAsync(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat = .RGBA8,
        colorSpace: CGColorSpace? = nil
    ) async throws -> CGImage {
        let result = try await renderer.render(
            image: image,
            to: fromRect,
            format: format,
            colorSpace: colorSpace ?? _workingColorSpace
        )
        return result.cgImage
    }

    // MARK: - Helper Methods

    private func createSolidColorCGImage(
        color: CIColor,
        width: Int,
        height: Int,
        colorSpace: CGColorSpace?
    ) -> CGImage? {
        let pixelData = createSolidColorData(color: color, width: width, height: height)
        return createCGImageFromPixelData(pixelData, width: width, height: height, colorSpace: colorSpace)
    }

    private func createSolidColorData(color: CIColor, width: Int, height: Int) -> Data {
        let r = UInt8(clamping: Int(color.red * 255))
        let g = UInt8(clamping: Int(color.green * 255))
        let b = UInt8(clamping: Int(color.blue * 255))
        let a = UInt8(clamping: Int(color.alpha * 255))

        var data = Data(capacity: width * height * 4)
        let pixel: [UInt8] = [r, g, b, a]
        for _ in 0..<(width * height) {
            data.append(contentsOf: pixel)
        }
        return data
    }

    private func extractPixelData(from cgImage: CGImage, width: Int, height: Int) -> Data {
        let bytesPerRow = width * 4
        var pixelData = Data(count: bytesPerRow * height)

        pixelData.withUnsafeMutableBytes { ptr in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: .deviceRGB,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            ) else { return }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        return pixelData
    }

    private func createCGImageFromPixelData(
        _ data: Data,
        width: Int,
        height: Int,
        colorSpace: CGColorSpace?
    ) -> CGImage? {
        let cs = colorSpace ?? .deviceRGB
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let bytesPerRow = width * 4

        let dataProvider = CGDataProvider(data: data)

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: cs,
            bitmapInfo: bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    /// Creates a Core Graphics image from a region of a Core Image image instance
    /// with an option for calculating HDR statistics.
    public func createCGImage(
        _ image: CIImage,
        from fromRect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?,
        deferred: Bool,
        calculateHDRStats: Bool
    ) -> CGImage? {
        createCGImage(image, from: fromRect, format: format, colorSpace: colorSpace, deferred: deferred)
    }

    /// Renders to the given bitmap.
    ///
    /// - Parameters:
    ///   - image: The CIImage to render.
    ///   - data: Pointer to the destination bitmap buffer.
    ///   - rowBytes: The number of bytes per row in the destination buffer.
    ///   - bounds: The region of the image to render.
    ///   - format: The pixel format of the destination buffer.
    ///   - colorSpace: The color space of the destination buffer.
    ///
    /// - Note: On WASM, this method only supports synchronous rendering for:
    ///   - Solid color images (without filters)
    ///   - CGImage sources (without filters)
    ///   - Images with pre-decoded pixel data (without additional filters)
    ///   - Images from encoded data (PNG/JPEG) that can be decoded synchronously
    ///   For filter chains, use `createCGImageAsync` instead.
    public func render(
        _ image: CIImage,
        toBitmap data: UnsafeMutableRawPointer,
        rowBytes: Int,
        bounds: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) {
        let width = Int(bounds.width)
        let height = Int(bounds.height)

        guard width > 0 && height > 0 else { return }

        // Check for filter chains - synchronous rendering does not support filters
        let hasFilters = !image._filters.isEmpty

        // Calculate bytes per pixel based on format
        let bytesPerPixel = format.bytesPerPixel

        // Get pixel data from the image
        let pixelData: Data?

        // Priority 1: Solid color image (without filters only)
        if let color = image._color, isSolidColorImage(image), !hasFilters {
            pixelData = createSolidColorData(color: color, width: width, height: height)
        }
        // Priority 2: Pre-decoded pixel data (from CIImage.decoded() or bitmapData init)
        // Only use if no filters are applied, otherwise we'd be drawing unprocessed data
        else if let decoded = image._pixelData, !decoded.isEmpty, !hasFilters {
            let sourceExtent = image.extent
            // Handle infinite extent
            let sourceWidth = sourceExtent.isInfinite ? width : Int(sourceExtent.width)
            let sourceHeight = sourceExtent.isInfinite ? height : Int(sourceExtent.height)

            // Calculate sourceBytesPerRow based on format, not fixed at 4 bytes per pixel
            let sourceFormat = image._format ?? .RGBA8
            let sourceBytesPerRow = image._bytesPerRow ?? sourceWidth * sourceFormat.bytesPerPixel

            pixelData = extractRegionFromPixelData(
                decoded,
                sourceWidth: sourceWidth,
                sourceHeight: sourceHeight,
                sourceBytesPerRow: sourceBytesPerRow,
                sourceFormat: sourceFormat,
                bounds: bounds,
                targetFormat: format
            )
        }
        // Priority 3: CGImage source without filters
        else if let cgImage = image.cgImage, !hasFilters {
            pixelData = extractPixelData(from: cgImage, width: width, height: height)
        }
        // Priority 4: Try to decode encoded data synchronously (without filters)
        else if let encodedData = image._data, !encodedData.isEmpty, !hasFilters {
            pixelData = decodeImageDataSync(encodedData, width: width, height: height, format: format)
        }
        // Priority 5: Cannot render synchronously (filter chains or unsupported sources)
        else {
            // For filter chains on WASM, synchronous rendering is not supported
            // Return nil to indicate failure - the buffer remains unchanged
            pixelData = nil
        }

        // Copy pixel data to destination buffer
        if let sourceData = pixelData {
            sourceData.withUnsafeBytes { srcPtr in
                guard let srcBase = srcPtr.baseAddress else { return }
                let destBase = data

                // Handle row-by-row copy if rowBytes differs from source
                let sourceRowBytes = width * bytesPerPixel
                if rowBytes == sourceRowBytes {
                    // Direct copy
                    let copySize = min(sourceData.count, rowBytes * height)
                    memcpy(destBase, srcBase, copySize)
                } else {
                    // Row-by-row copy with stride adjustment
                    for row in 0..<height {
                        let srcOffset = row * sourceRowBytes
                        let destOffset = row * rowBytes
                        let copyWidth = min(sourceRowBytes, rowBytes)

                        guard srcOffset + copyWidth <= sourceData.count else { break }

                        memcpy(
                            destBase.advanced(by: destOffset),
                            srcBase.advanced(by: srcOffset),
                            copyWidth
                        )
                    }
                }
            }
        }
    }

    /// Extracts a region from pixel data with format conversion.
    private func extractRegionFromPixelData(
        _ data: Data,
        sourceWidth: Int,
        sourceHeight: Int,
        sourceBytesPerRow: Int,
        sourceFormat: CIFormat,
        bounds: CGRect,
        targetFormat: CIFormat
    ) -> Data? {
        let targetWidth = Int(bounds.width)
        let targetHeight = Int(bounds.height)
        let startX = Int(bounds.origin.x)
        let startY = Int(bounds.origin.y)

        // Validate bounds
        guard startX >= 0, startY >= 0,
              startX + targetWidth <= sourceWidth,
              startY + targetHeight <= sourceHeight else {
            return nil
        }

        let sourceBytesPerPixel = sourceFormat.bytesPerPixel
        let targetBytesPerPixel = targetFormat.bytesPerPixel
        let targetRowBytes = targetWidth * targetBytesPerPixel

        var result = Data(count: targetRowBytes * targetHeight)

        // If formats match, do a direct copy
        if sourceFormat == targetFormat {
            result.withUnsafeMutableBytes { destPtr in
                data.withUnsafeBytes { srcPtr in
                    guard let destBase = destPtr.baseAddress,
                          let srcBase = srcPtr.baseAddress else { return }

                    for row in 0..<targetHeight {
                        let srcRow = startY + row
                        let srcOffset = srcRow * sourceBytesPerRow + startX * sourceBytesPerPixel
                        let destOffset = row * targetRowBytes

                        memcpy(
                            destBase.advanced(by: destOffset),
                            srcBase.advanced(by: srcOffset),
                            targetRowBytes
                        )
                    }
                }
            }
        } else {
            // Format conversion needed - implement basic RGBA8 handling
            // For now, just copy and let the receiver handle format differences
            result.withUnsafeMutableBytes { destPtr in
                data.withUnsafeBytes { srcPtr in
                    guard let destBase = destPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                          let srcBase = srcPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }

                    for row in 0..<targetHeight {
                        let srcRow = startY + row
                        for col in 0..<targetWidth {
                            let srcCol = startX + col
                            let srcOffset = srcRow * sourceBytesPerRow + srcCol * sourceBytesPerPixel
                            let destOffset = row * targetRowBytes + col * targetBytesPerPixel

                            // Copy available bytes, pad with 255 (alpha) if needed
                            let copyBytes = min(sourceBytesPerPixel, targetBytesPerPixel)
                            for i in 0..<copyBytes {
                                destBase[destOffset + i] = srcBase[srcOffset + i]
                            }
                            // If target has more channels (e.g., RGB -> RGBA), set alpha to 255
                            if targetBytesPerPixel > sourceBytesPerPixel {
                                for i in sourceBytesPerPixel..<targetBytesPerPixel {
                                    destBase[destOffset + i] = 255
                                }
                            }
                        }
                    }
                }
            }
        }

        return result
    }

    /// Synchronously decodes image data (PNG/JPEG) to pixel data.
    ///
    /// - Important: Synchronous image decoding is not implemented in OpenCoreImage.
    ///   This is because:
    ///   - On WASM: Browser APIs for image decoding are async-only
    ///   - OpenCoreImage is designed for WASM where CoreImage is unavailable
    ///
    /// - Note: For images created from encoded data (`CIImage(data:)` or
    ///   `CIImage(contentsOf:)`), use async APIs like `createCGImageAsync`
    ///   which properly handle decoding through WebGPU pipelines.
    ///
    /// - Returns: Always `nil`. Detection will fall back to pure Swift algorithms.
    private func decodeImageDataSync(
        _ data: Data,
        width: Int,
        height: Int,
        format: CIFormat
    ) -> Data? {
        // Synchronous image decoding is not implemented.
        // On WASM (the primary target), browser image decoding APIs are async-only.
        // Users should:
        // 1. Use async APIs (createCGImageAsync, detectFeaturesAsync) for encoded images
        // 2. Pre-decode images to CGImage before creating CIImage for sync operations
        // 3. Use CIImage(cgImage:) with pre-decoded images for detection
        _ = (data, width, height, format)  // Suppress unused parameter warnings
        return nil
    }

    // MARK: - Drawing Images

    /// Renders a region of an image to a rectangle in the context destination.
    public func draw(_ image: CIImage, in inRect: CGRect, from fromRect: CGRect) {
        // Placeholder implementation
        // In a full implementation, this would draw the image
    }

    // MARK: - Determining the Allowed Extents for Images

    /// Returns the maximum size allowed for any image rendered into the context.
    public func inputImageMaximumSize() -> CGSize {
        renderer.maximumInputSize
    }

    /// Returns the maximum size allowed for any image created by the context.
    public func outputImageMaximumSize() -> CGSize {
        renderer.maximumOutputSize
    }

    // MARK: - Managing Resources

    /// Frees any cached data, such as temporary images, associated with the context and runs the garbage collector.
    public func clearCaches() {
        renderer.clearCaches()
    }

    /// Runs the garbage collector to reclaim any resources that the context no longer requires.
    public func reclaimResources() {
        renderer.reclaimResources()
    }

    /// Returns the number of GPUs not currently driving a display.
    public class func offlineGPUCount() -> UInt32 {
        0
    }

    // MARK: - Rendering Images for Data or File Export

    /// Renders the image and exports the resulting image data in TIFF format.
    public func tiffRepresentation(
        of image: CIImage,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) -> Data? {
        // Placeholder implementation
        nil
    }

    /// Renders the image and exports the resulting image data in JPEG format.
    public func jpegRepresentation(
        of image: CIImage,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) -> Data? {
        // Synchronous encoding not available - use jpegRepresentationAsync on WASM
        nil
    }

    /// Renders the image and exports the resulting image data in PNG format.
    public func pngRepresentation(
        of image: CIImage,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) -> Data? {
        // Synchronous encoding not available - use pngRepresentationAsync on WASM
        nil
    }

    #if arch(wasm32)
    // MARK: - Async Image Representation (WASM)

    /// Asynchronously renders the image and exports the resulting image data in PNG format.
    ///
    /// - Parameters:
    ///   - image: The CIImage to render.
    ///   - format: The pixel format.
    ///   - colorSpace: The color space.
    ///   - options: Export options.
    /// - Returns: PNG encoded data.
    public func pngRepresentationAsync(
        of image: CIImage,
        format: CIFormat = .RGBA8,
        colorSpace: CGColorSpace? = nil,
        options: [CIImageRepresentationOption: Any] = [:]
    ) async throws -> Data {
        let rect = image.extent
        guard !rect.isInfinite && !rect.isEmpty else {
            throw CIError.invalidArgument
        }

        // Render the image to get pixel data
        let cgImage = try await createCGImageAsync(image, from: rect, format: format, colorSpace: colorSpace)

        // Extract pixel data from CGImage
        let width = Int(rect.width)
        let height = Int(rect.height)
        let pixelData = extractPixelData(from: cgImage, width: width, height: height)

        // Encode to PNG using browser APIs
        return try await ImageEncoder.encodePNG(pixelData: pixelData, width: width, height: height)
    }

    /// Asynchronously renders the image and exports the resulting image data in JPEG format.
    ///
    /// - Parameters:
    ///   - image: The CIImage to render.
    ///   - colorSpace: The color space.
    ///   - options: Export options (supports `.jpegQuality`).
    /// - Returns: JPEG encoded data.
    public func jpegRepresentationAsync(
        of image: CIImage,
        colorSpace: CGColorSpace? = nil,
        options: [CIImageRepresentationOption: Any] = [:]
    ) async throws -> Data {
        let rect = image.extent
        guard !rect.isInfinite && !rect.isEmpty else {
            throw CIError.invalidArgument
        }

        // Get quality from options
        let quality: Float
        if let q = options[.jpegQuality] as? Float {
            quality = q
        } else if let q = options[.jpegQuality] as? Double {
            quality = Float(q)
        } else {
            quality = 0.92
        }

        // Render the image to get pixel data
        let cgImage = try await createCGImageAsync(image, from: rect, format: .RGBA8, colorSpace: colorSpace)

        // Extract pixel data from CGImage
        let width = Int(rect.width)
        let height = Int(rect.height)
        let pixelData = extractPixelData(from: cgImage, width: width, height: height)

        // Encode to JPEG using browser APIs
        return try await ImageEncoder.encodeJPEG(pixelData: pixelData, width: width, height: height, quality: quality)
    }

    /// Asynchronously writes the image to a file in PNG format.
    public func writePNGRepresentationAsync(
        of image: CIImage,
        to url: URL,
        format: CIFormat = .RGBA8,
        colorSpace: CGColorSpace? = nil,
        options: [CIImageRepresentationOption: Any] = [:]
    ) async throws {
        let data = try await pngRepresentationAsync(of: image, format: format, colorSpace: colorSpace, options: options)
        try data.write(to: url)
    }

    /// Asynchronously writes the image to a file in JPEG format.
    public func writeJPEGRepresentationAsync(
        of image: CIImage,
        to url: URL,
        colorSpace: CGColorSpace? = nil,
        options: [CIImageRepresentationOption: Any] = [:]
    ) async throws {
        let data = try await jpegRepresentationAsync(of: image, colorSpace: colorSpace, options: options)
        try data.write(to: url)
    }
    #endif

    /// Renders the image and exports the resulting image data in HEIF format.
    public func heifRepresentation(
        of image: CIImage,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) -> Data? {
        // Placeholder implementation
        nil
    }

    /// Renders the image and exports the resulting image data in HEIF10 format.
    public func heif10Representation(
        of image: CIImage,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws -> Data {
        // Placeholder implementation
        throw CIError.notImplemented
    }

    /// Renders the image and exports the resulting image data in open EXR format.
    public func openEXRRepresentation(
        of image: CIImage,
        options: [CIImageRepresentationOption: Any]
    ) throws -> Data {
        // Placeholder implementation
        throw CIError.notImplemented
    }

    /// Renders the image and exports the resulting image data as a file in TIFF format.
    public func writeTIFFRepresentation(
        of image: CIImage,
        to url: URL,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        guard let data = tiffRepresentation(of: image, format: format, colorSpace: colorSpace, options: options) else {
            throw CIError.renderingFailed
        }
        try data.write(to: url)
    }

    /// Renders the image and exports the resulting image data as a file in JPEG format.
    public func writeJPEGRepresentation(
        of image: CIImage,
        to url: URL,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        guard let data = jpegRepresentation(of: image, colorSpace: colorSpace, options: options) else {
            throw CIError.renderingFailed
        }
        try data.write(to: url)
    }

    /// Renders the image and exports the resulting image data as a file in PNG format.
    public func writePNGRepresentation(
        of image: CIImage,
        to url: URL,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        guard let data = pngRepresentation(of: image, format: format, colorSpace: colorSpace, options: options) else {
            throw CIError.renderingFailed
        }
        try data.write(to: url)
    }

    /// Renders the image and exports the resulting image data as a file in HEIF format.
    public func writeHEIFRepresentation(
        of image: CIImage,
        to url: URL,
        format: CIFormat,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        guard let data = heifRepresentation(of: image, format: format, colorSpace: colorSpace, options: options) else {
            throw CIError.renderingFailed
        }
        try data.write(to: url)
    }

    /// Renders the image and exports the resulting image data as a file in HEIF10 format.
    public func writeHEIF10Representation(
        of image: CIImage,
        to url: URL,
        colorSpace: CGColorSpace,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        let data = try heif10Representation(of: image, colorSpace: colorSpace, options: options)
        try data.write(to: url)
    }

    /// Renders the image and exports the resulting image data as a file in open EXR format.
    public func writeOpenEXRRepresentation(
        of image: CIImage,
        to url: URL,
        options: [CIImageRepresentationOption: Any]
    ) throws {
        let data = try openEXRRepresentation(of: image, options: options)
        try data.write(to: url)
    }

    // MARK: - HDR Statistics

    /// Given a Core Image image, calculate its HDR statistics.
    public func calculateHDRStats(for image: CIImage) -> CIImage? {
        image
    }
}

// MARK: - Equatable

extension CIContext: Equatable {
    public static func == (lhs: CIContext, rhs: CIContext) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIContext: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CIContextOption

/// An enum string type that your code can use to select different options when creating a Core Image context.
public struct CIContextOption: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A key for the color space to use for the context's working color space.
    public static let workingColorSpace = CIContextOption(rawValue: "kCIContextWorkingColorSpace")

    /// A key for the working pixel format of the context.
    public static let workingFormat = CIContextOption(rawValue: "kCIContextWorkingFormat")

    /// A key for a boolean value that specifies whether to use high-quality downsampling.
    public static let highQualityDownsample = CIContextOption(rawValue: "kCIContextHighQualityDownsample")

    /// A key for the output color space of the context.
    public static let outputColorSpace = CIContextOption(rawValue: "kCIContextOutputColorSpace")

    /// A key for a boolean value that specifies whether to cache intermediates.
    public static let cacheIntermediates = CIContextOption(rawValue: "kCIContextCacheIntermediates")

    /// A key for a boolean value that specifies whether to use software rendering.
    public static let useSoftwareRenderer = CIContextOption(rawValue: "kCIContextUseSoftwareRenderer")

    /// A key for a boolean value that specifies whether to prioritize lower power consumption.
    public static let priorityRequestLow = CIContextOption(rawValue: "kCIContextPriorityRequestLow")

    /// A key for a boolean value that specifies whether to allow low power rendering.
    public static let allowLowPower = CIContextOption(rawValue: "kCIContextAllowLowPower")

    /// A key for the name of the context.
    public static let name = CIContextOption(rawValue: "kCIContextName")
}

// MARK: - CIImageRepresentationOption

/// Options for image representation export.
public struct CIImageRepresentationOption: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A key for a float value that specifies the JPEG quality (0.0 to 1.0).
    public static let jpegQuality = CIImageRepresentationOption(rawValue: "kCGImageDestinationLossyCompressionQuality")

    /// A key for a boolean value that specifies whether to use HDR.
    public static let hdrImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationHDRImage")

    /// A key for depth data to include in the image.
    public static let depthImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationDepthImage")

    /// A key for disparity data to include in the image.
    public static let disparityImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationDisparityImage")

    /// A key for portrait effects matte data to include in the image.
    public static let portraitEffectsMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationPortraitEffectsMatteImage")

    /// A key for semantic segmentation matte images to include.
    public static let semanticSegmentationSkinMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationSkinMatteImage")

    /// A key for semantic segmentation hair matte images to include.
    public static let semanticSegmentationHairMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationHairMatteImage")

    /// A key for semantic segmentation teeth matte images to include.
    public static let semanticSegmentationTeethMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationTeethMatteImage")

    /// A key for semantic segmentation glasses matte images to include.
    public static let semanticSegmentationGlassesMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationGlassesMatteImage")

    /// A key for semantic segmentation sky matte images to include.
    public static let semanticSegmentationSkyMatteImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationSemanticSegmentationSkyMatteImage")

    /// A key for HDR gain map data to include in the image.
    public static let hdrGainMapImage = CIImageRepresentationOption(rawValue: "kCIImageRepresentationHDRGainMapImage")
}

// MARK: - CIError

/// Errors that can occur during Core Image operations.
public enum CIError: Error {
    case notImplemented
    case renderingFailed
    case invalidArgument
    case outOfMemory
}
