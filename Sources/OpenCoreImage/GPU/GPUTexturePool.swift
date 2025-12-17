//
//  GPUTexturePool.swift
//  OpenCoreImage
//
//  Manages a pool of reusable GPU textures.
//

#if arch(wasm32)
import Foundation
import SwiftWebGPU

/// A key for identifying texture configurations.
internal struct TextureKey: Hashable {
    let width: UInt32
    let height: UInt32
    let format: GPUTextureFormat
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

    /// Available textures organized by configuration.
    private var availableTextures: [TextureKey: [GPUTexture]] = [:]

    /// Total count of pooled textures.
    private var totalPooledCount = 0

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
        let key = TextureKey(width: width, height: height, format: format)

        // Try to reuse an existing texture from the pool
        if var textures = availableTextures[key], !textures.isEmpty {
            let texture = textures.removeLast()
            availableTextures[key] = textures
            totalPooledCount -= 1
            return texture
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
        width: UInt32,
        height: UInt32,
        format: GPUTextureFormat
    ) {
        let key = TextureKey(width: width, height: height, format: format)

        // Check if we can add to the pool
        var textures = availableTextures[key] ?? []

        // Only pool if under limits
        guard textures.count < maxPoolSizePerKey,
              totalPooledCount < maxTotalPoolSize else {
            // Let texture be deallocated by not adding to pool
            return
        }

        textures.append(texture)
        availableTextures[key] = textures
        totalPooledCount += 1
    }

    /// Clears all pooled textures, releasing GPU memory.
    func clear() {
        availableTextures.removeAll()
        totalPooledCount = 0
    }

    /// Returns the current number of pooled textures.
    var pooledCount: Int {
        totalPooledCount
    }

    /// Returns statistics about the texture pool.
    var statistics: (total: Int, configurations: Int) {
        (totalPooledCount, availableTextures.count)
    }
}
#endif
