//
//  CIImageAccumulator.swift
//  OpenCoreImage
//
//  An object that manages feedback-based image processing for tasks such as
//  painting or fluid simulation.
//

import Foundation

/// An object that manages feedback-based image processing for tasks such as
/// painting or fluid simulation.
///
/// The `CIImageAccumulator` class enables feedback-based image processing for
/// such things as iterative painting operations or fluid dynamics simulations.
/// You use `CIImageAccumulator` objects in conjunction with other Core Image
/// classes, such as `CIFilter`, `CIImage`, `CIVector`, and `CIContext`, to take
/// advantage of the built-in Core Image filters when processing images.
public final class CIImageAccumulator: @unchecked Sendable {

    // MARK: - Private Storage

    private var _extent: CGRect
    private var _format: CIFormat
    private var _colorSpace: CGColorSpace?
    private var _currentImage: CIImage?

    // MARK: - Initialization

    /// Initializes an image accumulator with the specified extent and pixel format.
    public init?(extent: CGRect, format: CIFormat) {
        self._extent = extent
        self._format = format
        self._colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        self._currentImage = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: extent)
    }

    /// Initializes an image accumulator with the specified extent, pixel format, and color space.
    public init?(extent: CGRect, format: CIFormat, colorSpace: CGColorSpace) {
        self._extent = extent
        self._format = format
        self._colorSpace = colorSpace
        self._currentImage = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: extent)
    }

    // MARK: - Setting an Image

    /// Sets the contents of the image accumulator to the contents of the specified image object.
    public func setImage(_ image: CIImage) {
        _currentImage = image.cropped(to: _extent)
    }

    /// Updates an image accumulator with a subregion of an image object.
    public func setImage(_ image: CIImage, dirtyRect: CGRect) {
        guard let currentImage = _currentImage else {
            _currentImage = image.cropped(to: _extent)
            return
        }

        // Validate that dirtyRect intersects with the accumulator's extent
        let clippedDirtyRect = dirtyRect.intersection(_extent)
        guard !clippedDirtyRect.isNull && !clippedDirtyRect.isEmpty else {
            // dirtyRect is completely outside the accumulator's extent, no change needed
            return
        }

        // Composite the dirty region onto the current image
        let dirtyPortion = image.cropped(to: clippedDirtyRect)
        // Crop the result to preserve the accumulator's fixed extent
        _currentImage = dirtyPortion.composited(over: currentImage).cropped(to: _extent)
    }

    // MARK: - Obtaining Data From an Image Accumulator

    /// The extent of the image associated with the image accumulator.
    public var extent: CGRect {
        _extent
    }

    /// The pixel format of the image accumulator.
    public var format: CIFormat {
        _format
    }

    /// Returns the current contents of the image accumulator.
    public func image() -> CIImage {
        _currentImage ?? CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: _extent)
    }

    // MARK: - Resetting an Accumulator

    /// Resets the accumulator, discarding any pending updates and the current content.
    public func clear() {
        _currentImage = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: _extent)
    }
}

// MARK: - Equatable

extension CIImageAccumulator: Equatable {
    public static func == (lhs: CIImageAccumulator, rhs: CIImageAccumulator) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIImageAccumulator: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CustomStringConvertible

extension CIImageAccumulator: CustomStringConvertible {
    public var description: String {
        "CIImageAccumulator(extent: \(_extent), format: \(_format))"
    }
}

// MARK: - CustomDebugStringConvertible

extension CIImageAccumulator: CustomDebugStringConvertible {
    public var debugDescription: String {
        var desc = "CIImageAccumulator:\n"
        desc += "  extent: \(_extent)\n"
        desc += "  format: \(_format)\n"
        desc += "  colorSpace: \(_colorSpace?.name as String? ?? "nil")\n"
        return desc
    }
}
