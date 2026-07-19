//
//  CIRAWFilter.swift
//  OpenCoreImage
//
//  A filter subclass that produces an image by manipulating RAW image sensor data
//  from a digital camera or scanner. Full WASM implementation with demosaicing,
//  white balance, exposure, and other RAW processing algorithms.
//


// MARK: - CIRAWDecoderVersion

/// A structure that represents a decoder version for RAW image processing.
public struct CIRAWDecoderVersion: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Version 8 decoder.
    public static let version8 = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersion8")

    /// Version 8 DNG decoder.
    public static let version8DNG = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersion8DNG")

    /// Version None decoder.
    public static let versionNone = CIRAWDecoderVersion(rawValue: "CIRAWDecoderVersionNone")
}

// MARK: - Bayer Pattern

/// Represents the Bayer color filter array pattern
private enum BayerPattern {
    case rggb  // Red-Green-Green-Blue (most common)
    case bggr  // Blue-Green-Green-Red
    case grbg  // Green-Red-Blue-Green
    case gbrg  // Green-Blue-Red-Green

    /// Get color at position (x, y) in the pattern
    func colorAt(x: Int, y: Int) -> BayerColor {
        let evenRow = y % 2 == 0
        let evenCol = x % 2 == 0

        switch self {
        case .rggb:
            if evenRow {
                return evenCol ? .red : .green
            } else {
                return evenCol ? .green : .blue
            }
        case .bggr:
            if evenRow {
                return evenCol ? .blue : .green
            } else {
                return evenCol ? .green : .red
            }
        case .grbg:
            if evenRow {
                return evenCol ? .green : .red
            } else {
                return evenCol ? .blue : .green
            }
        case .gbrg:
            if evenRow {
                return evenCol ? .green : .blue
            } else {
                return evenCol ? .red : .green
            }
        }
    }
}

private enum BayerColor {
    case red
    case green
    case blue
}

// MARK: - RAW Processing Pipeline

/// Internal class for RAW image processing
private final class RAWProcessor {

    private let rawData: [UInt16]
    private let width: Int
    private let height: Int
    private let bayerPattern: BayerPattern
    private let blackLevel: UInt16
    private let whiteLevel: UInt16

    init(rawData: [UInt16], width: Int, height: Int,
         bayerPattern: BayerPattern = .rggb,
         blackLevel: UInt16 = 0, whiteLevel: UInt16 = 65535) {
        self.rawData = rawData
        self.width = width
        self.height = height
        self.bayerPattern = bayerPattern
        self.blackLevel = blackLevel
        self.whiteLevel = whiteLevel
    }

    /// Main processing pipeline
    func process(
        exposure: Float,
        whiteBalanceR: Float,
        whiteBalanceG: Float,
        whiteBalanceB: Float,
        shadowBias: Float,
        boostAmount: Float,
        boostShadowAmount: Float,
        contrastAmount: Float,
        sharpnessAmount: Float,
        noiseReductionAmount: Float,
        gamma: Float = 2.2
    ) -> [UInt8] {

        // Step 1: Black level subtraction and normalization
        var linearData = subtractBlackLevel()

        // Step 2: White balance correction
        applyWhiteBalance(&linearData, r: whiteBalanceR, g: whiteBalanceG, b: whiteBalanceB)

        // Step 3: Demosaic (Bayer interpolation)
        var rgbData = demosaic(linearData)

        // Step 4: Apply exposure adjustment
        applyExposure(&rgbData, exposure: exposure)

        // Step 5: Apply shadow/highlight adjustments
        applyShadowHighlight(&rgbData, shadowBias: shadowBias,
                             boostAmount: boostAmount, boostShadowAmount: boostShadowAmount)

        // Step 6: Apply noise reduction
        if noiseReductionAmount > 0 {
            applyNoiseReduction(&rgbData, amount: noiseReductionAmount)
        }

        // Step 7: Apply contrast
        if contrastAmount != 0 {
            applyContrast(&rgbData, amount: contrastAmount)
        }

        // Step 8: Apply sharpening
        if sharpnessAmount > 0 {
            applySharpening(&rgbData, amount: sharpnessAmount)
        }

        // Step 9: Apply gamma correction (linear to sRGB)
        applyGammaCorrection(&rgbData, gamma: gamma)

        // Step 10: Convert to 8-bit output
        return convertTo8Bit(rgbData)
    }

    // MARK: - Processing Steps

    private func subtractBlackLevel() -> [Float] {
        let range = Float(whiteLevel - blackLevel)
        return rawData.map { pixel in
            let value = Float(max(pixel, blackLevel) - blackLevel)
            return value / range
        }
    }

    private func applyWhiteBalance(_ data: inout [Float], r: Float, g: Float, b: Float) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let color = bayerPattern.colorAt(x: x, y: y)

                switch color {
                case .red:
                    data[index] *= r
                case .green:
                    data[index] *= g
                case .blue:
                    data[index] *= b
                }
            }
        }
    }

    /// Demosaic using bilinear interpolation
    private func demosaic(_ data: [Float]) -> [(r: Float, g: Float, b: Float)] {
        var result = [(r: Float, g: Float, b: Float)](repeating: (0, 0, 0), count: width * height)

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let index = y * width + x
                let color = bayerPattern.colorAt(x: x, y: y)

                var r: Float = 0
                var g: Float = 0
                var b: Float = 0

                switch color {
                case .red:
                    // At red pixel
                    r = data[index]
                    // Green from 4 neighbors
                    g = (data[index - 1] + data[index + 1] +
                         data[index - width] + data[index + width]) / 4
                    // Blue from 4 diagonal neighbors
                    b = (data[index - width - 1] + data[index - width + 1] +
                         data[index + width - 1] + data[index + width + 1]) / 4

                case .green:
                    g = data[index]
                    // Check if we're on a red row or blue row
                    let isRedRow = bayerPattern.colorAt(x: x - 1, y: y) == .red ||
                                   bayerPattern.colorAt(x: x + 1, y: y) == .red

                    if isRedRow {
                        // Red from horizontal neighbors
                        r = (data[index - 1] + data[index + 1]) / 2
                        // Blue from vertical neighbors
                        b = (data[index - width] + data[index + width]) / 2
                    } else {
                        // Blue from horizontal neighbors
                        b = (data[index - 1] + data[index + 1]) / 2
                        // Red from vertical neighbors
                        r = (data[index - width] + data[index + width]) / 2
                    }

                case .blue:
                    // At blue pixel
                    b = data[index]
                    // Green from 4 neighbors
                    g = (data[index - 1] + data[index + 1] +
                         data[index - width] + data[index + width]) / 4
                    // Red from 4 diagonal neighbors
                    r = (data[index - width - 1] + data[index - width + 1] +
                         data[index + width - 1] + data[index + width + 1]) / 4
                }

                result[index] = (r: r, g: g, b: b)
            }
        }

        // Handle edges by copying nearest interior pixels
        for x in 0..<width {
            result[x] = result[width + x]
            result[(height - 1) * width + x] = result[(height - 2) * width + x]
        }
        for y in 0..<height {
            result[y * width] = result[y * width + 1]
            result[y * width + width - 1] = result[y * width + width - 2]
        }

        return result
    }

    private func applyExposure(_ data: inout [(r: Float, g: Float, b: Float)], exposure: Float) {
        let factor = pow(2.0, exposure)
        for i in 0..<data.count {
            data[i].r *= factor
            data[i].g *= factor
            data[i].b *= factor
        }
    }

    private func applyShadowHighlight(_ data: inout [(r: Float, g: Float, b: Float)],
                                       shadowBias: Float, boostAmount: Float,
                                       boostShadowAmount: Float) {
        for i in 0..<data.count {
            var (r, g, b) = data[i]

            // Calculate luminance
            let lum = 0.299 * r + 0.587 * g + 0.114 * b

            // Shadow bias subtraction
            r = max(0, r - shadowBias)
            g = max(0, g - shadowBias)
            b = max(0, b - shadowBias)

            // Boost shadows (lift dark areas)
            if lum < 0.5 && boostShadowAmount > 0 {
                let shadowFactor = 1 + boostShadowAmount * (0.5 - lum) * 2
                r *= shadowFactor
                g *= shadowFactor
                b *= shadowFactor
            }

            // Global boost (tone curve)
            if boostAmount != 1 {
                r = pow(r, 1.0 / boostAmount)
                g = pow(g, 1.0 / boostAmount)
                b = pow(b, 1.0 / boostAmount)
            }

            data[i] = (r, g, b)
        }
    }

    private func applyNoiseReduction(_ data: inout [(r: Float, g: Float, b: Float)], amount: Float) {
        // Simple bilateral-like noise reduction
        let kernelSize = 3
        let half = kernelSize / 2
        let sigma = amount * 0.1

        var result = data

        for y in half..<(height - half) {
            for x in half..<(width - half) {
                let index = y * width + x
                let center = data[index]

                var sumR: Float = 0
                var sumG: Float = 0
                var sumB: Float = 0
                var weightSum: Float = 0

                for ky in -half...half {
                    for kx in -half...half {
                        let neighborIndex = (y + ky) * width + (x + kx)
                        let neighbor = data[neighborIndex]

                        // Calculate color distance
                        let dr = center.r - neighbor.r
                        let dg = center.g - neighbor.g
                        let db = center.b - neighbor.b
                        let colorDist = sqrt(dr * dr + dg * dg + db * db)

                        // Calculate spatial weight
                        let spatialDist = sqrt(Float(kx * kx + ky * ky))

                        // Combined weight
                        let weight = exp(-spatialDist / 2) * exp(-colorDist / (2 * sigma * sigma))

                        sumR += neighbor.r * weight
                        sumG += neighbor.g * weight
                        sumB += neighbor.b * weight
                        weightSum += weight
                    }
                }

                if weightSum > 0 {
                    result[index] = (r: sumR / weightSum,
                                     g: sumG / weightSum,
                                     b: sumB / weightSum)
                }
            }
        }

        data = result
    }

    private func applyContrast(_ data: inout [(r: Float, g: Float, b: Float)], amount: Float) {
        // S-curve contrast adjustment
        let contrastFactor = 1 + amount

        for i in 0..<data.count {
            var (r, g, b) = data[i]

            // Apply contrast around midpoint (0.5)
            r = ((r - 0.5) * contrastFactor) + 0.5
            g = ((g - 0.5) * contrastFactor) + 0.5
            b = ((b - 0.5) * contrastFactor) + 0.5

            data[i] = (max(0, r), max(0, g), max(0, b))
        }
    }

    private func applySharpening(_ data: inout [(r: Float, g: Float, b: Float)], amount: Float) {
        // Unsharp masking
        var blurred = data

        // Create blurred version (simple box blur)
        let kernelSize = 3
        let half = kernelSize / 2

        for y in half..<(height - half) {
            for x in half..<(width - half) {
                var sumR: Float = 0
                var sumG: Float = 0
                var sumB: Float = 0

                for ky in -half...half {
                    for kx in -half...half {
                        let neighborIndex = (y + ky) * width + (x + kx)
                        sumR += data[neighborIndex].r
                        sumG += data[neighborIndex].g
                        sumB += data[neighborIndex].b
                    }
                }

                let count = Float(kernelSize * kernelSize)
                blurred[y * width + x] = (r: sumR / count,
                                          g: sumG / count,
                                          b: sumB / count)
            }
        }

        // Apply unsharp mask: original + amount * (original - blurred)
        for i in 0..<data.count {
            let original = data[i]
            let blur = blurred[i]

            data[i] = (
                r: original.r + amount * (original.r - blur.r),
                g: original.g + amount * (original.g - blur.g),
                b: original.b + amount * (original.b - blur.b)
            )
        }
    }

    private func applyGammaCorrection(_ data: inout [(r: Float, g: Float, b: Float)], gamma: Float) {
        let invGamma = 1.0 / gamma

        for i in 0..<data.count {
            var (r, g, b) = data[i]

            // Clamp before gamma
            r = max(0, min(1, r))
            g = max(0, min(1, g))
            b = max(0, min(1, b))

            // Apply sRGB-like gamma
            r = r <= 0.0031308 ? 12.92 * r : 1.055 * pow(r, invGamma) - 0.055
            g = g <= 0.0031308 ? 12.92 * g : 1.055 * pow(g, invGamma) - 0.055
            b = b <= 0.0031308 ? 12.92 * b : 1.055 * pow(b, invGamma) - 0.055

            data[i] = (r, g, b)
        }
    }

    private func convertTo8Bit(_ data: [(r: Float, g: Float, b: Float)]) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: width * height * 4)

        for i in 0..<data.count {
            let (r, g, b) = data[i]

            result[i * 4 + 0] = UInt8(max(0, min(255, r * 255)))
            result[i * 4 + 1] = UInt8(max(0, min(255, g * 255)))
            result[i * 4 + 2] = UInt8(max(0, min(255, b * 255)))
            result[i * 4 + 3] = 255  // Alpha
        }

        return result
    }
}

// MARK: - DNG Header Parser

/// TIFF/DNG parser for uncompressed single-channel CFA image data.
private struct DNGParser {

    private enum ByteOrder {
        case littleEndian
        case bigEndian
    }

    private struct Entry {
        let type: UInt16
        let count: UInt32
        let valueFieldOffset: Int
    }

    struct RAWInfo {
        var width: Int
        var height: Int
        var bitsPerSample: Int
        var rawData: [UInt16]
        var bayerPattern: BayerPattern
        var blackLevel: UInt16
        var whiteLevel: UInt16
    }

    /// Parses uncompressed 8-bit or 16-bit CFA strips from a TIFF/DNG IFD.
    ///
    /// Compressed RAW formats and tiled storage are rejected. Returning `nil`
    /// is important here: callers must never receive fabricated pixels for an
    /// input that the decoder does not understand.
    static func parse(data: Data) -> RAWInfo? {
        guard data.count >= 8 else { return nil }

        let byteOrder: ByteOrder
        switch (data[0], data[1]) {
        case (0x49, 0x49):
            byteOrder = .littleEndian
        case (0x4D, 0x4D):
            byteOrder = .bigEndian
        default:
            return nil
        }

        guard readUInt16(data, at: 2, order: byteOrder) == 42,
              let rootOffsetValue = readUInt32(data, at: 4, order: byteOrder)
        else {
            return nil
        }

        var pendingOffsets = [Int(rootOffsetValue)]
        var visitedOffsets: Set<Int> = []

        while let ifdOffset = pendingOffsets.popLast() {
            guard visitedOffsets.insert(ifdOffset).inserted,
                  let parsedIFD = parseIFD(data, at: ifdOffset, order: byteOrder)
            else {
                continue
            }

            pendingOffsets.append(contentsOf: parsedIFD.linkedOffsets)
            if let rawInfo = decodeRAWInfo(
                entries: parsedIFD.entries,
                data: data,
                order: byteOrder
            ) {
                return rawInfo
            }
        }

        return nil
    }

    private static func parseIFD(
        _ data: Data,
        at offset: Int,
        order: ByteOrder
    ) -> (entries: [UInt16: Entry], linkedOffsets: [Int])? {
        guard let entryCount = readUInt16(data, at: offset, order: order) else {
            return nil
        }

        let entriesOffset = offset + 2
        let entriesByteCount = Int(entryCount) * 12
        guard entriesOffset >= 0,
              entriesByteCount >= 0,
              entriesOffset <= data.count - entriesByteCount,
              entriesOffset + entriesByteCount <= data.count - 4
        else {
            return nil
        }

        var entries: [UInt16: Entry] = [:]
        for index in 0..<Int(entryCount) {
            let entryOffset = entriesOffset + index * 12
            guard let tag = readUInt16(data, at: entryOffset, order: order),
                  let type = readUInt16(data, at: entryOffset + 2, order: order),
                  let count = readUInt32(data, at: entryOffset + 4, order: order)
            else {
                return nil
            }
            entries[tag] = Entry(type: type, count: count, valueFieldOffset: entryOffset + 8)
        }

        var linkedOffsets: [Int] = []
        let nextOffsetPosition = entriesOffset + entriesByteCount
        if let nextOffset = readUInt32(data, at: nextOffsetPosition, order: order), nextOffset != 0 {
            linkedOffsets.append(Int(nextOffset))
        }
        if let subIFDs = entries[330] {
            linkedOffsets.append(contentsOf: integerValues(
                for: subIFDs,
                data: data,
                order: order
            ).map(Int.init))
        }

        return (entries, linkedOffsets)
    }

    private static func decodeRAWInfo(
        entries: [UInt16: Entry],
        data: Data,
        order: ByteOrder
    ) -> RAWInfo? {
        guard let width = firstInteger(tag: 256, entries: entries, data: data, order: order),
              let height = firstInteger(tag: 257, entries: entries, data: data, order: order),
              let bits = firstInteger(tag: 258, entries: entries, data: data, order: order),
              let compression = firstInteger(tag: 259, entries: entries, data: data, order: order),
              let photometric = firstInteger(tag: 262, entries: entries, data: data, order: order),
              let stripEntry = entries[273],
              let stripByteCountEntry = entries[279],
              width >= 3,
              height >= 3,
              bits == 8 || bits == 16,
              compression == 1,
              photometric == 32803,
              firstInteger(tag: 277, entries: entries, data: data, order: order) ?? 1 == 1
        else {
            return nil
        }

        let stripOffsets = integerValues(for: stripEntry, data: data, order: order)
        let stripByteCounts = integerValues(for: stripByteCountEntry, data: data, order: order)
        guard !stripOffsets.isEmpty, stripOffsets.count == stripByteCounts.count else {
            return nil
        }

        let pixelCount = Int(width) * Int(height)
        guard pixelCount / Int(width) == Int(height) else { return nil }
        let bytesPerSample = Int(bits / 8)
        let expectedByteCount = pixelCount * bytesPerSample
        guard expectedByteCount / bytesPerSample == pixelCount else { return nil }

        var sampleBytes = Data(capacity: expectedByteCount)
        for (stripOffsetValue, stripByteCountValue) in zip(stripOffsets, stripByteCounts) {
            let stripOffset = Int(stripOffsetValue)
            let stripByteCount = Int(stripByteCountValue)
            guard stripOffset >= 0,
                  stripByteCount >= 0,
                  stripOffset <= data.count - stripByteCount
            else {
                return nil
            }
            sampleBytes.append(data[stripOffset..<(stripOffset + stripByteCount)])
        }
        guard sampleBytes.count == expectedByteCount else { return nil }

        var rawData = [UInt16]()
        rawData.reserveCapacity(pixelCount)
        if bits == 8 {
            rawData.append(contentsOf: sampleBytes.map { UInt16($0) * 257 })
        } else {
            for offset in stride(from: 0, to: sampleBytes.count, by: 2) {
                guard let value = readUInt16(sampleBytes, at: offset, order: order) else {
                    return nil
                }
                rawData.append(value)
            }
        }

        let pattern = bayerPattern(entries: entries, data: data, order: order) ?? .rggb
        let blackLevel = numericValue(tag: 50714, entries: entries, data: data, order: order)
            .map { UInt16(clamping: Int($0.rounded())) } ?? 0
        let defaultWhiteLevel = bits == 16 ? UInt16.max : UInt16(255 * 257)
        let whiteLevel = numericValue(tag: 50717, entries: entries, data: data, order: order)
            .map { UInt16(clamping: Int($0.rounded())) } ?? defaultWhiteLevel
        guard whiteLevel > blackLevel else { return nil }

        return RAWInfo(
            width: Int(width),
            height: Int(height),
            bitsPerSample: Int(bits),
            rawData: rawData,
            bayerPattern: pattern,
            blackLevel: blackLevel,
            whiteLevel: whiteLevel
        )
    }

    private static func bayerPattern(
        entries: [UInt16: Entry],
        data: Data,
        order: ByteOrder
    ) -> BayerPattern? {
        if let repeatEntry = entries[33421] {
            let dimensions = integerValues(for: repeatEntry, data: data, order: order)
            guard dimensions == [2, 2] else { return nil }
        }
        guard let patternEntry = entries[33422],
              let bytes = valueBytes(for: patternEntry, data: data, order: order),
              bytes.count >= 4
        else {
            return nil
        }
        switch Array(bytes.prefix(4)) {
        case [0, 1, 1, 2]: return .rggb
        case [2, 1, 1, 0]: return .bggr
        case [1, 0, 2, 1]: return .grbg
        case [1, 2, 0, 1]: return .gbrg
        default: return nil
        }
    }

    private static func firstInteger(
        tag: UInt16,
        entries: [UInt16: Entry],
        data: Data,
        order: ByteOrder
    ) -> UInt32? {
        guard let entry = entries[tag] else { return nil }
        return integerValues(for: entry, data: data, order: order).first
    }

    private static func integerValues(
        for entry: Entry,
        data: Data,
        order: ByteOrder
    ) -> [UInt32] {
        guard let bytes = valueBytes(for: entry, data: data, order: order) else { return [] }
        switch entry.type {
        case 1:
            return bytes.map(UInt32.init)
        case 3:
            return stride(from: 0, to: bytes.count, by: 2).compactMap {
                readUInt16(bytes, at: $0, order: order).map(UInt32.init)
            }
        case 4:
            return stride(from: 0, to: bytes.count, by: 4).compactMap {
                readUInt32(bytes, at: $0, order: order)
            }
        default:
            return []
        }
    }

    private static func numericValue(
        tag: UInt16,
        entries: [UInt16: Entry],
        data: Data,
        order: ByteOrder
    ) -> Double? {
        guard let entry = entries[tag],
              let bytes = valueBytes(for: entry, data: data, order: order)
        else {
            return nil
        }
        if entry.type == 5,
           let numerator = readUInt32(bytes, at: 0, order: order),
           let denominator = readUInt32(bytes, at: 4, order: order),
           denominator != 0 {
            return Double(numerator) / Double(denominator)
        }
        return integerValues(for: entry, data: data, order: order).first.map(Double.init)
    }

    private static func valueBytes(
        for entry: Entry,
        data: Data,
        order: ByteOrder
    ) -> Data? {
        let typeSize: Int
        switch entry.type {
        case 1: typeSize = 1
        case 3: typeSize = 2
        case 4: typeSize = 4
        case 5: typeSize = 8
        default: return nil
        }
        let count = Int(entry.count)
        guard count == 0 || count <= Int.max / typeSize else { return nil }
        let byteCount = count * typeSize
        let valueOffset: Int
        if byteCount <= 4 {
            valueOffset = entry.valueFieldOffset
        } else {
            guard let externalOffset = readUInt32(data, at: entry.valueFieldOffset, order: order) else {
                return nil
            }
            valueOffset = Int(externalOffset)
        }
        guard valueOffset >= 0,
              byteCount >= 0,
              valueOffset <= data.count - byteCount
        else {
            return nil
        }
        return Data(data[valueOffset..<(valueOffset + byteCount)])
    }

    private static func readUInt16(_ data: Data, at offset: Int, order: ByteOrder) -> UInt16? {
        guard offset >= 0, offset <= data.count - 2 else { return nil }
        switch order {
        case .littleEndian:
            return UInt16(data[offset]) | UInt16(data[offset + 1]) << 8
        case .bigEndian:
            return UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
        }
    }

    private static func readUInt32(_ data: Data, at offset: Int, order: ByteOrder) -> UInt32? {
        guard offset >= 0, offset <= data.count - 4 else { return nil }
        switch order {
        case .littleEndian:
            return UInt32(data[offset])
                | UInt32(data[offset + 1]) << 8
                | UInt32(data[offset + 2]) << 16
                | UInt32(data[offset + 3]) << 24
        case .bigEndian:
            return UInt32(data[offset]) << 24
                | UInt32(data[offset + 1]) << 16
                | UInt32(data[offset + 2]) << 8
                | UInt32(data[offset + 3])
        }
    }
}

// MARK: - CIRAWFilter

/// A filter subclass that produces an image by manipulating RAW image sensor data
/// from a digital camera or scanner.
///
/// Use this class to generate a `CIImage` object based on the configuration parameters you provide.
///
/// You can use this object in conjunction with other Core Image classes—such as `CIFilter` and
/// `CIContext`—to take advantage of the built-in Core Image filters when processing images or
/// writing custom filters.
public class CIRAWFilter: CIFilter {

    // MARK: - Private Storage

    private var _imageData: Data?
    private var _imageURL: URL?
    private var _parsedRAWInfo: DNGParser.RAWInfo?
    private var _cachedOutput: CIImage?

    // Configuration
    private var _baselineExposure: Float = 0
    private var _boostAmount: Float = 1
    private var _boostShadowAmount: Float = 0
    private var _colorNoiseReductionAmount: Float = 0
    private var _contrastAmount: Float = 0
    private var _decoderVersion: CIRAWDecoderVersion = .version8
    private var _detailAmount: Float = 0
    private var _exposure: Float = 0
    private var _extendedDynamicRangeAmount: Float = 0
    private var _isDraftModeEnabled: Bool = false
    private var _isGamutMappingEnabled: Bool = true
    private var _isLensCorrectionEnabled: Bool = false
    private var _linearSpaceFilter: CIFilter?
    private var _localToneMapAmount: Float = 0
    private var _luminanceNoiseReductionAmount: Float = 0
    private var _moireReductionAmount: Float = 0
    private var _neutralChromaticity: CGPoint = .zero
    private var _neutralLocation: CGPoint = .zero
    private var _neutralTemperature: Float = 5000
    private var _neutralTint: Float = 0
    private var _orientation: CGImagePropertyOrientation = .up
    private var _portraitEffectsMatte: CIImage?
    private var _previewImage: CIImage?
    private var _properties: [AnyHashable: Any] = [:]
    private var _scaleFactor: Float = 1
    private var _shadowBias: Float = 0
    private var _sharpnessAmount: Float = 0
    private var _semanticSegmentationGlassesMatte: CIImage?
    private var _semanticSegmentationHairMatte: CIImage?
    private var _semanticSegmentationSkinMatte: CIImage?
    private var _semanticSegmentationSkyMatte: CIImage?
    private var _semanticSegmentationTeethMatte: CIImage?
    private var _isHighlightRecoveryEnabled: Bool = false

    // MARK: - Initialization

    /// Creates a RAW filter from the image at the URL location that you specify.
    ///
    /// Returns `nil` when the file cannot be read or the data is not a
    /// recognizable RAW/DNG container. This matches Apple's failable-init
    /// contract — callers rely on `nil` to branch to a non-RAW path rather
    /// than getting back a filter that silently produces a placeholder image.
    public convenience init?(imageURL: URL) {
        let data: Data
        do {
            data = try Data(contentsOf: imageURL)
        } catch {
            return nil
        }
        guard let parsed = DNGParser.parse(data: data) else {
            return nil
        }
        self.init(filterName: "CIRAWFilter")
        self._imageURL = imageURL
        self._imageData = data
        self._parsedRAWInfo = parsed
    }

    /// Creates a RAW filter from the image data and type hint that you specify.
    ///
    /// Returns `nil` when the data is not a recognizable RAW/DNG container.
    public convenience init?(imageData: Data, identifierHint: String?) {
        guard let parsed = DNGParser.parse(data: imageData) else {
            return nil
        }
        self.init(filterName: "CIRAWFilter")
        self._imageData = imageData
        self._parsedRAWInfo = parsed
    }

    // MARK: - Class Properties

    /// An array containing the names of all supported camera models.
    public class var supportedCameraModels: [String] {
        // The built-in decoder supports a constrained TIFF/DNG storage layout,
        // not vendor camera profiles. Do not advertise unverified models.
        []
    }

    // MARK: - Supported Features

    /// An array of all supported decoder versions for the given image type.
    public var supportedDecoderVersions: [CIRAWDecoderVersion] {
        [.version8, .version8DNG, .versionNone]
    }

    /// A Boolean that indicates if the current image supports color noise reduction adjustments.
    public var isColorNoiseReductionSupported: Bool {
        _parsedRAWInfo != nil
    }

    /// A Boolean that indicates if the current image supports contrast adjustments.
    public var isContrastSupported: Bool {
        _parsedRAWInfo != nil
    }

    /// A Boolean that indicates if the current image supports detail enhancement adjustments.
    public var isDetailSupported: Bool {
        _parsedRAWInfo != nil
    }

    /// A Boolean that indicates if you can enable lens correction for the current image.
    public var isLensCorrectionSupported: Bool {
        // Lens correction requires lens profile data
        false
    }

    /// A Boolean that indicates if the current image supports local tone curve adjustments.
    public var isLocalToneMapSupported: Bool {
        false
    }

    /// A Boolean that indicates if the current image supports luminance noise reduction adjustments.
    public var isLuminanceNoiseReductionSupported: Bool {
        _parsedRAWInfo != nil
    }

    /// A Boolean that indicates if the current image supports moire artifact reduction adjustments.
    public var isMoireReductionSupported: Bool {
        false
    }

    /// A Boolean that indicates if the current image supports sharpness adjustments.
    public var isSharpnessSupported: Bool {
        _parsedRAWInfo != nil
    }

    /// A Boolean that indicates if the current image supports highlight recovery.
    public var isHighlightRecoverySupported: Bool {
        false
    }

    /// The full native size of the unscaled image.
    public var nativeSize: CGSize {
        if let info = _parsedRAWInfo {
            return CGSize(width: info.width, height: info.height)
        }
        return .zero
    }

    // MARK: - Configuration Properties

    /// A value that indicates the baseline exposure to apply to the image.
    public var baselineExposure: Float {
        get { _baselineExposure }
        set { _baselineExposure = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of global tone curve to apply to the image.
    public var boostAmount: Float {
        get { _boostAmount }
        set { _boostAmount = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount to boost the shadow areas of the image.
    public var boostShadowAmount: Float {
        get { _boostShadowAmount }
        set { _boostShadowAmount = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of chroma noise reduction to apply to the image.
    public var colorNoiseReductionAmount: Float {
        get { _colorNoiseReductionAmount }
        set { _colorNoiseReductionAmount = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of local contrast to apply to the edges of the image.
    public var contrastAmount: Float {
        get { _contrastAmount }
        set { _contrastAmount = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the decoder version to use.
    public var decoderVersion: CIRAWDecoderVersion {
        get { _decoderVersion }
        set { _decoderVersion = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of detail enhancement to apply to the edges of the image.
    public var detailAmount: Float {
        get { _detailAmount }
        set { _detailAmount = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of exposure to apply to the image.
    public var exposure: Float {
        get { _exposure }
        set { _exposure = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of extended dynamic range (EDR) to apply to the image.
    public var extendedDynamicRangeAmount: Float {
        get { _extendedDynamicRangeAmount }
        set { _extendedDynamicRangeAmount = newValue; _cachedOutput = nil }
    }

    /// A Boolean that indicates whether to enable draft mode.
    public var isDraftModeEnabled: Bool {
        get { _isDraftModeEnabled }
        set { _isDraftModeEnabled = newValue; _cachedOutput = nil }
    }

    /// A Boolean that indicates whether to enable gamut mapping.
    public var isGamutMappingEnabled: Bool {
        get { _isGamutMappingEnabled }
        set { _isGamutMappingEnabled = newValue; _cachedOutput = nil }
    }

    /// A Boolean that indicates whether to enable lens correction.
    public var isLensCorrectionEnabled: Bool {
        get { _isLensCorrectionEnabled }
        set { _isLensCorrectionEnabled = newValue; _cachedOutput = nil }
    }

    /// A Boolean that indicates whether to enable highlight recovery.
    public var isHighlightRecoveryEnabled: Bool {
        get { _isHighlightRecoveryEnabled }
        set { _isHighlightRecoveryEnabled = newValue; _cachedOutput = nil }
    }

    /// An optional filter you can apply to the RAW image while it's in linear space.
    public var linearSpaceFilter: CIFilter? {
        get { _linearSpaceFilter }
        set { _linearSpaceFilter = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of local tone curve to apply to the image.
    public var localToneMapAmount: Float {
        get { _localToneMapAmount }
        set { _localToneMapAmount = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of luminance noise reduction to apply to the image.
    public var luminanceNoiseReductionAmount: Float {
        get { _luminanceNoiseReductionAmount }
        set { _luminanceNoiseReductionAmount = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of moire artifact reduction to apply to high frequency areas of the image.
    public var moireReductionAmount: Float {
        get { _moireReductionAmount }
        set { _moireReductionAmount = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of white balance based on chromaticity values to apply to the image.
    public var neutralChromaticity: CGPoint {
        get { _neutralChromaticity }
        set { _neutralChromaticity = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of white balance based on pixel coordinates to apply to the image.
    public var neutralLocation: CGPoint {
        get { _neutralLocation }
        set { _neutralLocation = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of white balance based on temperature values to apply to the image.
    public var neutralTemperature: Float {
        get { _neutralTemperature }
        set { _neutralTemperature = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of white balance based on tint values to apply to the image.
    public var neutralTint: Float {
        get { _neutralTint }
        set { _neutralTint = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the orientation of the image.
    public var orientation: CGImagePropertyOrientation {
        get { _orientation }
        set { _orientation = newValue; _cachedOutput = nil }
    }

    /// An optional auxiliary image that represents the portrait effects matte of the image.
    public var portraitEffectsMatte: CIImage? {
        get { _portraitEffectsMatte }
        set { _portraitEffectsMatte = newValue }
    }

    /// An optional auxiliary image that represents a preview of the original image.
    public var previewImage: CIImage? {
        get { _previewImage }
        set { _previewImage = newValue }
    }

    /// A dictionary that contains properties of the image source.
    public var properties: [AnyHashable: Any] {
        get { _properties }
        set { _properties = newValue }
    }

    /// A value that indicates the desired scale factor to draw the output image.
    public var scaleFactor: Float {
        get { _scaleFactor }
        set { _scaleFactor = max(0.1, min(1.0, newValue)); _cachedOutput = nil }
    }

    /// An optional auxiliary image that represents the semantic segmentation glasses matte of the image.
    public var semanticSegmentationGlassesMatte: CIImage? {
        get { _semanticSegmentationGlassesMatte }
        set { _semanticSegmentationGlassesMatte = newValue }
    }

    /// An optional auxiliary image that represents the semantic segmentation hair matte of the image.
    public var semanticSegmentationHairMatte: CIImage? {
        get { _semanticSegmentationHairMatte }
        set { _semanticSegmentationHairMatte = newValue }
    }

    /// An optional auxiliary image that represents the semantic segmentation skin matte of the image.
    public var semanticSegmentationSkinMatte: CIImage? {
        get { _semanticSegmentationSkinMatte }
        set { _semanticSegmentationSkinMatte = newValue }
    }

    /// An optional auxiliary image that represents the semantic segmentation sky matte of the image.
    public var semanticSegmentationSkyMatte: CIImage? {
        get { _semanticSegmentationSkyMatte }
        set { _semanticSegmentationSkyMatte = newValue }
    }

    /// An optional auxiliary image that represents the semantic segmentation teeth matte of the image.
    public var semanticSegmentationTeethMatte: CIImage? {
        get { _semanticSegmentationTeethMatte }
        set { _semanticSegmentationTeethMatte = newValue }
    }

    /// A value that indicates the amount to subtract from the shadows in the image.
    public var shadowBias: Float {
        get { _shadowBias }
        set { _shadowBias = newValue; _cachedOutput = nil }
    }

    /// A value that indicates the amount of sharpness to apply to the edges of the image.
    public var sharpnessAmount: Float {
        get { _sharpnessAmount }
        set { _sharpnessAmount = newValue; _cachedOutput = nil }
    }

    // MARK: - White Balance Helpers

    /// Convert color temperature (Kelvin) to RGB multipliers
    private func temperatureToRGB(_ temperature: Float) -> (r: Float, g: Float, b: Float) {
        // Using Planckian locus approximation
        let temp = max(1000, min(40000, temperature)) / 100

        var r: Float, g: Float, b: Float

        // Red
        if temp <= 66 {
            r = 255
        } else {
            r = 329.698727446 * pow(temp - 60, -0.1332047592)
        }

        // Green
        if temp <= 66 {
            g = 99.4708025861 * log(temp) - 161.1195681661
        } else {
            g = 288.1221695283 * pow(temp - 60, -0.0755148492)
        }

        // Blue
        if temp >= 66 {
            b = 255
        } else if temp <= 19 {
            b = 0
        } else {
            b = 138.5177312231 * log(temp - 10) - 305.0447927307
        }

        // Normalize to 0-1 range and apply inverse for correction
        r = 255.0 / max(1, min(255, r))
        g = 255.0 / max(1, min(255, g))
        b = 255.0 / max(1, min(255, b))

        // Normalize so green is 1.0
        let maxVal = max(r, max(g, b))
        return (r / maxVal, g / maxVal, b / maxVal)
    }

    /// Apply tint adjustment to white balance
    private func applyTintToRGB(_ rgb: (r: Float, g: Float, b: Float), tint: Float) -> (r: Float, g: Float, b: Float) {
        // Tint adjusts the green-magenta axis
        let tintFactor = 1 + tint / 150  // Normalize tint range

        return (
            r: rgb.r,
            g: rgb.g / tintFactor,
            b: rgb.b
        )
    }

    // MARK: - Output

    /// Returns a `CIImage` object that encapsulates the operations configured in the filter.
    public override var outputImage: CIImage? {
        // Return cached output if available
        if let cached = _cachedOutput {
            return cached
        }

        guard let rawInfo = _parsedRAWInfo else { return nil }

        // Calculate white balance multipliers from temperature and tint
        var whiteBalance = temperatureToRGB(_neutralTemperature)
        whiteBalance = applyTintToRGB(whiteBalance, tint: _neutralTint)

        // Create processor and process RAW data
        let processor = RAWProcessor(
            rawData: rawInfo.rawData,
            width: rawInfo.width,
            height: rawInfo.height,
            bayerPattern: rawInfo.bayerPattern,
            blackLevel: rawInfo.blackLevel,
            whiteLevel: rawInfo.whiteLevel
        )

        // Combined noise reduction (color + luminance)
        let noiseReduction = max(_colorNoiseReductionAmount, _luminanceNoiseReductionAmount)

        // Process the RAW data
        let processedData = processor.process(
            exposure: _exposure + _baselineExposure,
            whiteBalanceR: whiteBalance.r,
            whiteBalanceG: whiteBalance.g,
            whiteBalanceB: whiteBalance.b,
            shadowBias: _shadowBias,
            boostAmount: _boostAmount,
            boostShadowAmount: _boostShadowAmount,
            contrastAmount: _contrastAmount,
            sharpnessAmount: _sharpnessAmount + _detailAmount,
            noiseReductionAmount: noiseReduction
        )

        // Create CIImage from processed data
        var outputImage = CIImage(
            bitmapData: Data(processedData),
            bytesPerRow: rawInfo.width * 4,
            size: CGSize(width: rawInfo.width, height: rawInfo.height),
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )

        // Apply orientation
        outputImage = applyOrientation(to: outputImage, orientation: _orientation)

        // Apply linear space filter if set
        if let linearFilter = _linearSpaceFilter {
            linearFilter.setValue(outputImage, forKey: kCIInputImageKey)
            if let filtered = linearFilter.outputImage {
                outputImage = filtered
            }
        }

        // Apply scaling if needed
        if _scaleFactor < 1.0 {
            outputImage = outputImage.transformed(by: CGAffineTransform(
                scaleX: CGFloat(_scaleFactor),
                y: CGFloat(_scaleFactor)
            ))
        }

        _cachedOutput = outputImage
        return outputImage
    }

    private func applyOrientation(to image: CIImage, orientation: CGImagePropertyOrientation) -> CIImage {
        switch orientation {
        case .up:
            return image
        case .upMirrored:
            return image.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
        case .down:
            return image.transformed(by: CGAffineTransform(rotationAngle: .pi))
        case .downMirrored:
            return image.transformed(by: CGAffineTransform(scaleX: -1, y: 1)
                .rotated(by: .pi))
        case .left:
            return image.transformed(by: CGAffineTransform(rotationAngle: .pi / 2))
        case .leftMirrored:
            return image.transformed(by: CGAffineTransform(scaleX: -1, y: 1)
                .rotated(by: .pi / 2))
        case .right:
            return image.transformed(by: CGAffineTransform(rotationAngle: -.pi / 2))
        case .rightMirrored:
            return image.transformed(by: CGAffineTransform(scaleX: -1, y: 1)
                .rotated(by: -.pi / 2))
        @unknown default:
            return image
        }
    }
}
