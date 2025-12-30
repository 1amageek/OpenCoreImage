//
//  CIWebAPIDetectorEngine.swift
//  OpenCoreImage
//
//  WASM-specific detector engine using browser APIs.
//

#if arch(wasm32)

import Foundation
import JavaScriptKit
import OpenCoreGraphics

/// WASM-specific detector engine that uses browser APIs when available.
///
/// This engine attempts to use browser's FaceDetector and BarcodeDetector APIs
/// for better detection accuracy. Falls back to pure Swift implementation when
/// browser APIs are not available.
internal final class CIWebAPIDetectorEngine: CIDetectorEngine, @unchecked Sendable {

    // MARK: - Properties

    private let defaultEngine: CIDefaultDetectorEngine
    private let context: CIContext?

    // MARK: - Initialization

    /// Creates a web API detector engine.
    ///
    /// - Parameters:
    ///   - context: Optional CIContext for rendering
    ///   - options: Detector configuration options
    init(context: CIContext?, options: [String: Any]?) {
        self.context = context
        self.defaultEngine = CIDefaultDetectorEngine(context: context, options: options)
    }

    // MARK: - CIDetectorEngine Protocol

    /// Synchronous feature detection.
    ///
    /// Since browser APIs are async, this always falls back to the pure Swift implementation.
    func detectFeatures(type: String, in image: CIImage, options: [String: Any]?) -> [CIFeature] {
        // Synchronous API uses pure Swift implementation
        return defaultEngine.detectFeatures(type: type, in: image, options: options)
    }

    /// Asynchronous feature detection using browser APIs when available.
    ///
    /// For face and QR code detection, attempts to use browser's native APIs
    /// for better accuracy. Falls back to pure Swift for other types or when
    /// browser APIs are not available.
    func detectFeaturesAsync(type: String, in image: CIImage, options: [String: Any]?) async -> [CIFeature] {
        switch type {
        case CIDetectorTypeFace:
            if let features = await detectFacesWithBrowserAPI(in: image, options: options) {
                return features
            }

        case CIDetectorTypeQRCode:
            if let features = await detectBarcodesWithBrowserAPI(in: image, options: options) {
                return features
            }

        default:
            break
        }

        // Fallback to pure Swift implementation
        return defaultEngine.detectFeatures(type: type, in: image, options: options)
    }

    // MARK: - Browser API: Face Detection

    /// Detects faces using browser's FaceDetector API.
    ///
    /// - Parameters:
    ///   - image: The source image
    ///   - options: Detection options
    /// - Returns: Array of face features, or nil if API is not available
    private func detectFacesWithBrowserAPI(in image: CIImage, options: [String: Any]?) async -> [CIFeature]? {
        // Check if FaceDetector API is available
        guard JSObject.global.FaceDetector.function != nil else {
            return nil
        }

        do {
            // Get image data (uses async version for filter chain support)
            guard let imageData = await getImageDataForBrowserAPIAsync(from: image) else {
                return nil
            }

            // Create FaceDetector
            let detectorOptions = JSObject.global.Object.function!.new()
            detectorOptions.fastMode = .boolean(true)

            let detector = try await JSObject.global.FaceDetector.function!.new(detectorOptions)

            // Create ImageData
            let imageDataJS = try createJSImageData(
                from: imageData.pixels,
                width: imageData.width,
                height: imageData.height
            )

            // Detect faces
            let promise = detector.detect!(imageDataJS)
            let results = try await JSPromise(promise.object!)!.value

            // Convert results to CIFaceFeature
            return convertFaceDetectorResults(results, imageHeight: imageData.height)
        } catch {
            return nil
        }
    }

    /// Converts FaceDetector API results to CIFaceFeature array.
    private func convertFaceDetectorResults(_ results: JSValue, imageHeight: Int) -> [CIFaceFeature] {
        var features: [CIFaceFeature] = []

        guard let length = results.length.number else {
            return features
        }

        for i in 0..<Int(length) {
            guard let face = results[i].object else { continue }

            // Get bounding box
            guard let boundingBox = face.boundingBox.object else { continue }
            let x = boundingBox.x.number ?? 0
            let y = boundingBox.y.number ?? 0
            let width = boundingBox.width.number ?? 0
            let height = boundingBox.height.number ?? 0

            // Convert to Core Image coordinate system (flip Y)
            let bounds = CGRect(
                x: CGFloat(x),
                y: CGFloat(Double(imageHeight) - y - height),
                width: CGFloat(width),
                height: CGFloat(height)
            )

            let feature = CIFaceFeature(bounds: bounds)

            // Extract landmarks if available
            if let landmarks = face.landmarks.array {
                extractFaceLandmarks(feature: feature, landmarks: Array(landmarks), imageHeight: imageHeight)
            }

            features.append(feature)
        }

        return features
    }

    /// Extracts facial landmarks from FaceDetector results.
    private func extractFaceLandmarks(feature: CIFaceFeature, landmarks: [JSValue], imageHeight: Int) {
        for landmark in landmarks {
            guard let type = landmark.type.string,
                  let locations = landmark.locations.array,
                  !locations.isEmpty else { continue }

            // Get the first location for simplicity
            guard let location = locations[0].object else { continue }
            let x = location.x.number ?? 0
            let y = location.y.number ?? 0

            // Convert to Core Image coordinate system
            let point = CGPoint(x: CGFloat(x), y: CGFloat(Double(imageHeight) - y))

            // FaceDetector API landmark types: "leftEye", "rightEye", "mouth", "nose"
            switch type {
            case "leftEye":
                feature.setLeftEyePosition(point, hasLeftEye: true)
            case "rightEye":
                feature.setRightEyePosition(point, hasRightEye: true)
            case "mouth":
                feature.setMouthPosition(point, hasMouth: true)
            default:
                break
            }
        }
    }

    // MARK: - Browser API: Barcode Detection

    /// Detects barcodes using browser's BarcodeDetector API.
    ///
    /// - Parameters:
    ///   - image: The source image
    ///   - options: Detection options
    /// - Returns: Array of QR code features, or nil if API is not available
    private func detectBarcodesWithBrowserAPI(in image: CIImage, options: [String: Any]?) async -> [CIFeature]? {
        // Check if BarcodeDetector API is available
        guard JSObject.global.BarcodeDetector.function != nil else {
            return nil
        }

        do {
            // Get image data (uses async version for filter chain support)
            guard let imageData = await getImageDataForBrowserAPIAsync(from: image) else {
                return nil
            }

            // Create BarcodeDetector for QR codes
            let detectorOptions = JSObject.global.Object.function!.new()
            let formats = JSObject.global.Array.function!.new()
            _ = formats.push!("qr_code")
            detectorOptions.formats = formats.jsValue

            let detector = try await JSObject.global.BarcodeDetector.function!.new(detectorOptions)

            // Create ImageData
            let imageDataJS = try createJSImageData(
                from: imageData.pixels,
                width: imageData.width,
                height: imageData.height
            )

            // Detect barcodes
            let promise = detector.detect!(imageDataJS)
            let results = try await JSPromise(promise.object!)!.value

            // Convert results to CIQRCodeFeature
            return convertBarcodeDetectorResults(results, imageHeight: imageData.height)
        } catch {
            return nil
        }
    }

    /// Converts BarcodeDetector API results to CIQRCodeFeature array.
    private func convertBarcodeDetectorResults(_ results: JSValue, imageHeight: Int) -> [CIQRCodeFeature] {
        var features: [CIQRCodeFeature] = []

        guard let length = results.length.number else {
            return features
        }

        for i in 0..<Int(length) {
            guard let barcode = results[i].object else { continue }

            // Get bounding box
            guard let boundingBox = barcode.boundingBox.object else { continue }
            let x = boundingBox.x.number ?? 0
            let y = boundingBox.y.number ?? 0
            let width = boundingBox.width.number ?? 0
            let height = boundingBox.height.number ?? 0

            // Convert to Core Image coordinate system (flip Y)
            let flippedY = Double(imageHeight) - y - height

            let bounds = CGRect(
                x: CGFloat(x),
                y: CGFloat(flippedY),
                width: CGFloat(width),
                height: CGFloat(height)
            )

            // Calculate corner points
            let topLeft = CGPoint(x: CGFloat(x), y: CGFloat(flippedY + height))
            let topRight = CGPoint(x: CGFloat(x + width), y: CGFloat(flippedY + height))
            let bottomLeft = CGPoint(x: CGFloat(x), y: CGFloat(flippedY))
            let bottomRight = CGPoint(x: CGFloat(x + width), y: CGFloat(flippedY))

            // Get decoded message
            let messageString = barcode.rawValue.string

            let feature = CIQRCodeFeature(
                bounds: bounds,
                topLeft: topLeft,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight,
                messageString: messageString,
                symbolDescriptor: nil
            )
            features.append(feature)
        }

        return features
    }

    // MARK: - Helper Types

    /// Image data for browser API calls.
    private struct BrowserImageData {
        let pixels: [UInt8]
        let width: Int
        let height: Int
    }

    // MARK: - Helper Methods

    /// Extracts image data for use with browser APIs (synchronous version).
    ///
    /// - Important: This method only works for images without filter chains.
    ///   For images with filters, use `getImageDataForBrowserAPIAsync` instead.
    private func getImageDataForBrowserAPI(from image: CIImage) -> BrowserImageData? {
        let ctx = context ?? CIContext()
        let extent = image.extent

        guard !extent.isInfinite else { return nil }

        let width = Int(extent.width)
        let height = Int(extent.height)

        guard width > 0 && height > 0 else { return nil }

        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        ctx.render(
            image,
            toBitmap: &pixelData,
            rowBytes: width * 4,
            bounds: extent,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )

        // Check if the data is all zeros (sync render failed)
        let hasNonZeroData = pixelData.contains { $0 != 0 }
        guard hasNonZeroData else { return nil }

        return BrowserImageData(pixels: pixelData, width: width, height: height)
    }

    /// Extracts image data for use with browser APIs (asynchronous version).
    ///
    /// This method supports images with filter chains by using GPU rendering.
    private func getImageDataForBrowserAPIAsync(from image: CIImage) async -> BrowserImageData? {
        // First try synchronous method (faster for simple images)
        if let syncResult = getImageDataForBrowserAPI(from: image) {
            return syncResult
        }

        // Fall back to async rendering for filter chains
        let ctx = context ?? CIContext()
        let extent = image.extent

        guard !extent.isInfinite else { return nil }

        let width = Int(extent.width)
        let height = Int(extent.height)

        guard width > 0 && height > 0 else { return nil }

        do {
            // Use async rendering to handle filter chains
            let cgImage = try await ctx.createCGImageAsync(image, from: extent, format: .RGBA8, colorSpace: nil)

            // Extract pixel data from CGImage
            guard let pixelData = extractPixelDataFromCGImage(cgImage, width: width, height: height) else {
                return nil
            }

            return BrowserImageData(pixels: pixelData, width: width, height: height)
        } catch {
            return nil
        }
    }

    /// Extracts pixel data from a CGImage.
    private func extractPixelDataFromCGImage(_ cgImage: CGImage, width: Int, height: Int) -> [UInt8]? {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }

        guard let cgContext = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        return pixelData
    }

    /// Creates a JavaScript ImageData object from pixel data.
    private func createJSImageData(from pixels: [UInt8], width: Int, height: Int) throws -> JSValue {
        // Create Uint8ClampedArray efficiently using typed array
        // First create an ArrayBuffer, then create Uint8ClampedArray from it
        let arrayBuffer = JSObject.global.ArrayBuffer.function!.new(pixels.count)
        let uint8View = JSObject.global.Uint8Array.function!.new(arrayBuffer)

        // Copy data in chunks for better performance
        let chunkSize = 65536  // 64KB chunks
        for chunkStart in stride(from: 0, to: pixels.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, pixels.count)
            for i in chunkStart..<chunkEnd {
                uint8View[i] = .number(Double(pixels[i]))
            }
        }

        // Create Uint8ClampedArray from the same buffer
        let uint8ClampedArray = JSObject.global.Uint8ClampedArray.function!.new(arrayBuffer)

        // Create ImageData
        let imageData = JSObject.global.ImageData.function!.new(
            uint8ClampedArray,
            width,
            height
        )

        return imageData.jsValue
    }
}

#endif // arch(wasm32)
