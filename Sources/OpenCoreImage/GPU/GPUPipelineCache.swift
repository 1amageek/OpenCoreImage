//
//  GPUPipelineCache.swift
//  OpenCoreImage
//
//  Caches compiled GPU compute pipelines.
//

#if arch(wasm32)
import Foundation
import SwiftWebGPU

/// Caches compiled GPU compute pipelines to avoid recompilation.
/// Uses actor isolation for thread-safe access.
internal actor GPUPipelineCache {

    // MARK: - Singleton

    /// Shared instance of the pipeline cache.
    static let shared = GPUPipelineCache()

    // MARK: - State

    /// Cached pipelines indexed by filter name.
    private var pipelines: [String: GPUComputePipeline] = [:]

    /// In-flight compilation tasks to avoid duplicate work.
    private var compilationTasks: [String: Task<GPUComputePipeline, Error>] = [:]

    /// Cached shader modules indexed by filter name.
    private var shaderModules: [String: GPUShaderModule] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Interface

    /// Returns a cached pipeline or creates a new one for the specified filter.
    /// - Parameters:
    ///   - filterName: The name of the filter (e.g., "CIGaussianBlur").
    ///   - device: The GPU device to create the pipeline on.
    /// - Throws: GPUError if shader is not found or compilation fails.
    /// - Returns: A compiled GPUComputePipeline.
    func getPipeline(
        for filterName: String,
        device: GPUDevice
    ) async throws -> GPUComputePipeline {
        // Return cached pipeline if available
        if let cached = pipelines[filterName] {
            return cached
        }

        // Join existing compilation task if one is in progress
        if let task = compilationTasks[filterName] {
            return try await task.value
        }

        // Start new compilation
        let task = Task<GPUComputePipeline, Error> {
            // Get shader source from registry
            guard let shaderSource = WGSLShaderRegistry.getShader(for: filterName) else {
                throw GPUError.shaderNotFound(filterName)
            }

            // Create shader module
            let shaderModule = device.createShaderModule(
                descriptor: GPUShaderModuleDescriptor(code: shaderSource)
            )
            self.shaderModules[filterName] = shaderModule

            // Create compute pipeline
            let pipeline: GPUComputePipeline
            do {
                pipeline = try await device.createComputePipelineAsync(
                    descriptor: GPUComputePipelineDescriptor(
                        compute: GPUProgrammableStage(
                            module: shaderModule,
                            entryPoint: "main"
                        ),
                        layout: .auto
                    )
                )
            } catch {
                throw GPUError.pipelineCreationFailed(
                    "Failed to create pipeline for \(filterName): \(error)"
                )
            }

            return pipeline
        }

        compilationTasks[filterName] = task

        do {
            let pipeline = try await task.value
            pipelines[filterName] = pipeline
            compilationTasks[filterName] = nil
            return pipeline
        } catch {
            compilationTasks[filterName] = nil
            throw error
        }
    }

    /// Pre-compiles pipelines for commonly used filters.
    /// - Parameters:
    ///   - filterNames: Array of filter names to precompile.
    ///   - device: The GPU device to create pipelines on.
    func precompile(filterNames: [String], device: GPUDevice) async {
        await withTaskGroup(of: Void.self) { group in
            for filterName in filterNames {
                group.addTask {
                    do {
                        _ = try await self.getPipeline(for: filterName, device: device)
                    } catch {
                        // Silently ignore precompilation failures
                        // They will be reported when the filter is actually used
                    }
                }
            }
        }
    }

    /// Returns true if a pipeline is cached for the given filter.
    /// - Parameter filterName: The name of the filter.
    /// - Returns: True if cached, false otherwise.
    func hasPipeline(for filterName: String) -> Bool {
        pipelines[filterName] != nil
    }

    /// Clears all cached pipelines and shader modules.
    func clear() {
        pipelines.removeAll()
        shaderModules.removeAll()
        for task in compilationTasks.values {
            task.cancel()
        }
        compilationTasks.removeAll()
    }

    /// Returns the number of cached pipelines.
    var cachedCount: Int {
        pipelines.count
    }
}
#endif
