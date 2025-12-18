//
//  ImageEncoder.swift
//  OpenCoreImage
//
//  Encodes pixel data to image formats (PNG, JPEG) using browser APIs.
//

#if arch(wasm32)
import Foundation
import JavaScriptKit

/// Supported image output formats.
internal enum ImageFormat {
    case png
    case jpeg(quality: Float)
    case webp(quality: Float)

    var mimeType: String {
        switch self {
        case .png: return "image/png"
        case .jpeg: return "image/jpeg"
        case .webp: return "image/webp"
        }
    }

    var quality: Float? {
        switch self {
        case .png: return nil
        case .jpeg(let q): return q
        case .webp(let q): return q
        }
    }
}

/// Encodes pixel data to various image formats using browser APIs.
internal struct ImageEncoder {

    /// Encodes RGBA pixel data to the specified image format.
    /// Uses the browser's Canvas API for encoding.
    ///
    /// - Parameters:
    ///   - pixelData: The raw RGBA pixel data (4 bytes per pixel).
    ///   - width: The width of the image in pixels.
    ///   - height: The height of the image in pixels.
    ///   - format: The desired output format.
    /// - Returns: The encoded image data.
    /// - Throws: An error if encoding fails.
    static func encode(
        pixelData: Data,
        width: Int,
        height: Int,
        format: ImageFormat
    ) async throws -> Data {
        guard pixelData.count == width * height * 4 else {
            throw ImageEncoderError.invalidPixelData
        }

        // Create an OffscreenCanvas
        let canvas = JSObject.global.OffscreenCanvas.function!.new(width, height)
        let ctx = canvas.getContext!("2d").object!

        // Create ImageData from pixel data
        let uint8Array = JSDataTransfer.toUint8Array(pixelData)
        let uint8ClampedArray = JSObject.global.Uint8ClampedArray.function!.new(uint8Array)
        let imageData = JSObject.global.ImageData.function!.new(uint8ClampedArray, width, height)

        // Put the image data onto the canvas
        _ = ctx.putImageData!(imageData, 0, 0)

        // Convert to blob with specified format
        let blobPromise: JSValue
        if let quality = format.quality {
            let options = JSObject.global.Object.function!.new()
            options.type = format.mimeType.jsValue
            options.quality = JSValue(floatLiteral: Double(quality))
            blobPromise = canvas.convertToBlob!(options)
        } else {
            let options = JSObject.global.Object.function!.new()
            options.type = format.mimeType.jsValue
            blobPromise = canvas.convertToBlob!(options)
        }

        // Await the blob
        let blob = try await JSPromise(blobPromise.object!)!.value

        guard let blobObject = blob.object else {
            throw ImageEncoderError.encodingFailed
        }

        // Read the blob as ArrayBuffer
        let arrayBufferPromise = blobObject.arrayBuffer!()
        let arrayBuffer = try await JSPromise(arrayBufferPromise.object!)!.value

        guard let arrayBufferObject = arrayBuffer.object else {
            throw ImageEncoderError.encodingFailed
        }

        // Convert to Uint8Array and then to Data
        let resultArray = JSObject.global.Uint8Array.function!.new(arrayBufferObject)
        let length = Int(resultArray.length.number ?? 0)
        let encodedData = JSDataTransfer.toData(resultArray, expectedLength: length)

        return encodedData
    }

    /// Encodes RGBA pixel data to PNG format.
    ///
    /// - Parameters:
    ///   - pixelData: The raw RGBA pixel data.
    ///   - width: The width of the image.
    ///   - height: The height of the image.
    /// - Returns: PNG encoded data.
    static func encodePNG(pixelData: Data, width: Int, height: Int) async throws -> Data {
        try await encode(pixelData: pixelData, width: width, height: height, format: .png)
    }

    /// Encodes RGBA pixel data to JPEG format.
    ///
    /// - Parameters:
    ///   - pixelData: The raw RGBA pixel data.
    ///   - width: The width of the image.
    ///   - height: The height of the image.
    ///   - quality: JPEG quality (0.0 to 1.0).
    /// - Returns: JPEG encoded data.
    static func encodeJPEG(
        pixelData: Data,
        width: Int,
        height: Int,
        quality: Float = 0.92
    ) async throws -> Data {
        try await encode(pixelData: pixelData, width: width, height: height, format: .jpeg(quality: quality))
    }
}

/// Errors that can occur during image encoding.
internal enum ImageEncoderError: Error {
    case invalidPixelData
    case encodingFailed
    case unsupportedFormat
}
#endif
