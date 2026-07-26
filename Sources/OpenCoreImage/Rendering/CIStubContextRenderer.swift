//
//  CIStubContextRenderer.swift
//  OpenCoreImage
//
//  Stub implementation of CIContextRenderer for non-WASM platforms.
//  Used for testing and development on native platforms.
//


#if !arch(wasm32)

/// Stub implementation of `CIContextRenderer` for non-WASM platforms.
///
/// This renderer provides basic functionality for testing on macOS/iOS.
/// It handles simple cases like solid color images and passthrough of CGImages,
/// but does not perform actual GPU-accelerated filter processing.
///
/// On native platforms (iOS, macOS), users should use Apple's CoreImage directly
/// for full functionality. This stub exists to allow OpenCoreImage code to compile
/// and run basic tests on native platforms.
internal final class CIStubContextRenderer: CIContextRenderer {

    // MARK: - Initialization

    /// Creates a new stub context renderer.
    ///
    /// - Parameter options: Context options.
    init(options: [CIContextOption: Any]?) {
        _ = options
    }

    // MARK: - CIContextRenderer

    nonisolated(nonsending) func render(
        image: CIImage,
        to rect: CGRect,
        format: CIFormat,
        colorSpace: CGColorSpace?
    ) async throws -> CIRenderResult {
        try CIRenderResult.validateOutputFormat(format)

        let width = Int(rect.width)
        let height = Int(rect.height)

        // Handle solid color images
        if let color = image._color, image._filters.isEmpty {
            let pixelData = createSolidColorData(color: color, width: width, height: height)
            return try CIRenderResult(
                pixelData: pixelData,
                width: width,
                height: height,
                colorSpace: colorSpace ?? .deviceRGB,
                format: format
            )
        }

        // Handle direct CGImage source with no filters (pure passthrough).
        if let cgImage = image.cgImage, image._filters.isEmpty {
            let pixelData = try extractPassthroughPixelData(
                from: cgImage,
                requestedWidth: width,
                requestedHeight: height
            )
            return try CIRenderResult(
                pixelData: pixelData,
                width: width,
                height: height,
                colorSpace: colorSpace ?? cgImage.colorSpace ?? .deviceRGB,
                format: format
            )
        }

        // Filter chains and transformed passthroughs require a real renderer.
        // The native stub intentionally throws rather than returning a
        // silently-zeroed buffer, so callers can distinguish "unsupported on
        // native" from "rendered black".
        // FIXME(INCOMPLETE_IMPLEMENTATION): Native compatibility rendering cannot evaluate filter chains or transformed sources.
        // Native createCGImageAsync reaches this branch and must receive a typed failure rather than an unfiltered or zero-filled image.
        // Remove this marker only after the native renderer matches the production filter semantics and success/failure tests.
        throw CIError.notImplemented
    }

    func clearCaches() {
        // No-op for stub renderer
    }

    func reclaimResources() {
        // No-op for stub renderer
    }

    // MARK: - Helper Methods

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

    /// Returns the raw RGBA8 bytes of `cgImage` when it can be returned verbatim
    /// as a passthrough result of size `requestedWidth` × `requestedHeight`.
    ///
    /// The native stub has no renderer delegate, so it cannot rasterise a
    /// `CGContext.draw` call. Instead it inspects the underlying `data`
    /// provider and returns it only when all of the following hold:
    ///  - the image has a pixel buffer attached (non-nil `data`)
    ///  - the image's dimensions match the requested passthrough rect
    ///  - the image is already in tightly-packed RGBA8 premultiplied-last
    ///    layout (bitsPerPixel == 32, bytesPerRow == width * 4, alpha info
    ///    `.premultipliedLast`, byte order default/big-endian).
    ///
    /// Any other combination throws `CIError.notImplemented` rather than
    /// silently returning a zero-filled buffer — callers must be able to
    /// distinguish "native stub cannot transcode" from "rendered black".
    private func extractPassthroughPixelData(
        from cgImage: CGImage,
        requestedWidth: Int,
        requestedHeight: Int
    ) throws -> Data {
        guard cgImage.width == requestedWidth, cgImage.height == requestedHeight else {
            throw CIError.notImplemented
        }
        guard let data = cgImage.data else {
            throw CIError.notImplemented
        }
        let expectedBytesPerRow = requestedWidth * 4
        guard cgImage.bitsPerPixel == 32,
              cgImage.bitsPerComponent == 8,
              cgImage.bytesPerRow == expectedBytesPerRow,
              cgImage.alphaInfo == .premultipliedLast,
              data.count == expectedBytesPerRow * requestedHeight
        else {
            throw CIError.notImplemented
        }
        return data
    }

}
#endif
