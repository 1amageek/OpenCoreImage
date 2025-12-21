//
//  GPUError.swift
//  OpenCoreImage
//
//  GPU-related error types.
//

import Foundation

/// Errors that can occur during GPU operations.
internal enum GPUError: Error, LocalizedError {
    /// WebGPU is not available in this environment.
    case webGPUNotAvailable

    /// Failed to request a GPU adapter.
    case adapterNotAvailable

    /// Failed to request a GPU device.
    case deviceNotAvailable

    /// The specified shader was not found in the registry.
    case shaderNotFound(String)

    /// Shader compilation failed.
    case compilationFailed(String)

    /// Pipeline creation failed.
    case pipelineCreationFailed(String)

    /// Rendering failed.
    case renderingFailed(String)

    /// Texture upload failed.
    case textureUploadFailed(String)

    /// Texture readback failed.
    case textureReadbackFailed(String)

    /// Invalid filter parameters.
    case invalidParameters(String)

    /// The filter is not supported.
    case unsupportedFilter(String)

    public var errorDescription: String? {
        switch self {
        case .webGPUNotAvailable:
            return "WebGPU is not available in this environment"
        case .adapterNotAvailable:
            return "Failed to request a GPU adapter"
        case .deviceNotAvailable:
            return "Failed to request a GPU device"
        case .shaderNotFound(let name):
            return "Shader not found: \(name)"
        case .compilationFailed(let message):
            return "Shader compilation failed: \(message)"
        case .pipelineCreationFailed(let message):
            return "Pipeline creation failed: \(message)"
        case .renderingFailed(let message):
            return "Rendering failed: \(message)"
        case .textureUploadFailed(let message):
            return "Texture upload failed: \(message)"
        case .textureReadbackFailed(let message):
            return "Texture readback failed: \(message)"
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case .unsupportedFilter(let name):
            return "Unsupported filter: \(name)"
        }
    }
}
