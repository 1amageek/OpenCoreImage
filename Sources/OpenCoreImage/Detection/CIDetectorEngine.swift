//
//  CIDetectorEngine.swift
//  OpenCoreImage
//
//  Internal protocol for detector engine implementations.
//

import Foundation

/// Internal protocol for detector engine implementations.
///
/// This protocol defines the interface for detection engines. Two implementations exist:
/// - `CIDefaultDetectorEngine`: Pure Swift implementation for all platforms
/// - `CIWebAPIDetectorEngine`: WASM-specific implementation using browser APIs
///
/// This follows the Renderer Delegate pattern used by `CIContextRenderer`.
internal protocol CIDetectorEngine: Sendable {

    /// Synchronous feature detection using pure Swift implementation.
    ///
    /// - Parameters:
    ///   - type: The detector type (e.g., `CIDetectorTypeFace`)
    ///   - image: The image to analyze
    ///   - options: Detection options
    /// - Returns: Array of detected features
    func detectFeatures(type: String, in image: CIImage, options: [String: Any]?) -> [CIFeature]

    /// Asynchronous feature detection, potentially using browser APIs.
    ///
    /// On WASM, this may use browser's FaceDetector or BarcodeDetector APIs when available.
    /// Falls back to pure Swift implementation when browser APIs are not available.
    ///
    /// - Parameters:
    ///   - type: The detector type (e.g., `CIDetectorTypeFace`)
    ///   - image: The image to analyze
    ///   - options: Detection options
    /// - Returns: Array of detected features
    func detectFeaturesAsync(type: String, in image: CIImage, options: [String: Any]?) async -> [CIFeature]
}
