//
//  DetectionAlgorithmTests.swift
//  OpenCoreImage
//
//  Tests for detection algorithms and image analyzer.
//

import Testing
import Foundation
@testable import OpenCoreImage

// MARK: - ImageAnalyzer Tests

@Suite("ImageAnalyzer")
struct ImageAnalyzerTests {

    @Test("Analyzer can be initialized")
    func analyzerInitialization() {
        let analyzer = ImageAnalyzer(context: nil)
        // Should not throw
        _ = analyzer
    }

    @Test("RGB to YCbCr conversion")
    func rgbToYCbCrConversion() {
        let analyzer = ImageAnalyzer(context: nil)

        // Test pure red
        let (y, cb, cr) = analyzer.rgbToYCbCr(r: 255, g: 0, b: 0)
        #expect(y > 50 && y < 100)  // Red has medium luminance
        #expect(cr > 200)  // Red has high Cr

        // Test pure white
        let (yW, cbW, crW) = analyzer.rgbToYCbCr(r: 255, g: 255, b: 255)
        #expect(yW > 250)  // White has high luminance
        #expect(abs(cbW - 128) < 5)  // Neutral chrominance
        #expect(abs(crW - 128) < 5)  // Neutral chrominance
    }

    @Test("Skin color detection")
    func skinColorDetection() {
        let analyzer = ImageAnalyzer(context: nil)

        // Typical skin tone in RGB (approximately)
        let (y, cb, cr) = analyzer.rgbToYCbCr(r: 220, g: 180, b: 160)
        let isSkin = analyzer.isSkinColor(y: y, cb: cb, cr: cr)
        #expect(isSkin)

        // Pure blue should not be skin
        let (yB, cbB, crB) = analyzer.rgbToYCbCr(r: 0, g: 0, b: 255)
        let isSkinBlue = analyzer.isSkinColor(y: yB, cb: cbB, cr: crB)
        #expect(!isSkinBlue)
    }

    @Test("Grayscale conversion")
    func grayscaleConversion() {
        let analyzer = ImageAnalyzer(context: nil)

        // Pure white should be close to 255 (may vary due to integer arithmetic)
        let white = analyzer.toGrayscale(r: 255, g: 255, b: 255)
        #expect(white >= 254 && white <= 255)

        // Pure black should be 0
        let black = analyzer.toGrayscale(r: 0, g: 0, b: 0)
        #expect(black == 0)

        // Gray should be in the middle
        let gray = analyzer.toGrayscale(r: 128, g: 128, b: 128)
        #expect(gray >= 127 && gray <= 129)
    }

    @Test("Find connected components in simple mask")
    func findConnectedComponentsSimple() {
        let analyzer = ImageAnalyzer(context: nil)

        // Create a 5x5 mask with one 3x3 component in the center
        var mask = [Bool](repeating: false, count: 25)
        for y in 1...3 {
            for x in 1...3 {
                mask[y * 5 + x] = true
            }
        }

        let components = analyzer.findConnectedComponents(mask: mask, width: 5, height: 5)
        #expect(components.count == 1)
        #expect(components[0].pixelCount == 9)
        #expect(components[0].width == 3)  // maxX - minX + 1 (inclusive)
        #expect(components[0].height == 3)  // maxY - minY + 1 (inclusive)
    }

    @Test("Find multiple connected components")
    func findMultipleConnectedComponents() {
        let analyzer = ImageAnalyzer(context: nil)

        // Create a 10x10 mask with two separate components
        var mask = [Bool](repeating: false, count: 100)

        // First component in top-left
        mask[0] = true
        mask[1] = true
        mask[10] = true
        mask[11] = true

        // Second component in bottom-right
        mask[88] = true
        mask[89] = true
        mask[98] = true
        mask[99] = true

        let components = analyzer.findConnectedComponents(mask: mask, width: 10, height: 10)
        #expect(components.count == 2)
    }

    @Test("Sobel edge detection on uniform image")
    func sobelEdgeDetectionUniform() {
        let analyzer = ImageAnalyzer(context: nil)

        // Create a uniform gray image (no edges)
        var pixelData = [UInt8](repeating: 128, count: 100 * 100 * 4)
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            pixelData[i] = 128      // R
            pixelData[i + 1] = 128  // G
            pixelData[i + 2] = 128  // B
            pixelData[i + 3] = 255  // A
        }

        let edges = analyzer.applySobelEdgeDetection(pixelData: pixelData, width: 100, height: 100)

        // Sum all edge magnitudes (should be very low for uniform image)
        let edgeSum = edges.reduce(0) { $0 + Int($1) }
        #expect(edgeSum < 1000)  // Low edge response for uniform image
    }

    @Test("Binarize image creates mask")
    func binarizeImage() {
        let analyzer = ImageAnalyzer(context: nil)

        // Create image with left half dark, right half light
        var pixelData = [UInt8](repeating: 0, count: 10 * 10 * 4)
        for y in 0..<10 {
            for x in 0..<10 {
                let index = (y * 10 + x) * 4
                let value: UInt8 = x < 5 ? 50 : 200
                pixelData[index] = value
                pixelData[index + 1] = value
                pixelData[index + 2] = value
                pixelData[index + 3] = 255
            }
        }

        let binary = analyzer.binarizeImage(pixelData: pixelData, width: 10, height: 10)

        // Left half should be dark (true in binary), right half should be light (false)
        for y in 0..<10 {
            for x in 0..<10 {
                if x < 5 {
                    #expect(binary[y * 10 + x] == true)
                } else {
                    #expect(binary[y * 10 + x] == false)
                }
            }
        }
    }

    @Test("Morphological dilation expands regions")
    func morphologicalDilation() {
        let analyzer = ImageAnalyzer(context: nil)

        // Create 10x10 edge image with single bright pixel in center
        var edges = [UInt8](repeating: 0, count: 100)
        edges[44] = 255  // Center-ish

        let dilated = analyzer.morphologicalDilate(edges: edges, width: 10, height: 10, kernelSize: 3)

        // The bright pixel should expand to neighbors
        #expect(dilated[44] == 255)  // Original
        #expect(dilated[33] == 255)  // Upper-left
        #expect(dilated[45] == 255)  // Right
        #expect(dilated[54] == 255)  // Below
    }

    @Test("Approximate to quadrilateral from contour")
    func approximateToQuadrilateral() {
        let analyzer = ImageAnalyzer(context: nil)

        // Create a simple rectangular contour with corners at (10,10), (40,10), (10,30), (40,30)
        // Width = 30, Height = 20 (both > 10 as required by algorithm)
        var points: [(x: Int, y: Int)] = []

        // Add points along the perimeter to form a rectangle
        // Top edge
        for x in 10...40 {
            points.append((x: x, y: 10))
        }
        // Right edge
        for y in 11...30 {
            points.append((x: 40, y: y))
        }
        // Bottom edge
        for x in stride(from: 39, through: 10, by: -1) {
            points.append((x: x, y: 30))
        }
        // Left edge
        for y in stride(from: 29, through: 11, by: -1) {
            points.append((x: 10, y: y))
        }

        let contour = ImageAnalyzer.Contour(points: points)
        let quad = analyzer.approximateToQuadrilateral(contour: contour)

        #expect(quad != nil)
        if let quad = quad {
            // The algorithm finds corners closest to bounding box corners
            #expect(quad.topLeft.x == 10)
            #expect(quad.topLeft.y == 10)
            #expect(quad.topRight.x == 40)
            #expect(quad.topRight.y == 10)
            #expect(quad.bottomLeft.x == 10)
            #expect(quad.bottomLeft.y == 30)
            #expect(quad.bottomRight.x == 40)
            #expect(quad.bottomRight.y == 30)
        }
    }
}

// MARK: - CIDefaultDetectorEngine Tests

@Suite("CIDefaultDetectorEngine")
struct CIDefaultDetectorEngineTests {

    @Test("Engine can be initialized")
    func engineInitialization() {
        let engine = CIDefaultDetectorEngine(context: nil, options: nil)
        _ = engine  // Should not throw
    }

    @Test("Engine with options")
    func engineWithOptions() {
        let options: [String: Any] = [
            CIDetectorMinFeatureSize: 0.1,
            CIDetectorMaxFeatureCount: 5
        ]
        let engine = CIDefaultDetectorEngine(context: nil, options: options)
        _ = engine  // Should not throw
    }

    @Test("Detect features returns empty for infinite extent")
    func detectFeaturesInfiniteExtent() {
        let engine = CIDefaultDetectorEngine(context: nil, options: nil)
        let image = CIImage(color: .red)  // Infinite extent

        let features = engine.detectFeatures(type: CIDetectorTypeFace, in: image, options: nil)
        #expect(features.isEmpty)
    }

    @Test("Detect features returns empty for unknown type")
    func detectFeaturesUnknownType() {
        let engine = CIDefaultDetectorEngine(context: nil, options: nil)
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let features = engine.detectFeatures(type: "UnknownType", in: image, options: nil)
        #expect(features.isEmpty)
    }

    @Test("Async detection matches sync detection")
    func asyncMatchesSync() async {
        let engine = CIDefaultDetectorEngine(context: nil, options: nil)
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let syncFeatures = engine.detectFeatures(type: CIDetectorTypeFace, in: image, options: nil)
        let asyncFeatures = await engine.detectFeaturesAsync(type: CIDetectorTypeFace, in: image, options: nil)

        #expect(syncFeatures.count == asyncFeatures.count)
    }
}

// MARK: - Detection Algorithm Integration Tests

@Suite("Detection Algorithm Integration")
struct DetectionAlgorithmIntegrationTests {

    @Test("Face detection algorithm can be called")
    func faceDetectionAlgorithm() {
        let analyzer = ImageAnalyzer(context: nil)
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let features = FaceDetectionAlgorithm.detect(
            in: image,
            using: analyzer,
            options: nil,
            minFeatureSize: 0.0,
            maxFeatureCount: 10
        )

        // May or may not find faces in a solid red image
        #expect(features is [CIFaceFeature])
    }

    @Test("Rectangle detection algorithm can be called")
    func rectangleDetectionAlgorithm() {
        let analyzer = ImageAnalyzer(context: nil)
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let features = RectangleDetectionAlgorithm.detect(
            in: image,
            using: analyzer,
            options: nil,
            minFeatureSize: 0.0,
            maxFeatureCount: 10
        )

        #expect(features is [CIRectangleFeature])
    }

    @Test("QR code detection algorithm can be called")
    func qrCodeDetectionAlgorithm() {
        let analyzer = ImageAnalyzer(context: nil)
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let features = QRCodeDetectionAlgorithm.detect(
            in: image,
            using: analyzer,
            options: nil,
            minFeatureSize: 0.0,
            maxFeatureCount: 10
        )

        #expect(features is [CIQRCodeFeature])
    }

    @Test("Text detection algorithm can be called")
    func textDetectionAlgorithm() {
        let analyzer = ImageAnalyzer(context: nil)
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let features = TextDetectionAlgorithm.detect(
            in: image,
            using: analyzer,
            options: nil,
            minFeatureSize: 0.0,
            maxFeatureCount: 10
        )

        #expect(features is [CITextFeature])
    }
}

// MARK: - CIDetector Async API Tests

@Suite("CIDetector Async API")
struct CIDetectorAsyncAPITests {

    @Test("Async features returns same as sync for default engine")
    func asyncMatchesSyncFeatures() async {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)!
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let syncFeatures = detector.features(in: image)
        let asyncFeatures = await detector.featuresAsync(in: image)

        #expect(syncFeatures.count == asyncFeatures.count)
    }

    @Test("Async features with options")
    func asyncFeaturesWithOptions() async {
        let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: nil)!
        let image = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 50, height: 50))

        let features = await detector.featuresAsync(in: image, options: nil)
        #expect(features is [CIFeature])
    }
}

// MARK: - CIFeature Public API Tests

@Suite("CIFeature Public API")
struct CIFeaturePublicAPITests {

    @Test("CIFaceFeature bounds and type")
    func faceFeatureBoundsAndType() {
        let bounds = CGRect(x: 10, y: 20, width: 100, height: 100)
        let face = CIFaceFeature(bounds: bounds)

        #expect(face.bounds == bounds)
        #expect(face.type == CIFeatureTypeFace)
    }

    @Test("CIFaceFeature eye positions")
    func faceFeatureEyePositions() {
        let face = CIFaceFeature(bounds: .zero)

        #expect(face.hasLeftEyePosition == false)
        #expect(face.hasRightEyePosition == false)

        face.setLeftEyePosition(CGPoint(x: 30, y: 50), hasLeftEye: true)
        face.setRightEyePosition(CGPoint(x: 70, y: 50), hasRightEye: true)

        #expect(face.hasLeftEyePosition == true)
        #expect(face.hasRightEyePosition == true)
        #expect(face.leftEyePosition == CGPoint(x: 30, y: 50))
        #expect(face.rightEyePosition == CGPoint(x: 70, y: 50))
    }

    @Test("CIFaceFeature mouth position")
    func faceFeatureMouthPosition() {
        let face = CIFaceFeature(bounds: .zero)

        #expect(face.hasMouthPosition == false)

        face.setMouthPosition(CGPoint(x: 50, y: 30), hasMouth: true)

        #expect(face.hasMouthPosition == true)
        #expect(face.mouthPosition == CGPoint(x: 50, y: 30))
    }

    @Test("CIFaceFeature tracking")
    func faceFeatureTracking() {
        let face = CIFaceFeature(bounds: .zero)

        #expect(face.hasTrackingID == false)
        #expect(face.hasTrackingFrameCount == false)

        face.setTrackingID(42, hasTrackingID: true)
        face.setTrackingFrameCount(10, hasTrackingFrameCount: true)

        #expect(face.hasTrackingID == true)
        #expect(face.trackingID == 42)
        #expect(face.hasTrackingFrameCount == true)
        #expect(face.trackingFrameCount == 10)
    }

    @Test("CIRectangleFeature corners")
    func rectangleFeatureCorners() {
        let topLeft = CGPoint(x: 0, y: 100)
        let topRight = CGPoint(x: 100, y: 100)
        let bottomLeft = CGPoint(x: 0, y: 0)
        let bottomRight = CGPoint(x: 100, y: 0)

        let rect = CIRectangleFeature(
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
            topLeft: topLeft,
            topRight: topRight,
            bottomLeft: bottomLeft,
            bottomRight: bottomRight
        )

        #expect(rect.type == CIFeatureTypeRectangle)
        #expect(rect.topLeft == topLeft)
        #expect(rect.topRight == topRight)
        #expect(rect.bottomLeft == bottomLeft)
        #expect(rect.bottomRight == bottomRight)
    }

    @Test("CITextFeature corners and subFeatures")
    func textFeatureCorners() {
        let topLeft = CGPoint(x: 10, y: 40)
        let topRight = CGPoint(x: 100, y: 40)
        let bottomLeft = CGPoint(x: 10, y: 30)
        let bottomRight = CGPoint(x: 100, y: 30)

        let text = CITextFeature(
            bounds: CGRect(x: 10, y: 30, width: 90, height: 10),
            topLeft: topLeft,
            topRight: topRight,
            bottomLeft: bottomLeft,
            bottomRight: bottomRight
        )

        #expect(text.type == CIFeatureTypeText)
        #expect(text.topLeft == topLeft)
        #expect(text.subFeatures == nil)
    }

    @Test("CIQRCodeFeature message")
    func qrCodeFeatureMessage() {
        let qr = CIQRCodeFeature(
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
            topLeft: CGPoint(x: 0, y: 100),
            topRight: CGPoint(x: 100, y: 100),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 100, y: 0),
            messageString: "Hello World",
            symbolDescriptor: nil
        )

        #expect(qr.type == CIFeatureTypeQRCode)
        #expect(qr.messageString == "Hello World")
        #expect(qr.symbolDescriptor == nil)
    }
}
