//
//  ImageDecoder.swift
//  OpenCoreImage
//
//  Decodes image data (JPEG, PNG, etc.) using browser APIs.
//

#if arch(wasm32)
import Foundation
import JavaScriptKit

/// Result of decoding an image.
internal struct DecodedImage: Sendable {
    /// The width of the image in pixels.
    let width: Int

    /// The height of the image in pixels.
    let height: Int

    /// The raw RGBA pixel data (4 bytes per pixel).
    let pixelData: Data
}

/// Decodes image data using browser's built-in image decoding capabilities.
internal struct ImageDecoder {

    /// Decodes image data (JPEG, PNG, WebP, GIF, etc.) to RGBA pixel data.
    /// Uses the browser's `createImageBitmap()` API for decoding.
    ///
    /// - Parameter data: The encoded image data.
    /// - Returns: The decoded image with dimensions and pixel data.
    /// - Throws: An error if decoding fails.
    static func decode(_ data: Data) async throws -> DecodedImage {
        // Create a Blob from the image data
        let uint8Array = JSDataTransfer.toUint8Array(data)
        let blob = JSObject.global.Blob.function!.new([uint8Array])

        // Use createImageBitmap to decode the image
        let createImageBitmap = JSObject.global.createImageBitmap.function!
        let bitmapPromise = createImageBitmap(blob)

        // Await the promise
        let bitmap = try await JSPromise(bitmapPromise.object!)!.value

        guard let bitmapObject = bitmap.object else {
            throw ImageDecoderError.decodingFailed
        }

        // Get image dimensions
        let width = Int(bitmapObject.width.number ?? 0)
        let height = Int(bitmapObject.height.number ?? 0)

        guard width > 0 && height > 0 else {
            throw ImageDecoderError.invalidDimensions
        }

        // Create an OffscreenCanvas to extract pixel data
        let canvas = JSObject.global.OffscreenCanvas.function!.new(width, height)
        let ctx = canvas.getContext!("2d").object!

        // Draw the bitmap onto the canvas
        _ = ctx.drawImage!(bitmapObject, 0, 0)

        // Get the pixel data
        let imageData = ctx.getImageData!(0, 0, width, height).object!
        let dataArray = imageData.data.object!

        // Convert to Swift Data
        let pixelData = JSDataTransfer.toData(dataArray, expectedLength: width * height * 4)

        // Close the bitmap to free resources
        _ = bitmapObject.close!()

        return DecodedImage(width: width, height: height, pixelData: pixelData)
    }

    /// Decodes image data synchronously by blocking on the async result.
    /// Note: This should only be used when async is not available.
    ///
    /// - Parameter data: The encoded image data.
    /// - Returns: The decoded image, or nil if decoding fails.
    static func decodeSync(_ data: Data) -> DecodedImage? {
        // For synchronous decoding, we try to detect image dimensions from headers
        // and decode lazily. Full pixel data extraction requires async.

        // Try to read dimensions from PNG header
        if let dimensions = readPNGDimensions(from: data) {
            // Return with placeholder - actual decoding will happen async
            return DecodedImage(
                width: dimensions.width,
                height: dimensions.height,
                pixelData: Data() // Empty - needs async decode
            )
        }

        // Try to read dimensions from JPEG header
        if let dimensions = readJPEGDimensions(from: data) {
            return DecodedImage(
                width: dimensions.width,
                height: dimensions.height,
                pixelData: Data() // Empty - needs async decode
            )
        }

        return nil
    }

    // MARK: - Header Parsing

    /// Reads image dimensions from PNG header.
    private static func readPNGDimensions(from data: Data) -> (width: Int, height: Int)? {
        // PNG signature: 89 50 4E 47 0D 0A 1A 0A
        // IHDR chunk starts at byte 8
        guard data.count >= 24 else { return nil }

        let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        for (i, byte) in signature.enumerated() {
            guard data[i] == byte else { return nil }
        }

        // IHDR chunk: bytes 12-15 = width, bytes 16-19 = height (big-endian)
        let width = Int(data[16]) << 24 | Int(data[17]) << 16 | Int(data[18]) << 8 | Int(data[19])
        let height = Int(data[20]) << 24 | Int(data[21]) << 16 | Int(data[22]) << 8 | Int(data[23])

        guard width > 0 && height > 0 else { return nil }
        return (width, height)
    }

    /// Reads image dimensions from JPEG header.
    private static func readJPEGDimensions(from data: Data) -> (width: Int, height: Int)? {
        // JPEG starts with FF D8
        guard data.count >= 2, data[0] == 0xFF, data[1] == 0xD8 else { return nil }

        var offset = 2
        while offset < data.count - 8 {
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

            // SOF markers (Start of Frame) contain dimensions
            // SOF0 (0xC0) - Baseline DCT
            // SOF1 (0xC1) - Extended sequential DCT
            // SOF2 (0xC2) - Progressive DCT
            if marker >= 0xC0 && marker <= 0xC3 {
                // SOF segment: FF Cx LL LL PP HH HH WW WW
                // LL LL = segment length
                // PP = precision
                // HH HH = height (big-endian)
                // WW WW = width (big-endian)
                guard offset + 9 < data.count else { return nil }

                let height = Int(data[offset + 5]) << 8 | Int(data[offset + 6])
                let width = Int(data[offset + 7]) << 8 | Int(data[offset + 8])

                guard width > 0 && height > 0 else { return nil }
                return (width, height)
            }

            // Skip to next marker
            if marker == 0xD8 || marker == 0xD9 || (marker >= 0xD0 && marker <= 0xD7) {
                // Standalone markers (no length)
                offset += 2
            } else {
                // Markers with length
                guard offset + 3 < data.count else { return nil }
                let length = Int(data[offset + 2]) << 8 | Int(data[offset + 3])
                offset += 2 + length
            }
        }

        return nil
    }
}

/// Errors that can occur during image decoding.
internal enum ImageDecoderError: Error {
    case decodingFailed
    case invalidDimensions
    case unsupportedFormat
}
#endif
