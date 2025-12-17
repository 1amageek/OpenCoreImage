//
//  CIBarcodeDescriptorTests.swift
//  OpenCoreImage
//
//  Tests for CIBarcodeDescriptor and its subclasses.
//

import Testing
import Foundation
@testable import OpenCoreImage

// MARK: - CIBarcodeDescriptor Tests

@Suite("CIBarcodeDescriptor Base Class")
struct CIBarcodeDescriptorBaseTests {

    @Test("Barcode descriptor equality is reference based")
    func descriptorEquality() {
        let payload = Data([0x01, 0x02, 0x03])
        let desc1 = CIQRCodeDescriptor(
            payload: payload,
            symbolVersion: 1,
            maskPattern: 0,
            errorCorrectionLevel: .levelL
        )!
        let desc2 = desc1  // Same reference

        #expect(desc1 == desc2)
    }

    @Test("Barcode descriptor hashable")
    func descriptorHashable() {
        let payload = Data([0x01, 0x02, 0x03])
        let desc1 = CIQRCodeDescriptor(
            payload: payload,
            symbolVersion: 1,
            maskPattern: 0,
            errorCorrectionLevel: .levelL
        )!
        let desc2 = CIQRCodeDescriptor(
            payload: payload,
            symbolVersion: 1,
            maskPattern: 0,
            errorCorrectionLevel: .levelL
        )!

        var set: Set<CIBarcodeDescriptor> = []
        set.insert(desc1)
        set.insert(desc2)
        #expect(set.count == 2)  // Different instances
    }
}

// MARK: - CIQRCodeDescriptor Tests

@Suite("CIQRCodeDescriptor")
struct CIQRCodeDescriptorTests {

    @Test("Initialize with valid parameters")
    func initWithValidParams() {
        let payload = Data([0x01, 0x02, 0x03])
        let descriptor = CIQRCodeDescriptor(
            payload: payload,
            symbolVersion: 1,
            maskPattern: 0,
            errorCorrectionLevel: .levelL
        )
        #expect(descriptor != nil)
        #expect(descriptor?.errorCorrectedPayload == payload)
        #expect(descriptor?.symbolVersion == 1)
        #expect(descriptor?.maskPattern == 0)
        #expect(descriptor?.errorCorrectionLevel == .levelL)
    }

    @Test("Initialize with max symbol version")
    func initWithMaxSymbolVersion() {
        let payload = Data([0x01])
        let descriptor = CIQRCodeDescriptor(
            payload: payload,
            symbolVersion: 40,
            maskPattern: 0,
            errorCorrectionLevel: .levelH
        )
        #expect(descriptor != nil)
        #expect(descriptor?.symbolVersion == 40)
    }

    @Test("Fail with invalid symbol version zero")
    func failWithInvalidVersionZero() {
        let payload = Data([0x01])
        let descriptor = CIQRCodeDescriptor(
            payload: payload,
            symbolVersion: 0,
            maskPattern: 0,
            errorCorrectionLevel: .levelL
        )
        #expect(descriptor == nil)
    }

    @Test("Fail with invalid symbol version over 40")
    func failWithInvalidVersionOver40() {
        let payload = Data([0x01])
        let descriptor = CIQRCodeDescriptor(
            payload: payload,
            symbolVersion: 41,
            maskPattern: 0,
            errorCorrectionLevel: .levelL
        )
        #expect(descriptor == nil)
    }

    @Test("Max mask pattern is 7")
    func maxMaskPattern() {
        let payload = Data([0x01])
        let descriptor = CIQRCodeDescriptor(
            payload: payload,
            symbolVersion: 1,
            maskPattern: 7,
            errorCorrectionLevel: .levelL
        )
        #expect(descriptor != nil)
        #expect(descriptor?.maskPattern == 7)
    }

    @Test("Fail with invalid mask pattern over 7")
    func failWithInvalidMaskPattern() {
        let payload = Data([0x01])
        let descriptor = CIQRCodeDescriptor(
            payload: payload,
            symbolVersion: 1,
            maskPattern: 8,
            errorCorrectionLevel: .levelL
        )
        #expect(descriptor == nil)
    }

    @Test("Error correction level L")
    func errorCorrectionLevelL() {
        #expect(CIQRCodeDescriptor.ErrorCorrectionLevel.levelL.rawValue == 0)
    }

    @Test("Error correction level M")
    func errorCorrectionLevelM() {
        #expect(CIQRCodeDescriptor.ErrorCorrectionLevel.levelM.rawValue == 1)
    }

    @Test("Error correction level Q")
    func errorCorrectionLevelQ() {
        #expect(CIQRCodeDescriptor.ErrorCorrectionLevel.levelQ.rawValue == 2)
    }

    @Test("Error correction level H")
    func errorCorrectionLevelH() {
        #expect(CIQRCodeDescriptor.ErrorCorrectionLevel.levelH.rawValue == 3)
    }
}

// MARK: - CIAztecCodeDescriptor Tests

@Suite("CIAztecCodeDescriptor")
struct CIAztecCodeDescriptorTests {

    @Test("Initialize with valid parameters")
    func initWithValidParams() {
        let payload = Data([0x01, 0x02, 0x03])
        let descriptor = CIAztecCodeDescriptor(
            payload: payload,
            isCompact: false,
            layerCount: 1,
            dataCodewordCount: 10
        )
        #expect(descriptor != nil)
        #expect(descriptor?.errorCorrectedPayload == payload)
        #expect(descriptor?.isCompact == false)
        #expect(descriptor?.layerCount == 1)
        #expect(descriptor?.dataCodewordCount == 10)
    }

    @Test("Initialize compact Aztec")
    func initCompactAztec() {
        let payload = Data([0x01])
        let descriptor = CIAztecCodeDescriptor(
            payload: payload,
            isCompact: true,
            layerCount: 1,
            dataCodewordCount: 5
        )
        #expect(descriptor != nil)
        #expect(descriptor?.isCompact == true)
    }

    @Test("Fail with invalid layer count zero")
    func failWithInvalidLayerCountZero() {
        let payload = Data([0x01])
        let descriptor = CIAztecCodeDescriptor(
            payload: payload,
            isCompact: false,
            layerCount: 0,
            dataCodewordCount: 10
        )
        #expect(descriptor == nil)
    }

    @Test("Fail with negative data codeword count")
    func failWithNegativeDataCodewordCount() {
        let payload = Data([0x01])
        let descriptor = CIAztecCodeDescriptor(
            payload: payload,
            isCompact: false,
            layerCount: 1,
            dataCodewordCount: -1
        )
        #expect(descriptor == nil)
    }

    @Test("Zero data codeword count is valid")
    func zeroDataCodewordCountValid() {
        let payload = Data([0x01])
        let descriptor = CIAztecCodeDescriptor(
            payload: payload,
            isCompact: false,
            layerCount: 1,
            dataCodewordCount: 0
        )
        #expect(descriptor != nil)
    }
}

// MARK: - CIPDF417CodeDescriptor Tests

@Suite("CIPDF417CodeDescriptor")
struct CIPDF417CodeDescriptorTests {

    @Test("Initialize with valid parameters")
    func initWithValidParams() {
        let payload = Data([0x01, 0x02, 0x03])
        let descriptor = CIPDF417CodeDescriptor(
            payload: payload,
            isCompact: false,
            rowCount: 10,
            columnCount: 5
        )
        #expect(descriptor != nil)
        #expect(descriptor?.errorCorrectedPayload == payload)
        #expect(descriptor?.isCompact == false)
        #expect(descriptor?.rowCount == 10)
        #expect(descriptor?.columnCount == 5)
    }

    @Test("Initialize compact PDF417")
    func initCompactPDF417() {
        let payload = Data([0x01])
        let descriptor = CIPDF417CodeDescriptor(
            payload: payload,
            isCompact: true,
            rowCount: 3,
            columnCount: 1
        )
        #expect(descriptor != nil)
        #expect(descriptor?.isCompact == true)
    }

    @Test("Min row count is 3")
    func minRowCount() {
        let payload = Data([0x01])
        let descriptor = CIPDF417CodeDescriptor(
            payload: payload,
            isCompact: false,
            rowCount: 3,
            columnCount: 1
        )
        #expect(descriptor != nil)
    }

    @Test("Fail with row count below 3")
    func failWithRowCountBelow3() {
        let payload = Data([0x01])
        let descriptor = CIPDF417CodeDescriptor(
            payload: payload,
            isCompact: false,
            rowCount: 2,
            columnCount: 1
        )
        #expect(descriptor == nil)
    }

    @Test("Max row count is 90")
    func maxRowCount() {
        let payload = Data([0x01])
        let descriptor = CIPDF417CodeDescriptor(
            payload: payload,
            isCompact: false,
            rowCount: 90,
            columnCount: 1
        )
        #expect(descriptor != nil)
    }

    @Test("Fail with row count above 90")
    func failWithRowCountAbove90() {
        let payload = Data([0x01])
        let descriptor = CIPDF417CodeDescriptor(
            payload: payload,
            isCompact: false,
            rowCount: 91,
            columnCount: 1
        )
        #expect(descriptor == nil)
    }

    @Test("Min column count is 1")
    func minColumnCount() {
        let payload = Data([0x01])
        let descriptor = CIPDF417CodeDescriptor(
            payload: payload,
            isCompact: false,
            rowCount: 3,
            columnCount: 1
        )
        #expect(descriptor != nil)
    }

    @Test("Fail with column count below 1")
    func failWithColumnCountBelow1() {
        let payload = Data([0x01])
        let descriptor = CIPDF417CodeDescriptor(
            payload: payload,
            isCompact: false,
            rowCount: 3,
            columnCount: 0
        )
        #expect(descriptor == nil)
    }

    @Test("Max column count is 30")
    func maxColumnCount() {
        let payload = Data([0x01])
        let descriptor = CIPDF417CodeDescriptor(
            payload: payload,
            isCompact: false,
            rowCount: 3,
            columnCount: 30
        )
        #expect(descriptor != nil)
    }

    @Test("Fail with column count above 30")
    func failWithColumnCountAbove30() {
        let payload = Data([0x01])
        let descriptor = CIPDF417CodeDescriptor(
            payload: payload,
            isCompact: false,
            rowCount: 3,
            columnCount: 31
        )
        #expect(descriptor == nil)
    }
}

// MARK: - CIDataMatrixCodeDescriptor Tests

@Suite("CIDataMatrixCodeDescriptor")
struct CIDataMatrixCodeDescriptorTests {

    @Test("Initialize with valid parameters")
    func initWithValidParams() {
        let payload = Data([0x01, 0x02, 0x03])
        let descriptor = CIDataMatrixCodeDescriptor(
            payload: payload,
            rowCount: 10,
            columnCount: 10,
            eccVersion: .v200
        )
        #expect(descriptor != nil)
        #expect(descriptor?.errorCorrectedPayload == payload)
        #expect(descriptor?.rowCount == 10)
        #expect(descriptor?.columnCount == 10)
        #expect(descriptor?.eccVersion == .v200)
    }

    @Test("Min row count is 10")
    func minRowCount() {
        let payload = Data([0x01])
        let descriptor = CIDataMatrixCodeDescriptor(
            payload: payload,
            rowCount: 10,
            columnCount: 10,
            eccVersion: .v200
        )
        #expect(descriptor != nil)
    }

    @Test("Fail with row count below 10")
    func failWithRowCountBelow10() {
        let payload = Data([0x01])
        let descriptor = CIDataMatrixCodeDescriptor(
            payload: payload,
            rowCount: 9,
            columnCount: 10,
            eccVersion: .v200
        )
        #expect(descriptor == nil)
    }

    @Test("Max row count is 144")
    func maxRowCount() {
        let payload = Data([0x01])
        let descriptor = CIDataMatrixCodeDescriptor(
            payload: payload,
            rowCount: 144,
            columnCount: 10,
            eccVersion: .v200
        )
        #expect(descriptor != nil)
    }

    @Test("Fail with row count above 144")
    func failWithRowCountAbove144() {
        let payload = Data([0x01])
        let descriptor = CIDataMatrixCodeDescriptor(
            payload: payload,
            rowCount: 145,
            columnCount: 10,
            eccVersion: .v200
        )
        #expect(descriptor == nil)
    }

    @Test("Min column count is 10")
    func minColumnCount() {
        let payload = Data([0x01])
        let descriptor = CIDataMatrixCodeDescriptor(
            payload: payload,
            rowCount: 10,
            columnCount: 10,
            eccVersion: .v200
        )
        #expect(descriptor != nil)
    }

    @Test("Fail with column count below 10")
    func failWithColumnCountBelow10() {
        let payload = Data([0x01])
        let descriptor = CIDataMatrixCodeDescriptor(
            payload: payload,
            rowCount: 10,
            columnCount: 9,
            eccVersion: .v200
        )
        #expect(descriptor == nil)
    }

    @Test("ECC version v000")
    func eccVersionV000() {
        #expect(CIDataMatrixCodeDescriptor.ECCVersion.v000.rawValue == 0)
    }

    @Test("ECC version v050")
    func eccVersionV050() {
        #expect(CIDataMatrixCodeDescriptor.ECCVersion.v050.rawValue == 50)
    }

    @Test("ECC version v080")
    func eccVersionV080() {
        #expect(CIDataMatrixCodeDescriptor.ECCVersion.v080.rawValue == 80)
    }

    @Test("ECC version v100")
    func eccVersionV100() {
        #expect(CIDataMatrixCodeDescriptor.ECCVersion.v100.rawValue == 100)
    }

    @Test("ECC version v140")
    func eccVersionV140() {
        #expect(CIDataMatrixCodeDescriptor.ECCVersion.v140.rawValue == 140)
    }

    @Test("ECC version v200")
    func eccVersionV200() {
        #expect(CIDataMatrixCodeDescriptor.ECCVersion.v200.rawValue == 200)
    }
}
