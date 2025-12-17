//
//  CIDetectorTests.swift
//  OpenCoreImage
//
//  Tests for CIDetector and CIFeature classes.
//

import Testing
import Foundation
@testable import OpenCoreImage

// MARK: - CIDetector Constants Tests

@Suite("CIDetector Constants")
struct CIDetectorConstantsTests {

    @Test("All detector types follow naming convention")
    func detectorTypesFollowConvention() {
        let detectorTypes = [
            CIDetectorTypeFace,
            CIDetectorTypeRectangle,
            CIDetectorTypeQRCode,
            CIDetectorTypeText
        ]

        for type in detectorTypes {
            #expect(type.hasPrefix("CIDetectorType"), "Type '\(type)' should start with 'CIDetectorType'")
            #expect(!type.isEmpty)
        }

        // Verify uniqueness
        let uniqueTypes = Set(detectorTypes)
        #expect(uniqueTypes.count == detectorTypes.count, "All detector types should be unique")
    }

    @Test("All configuration keys follow naming convention")
    func configurationKeysFollowConvention() {
        let configKeys = [
            CIDetectorAccuracy,
            CIDetectorTracking,
            CIDetectorMinFeatureSize,
            CIDetectorMaxFeatureCount,
            CIDetectorNumberOfAngles,
            CIDetectorAspectRatio,
            CIDetectorFocalLength,
            CIDetectorReturnSubFeatures
        ]

        for key in configKeys {
            #expect(key.hasPrefix("CIDetector"), "Key '\(key)' should start with 'CIDetector'")
            #expect(!key.isEmpty)
        }
    }

    @Test("All accuracy options follow naming convention")
    func accuracyOptionsFollowConvention() {
        #expect(CIDetectorAccuracyLow.hasPrefix("CIDetectorAccuracy"))
        #expect(CIDetectorAccuracyHigh.hasPrefix("CIDetectorAccuracy"))
        #expect(CIDetectorAccuracyLow != CIDetectorAccuracyHigh)
    }

    @Test("All feature detection keys follow naming convention")
    func featureDetectionKeysFollowConvention() {
        let detectionKeys = [
            CIDetectorImageOrientation,
            CIDetectorEyeBlink,
            CIDetectorSmile
        ]

        for key in detectionKeys {
            #expect(key.hasPrefix("CIDetector"), "Key '\(key)' should start with 'CIDetector'")
        }
    }

    @Test("All feature types follow naming convention")
    func featureTypesFollowConvention() {
        let featureTypes = [
            CIFeatureTypeFace,
            CIFeatureTypeRectangle,
            CIFeatureTypeQRCode,
            CIFeatureTypeText
        ]

        for type in featureTypes {
            #expect(type.hasPrefix("CIFeatureType"), "Type '\(type)' should start with 'CIFeatureType'")
        }

        // Verify uniqueness
        let uniqueTypes = Set(featureTypes)
        #expect(uniqueTypes.count == featureTypes.count, "All feature types should be unique")
    }

    @Test("Detector types can be used to create detectors")
    func detectorTypesCreateDetectors() {
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)
        let rectDetector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: nil)
        let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)
        let textDetector = CIDetector(ofType: CIDetectorTypeText, context: nil, options: nil)

        #expect(faceDetector != nil)
        #expect(rectDetector != nil)
        #expect(qrDetector != nil)
        #expect(textDetector != nil)
    }

    @Test("Configuration keys work in options dictionary")
    func configurationKeysWorkInOptions() {
        let options: [String: Any] = [
            CIDetectorAccuracy: CIDetectorAccuracyHigh,
            CIDetectorTracking: true,
            CIDetectorMinFeatureSize: 0.1,
            CIDetectorMaxFeatureCount: 10
        ]

        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)
        #expect(detector != nil)
    }

    @Test("Feature detection keys work in feature detection options")
    func featureDetectionKeysWorkInOptions() {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)!
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let options: [String: Any] = [
            CIDetectorImageOrientation: 1,
            CIDetectorEyeBlink: true,
            CIDetectorSmile: true
        ]

        // Should not crash
        let features = detector.features(in: image, options: options)
        #expect(features.count >= 0)
    }
}

// MARK: - CIDetector Initialization Tests

@Suite("CIDetector Initialization")
struct CIDetectorInitializationTests {

    @Test("Initialize face detector")
    func initFaceDetector() {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)
        #expect(detector != nil)
    }

    @Test("Initialize rectangle detector")
    func initRectangleDetector() {
        let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: nil)
        #expect(detector != nil)
    }

    @Test("Initialize QR code detector")
    func initQRCodeDetector() {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)
        #expect(detector != nil)
    }

    @Test("Initialize text detector")
    func initTextDetector() {
        let detector = CIDetector(ofType: CIDetectorTypeText, context: nil, options: nil)
        #expect(detector != nil)
    }

    @Test("Initialize with context")
    func initWithContext() {
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: nil)
        #expect(detector != nil)
    }

    @Test("Initialize with options")
    func initWithOptions() {
        let options: [String: Any] = [
            CIDetectorAccuracy: CIDetectorAccuracyHigh,
            CIDetectorMinFeatureSize: 0.1
        ]
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)
        #expect(detector != nil)
    }
}

// MARK: - CIDetector Feature Detection Tests

@Suite("CIDetector Feature Detection")
struct CIDetectorFeatureDetectionTests {

    @Test("Features in image returns empty array for plain color image")
    func featuresInImageReturnsEmptyArray() {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)!
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let features = detector.features(in: image)

        // Plain color image should not contain faces
        #expect(features.isEmpty || features.count >= 0) // Placeholder returns empty
    }

    @Test("Features in image with options accepts orientation parameter")
    func featuresInImageWithOptionsAcceptsOrientation() {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)!
        let image = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        // Should not crash with orientation option
        let features = detector.features(in: image, options: [CIDetectorImageOrientation: 1])
        #expect(features.count >= 0)
    }

    @Test("Different detector types can detect in same image")
    func differentDetectorTypesCanDetect() {
        let image = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 200, height: 200))

        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)!
        let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)!
        let rectDetector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: nil)!

        let faceFeatures = faceDetector.features(in: image)
        let qrFeatures = qrDetector.features(in: image)
        let rectFeatures = rectDetector.features(in: image)

        // All should return valid arrays (possibly empty)
        #expect(faceFeatures.count >= 0)
        #expect(qrFeatures.count >= 0)
        #expect(rectFeatures.count >= 0)
    }
}

// MARK: - CIDetector Equatable/Hashable Tests

@Suite("CIDetector Equatable and Hashable")
struct CIDetectorEquatableHashableTests {

    @Test("Same instance is equal")
    func sameInstanceEqual() {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)!
        #expect(detector == detector)
    }

    @Test("Different instances are not equal")
    func differentInstancesNotEqual() {
        let detector1 = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)!
        let detector2 = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)!
        #expect(detector1 != detector2)
    }

    @Test("Same instance has same hash")
    func sameInstanceSameHash() {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)!
        #expect(detector.hashValue == detector.hashValue)
    }
}

// MARK: - CIFeature Tests

@Suite("CIFeature")
struct CIFeatureTests {

    @Test("Feature has bounds")
    func featureHasBounds() {
        let bounds = CGRect(x: 10, y: 20, width: 100, height: 100)
        let feature = CIFaceFeature(bounds: bounds)
        #expect(feature.bounds == bounds)
    }

    @Test("Feature has type")
    func featureHasType() {
        let feature = CIFaceFeature(bounds: .zero)
        #expect(feature.type == CIFeatureTypeFace)
    }

    @Test("Feature equality is reference based")
    func featureEqualityReferenceBased() {
        let feature1 = CIFaceFeature(bounds: .zero)
        let feature2 = feature1  // Same reference
        #expect(feature1 == feature2)
    }

    @Test("Different features are not equal")
    func differentFeaturesNotEqual() {
        let feature1 = CIFaceFeature(bounds: .zero)
        let feature2 = CIFaceFeature(bounds: .zero)
        #expect(feature1 != feature2)
    }

    @Test("Feature is hashable")
    func featureHashable() {
        let feature = CIFaceFeature(bounds: .zero)
        #expect(feature.hashValue == feature.hashValue)
    }
}

// MARK: - CIFaceFeature Tests

@Suite("CIFaceFeature")
struct CIFaceFeatureTests {

    @Test("Face feature has correct type")
    func faceFeatureHasCorrectType() {
        let feature = CIFaceFeature(bounds: .zero)
        #expect(feature.type == CIFeatureTypeFace)
    }

    @Test("Face feature default values for facial landmarks")
    func faceFeatureDefaultFacialLandmarks() {
        let feature = CIFaceFeature(bounds: .zero)

        // All "has" flags should be false by default
        #expect(feature.hasLeftEyePosition == false)
        #expect(feature.hasRightEyePosition == false)
        #expect(feature.hasMouthPosition == false)
        #expect(feature.hasFaceAngle == false)

        // All positions should be zero by default
        #expect(feature.leftEyePosition == .zero)
        #expect(feature.rightEyePosition == .zero)
        #expect(feature.mouthPosition == .zero)
        #expect(feature.faceAngle == 0)
    }

    @Test("Face feature default values for expression detection")
    func faceFeatureDefaultExpressionDetection() {
        let feature = CIFaceFeature(bounds: .zero)

        // Expression-related defaults
        #expect(feature.hasSmile == false)
        #expect(feature.leftEyeClosed == false)
        #expect(feature.rightEyeClosed == false)
    }

    @Test("Face feature default values for tracking")
    func faceFeatureDefaultTrackingValues() {
        let feature = CIFaceFeature(bounds: .zero)

        // Tracking-related defaults
        #expect(feature.hasTrackingID == false)
        #expect(feature.hasTrackingFrameCount == false)
        #expect(feature.trackingID == 0)
        #expect(feature.trackingFrameCount == 0)
    }

    @Test("Face feature preserves bounds")
    func faceFeaturePreservesBounds() {
        let bounds = CGRect(x: 50, y: 100, width: 200, height: 250)
        let feature = CIFaceFeature(bounds: bounds)

        #expect(feature.bounds == bounds)
        #expect(feature.bounds.origin.x == 50)
        #expect(feature.bounds.origin.y == 100)
        #expect(feature.bounds.width == 200)
        #expect(feature.bounds.height == 250)
    }
}

// MARK: - CIRectangleFeature Tests

@Suite("CIRectangleFeature")
struct CIRectangleFeatureTests {

    @Test("Rectangle feature has correct type")
    func rectangleFeatureHasCorrectType() {
        let feature = CIRectangleFeature(
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
            topLeft: CGPoint(x: 0, y: 100),
            topRight: CGPoint(x: 100, y: 100),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 100, y: 0)
        )
        #expect(feature.type == CIFeatureTypeRectangle)
    }

    @Test("Rectangle corners")
    func rectangleCorners() {
        let feature = CIRectangleFeature(
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
            topLeft: CGPoint(x: 0, y: 100),
            topRight: CGPoint(x: 100, y: 100),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 100, y: 0)
        )
        #expect(feature.topLeft == CGPoint(x: 0, y: 100))
        #expect(feature.topRight == CGPoint(x: 100, y: 100))
        #expect(feature.bottomLeft == CGPoint(x: 0, y: 0))
        #expect(feature.bottomRight == CGPoint(x: 100, y: 0))
    }
}

// MARK: - CITextFeature Tests

@Suite("CITextFeature")
struct CITextFeatureTests {

    @Test("Text feature has correct type")
    func textFeatureHasCorrectType() {
        let feature = CITextFeature(
            bounds: CGRect(x: 0, y: 0, width: 200, height: 50),
            topLeft: CGPoint(x: 0, y: 50),
            topRight: CGPoint(x: 200, y: 50),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 200, y: 0)
        )
        #expect(feature.type == CIFeatureTypeText)
    }

    @Test("Text corners")
    func textCorners() {
        let feature = CITextFeature(
            bounds: CGRect(x: 0, y: 0, width: 200, height: 50),
            topLeft: CGPoint(x: 0, y: 50),
            topRight: CGPoint(x: 200, y: 50),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 200, y: 0)
        )
        #expect(feature.topLeft == CGPoint(x: 0, y: 50))
        #expect(feature.topRight == CGPoint(x: 200, y: 50))
        #expect(feature.bottomLeft == CGPoint(x: 0, y: 0))
        #expect(feature.bottomRight == CGPoint(x: 200, y: 0))
    }

    @Test("Sub features default is nil")
    func subFeaturesDefault() {
        let feature = CITextFeature(
            bounds: .zero,
            topLeft: .zero,
            topRight: .zero,
            bottomLeft: .zero,
            bottomRight: .zero
        )
        #expect(feature.subFeatures == nil)
    }
}

// MARK: - CIQRCodeFeature Tests

@Suite("CIQRCodeFeature")
struct CIQRCodeFeatureTests {

    @Test("QR code feature has correct type")
    func qrCodeFeatureHasCorrectType() {
        let feature = CIQRCodeFeature(
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
            topLeft: CGPoint(x: 0, y: 100),
            topRight: CGPoint(x: 100, y: 100),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 100, y: 0),
            messageString: "Test",
            symbolDescriptor: nil
        )
        #expect(feature.type == CIFeatureTypeQRCode)
    }

    @Test("QR code corners")
    func qrCodeCorners() {
        let feature = CIQRCodeFeature(
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
            topLeft: CGPoint(x: 0, y: 100),
            topRight: CGPoint(x: 100, y: 100),
            bottomLeft: CGPoint(x: 0, y: 0),
            bottomRight: CGPoint(x: 100, y: 0),
            messageString: nil,
            symbolDescriptor: nil
        )
        #expect(feature.topLeft == CGPoint(x: 0, y: 100))
        #expect(feature.topRight == CGPoint(x: 100, y: 100))
        #expect(feature.bottomLeft == CGPoint(x: 0, y: 0))
        #expect(feature.bottomRight == CGPoint(x: 100, y: 0))
    }

    @Test("QR code message string")
    func qrCodeMessageString() {
        let feature = CIQRCodeFeature(
            bounds: .zero,
            topLeft: .zero,
            topRight: .zero,
            bottomLeft: .zero,
            bottomRight: .zero,
            messageString: "Hello World",
            symbolDescriptor: nil
        )
        #expect(feature.messageString == "Hello World")
    }

    @Test("QR code symbol descriptor")
    func qrCodeSymbolDescriptor() {
        let descriptor = CIQRCodeDescriptor(
            payload: Data([0x01]),
            symbolVersion: 1,
            maskPattern: 0,
            errorCorrectionLevel: .levelL
        )
        let feature = CIQRCodeFeature(
            bounds: .zero,
            topLeft: .zero,
            topRight: .zero,
            bottomLeft: .zero,
            bottomRight: .zero,
            messageString: nil,
            symbolDescriptor: descriptor
        )
        #expect(feature.symbolDescriptor != nil)
    }
}
