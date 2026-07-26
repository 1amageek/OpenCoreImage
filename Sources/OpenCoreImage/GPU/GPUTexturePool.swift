//
//  GPUTexturePool.swift
//  OpenCoreImage
//
//  Manages a pool of reusable GPU textures.
//

#if arch(wasm32)
import SwiftWebGPU

/// A key for identifying compatible texture allocations.
internal struct TextureKey: Equatable {
    let deviceIdentifier: ObjectIdentifier
    let width: UInt32
    let height: UInt32
    let format: GPUTextureFormat
    let usage: UInt32
}

/// Manages a pool of reusable GPU textures to minimize allocations.
/// Uses actor isolation for thread-safe access.
internal actor GPUTexturePool {

    // MARK: - Singleton

    /// Shared instance of the texture pool.
    static let shared = GPUTexturePool()

    // MARK: - Configuration

    /// Maximum number of textures to keep in the pool per configuration.
    private let maxPoolSizePerKey = 4

    /// Maximum total textures across all configurations.
    private let maxTotalPoolSize = 20

    // MARK: - State

    private struct PooledTexture {
        let key: TextureKey
        let texture: GPUTexture
    }

    /// Available textures in insertion order.
    ///
    /// The pool is intentionally array-backed. Swift 6.4 release-WASM can
    /// miscompile `_DictionaryStorage` operations for composite keys, while
    /// the strict global capacity keeps linear lookup bounded.
    private var availableTextures: [PooledTexture] = []

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Interface

    /// Acquires a texture with the specified dimensions and format.
    /// - Parameters:
    ///   - device: The GPU device to create the texture on.
    ///   - width: The width of the texture in pixels.
    ///   - height: The height of the texture in pixels.
    ///   - format: The texture format.
    ///   - usage: The texture usage flags.
    /// - Returns: A GPUTexture ready for use.
    func acquire(
        device: GPUDevice,
        width: UInt32,
        height: UInt32,
        format: GPUTextureFormat = .rgba8unorm,
        usage: GPUTextureUsage = [.textureBinding, .storageBinding, .copyDst, .copySrc]
    ) -> GPUTexture {
        let key = TextureKey(
            deviceIdentifier: ObjectIdentifier(device),
            width: width,
            height: height,
            format: format,
            usage: usage.rawValue
        )

        if let index = availableTextures.lastIndex(where: { $0.key == key }) {
            return availableTextures.remove(at: index).texture
        }

        // Create a new texture
        let descriptor = GPUTextureDescriptor(
            size: GPUExtent3D(width: width, height: height, depthOrArrayLayers: 1),
            format: format,
            usage: usage
        )
        return device.createTexture(descriptor: descriptor)
    }

    /// Releases a texture back to the pool for reuse.
    /// - Parameters:
    ///   - texture: The texture to release.
    ///   - width: The width of the texture.
    ///   - height: The height of the texture.
    ///   - format: The texture format.
    func release(
        _ texture: GPUTexture,
        device: GPUDevice,
        width: UInt32,
        height: UInt32,
        format: GPUTextureFormat,
        usage: GPUTextureUsage = [.textureBinding, .storageBinding, .copyDst, .copySrc]
    ) {
        let key = TextureKey(
            deviceIdentifier: ObjectIdentifier(device),
            width: width,
            height: height,
            format: format,
            usage: usage.rawValue
        )

        var matchingCount = 0
        for entry in availableTextures where entry.key == key {
            matchingCount += 1
        }

        guard matchingCount < maxPoolSizePerKey,
              availableTextures.count < maxTotalPoolSize else {
            texture.destroy()
            return
        }

        availableTextures.append(PooledTexture(key: key, texture: texture))
    }

    /// Clears all pooled textures, releasing GPU memory.
    func clear() {
        for entry in availableTextures {
            entry.texture.destroy()
        }
        availableTextures.removeAll()
    }

    /// Returns the current number of pooled textures.
    var pooledCount: Int {
        availableTextures.count
    }

    /// Returns statistics about the texture pool.
    var statistics: (total: Int, configurations: Int) {
        var configurations: [TextureKey] = []
        for entry in availableTextures where !configurations.contains(entry.key) {
            configurations.append(entry.key)
        }
        return (availableTextures.count, configurations.count)
    }
}
#endif
