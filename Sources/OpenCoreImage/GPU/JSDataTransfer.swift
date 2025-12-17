//
//  JSDataTransfer.swift
//  OpenCoreImage
//
//  Efficient data transfer utilities between Swift and JavaScript.
//

#if arch(wasm32)
import Foundation
import JavaScriptKit

/// Utilities for efficient data transfer between Swift Data and JavaScript TypedArrays.
internal struct JSDataTransfer {

    // MARK: - Swift to JavaScript

    /// Converts Swift Data to a JavaScript Uint8Array efficiently.
    /// Uses bulk memory operations when available.
    /// - Parameter data: The Swift Data to convert.
    /// - Returns: A JavaScript Uint8Array containing the data.
    static func toUint8Array(_ data: Data) -> JSObject {
        let count = data.count

        // Create Uint8Array
        let uint8Array = JSObject.global.Uint8Array.function!.new(count)

        // For small data, direct copy is fine
        if count <= 1024 {
            data.withUnsafeBytes { bytes in
                for (index, byte) in bytes.enumerated() {
                    uint8Array[index] = JSValue(integerLiteral: Int32(byte))
                }
            }
            return uint8Array
        }

        // For larger data, use chunked approach with batch operations
        // Process in chunks to balance between JS calls and memory efficiency
        let chunkSize = 4096
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            let basePtr = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self)

            var offset = 0
            while offset < count {
                let remaining = count - offset
                let currentChunkSize = min(chunkSize, remaining)

                // Create a temporary array for this chunk
                let chunkArray = JSObject.global.Uint8Array.function!.new(currentChunkSize)

                for i in 0..<currentChunkSize {
                    chunkArray[i] = JSValue(integerLiteral: Int32(basePtr[offset + i]))
                }

                // Use set() to copy chunk at offset - this is faster than individual assignments
                _ = uint8Array.set!(chunkArray, offset)

                offset += currentChunkSize
            }
        }

        return uint8Array
    }

    /// Converts Swift Data to a JavaScript Uint8Array using a subarray view.
    /// This creates the array and copies data in a single operation when possible.
    /// - Parameter data: The Swift Data to convert.
    /// - Returns: A JavaScript Uint8Array containing the data.
    static func toUint8ArrayDirect(_ data: Data) -> JSObject {
        let count = data.count

        // Create an ArrayBuffer
        let arrayBuffer = JSObject.global.ArrayBuffer.function!.new(count)
        let uint8Array = JSObject.global.Uint8Array.function!.new(arrayBuffer)

        // Copy data byte by byte (unfortunately JavaScript doesn't expose direct memory access)
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            let basePtr = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            for i in 0..<count {
                uint8Array[i] = JSValue(integerLiteral: Int32(basePtr[i]))
            }
        }

        return uint8Array
    }

    // MARK: - JavaScript to Swift

    /// Converts a JavaScript Uint8Array to Swift Data efficiently.
    /// - Parameters:
    ///   - uint8Array: The JavaScript Uint8Array to convert.
    ///   - expectedLength: Optional expected length for pre-allocation.
    /// - Returns: Swift Data containing the array contents.
    static func toData(_ uint8Array: JSObject, expectedLength: Int? = nil) -> Data {
        let length = expectedLength ?? Int(uint8Array.length.number ?? 0)
        guard length > 0 else { return Data() }

        var data = Data(count: length)
        data.withUnsafeMutableBytes { (destPtr: UnsafeMutableRawBufferPointer) in
            let dest = destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self)
            for i in 0..<length {
                dest[i] = UInt8(uint8Array[i].number ?? 0)
            }
        }

        return data
    }

    /// Converts a JavaScript Uint8Array to Swift Data with row alignment handling.
    /// Used for texture readback where GPU may use different row alignment.
    /// - Parameters:
    ///   - uint8Array: The JavaScript Uint8Array to convert.
    ///   - width: Image width in pixels.
    ///   - height: Image height in pixels.
    ///   - alignedBytesPerRow: The aligned bytes per row from GPU.
    ///   - bytesPerPixel: Bytes per pixel (typically 4 for RGBA).
    /// - Returns: Swift Data with correct row stride (no padding).
    static func toDataWithAlignment(
        _ uint8Array: JSObject,
        width: Int,
        height: Int,
        alignedBytesPerRow: Int,
        bytesPerPixel: Int = 4
    ) -> Data {
        let actualBytesPerRow = width * bytesPerPixel
        let length = Int(uint8Array.length.number ?? 0)

        // If alignment matches, just do direct copy
        if alignedBytesPerRow == actualBytesPerRow {
            return toData(uint8Array, expectedLength: length)
        }

        // Need to strip padding from each row
        var data = Data(count: actualBytesPerRow * height)
        data.withUnsafeMutableBytes { (destPtr: UnsafeMutableRawBufferPointer) in
            let dest = destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self)

            for row in 0..<height {
                let srcRowStart = row * alignedBytesPerRow
                let destRowStart = row * actualBytesPerRow

                for col in 0..<actualBytesPerRow {
                    let srcIndex = srcRowStart + col
                    if srcIndex < length {
                        dest[destRowStart + col] = UInt8(uint8Array[srcIndex].number ?? 0)
                    }
                }
            }
        }

        return data
    }
}
#endif
