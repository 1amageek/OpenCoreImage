//
//  CIVector.swift
//  OpenCoreImage
//
//  The Core Image class that defines a vector object.
//

import Foundation

/// The Core Image class that defines a vector object.
///
/// A `CIVector` can store one or more `CGFloat` values in one object.
/// They can store a group of float values for a variety of different uses
/// such as coordinate points, direction vectors, geometric rectangles,
/// transform matrices, convolution weights, or just a list of parameter values.
public final class CIVector: @unchecked Sendable {

    // MARK: - Private Storage

    private let storage: ContiguousArray<CGFloat>

    // MARK: - Initializers

    /// Initialize a Core Image vector object with the specified values.
    public init(values: UnsafePointer<CGFloat>, count: Int) {
        var array = ContiguousArray<CGFloat>()
        array.reserveCapacity(count)
        for i in 0..<count {
            array.append(values[i])
        }
        self.storage = array
    }

    /// Initialize a Core Image vector object with one value.
    public convenience init(x: CGFloat) {
        var values: [CGFloat] = [x]
        self.init(values: &values, count: 1)
    }

    /// Initialize a Core Image vector object with two values.
    public convenience init(x: CGFloat, y: CGFloat) {
        var values: [CGFloat] = [x, y]
        self.init(values: &values, count: 2)
    }

    /// Initialize a Core Image vector object with three values.
    public convenience init(x: CGFloat, y: CGFloat, z: CGFloat) {
        var values: [CGFloat] = [x, y, z]
        self.init(values: &values, count: 3)
    }

    /// Initialize a Core Image vector object with four values.
    public convenience init(x: CGFloat, y: CGFloat, z: CGFloat, w: CGFloat) {
        var values: [CGFloat] = [x, y, z, w]
        self.init(values: &values, count: 4)
    }

    /// Initialize a Core Image vector object with values provided in a string representation.
    ///
    /// The string should be formatted as "[X Y Z W]" where each value is separated by spaces.
    public convenience init(string representation: String) {
        let trimmed = representation.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        let components = trimmed.split(separator: " ")
        var values: [CGFloat] = []
        for component in components {
            if let doubleValue = Double(component) {
                values.append(CGFloat(doubleValue))
            }
        }
        if values.isEmpty {
            values = [0]
        }
        self.init(values: &values, count: values.count)
    }

    /// Initialize a Core Image vector object with six values provided by a `CGAffineTransform` structure.
    public convenience init(cgAffineTransform transform: CGAffineTransform) {
        var values: [CGFloat] = [
            CGFloat(transform.a),
            CGFloat(transform.b),
            CGFloat(transform.c),
            CGFloat(transform.d),
            CGFloat(transform.tx),
            CGFloat(transform.ty)
        ]
        self.init(values: &values, count: 6)
    }

    /// Initialize a Core Image vector object with two values provided by a `CGPoint` structure.
    public convenience init(cgPoint point: CGPoint) {
        self.init(x: point.x, y: point.y)
    }

    /// Initialize a Core Image vector object with four values provided by a `CGRect` structure.
    public convenience init(cgRect rect: CGRect) {
        var values: [CGFloat] = [rect.origin.x, rect.origin.y, rect.size.width, rect.size.height]
        self.init(values: &values, count: 4)
    }

    // MARK: - Getting Values From a Vector

    /// Returns a value from a specific position in the vector.
    public func value(at index: Int) -> CGFloat {
        guard index >= 0 && index < storage.count else {
            return 0
        }
        return storage[index]
    }

    /// The number of items in the vector.
    public var count: Int {
        storage.count
    }

    /// The value located in the first position in the vector.
    public var x: CGFloat {
        value(at: 0)
    }

    /// The value located in the second position in the vector.
    public var y: CGFloat {
        value(at: 1)
    }

    /// The value located in the third position in the vector.
    public var z: CGFloat {
        value(at: 2)
    }

    /// The value located in the fourth position in the vector.
    public var w: CGFloat {
        value(at: 3)
    }

    /// Returns a formatted string with all the values of a `CIVector`.
    public var stringRepresentation: String {
        let values = (0..<count).map { "\(value(at: $0).native)" }
        return "[\(values.joined(separator: " "))]"
    }

    /// Returns the values in the vector as a `CGAffineTransform` structure.
    public var cgAffineTransformValue: CGAffineTransform {
        CGAffineTransform(
            a: value(at: 0).native,
            b: value(at: 1).native,
            c: value(at: 2).native,
            d: value(at: 3).native,
            tx: value(at: 4).native,
            ty: value(at: 5).native
        )
    }

    /// Returns the values in the vector as a `CGPoint` structure.
    public var cgPointValue: CGPoint {
        CGPoint(x: x, y: y)
    }

    /// Returns the values in the vector as a `CGRect` structure.
    public var cgRectValue: CGRect {
        CGRect(x: value(at: 0), y: value(at: 1), width: value(at: 2), height: value(at: 3))
    }
}

// MARK: - Equatable

extension CIVector: Equatable {
    public static func == (lhs: CIVector, rhs: CIVector) -> Bool {
        lhs.storage == rhs.storage
    }
}

// MARK: - Hashable

extension CIVector: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage.count)
        for value in storage {
            hasher.combine(value)
        }
    }
}

// MARK: - CustomStringConvertible

extension CIVector: CustomStringConvertible {
    public var description: String {
        stringRepresentation
    }
}

// MARK: - CustomDebugStringConvertible

extension CIVector: CustomDebugStringConvertible {
    public var debugDescription: String {
        "CIVector(\(stringRepresentation))"
    }
}
