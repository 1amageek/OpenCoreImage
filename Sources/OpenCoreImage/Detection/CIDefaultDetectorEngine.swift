//
//  CIDefaultDetectorEngine.swift
//  OpenCoreImage
//
//  Pure Swift implementation of detector engine for all platforms.
//

import Foundation

/// Pure Swift implementation of the detector engine.
///
/// This engine uses CPU-based algorithms for all detection types and works
/// on all platforms. It provides the fallback implementation when browser
/// APIs are not available.
internal final class CIDefaultDetectorEngine: CIDetectorEngine, @unchecked Sendable {

    // MARK: - Properties

    private let context: CIContext?
    private let options: [String: Any]
    private let analyzer: ImageAnalyzer

    // Detection parameters
    private let minFeatureSize: Float
    private let maxFeatureCount: Int

    // MARK: - Initialization

    /// Creates a default detector engine.
    ///
    /// - Parameters:
    ///   - context: Optional CIContext for rendering
    ///   - options: Detector configuration options
    init(context: CIContext?, options: [String: Any]?) {
        self.context = context
        self.options = options ?? [:]
        self.analyzer = ImageAnalyzer(context: context)

        // Parse options
        self.minFeatureSize = (options?[CIDetectorMinFeatureSize] as? Float) ?? 0.0
        self.maxFeatureCount = (options?[CIDetectorMaxFeatureCount] as? Int) ?? 10
    }

    // MARK: - CIDetectorEngine Protocol

    /// Synchronous feature detection.
    func detectFeatures(type: String, in image: CIImage, options: [String: Any]?) -> [CIFeature] {
        let extent = image.extent
        guard !extent.isInfinite && extent.width > 0 && extent.height > 0 else {
            return []
        }

        switch type {
        case CIDetectorTypeFace:
            return FaceDetectionAlgorithm.detect(
                in: image,
                using: analyzer,
                options: options,
                minFeatureSize: minFeatureSize,
                maxFeatureCount: maxFeatureCount
            )

        case CIDetectorTypeRectangle:
            return RectangleDetectionAlgorithm.detect(
                in: image,
                using: analyzer,
                options: options,
                minFeatureSize: minFeatureSize,
                maxFeatureCount: maxFeatureCount
            )

        case CIDetectorTypeQRCode:
            return QRCodeDetectionAlgorithm.detect(
                in: image,
                using: analyzer,
                options: options,
                minFeatureSize: minFeatureSize,
                maxFeatureCount: maxFeatureCount
            )

        case CIDetectorTypeText:
            return TextDetectionAlgorithm.detect(
                in: image,
                using: analyzer,
                options: options,
                minFeatureSize: minFeatureSize,
                maxFeatureCount: maxFeatureCount
            )

        default:
            return []
        }
    }

    /// Asynchronous feature detection.
    ///
    /// For the default engine, this simply calls the synchronous implementation
    /// since all algorithms are CPU-based.
    func detectFeaturesAsync(type: String, in image: CIImage, options: [String: Any]?) async -> [CIFeature] {
        // Pure Swift implementation - same as synchronous
        detectFeatures(type: type, in: image, options: options)
    }
}
