//
//  ImageDecoder.swift
//  OpenCoreImage
//
//  Decodes image data (JPEG, PNG, etc.) using browser APIs.
//

#if arch(wasm32)
import JavaScriptKit
import JavaScriptEventLoop

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

}

/// Errors that can occur during image decoding.
internal enum ImageDecoderError: Error {
    case decodingFailed
    case invalidDimensions
    case unsupportedFormat
}
#endif
