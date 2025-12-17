//
//  CIColor.swift
//  OpenCoreImage
//
//  The Core Image class that defines a color object.
//

import Foundation

/// The Core Image class that defines a color object.
///
/// Use `CIColor` instances in conjunction with other Core Image classes,
/// such as `CIFilter` and `CIKernel`. Many of the built-in Core Image filters
/// have one or more `CIColor` inputs that you can set to affect the filter's behavior.
public final class CIColor: @unchecked Sendable {

    // MARK: - Private Storage

    private let _colorSpace: CGColorSpace
    private let _components: ContiguousArray<CGFloat>

    // MARK: - Initializers

    /// Create a Core Image color object with a Core Graphics color object.
    public init(cgColor: CGColor) {
        self._colorSpace = cgColor.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        if let components = cgColor.components {
            var array = ContiguousArray<CGFloat>()
            for i in 0..<cgColor.numberOfComponents {
                array.append(components[i])
            }
            self._components = array
        } else {
            self._components = [0, 0, 0, 1]
        }
    }

    /// Initialize a Core Image color object in the sRGB color space with the specified
    /// red, green, and blue component values.
    public convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    /// Initialize a Core Image color object in the sRGB color space with the specified
    /// red, green, blue, and alpha component values.
    public convenience init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        self.init(red: red, green: green, blue: blue, alpha: alpha, colorSpace: colorSpace)!
    }

    /// Initialize a Core Image color object with the specified red, green, and blue
    /// component values as measured in the specified color space.
    public init?(red: CGFloat, green: CGFloat, blue: CGFloat, colorSpace: CGColorSpace) {
        guard colorSpace.numberOfComponents >= 3 else { return nil }
        self._colorSpace = colorSpace
        self._components = [red, green, blue, 1.0]
    }

    /// Initialize a Core Image color object with the specified red, green, blue, and alpha
    /// component values as measured in the specified color space.
    public init?(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat, colorSpace: CGColorSpace) {
        guard colorSpace.numberOfComponents >= 3 else { return nil }
        self._colorSpace = colorSpace
        self._components = [red, green, blue, alpha]
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

    // MARK: - Private Initializer

    private init(colorSpace: CGColorSpace, components: ContiguousArray<CGFloat>) {
        self._colorSpace = colorSpace
        self._components = components
    }

    // MARK: - Getting Color Components

    /// Returns the `CGColorSpace` associated with the color.
    public var colorSpace: CGColorSpace {
        _colorSpace
    }

    /// Return a pointer to an array of `CGFloat` values including alpha.
    public var components: UnsafePointer<CGFloat> {
        _components.withUnsafeBufferPointer { buffer in
            buffer.baseAddress!
        }
    }

    /// Returns the color components of the color including alpha.
    public var numberOfComponents: Int {
        _components.count
    }

    /// Returns the unpremultiplied red component of the color.
    public var red: CGFloat {
        _components.count > 0 ? _components[0] : 0
    }

    /// Returns the unpremultiplied green component of the color.
    public var green: CGFloat {
        _components.count > 1 ? _components[1] : 0
    }

    /// Returns the unpremultiplied blue component of the color.
    public var blue: CGFloat {
        _components.count > 2 ? _components[2] : 0
    }

    /// Returns the alpha value of the color.
    public var alpha: CGFloat {
        _components.count > 3 ? _components[3] : 1
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
        lhs._components == rhs._components &&
        lhs._colorSpace.name == rhs._colorSpace.name
    }
}

// MARK: - Hashable

extension CIColor: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_colorSpace.name)
        for component in _components {
            hasher.combine(component)
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
