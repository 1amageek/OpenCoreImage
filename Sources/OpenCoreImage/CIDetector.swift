//
//  CIDetector.swift
//  OpenCoreImage
//
//  Image feature detection using the detector engine pattern.
//

import Foundation

// MARK: - Detector Type Constants

/// A Core Image detector type for detecting faces.
public let CIDetectorTypeFace: String = "CIDetectorTypeFace"

/// A Core Image detector type for detecting rectangles.
public let CIDetectorTypeRectangle: String = "CIDetectorTypeRectangle"

/// A Core Image detector type for detecting QR codes.
public let CIDetectorTypeQRCode: String = "CIDetectorTypeQRCode"

/// A Core Image detector type for detecting text.
public let CIDetectorTypeText: String = "CIDetectorTypeText"

// MARK: - Detector Configuration Keys

/// A key used to specify detector accuracy.
public let CIDetectorAccuracy: String = "CIDetectorAccuracy"

/// A key used to specify tracking.
public let CIDetectorTracking: String = "CIDetectorTracking"

/// A key used to specify minimum feature size.
public let CIDetectorMinFeatureSize: String = "CIDetectorMinFeatureSize"

/// A key used to specify maximum feature count.
public let CIDetectorMaxFeatureCount: String = "CIDetectorMaxFeatureCount"

/// A key used to specify the number of angles.
public let CIDetectorNumberOfAngles: String = "CIDetectorNumberOfAngles"

/// A key used to specify aspect ratio.
public let CIDetectorAspectRatio: String = "CIDetectorAspectRatio"

/// A key used to specify focal length.
public let CIDetectorFocalLength: String = "CIDetectorFocalLength"

/// A key used to specify return sub-features.
public let CIDetectorReturnSubFeatures: String = "CIDetectorReturnSubFeatures"

// MARK: - Detector Accuracy Options

/// Indicates that the detector should use low accuracy.
public let CIDetectorAccuracyLow: String = "CIDetectorAccuracyLow"

/// Indicates that the detector should use high accuracy.
public let CIDetectorAccuracyHigh: String = "CIDetectorAccuracyHigh"

// MARK: - Feature Detection Keys

/// A key used to specify image orientation.
public let CIDetectorImageOrientation: String = "CIDetectorImageOrientation"

/// A key used to enable eye blink detection.
public let CIDetectorEyeBlink: String = "CIDetectorEyeBlink"

/// A key used to enable smile detection.
public let CIDetectorSmile: String = "CIDetectorSmile"

// MARK: - Supported Detector Types

/// Array of all supported detector types.
private let supportedDetectorTypes: [String] = [
    CIDetectorTypeFace,
    CIDetectorTypeRectangle,
    CIDetectorTypeQRCode,
    CIDetectorTypeText
]

// MARK: - CIDetector

/// An image processor that identifies notable features, such as faces and barcodes,
/// in a still image or video.
///
/// A `CIDetector` object uses image processing to search for and identify notable features
/// (faces, rectangles, and barcodes) in a still image or video. Detected features are
/// represented by `CIFeature` objects that provide more information about each feature.
///
/// This class can maintain many state variables that can impact performance. So for best
/// performance, reuse `CIDetector` instances instead of creating new ones.
///
/// ## Architecture
///
/// CIDetector uses the Renderer Delegate pattern with platform-specific engines:
/// - `CIDefaultDetectorEngine`: Pure Swift implementation for all platforms
/// - `CIWebAPIDetectorEngine`: WASM-specific implementation using browser APIs
///
/// ## Synchronous vs Asynchronous API
///
/// - `features(in:options:)`: Synchronous API, always uses pure Swift implementation
/// - `featuresAsync(in:options:)`: Asynchronous API, uses browser APIs when available
public final class CIDetector: @unchecked Sendable {

    // MARK: - Private Storage

    private let _type: String
    private let engine: CIDetectorEngine

    // MARK: - Initialization

    /// Creates and returns a configured detector.
    ///
    /// - Parameters:
    ///   - type: The type of feature to detect. Must be one of:
    ///     - `CIDetectorTypeFace`
    ///     - `CIDetectorTypeRectangle`
    ///     - `CIDetectorTypeQRCode`
    ///     - `CIDetectorTypeText`
    ///   - context: A Core Image context to use for rendering.
    ///   - options: A dictionary of detector configuration options.
    /// - Returns: A configured detector, or nil if the type is invalid.
    public init?(ofType type: String, context: CIContext?, options: [String: Any]?) {
        // Validate detector type
        guard supportedDetectorTypes.contains(type) else {
            return nil
        }

        self._type = type
        self.engine = Self.createEngine(context: context, options: options)
    }

    // MARK: - Engine Factory

    /// Creates the appropriate detector engine for the current platform.
    private static func createEngine(context: CIContext?, options: [String: Any]?) -> CIDetectorEngine {
        #if arch(wasm32)
        return CIWebAPIDetectorEngine(context: context, options: options)
        #else
        return CIDefaultDetectorEngine(context: context, options: options)
        #endif
    }

    // MARK: - Properties

    /// The type of the detector.
    public var type: String {
        _type
    }

    // MARK: - Synchronous Feature Detection

    /// Searches for features in an image.
    ///
    /// - Parameter image: The image to search for features.
    /// - Returns: An array of detected features.
    public func features(in image: CIImage) -> [CIFeature] {
        features(in: image, options: nil)
    }

    /// Searches for features in an image based on the specified options.
    ///
    /// This method uses pure Swift algorithms for detection. For browser API-based
    /// detection on WASM, use `featuresAsync(in:options:)` instead.
    ///
    /// - Parameters:
    ///   - image: The image to search for features.
    ///   - options: A dictionary of detection options.
    /// - Returns: An array of detected features.
    public func features(in image: CIImage, options: [String: Any]?) -> [CIFeature] {
        engine.detectFeatures(type: _type, in: image, options: options)
    }

    // MARK: - Asynchronous Feature Detection

    /// Asynchronously searches for features in an image.
    ///
    /// On WASM, this method attempts to use browser APIs (FaceDetector, BarcodeDetector)
    /// for better detection accuracy when available. Falls back to pure Swift implementation
    /// when browser APIs are not available or on non-WASM platforms.
    ///
    /// - Parameter image: The image to search for features.
    /// - Returns: An array of detected features.
    public func featuresAsync(in image: CIImage) async -> [CIFeature] {
        await featuresAsync(in: image, options: nil)
    }

    /// Asynchronously searches for features in an image based on the specified options.
    ///
    /// On WASM, this method attempts to use browser APIs (FaceDetector, BarcodeDetector)
    /// for better detection accuracy when available. Falls back to pure Swift implementation
    /// when browser APIs are not available or on non-WASM platforms.
    ///
    /// - Parameters:
    ///   - image: The image to search for features.
    ///   - options: A dictionary of detection options.
    /// - Returns: An array of detected features.
    public func featuresAsync(in image: CIImage, options: [String: Any]?) async -> [CIFeature] {
        await engine.detectFeaturesAsync(type: _type, in: image, options: options)
    }
}

// MARK: - Equatable

extension CIDetector: Equatable {
    public static func == (lhs: CIDetector, rhs: CIDetector) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIDetector: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
