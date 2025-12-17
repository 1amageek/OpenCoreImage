//
//  CIBarcodeDescriptor.swift
//  OpenCoreImage
//
//  Barcode descriptor classes for representing machine-readable codes.
//

import Foundation

// MARK: - CIBarcodeDescriptor

/// An abstract base class that represents a machine-readable code's attributes.
///
/// Subclasses encapsulate the formal specification and fields specific to a code type.
/// Each subclass is sufficient to recreate the unique symbol exactly as seen or used
/// with a custom parser.
public class CIBarcodeDescriptor: @unchecked Sendable {

    // MARK: - Initialization

    internal init() {}
}

// MARK: - Equatable

extension CIBarcodeDescriptor: Equatable {
    public static func == (lhs: CIBarcodeDescriptor, rhs: CIBarcodeDescriptor) -> Bool {
        lhs === rhs
    }
}

// MARK: - Hashable

extension CIBarcodeDescriptor: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - CIQRCodeDescriptor

/// A concrete subclass of the Core Image Barcode Descriptor that represents a square QR code symbol.
///
/// ISO/IEC 18004 defines versions from 1 to 40, where a higher symbol version indicates
/// a larger data-carrying capacity. QR Codes can encode text, vCard contact information,
/// or Uniform Resource Identifiers (URI).
public final class CIQRCodeDescriptor: CIBarcodeDescriptor, @unchecked Sendable {

    // MARK: - Error Correction Level

    /// Constants indicating the percentage of the symbol that is dedicated to error correction.
    public enum ErrorCorrectionLevel: Int, Sendable {
        /// Error correction level L (7% recovery capacity)
        case levelL = 0
        /// Error correction level M (15% recovery capacity)
        case levelM = 1
        /// Error correction level Q (25% recovery capacity)
        case levelQ = 2
        /// Error correction level H (30% recovery capacity)
        case levelH = 3
    }

    // MARK: - Private Storage

    private let _errorCorrectedPayload: Data
    private let _symbolVersion: Int
    private let _maskPattern: UInt8
    private let _errorCorrectionLevel: ErrorCorrectionLevel

    // MARK: - Initialization

    /// Initializes a QR code descriptor for the given payload and parameters.
    public init?(payload: Data, symbolVersion: Int, maskPattern: UInt8, errorCorrectionLevel: ErrorCorrectionLevel) {
        guard symbolVersion >= 1 && symbolVersion <= 40 else { return nil }
        guard maskPattern <= 7 else { return nil }

        self._errorCorrectedPayload = payload
        self._symbolVersion = symbolVersion
        self._maskPattern = maskPattern
        self._errorCorrectionLevel = errorCorrectionLevel
        super.init()
    }

    // MARK: - Properties

    /// The error-corrected codeword payload that comprises the QR code symbol.
    public var errorCorrectedPayload: Data {
        _errorCorrectedPayload
    }

    /// The version of the QR code which corresponds to the size of the QR code symbol.
    public var symbolVersion: Int {
        _symbolVersion
    }

    /// The data mask pattern for the QR code symbol.
    public var maskPattern: UInt8 {
        _maskPattern
    }

    /// The error correction level of the QR code symbol.
    public var errorCorrectionLevel: ErrorCorrectionLevel {
        _errorCorrectionLevel
    }
}

// MARK: - CIAztecCodeDescriptor

/// A concrete subclass the Core Image Barcode Descriptor that represents an Aztec code symbol.
///
/// An Aztec code symbol is a 2D barcode format defined by the ISO/IEC 24778:2008 standard.
/// It encodes data in concentric square rings around a central bullseye pattern.
public final class CIAztecCodeDescriptor: CIBarcodeDescriptor, @unchecked Sendable {

    // MARK: - Private Storage

    private let _errorCorrectedPayload: Data
    private let _isCompact: Bool
    private let _layerCount: Int
    private let _dataCodewordCount: Int

    // MARK: - Initialization

    /// Initializes an Aztec code descriptor for the given payload and parameters.
    public init?(payload: Data, isCompact: Bool, layerCount: Int, dataCodewordCount: Int) {
        guard layerCount >= 1 else { return nil }
        guard dataCodewordCount >= 0 else { return nil }

        self._errorCorrectedPayload = payload
        self._isCompact = isCompact
        self._layerCount = layerCount
        self._dataCodewordCount = dataCodewordCount
        super.init()
    }

    // MARK: - Properties

    /// The error-corrected payload that comprises the the Aztec code symbol.
    public var errorCorrectedPayload: Data {
        _errorCorrectedPayload
    }

    /// A Boolean value telling if the Aztec code is compact.
    public var isCompact: Bool {
        _isCompact
    }

    /// The number of data layers in the Aztec code symbol.
    public var layerCount: Int {
        _layerCount
    }

    /// The number of non-error-correction codewords carried by the Aztec code symbol.
    public var dataCodewordCount: Int {
        _dataCodewordCount
    }
}

// MARK: - CIPDF417CodeDescriptor

/// A concrete subclass of Core Image Barcode Descriptor that represents a PDF417 symbol.
///
/// PDF417 is a stacked linear barcode symbol format used predominantly in transport,
/// ID cards, and inventory management. Each pattern in the code comprises 4 bars and spaces,
/// 17 units long.
public final class CIPDF417CodeDescriptor: CIBarcodeDescriptor, @unchecked Sendable {

    // MARK: - Private Storage

    private let _errorCorrectedPayload: Data
    private let _isCompact: Bool
    private let _rowCount: Int
    private let _columnCount: Int

    // MARK: - Initialization

    /// Initializes an PDF417 code descriptor for the given payload and parameters.
    public init?(payload: Data, isCompact: Bool, rowCount: Int, columnCount: Int) {
        guard rowCount >= 3 && rowCount <= 90 else { return nil }
        guard columnCount >= 1 && columnCount <= 30 else { return nil }

        self._errorCorrectedPayload = payload
        self._isCompact = isCompact
        self._rowCount = rowCount
        self._columnCount = columnCount
        super.init()
    }

    // MARK: - Properties

    /// The error-corrected payload containing the data encoded in the PDF417 code symbol.
    public var errorCorrectedPayload: Data {
        _errorCorrectedPayload
    }

    /// A boolean value telling if the PDF417 code is compact.
    public var isCompact: Bool {
        _isCompact
    }

    /// The number of rows in the PDF417 code symbol.
    public var rowCount: Int {
        _rowCount
    }

    /// The number of columns in the PDF417 code symbol.
    public var columnCount: Int {
        _columnCount
    }
}

// MARK: - CIDataMatrixCodeDescriptor

/// A concrete subclass the Core Image Barcode Descriptor that represents an Data Matrix code symbol.
///
/// A Data Matrix code symbol is a 2D barcode format defined by the ISO/IEC 16022:2006(E) standard.
/// It encodes data in square or rectangular symbol with solid lines on the left and bottom sides.
public final class CIDataMatrixCodeDescriptor: CIBarcodeDescriptor, @unchecked Sendable {

    // MARK: - ECC Version

    /// Constants indicating the Data Matrix code ECC version.
    public enum ECCVersion: Int, Sendable {
        /// ECC 000
        case v000 = 0
        /// ECC 050
        case v050 = 50
        /// ECC 080
        case v080 = 80
        /// ECC 100
        case v100 = 100
        /// ECC 140
        case v140 = 140
        /// ECC 200
        case v200 = 200
    }

    // MARK: - Private Storage

    private let _errorCorrectedPayload: Data
    private let _rowCount: Int
    private let _columnCount: Int
    private let _eccVersion: ECCVersion

    // MARK: - Initialization

    /// Initializes a Data Matrix code descriptor for the given payload and parameters.
    public init?(payload: Data, rowCount: Int, columnCount: Int, eccVersion: ECCVersion) {
        guard rowCount >= 10 && rowCount <= 144 else { return nil }
        guard columnCount >= 10 && columnCount <= 144 else { return nil }

        self._errorCorrectedPayload = payload
        self._rowCount = rowCount
        self._columnCount = columnCount
        self._eccVersion = eccVersion
        super.init()
    }

    // MARK: - Properties

    /// The error-corrected payload containing the data encoded in the Data Matrix code symbol.
    public var errorCorrectedPayload: Data {
        _errorCorrectedPayload
    }

    /// The number of rows in the Data Matrix code symbol.
    public var rowCount: Int {
        _rowCount
    }

    /// The number of columns in the Data Matrix code symbol.
    public var columnCount: Int {
        _columnCount
    }

    /// The error correction version of the Data Matrix code symbol.
    public var eccVersion: ECCVersion {
        _eccVersion
    }
}
