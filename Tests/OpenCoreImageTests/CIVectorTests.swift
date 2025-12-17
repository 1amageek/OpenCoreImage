//
//  CIVectorTests.swift
//  OpenCoreImage
//
//  Tests for CIVector functionality.
//

import Testing
@testable import OpenCoreImage

// MARK: - CIVector Initialization Tests

@Suite("CIVector Initialization")
struct CIVectorInitializationTests {

    @Test("Initialize with single value")
    func initWithSingleValue() {
        let vector = CIVector(x: 5.0)
        #expect(vector.count == 1)
        #expect(vector.x == 5.0)
        #expect(vector.y == 0)  // Out of bounds returns 0
    }

    @Test("Initialize with two values")
    func initWithTwoValues() {
        let vector = CIVector(x: 3.0, y: 4.0)
        #expect(vector.count == 2)
        #expect(vector.x == 3.0)
        #expect(vector.y == 4.0)
        #expect(vector.z == 0)  // Out of bounds returns 0
    }

    @Test("Initialize with three values")
    func initWithThreeValues() {
        let vector = CIVector(x: 1.0, y: 2.0, z: 3.0)
        #expect(vector.count == 3)
        #expect(vector.x == 1.0)
        #expect(vector.y == 2.0)
        #expect(vector.z == 3.0)
        #expect(vector.w == 0)  // Out of bounds returns 0
    }

    @Test("Initialize with four values")
    func initWithFourValues() {
        let vector = CIVector(x: 1.0, y: 2.0, z: 3.0, w: 4.0)
        #expect(vector.count == 4)
        #expect(vector.x == 1.0)
        #expect(vector.y == 2.0)
        #expect(vector.z == 3.0)
        #expect(vector.w == 4.0)
    }

    @Test("Initialize with values pointer")
    func initWithValuesPointer() {
        var values: [CGFloat] = [10.0, 20.0, 30.0]
        let vector = CIVector(values: &values, count: 3)
        #expect(vector.count == 3)
        #expect(vector.value(at: 0) == 10.0)
        #expect(vector.value(at: 1) == 20.0)
        #expect(vector.value(at: 2) == 30.0)
    }

    @Test("Initialize from CGPoint")
    func initFromCGPoint() {
        let point = CGPoint(x: 100.0, y: 200.0)
        let vector = CIVector(cgPoint: point)
        #expect(vector.count == 2)
        #expect(vector.x == 100.0)
        #expect(vector.y == 200.0)
    }

    @Test("Initialize from CGRect")
    func initFromCGRect() {
        let rect = CGRect(x: 10.0, y: 20.0, width: 100.0, height: 200.0)
        let vector = CIVector(cgRect: rect)
        #expect(vector.count == 4)
        #expect(vector.value(at: 0) == 10.0)
        #expect(vector.value(at: 1) == 20.0)
        #expect(vector.value(at: 2) == 100.0)
        #expect(vector.value(at: 3) == 200.0)
    }

    @Test("Initialize from CGAffineTransform")
    func initFromCGAffineTransform() {
        let transform = CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 50.0, ty: 100.0)
        let vector = CIVector(cgAffineTransform: transform)
        #expect(vector.count == 6)
        #expect(vector.value(at: 0) == 1.0)
        #expect(vector.value(at: 1) == 0.0)
        #expect(vector.value(at: 2) == 0.0)
        #expect(vector.value(at: 3) == 1.0)
        #expect(vector.value(at: 4) == 50.0)
        #expect(vector.value(at: 5) == 100.0)
    }
}

// MARK: - CIVector String Initialization Tests

@Suite("CIVector String Initialization")
struct CIVectorStringInitializationTests {

    @Test("Initialize from valid string")
    func initFromValidString() {
        let vector = CIVector(string: "[1.0 2.0 3.0 4.0]")
        #expect(vector.count == 4)
        #expect(vector.x == 1.0)
        #expect(vector.y == 2.0)
        #expect(vector.z == 3.0)
        #expect(vector.w == 4.0)
    }

    @Test("Initialize from string without brackets")
    func initFromStringWithoutBrackets() {
        let vector = CIVector(string: "5.0 10.0")
        #expect(vector.count == 2)
        #expect(vector.x == 5.0)
        #expect(vector.y == 10.0)
    }

    @Test("Initialize from empty string defaults to single zero")
    func initFromEmptyString() {
        let vector = CIVector(string: "")
        #expect(vector.count == 1)
        #expect(vector.x == 0)
    }

    @Test("Initialize from string with negative values")
    func initFromStringWithNegativeValues() {
        let vector = CIVector(string: "[-5.5 10.0 -3.0]")
        #expect(vector.count == 3)
        #expect(vector.x == -5.5)
        #expect(vector.y == 10.0)
        #expect(vector.z == -3.0)
    }
}

// MARK: - CIVector Value Access Tests

@Suite("CIVector Value Access")
struct CIVectorValueAccessTests {

    @Test("Access values within bounds")
    func accessWithinBounds() {
        let vector = CIVector(x: 1.0, y: 2.0, z: 3.0)
        #expect(vector.value(at: 0) == 1.0)
        #expect(vector.value(at: 1) == 2.0)
        #expect(vector.value(at: 2) == 3.0)
    }

    @Test("Access values out of bounds returns zero")
    func accessOutOfBoundsReturnsZero() {
        let vector = CIVector(x: 1.0, y: 2.0)
        #expect(vector.value(at: -1) == 0)
        #expect(vector.value(at: 2) == 0)
        #expect(vector.value(at: 100) == 0)
    }
}

// MARK: - CIVector Conversion Tests

@Suite("CIVector Conversions")
struct CIVectorConversionTests {

    @Test("Convert to CGPoint")
    func convertToCGPoint() {
        let vector = CIVector(x: 100.0, y: 200.0)
        let point = vector.cgPointValue
        #expect(point.x == 100.0)
        #expect(point.y == 200.0)
    }

    @Test("Convert to CGRect")
    func convertToCGRect() {
        let vector = CIVector(x: 10.0, y: 20.0, z: 100.0, w: 200.0)
        let rect = vector.cgRectValue
        #expect(rect.origin.x == 10.0)
        #expect(rect.origin.y == 20.0)
        #expect(rect.size.width == 100.0)
        #expect(rect.size.height == 200.0)
    }

    @Test("Convert to CGAffineTransform")
    func convertToCGAffineTransform() {
        var values: [CGFloat] = [2.0, 0.0, 0.0, 2.0, 10.0, 20.0]
        let vector = CIVector(values: &values, count: 6)
        let transform = vector.cgAffineTransformValue
        #expect(transform.a == 2.0)
        #expect(transform.b == 0.0)
        #expect(transform.c == 0.0)
        #expect(transform.d == 2.0)
        #expect(transform.tx == 10.0)
        #expect(transform.ty == 20.0)
    }

    @Test("String representation")
    func stringRepresentation() {
        let vector = CIVector(x: 1.0, y: 2.0, z: 3.0)
        let str = vector.stringRepresentation
        #expect(str.contains("1"))
        #expect(str.contains("2"))
        #expect(str.contains("3"))
        #expect(str.hasPrefix("["))
        #expect(str.hasSuffix("]"))
    }
}

// MARK: - CIVector Equatable/Hashable Tests

@Suite("CIVector Equatable and Hashable")
struct CIVectorEquatableHashableTests {

    @Test("Equal vectors are equal")
    func equalVectors() {
        let v1 = CIVector(x: 1.0, y: 2.0, z: 3.0)
        let v2 = CIVector(x: 1.0, y: 2.0, z: 3.0)
        #expect(v1 == v2)
    }

    @Test("Different vectors are not equal")
    func differentVectors() {
        let v1 = CIVector(x: 1.0, y: 2.0)
        let v2 = CIVector(x: 1.0, y: 3.0)
        #expect(v1 != v2)
    }

    @Test("Vectors with different counts are not equal")
    func differentCountVectors() {
        let v1 = CIVector(x: 1.0, y: 2.0)
        let v2 = CIVector(x: 1.0, y: 2.0, z: 0.0)
        #expect(v1 != v2)
    }

    @Test("Equal vectors have same hash")
    func equalHashValues() {
        let v1 = CIVector(x: 1.0, y: 2.0, z: 3.0)
        let v2 = CIVector(x: 1.0, y: 2.0, z: 3.0)
        #expect(v1.hashValue == v2.hashValue)
    }

    @Test("Vectors can be used in Set")
    func vectorsInSet() {
        let v1 = CIVector(x: 1.0, y: 2.0)
        let v2 = CIVector(x: 1.0, y: 2.0)
        let v3 = CIVector(x: 3.0, y: 4.0)

        var set: Set<CIVector> = []
        set.insert(v1)
        set.insert(v2)
        set.insert(v3)

        #expect(set.count == 2)
    }
}

// MARK: - CIVector Description Tests

@Suite("CIVector Description")
struct CIVectorDescriptionTests {

    @Test("Description matches string representation")
    func descriptionMatchesStringRepresentation() {
        let vector = CIVector(x: 1.0, y: 2.0)
        #expect(vector.description == vector.stringRepresentation)
    }

    @Test("Debug description includes type name")
    func debugDescriptionIncludesTypeName() {
        let vector = CIVector(x: 1.0, y: 2.0)
        #expect(vector.debugDescription.contains("CIVector"))
    }
}
