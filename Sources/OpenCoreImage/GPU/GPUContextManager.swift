//
//  GPUContextManager.swift
//  OpenCoreImage
//
//  Manages WebGPU device initialization and lifecycle.
//

#if arch(wasm32)
import Foundation
import SwiftWebGPU

/// Manages WebGPU device initialization and lifecycle as a singleton actor.
/// Uses actor isolation for thread-safe access to GPU resources.
internal actor GPUContextManager {

    // MARK: - Singleton

    /// Shared instance of the GPU context manager.
    static let shared = GPUContextManager()

    // MARK: - State

    private var adapter: GPUAdapter?
    private var device: GPUDevice?
    private var initializationTask: Task<GPUDevice, Error>?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Interface

    /// Returns the initialized GPUDevice, initializing if necessary.
    /// - Throws: GPUError if initialization fails.
    /// - Returns: The initialized GPUDevice.
    func getDevice() async throws -> GPUDevice {
        // Return cached device if available
        if let device = device {
            return device
        }

        // Join existing initialization task if one is in progress
        if let task = initializationTask {
            return try await task.value
        }

        // Start new initialization
        let task = Task<GPUDevice, Error> {
            // Check WebGPU availability
            guard let gpu = GPU.shared else {
                throw GPUError.webGPUNotAvailable
            }

            // Request adapter
            guard let adapter = await gpu.requestAdapter() else {
                throw GPUError.adapterNotAvailable
            }
            self.adapter = adapter

            // Request device
            let device: GPUDevice
            do {
                device = try await adapter.requestDevice()
            } catch {
                throw GPUError.deviceNotAvailable
            }
            self.device = device

            return device
        }

        initializationTask = task

        do {
            let device = try await task.value
            initializationTask = nil
            return device
        } catch {
            initializationTask = nil
            throw error
        }
    }

    /// Returns the command queue for the device.
    /// - Throws: GPUError if device initialization fails.
    /// - Returns: The GPUQueue for submitting commands.
    func getQueue() async throws -> GPUQueue {
        let device = try await getDevice()
        return device.queue
    }

    /// Returns true if a GPU device is currently initialized.
    var isInitialized: Bool {
        device != nil
    }

    /// Resets the GPU context, releasing all resources.
    /// Useful for error recovery or cleanup.
    func reset() {
        adapter = nil
        device = nil
        initializationTask?.cancel()
        initializationTask = nil
    }
}
#endif
