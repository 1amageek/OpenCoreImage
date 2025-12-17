//
//  CIDetector.swift
//  OpenCoreImage
//
//  Image feature detection classes.
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

// MARK: - Feature Type Constants

/// A Core Image feature type for person's face.
public let CIFeatureTypeFace: String = "CIFeatureTypeFace"

/// A Core Image feature type for rectangular object.
public let CIFeatureTypeRectangle: String = "CIFeatureTypeRectangle"

/// A Core Image feature type for QR code object.
public let CIFeatureTypeQRCode: String = "CIFeatureTypeQRCode"

/// A Core Image feature type for text.
public let CIFeatureTypeText: String = "CIFeatureTypeText"

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
public final class CIDetector: @unchecked Sendable {

    // MARK: - Private Storage

    private let _type: String
    private let _context: CIContext?
    private let _options: [String: Any]

    // MARK: - Initialization

    /// Creates and returns a configured detector.
    public init?(ofType type: String, context: CIContext?, options: [String: Any]?) {
        self._type = type
        self._context = context
        self._options = options ?? [:]
    }

    // MARK: - Finding Features

    /// Searches for features in an image.
    public func features(in image: CIImage) -> [CIFeature] {
        features(in: image, options: nil)
    }

    /// Searches for features in an image based on the specified image orientation.
    public func features(in image: CIImage, options: [String: Any]?) -> [CIFeature] {
        // Placeholder implementation - returns empty array
        // In a full implementation, this would perform actual feature detection
        []
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

// MARK: - CIFeature

/// The abstract superclass for objects representing notable features detected in an image.
///
/// A `CIFeature` object represents a portion of an image that a detector believes matches
/// its criteria. Subclasses of CIFeature holds additional information specific to the
/// detector that discovered the feature.
public class CIFeature: @unchecked Sendable {

    // MARK: - Private Storage

    internal var _bounds: CGRect
    internal var _type: String

    // MARK: - Initialization

    internal init(bounds: CGRect, type: String) {
        self._bounds = bounds
        self._type = type
    }

    // MARK: - Properties

    /// The rectangle that holds discovered feature.
    public var bounds: CGRect {
        _bounds
    }

    /// The type of feature that was discovered.
    public var type: String {
        _type
    }
}

// MARK: - Equatable

extension CIFeature: Equatable {
    public static func == (lhs: CIFeature, rhs: CIFeature) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIFeature: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CIFaceFeature

/// Information about a face detected in a still or video image.
///
/// The properties of a `CIFaceFeature` object provide information about the face's eyes
/// and mouth. A face object in a video can also have properties that track its location
/// over time, tracking ID and frame count.
public final class CIFaceFeature: CIFeature, @unchecked Sendable {

    // MARK: - Private Storage

    private var _hasFaceAngle: Bool = false
    private var _faceAngle: Float = 0
    private var _hasLeftEyePosition: Bool = false
    private var _leftEyePosition: CGPoint = .zero
    private var _hasRightEyePosition: Bool = false
    private var _rightEyePosition: CGPoint = .zero
    private var _hasMouthPosition: Bool = false
    private var _mouthPosition: CGPoint = .zero
    private var _hasSmile: Bool = false
    private var _leftEyeClosed: Bool = false
    private var _rightEyeClosed: Bool = false
    private var _hasTrackingID: Bool = false
    private var _trackingID: Int32 = 0
    private var _hasTrackingFrameCount: Bool = false
    private var _trackingFrameCount: Int32 = 0

    // MARK: - Initialization

    internal init(bounds: CGRect) {
        super.init(bounds: bounds, type: CIFeatureTypeFace)
    }

    // MARK: - Locating Faces

    /// A Boolean value that indicates whether information about face rotation is available.
    public var hasFaceAngle: Bool {
        _hasFaceAngle
    }

    /// The rotation of the face.
    public var faceAngle: Float {
        _faceAngle
    }

    // MARK: - Identifying Facial Features

    /// A Boolean value that indicates whether the detector found the face's left eye.
    public var hasLeftEyePosition: Bool {
        _hasLeftEyePosition
    }

    /// A Boolean value that indicates whether the detector found the face's right eye.
    public var hasRightEyePosition: Bool {
        _hasRightEyePosition
    }

    /// A Boolean value that indicates whether the detector found the face's mouth.
    public var hasMouthPosition: Bool {
        _hasMouthPosition
    }

    /// The image coordinate of the center of the left eye.
    public var leftEyePosition: CGPoint {
        _leftEyePosition
    }

    /// The image coordinate of the center of the right eye.
    public var rightEyePosition: CGPoint {
        _rightEyePosition
    }

    /// The image coordinate of the center of the mouth.
    public var mouthPosition: CGPoint {
        _mouthPosition
    }

    /// A Boolean value that indicates whether a smile is detected in the face.
    public var hasSmile: Bool {
        _hasSmile
    }

    /// A Boolean value that indicates whether a closed left eye is detected in the face.
    public var leftEyeClosed: Bool {
        _leftEyeClosed
    }

    /// A Boolean value that indicates whether a closed right eye is detected in the face.
    public var rightEyeClosed: Bool {
        _rightEyeClosed
    }

    // MARK: - Tracking Distinct Faces in Video

    /// A Boolean value that indicates whether the face object has a tracking ID.
    public var hasTrackingID: Bool {
        _hasTrackingID
    }

    /// The tracking identifier of the face object.
    public var trackingID: Int32 {
        _trackingID
    }

    /// A Boolean value that indicates the face object has a tracking frame count.
    public var hasTrackingFrameCount: Bool {
        _hasTrackingFrameCount
    }

    /// The tracking frame count of the face.
    public var trackingFrameCount: Int32 {
        _trackingFrameCount
    }
}

// MARK: - CIRectangleFeature

/// Information about a rectangular region detected in a still or video image.
///
/// A detected rectangle feature is not necessarily rectangular in the plane of the image;
/// rather, the feature identifies a shape that may be rectangular in space (for example
/// a book on a desk) but which appears as a four-sided polygon in the image. The properties
/// of a `CIRectangleFeature` object identify its four corners in image coordinates.
public final class CIRectangleFeature: CIFeature, @unchecked Sendable {

    // MARK: - Private Storage

    private var _topLeft: CGPoint
    private var _topRight: CGPoint
    private var _bottomLeft: CGPoint
    private var _bottomRight: CGPoint

    // MARK: - Initialization

    internal init(bounds: CGRect, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) {
        self._topLeft = topLeft
        self._topRight = topRight
        self._bottomLeft = bottomLeft
        self._bottomRight = bottomRight
        super.init(bounds: bounds, type: CIFeatureTypeRectangle)
    }

    // MARK: - Properties

    /// The upper-left corner of the detected rectangle, in image coordinates.
    public var topLeft: CGPoint {
        _topLeft
    }

    /// The upper-right corner of the detected rectangle, in image coordinates.
    public var topRight: CGPoint {
        _topRight
    }

    /// The lower-left corner of the detected rectangle, in image coordinates.
    public var bottomLeft: CGPoint {
        _bottomLeft
    }

    /// The lower-right corner of the detected rectangle, in image coordinates.
    public var bottomRight: CGPoint {
        _bottomRight
    }
}

// MARK: - CITextFeature

/// Information about a text that was detected in a still or video image.
///
/// A detected text feature is not necessarily rectangular in the plane of the image;
/// rather, the feature identifies a shape that may be rectangular in space (for example
/// a text on a sign) but which appears as a four-sided polygon in the image. The properties
/// of a `CITextFeature` object identify its four corners in image coordinates.
public final class CITextFeature: CIFeature, @unchecked Sendable {

    // MARK: - Private Storage

    private var _topLeft: CGPoint
    private var _topRight: CGPoint
    private var _bottomLeft: CGPoint
    private var _bottomRight: CGPoint
    private var _subFeatures: [Any]?

    // MARK: - Initialization

    internal init(bounds: CGRect, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) {
        self._topLeft = topLeft
        self._topRight = topRight
        self._bottomLeft = bottomLeft
        self._bottomRight = bottomRight
        self._subFeatures = nil
        super.init(bounds: bounds, type: CIFeatureTypeText)
    }

    // MARK: - Properties

    /// The image coordinate of the upper-left corner of the detected text.
    public var topLeft: CGPoint {
        _topLeft
    }

    /// The image coordinate of the upper-right corner of the detected text.
    public var topRight: CGPoint {
        _topRight
    }

    /// The image coordinate of the lower-left corner of the detected text.
    public var bottomLeft: CGPoint {
        _bottomLeft
    }

    /// The image coordinate of the lower-right corner of the detected text.
    public var bottomRight: CGPoint {
        _bottomRight
    }

    /// An array containing additional features detected within the feature.
    public var subFeatures: [Any]? {
        _subFeatures
    }
}

// MARK: - CIQRCodeFeature

/// Information about a Quick Response code detected in a still or video image.
///
/// A QR code is a two-dimensional barcode using the ISO/IEC 18004:2006 standard.
/// The properties of a CIQRCodeFeature object identify the corners of the barcode
/// in the image perspective and provide the decoded message.
public final class CIQRCodeFeature: CIFeature, @unchecked Sendable {

    // MARK: - Private Storage

    private var _topLeft: CGPoint
    private var _topRight: CGPoint
    private var _bottomLeft: CGPoint
    private var _bottomRight: CGPoint
    private var _messageString: String?
    private var _symbolDescriptor: CIQRCodeDescriptor?

    // MARK: - Initialization

    internal init(bounds: CGRect, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint, messageString: String?, symbolDescriptor: CIQRCodeDescriptor?) {
        self._topLeft = topLeft
        self._topRight = topRight
        self._bottomLeft = bottomLeft
        self._bottomRight = bottomRight
        self._messageString = messageString
        self._symbolDescriptor = symbolDescriptor
        super.init(bounds: bounds, type: CIFeatureTypeQRCode)
    }

    // MARK: - Locating the Barcode

    /// The image coordinate of the upper-left corner of the detected QR code.
    public var topLeft: CGPoint {
        _topLeft
    }

    /// The image coordinate of the upper-right corner of the detected QR code.
    public var topRight: CGPoint {
        _topRight
    }

    /// The image coordinate of the lower-left corner of the detected QR code.
    public var bottomLeft: CGPoint {
        _bottomLeft
    }

    /// The image coordinate of the lower-right corner of the detected QR code.
    public var bottomRight: CGPoint {
        _bottomRight
    }

    // MARK: - Decoding the Barcode

    /// The string decoded from the detected barcode.
    public var messageString: String? {
        _messageString
    }

    /// An abstract representation of a QR Code symbol.
    public var symbolDescriptor: CIQRCodeDescriptor? {
        _symbolDescriptor
    }
}
