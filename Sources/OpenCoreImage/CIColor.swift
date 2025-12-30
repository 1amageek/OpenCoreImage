//
//  CIColor.swift
//  OpenCoreImage
//
//  The Core Image class that defines a color object.
//

import Foundation
import OpenCoreGraphics

/// The Core Image class that defines a color object.
///
/// Use `CIColor` instances in conjunction with other Core Image classes,
/// such as `CIFilter` and `CIKernel`. Many of the built-in Core Image filters
/// have one or more `CIColor` inputs that you can set to affect the filter's behavior.
public final class CIColor: @unchecked Sendable {

    // MARK: - Private Storage

    private let _colorSpace: CGColorSpace
    /// Heap-allocated stable storage for RGBA components.
    /// The pointer remains valid for the lifetime of this CIColor instance.
    private let _storage: UnsafeMutablePointer<CGFloat>
    private let _count: Int

    // MARK: - Initializers

    /// Create a Core Image color object with a Core Graphics color object.
    ///
    /// CIColor always stores colors as RGBA internally. If the source CGColor
    /// is in a different color space (e.g., grayscale), it is converted to RGBA.
    public init(cgColor: CGColor) {
        let sourceColorSpace = cgColor.colorSpace ?? .deviceRGB
        let sourceComponents = cgColor.components ?? [0, 0, 0, 1]
        let numComponents = cgColor.numberOfComponents

        // Convert to RGBA based on source color space model
        let rgba: [CGFloat]
        if sourceColorSpace.model == .monochrome && numComponents >= 1 {
            // Grayscale: [gray] or [gray, alpha]
            let gray = sourceComponents[0]
            let alpha = numComponents >= 2 ? sourceComponents[1] : 1.0
            rgba = [gray, gray, gray, alpha]
        } else if sourceColorSpace.model == .rgb && numComponents >= 3 {
            // RGB: [r, g, b] or [r, g, b, a]
            let r = sourceComponents[0]
            let g = sourceComponents[1]
            let b = sourceComponents[2]
            let a = numComponents >= 4 ? sourceComponents[3] : 1.0
            rgba = [r, g, b, a]
        } else {
            // Fallback: copy available components, pad with defaults
            var components = [CGFloat](repeating: 0, count: 4)
            for i in 0..<min(numComponents, 4) {
                components[i] = sourceComponents[i]
            }
            if numComponents < 4 { components[3] = 1.0 }
            rgba = components
        }

        // Store in sRGB color space for CIColor
        self._colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? .deviceRGB
        self._count = rgba.count
        self._storage = UnsafeMutablePointer<CGFloat>.allocate(capacity: rgba.count)
        for (i, value) in rgba.enumerated() {
            _storage[i] = value
        }
    }

    deinit {
        _storage.deallocate()
    }

    /// Initialize a Core Image color object in the sRGB color space with the specified
    /// red, green, and blue component values.
    public convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    /// Initialize a Core Image color object in the sRGB color space with the specified
    /// red, green, blue, and alpha component values.
    public convenience init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? .deviceRGB
        self.init(red: red, green: green, blue: blue, alpha: alpha, colorSpace: colorSpace)!
    }

    /// Initialize a Core Image color object with the specified red, green, and blue
    /// component values as measured in the specified color space.
    public init?(red: CGFloat, green: CGFloat, blue: CGFloat, colorSpace: CGColorSpace) {
        guard colorSpace.numberOfComponents >= 3 else { return nil }
        self._colorSpace = colorSpace
        let rgba = [red, green, blue, 1.0]
        self._count = rgba.count
        self._storage = UnsafeMutablePointer<CGFloat>.allocate(capacity: rgba.count)
        for (i, value) in rgba.enumerated() {
            _storage[i] = value
        }
    }

    /// Initialize a Core Image color object with the specified red, green, blue, and alpha
    /// component values as measured in the specified color space.
    public init?(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat, colorSpace: CGColorSpace) {
        guard colorSpace.numberOfComponents >= 3 else { return nil }
        self._colorSpace = colorSpace
        let rgba = [red, green, blue, alpha]
        self._count = rgba.count
        self._storage = UnsafeMutablePointer<CGFloat>.allocate(capacity: rgba.count)
        for (i, value) in rgba.enumerated() {
            _storage[i] = value
        }
    }

    /// Create a Core Image color object in the sRGB color space using a string
    /// containing the RGBA color component values.
    ///
    /// The string should be formatted as "R G B A" where each value is a float between 0 and 1.
    public convenience init(string representation: String) {
        let components = representation.split(separator: " ")
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1

        if components.count >= 1, let value = Double(components[0]) {
            r = CGFloat(value)
        }
        if components.count >= 2, let value = Double(components[1]) {
            g = CGFloat(value)
        }
        if components.count >= 3, let value = Double(components[2]) {
            b = CGFloat(value)
        }
        if components.count >= 4, let value = Double(components[3]) {
            a = CGFloat(value)
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    // MARK: - Getting Color Components

    /// Returns the `CGColorSpace` associated with the color.
    public var colorSpace: CGColorSpace {
        _colorSpace
    }

    /// Return a pointer to an array of `CGFloat` values including alpha.
    ///
    /// The pointer remains valid for the lifetime of this CIColor instance.
    public var components: UnsafePointer<CGFloat> {
        UnsafePointer(_storage)
    }

    /// Returns the color components of the color including alpha.
    public var numberOfComponents: Int {
        _count
    }

    /// Returns the unpremultiplied red component of the color.
    public var red: CGFloat {
        _count > 0 ? _storage[0] : 0
    }

    /// Returns the unpremultiplied green component of the color.
    public var green: CGFloat {
        _count > 1 ? _storage[1] : 0
    }

    /// Returns the unpremultiplied blue component of the color.
    public var blue: CGFloat {
        _count > 2 ? _storage[2] : 0
    }

    /// Returns the alpha value of the color.
    public var alpha: CGFloat {
        _count > 3 ? _storage[3] : 1
    }

    /// Returns a formatted string with the unpremultiplied color and alpha components of the color.
    public var stringRepresentation: String {
        "\(red.native) \(green.native) \(blue.native) \(alpha.native)"
    }

    // MARK: - Preset Colors

    /// Returns a singleton Core Image color instance in the sRGB color space with RGB values `0,0,0` and alpha value `1`.
    public static let black = CIColor(red: 0, green: 0, blue: 0, alpha: 1)

    /// Returns a singleton Core Image color instance in the sRGB color space with RGB values `0,0,1` and alpha value `1`.
    public static let blue = CIColor(red: 0, green: 0, blue: 1, alpha: 1)

    /// Returns a singleton Core Image color instance in the sRGB color space with RGB values `0,0,0` and alpha value `0`.
    public static let clear = CIColor(red: 0, green: 0, blue: 0, alpha: 0)

    /// Returns a singleton Core Image color instance in the sRGB color space with RGB values `0,1,1` and alpha value `1`.
    public static let cyan = CIColor(red: 0, green: 1, blue: 1, alpha: 1)

    /// Returns a singleton Core Image color instance in the sRGB color space with RGB values `0.5,0.5,0.5` and alpha value `1`.
    public static let gray = CIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)

    /// Returns a singleton Core Image color instance in the sRGB color space with RGB values `0,1,0` and alpha value `1`.
    public static let green = CIColor(red: 0, green: 1, blue: 0, alpha: 1)

    /// Returns a singleton Core Image color instance in the sRGB color space with RGB values `1,0,1` and alpha value `1`.
    public static let magenta = CIColor(red: 1, green: 0, blue: 1, alpha: 1)

    /// Returns a singleton Core Image color instance in the sRGB color space with RGB values `1,0,0` and alpha value `1`.
    public static let red = CIColor(red: 1, green: 0, blue: 0, alpha: 1)

    /// Returns a singleton Core Image color instance in the sRGB color space with RGB values `1,1,1` and alpha value `1`.
    public static let white = CIColor(red: 1, green: 1, blue: 1, alpha: 1)

    /// Returns a singleton Core Image color instance in the sRGB color space with RGB values `1,1,0` and alpha value `1`.
    public static let yellow = CIColor(red: 1, green: 1, blue: 0, alpha: 1)
}

// MARK: - Equatable

extension CIColor: Equatable {
    public static func == (lhs: CIColor, rhs: CIColor) -> Bool {
        guard lhs._count == rhs._count,
              lhs._colorSpace.name == rhs._colorSpace.name else {
            return false
        }
        for i in 0..<lhs._count {
            if lhs._storage[i] != rhs._storage[i] {
                return false
            }
        }
        return true
    }
}

// MARK: - Hashable

extension CIColor: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_colorSpace.name)
        for i in 0..<_count {
            hasher.combine(_storage[i])
        }
    }
}

// MARK: - CustomStringConvertible

extension CIColor: CustomStringConvertible {
    public var description: String {
        "CIColor(red: \(red.native), green: \(green.native), blue: \(blue.native), alpha: \(alpha.native))"
    }
}

// MARK: - CustomDebugStringConvertible

extension CIColor: CustomDebugStringConvertible {
    public var debugDescription: String {
        description
    }
}
