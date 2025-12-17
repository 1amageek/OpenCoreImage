//
//  CIRenderDestinationTests.swift
//  OpenCoreImage
//
//  Tests for CIRenderDestination, CIRenderInfo, and CIRenderTask functionality.
//

import Testing
@testable import OpenCoreImage

// MARK: - CIRenderDestinationAlphaMode Tests

@Suite("CIRenderDestinationAlphaMode")
struct CIRenderDestinationAlphaModeTests {

    @Test("None alpha mode")
    func nonAlphaMode() {
        let mode = CIRenderDestinationAlphaMode.none
        #expect(mode.rawValue == 0)
    }

    @Test("Premultiplied alpha mode")
    func premultipliedAlphaMode() {
        let mode = CIRenderDestinationAlphaMode.premultiplied
        #expect(mode.rawValue == 1)
    }

    @Test("Unpremultiplied alpha mode")
    func unpremultipliedAlphaMode() {
        let mode = CIRenderDestinationAlphaMode.unpremultiplied
        #expect(mode.rawValue == 2)
    }

    @Test("Alpha modes are hashable")
    func alphaModeHashable() {
        var set: Set<CIRenderDestinationAlphaMode> = []
        set.insert(.none)
        set.insert(.none)
        set.insert(.premultiplied)
        #expect(set.count == 2)
    }
}

// MARK: - CIRenderDestination Initialization Tests

@Suite("CIRenderDestination Initialization")
struct CIRenderDestinationInitializationTests {

    @Test("Initialize with dimensions")
    func initWithDimensions() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(destination.width == 100)
        #expect(destination.height == 100)
    }

    @Test("Initialize with bitmap data")
    func initWithBitmapData() {
        var pixelData = [UInt8](repeating: 0, count: 100 * 100 * 4)
        let destination = pixelData.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 100,
                height: 100,
                bytesPerRow: 100 * 4,
                format: .RGBA8
            )
        }
        #expect(destination.width == 100)
        #expect(destination.height == 100)
    }

    @Test("Initialize with IOSurface")
    func initWithIOSurface() {
        let destination = CIRenderDestination(ioSurface: "mock" as Any)
        #expect(destination.width == 0)  // IOSurface init doesn't set dimensions
        #expect(destination.height == 0)
    }

    @Test("Initialize with GL texture")
    func initWithGLTexture() {
        let destination = CIRenderDestination(glTexture: 1, target: 0x0DE1, width: 200, height: 200)
        #expect(destination.width == 200)
        #expect(destination.height == 200)
    }
}

// MARK: - CIRenderDestination Properties Tests

@Suite("CIRenderDestination Properties")
struct CIRenderDestinationPropertiesTests {

    @Test("Alpha mode default is premultiplied")
    func alphaModeDefault() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(destination.alphaMode == .premultiplied)
    }

    @Test("Alpha mode is settable")
    func alphaModeSettable() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        destination.alphaMode = .unpremultiplied
        #expect(destination.alphaMode == .unpremultiplied)
    }

    @Test("Color space exists by default")
    func colorSpaceDefault() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(destination.colorSpace != nil)
    }

    @Test("Color space is settable")
    func colorSpaceSettable() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        destination.colorSpace = nil
        #expect(destination.colorSpace == nil)
    }

    @Test("Blend kernel is nil by default")
    func blendKernelDefault() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(destination.blendKernel == nil)
    }

    @Test("Blend kernel is settable")
    func blendKernelSettable() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        destination.blendKernel = CIBlendKernel.sourceOver
        #expect(destination.blendKernel != nil)
    }

    @Test("Blends in destination color space default")
    func blendsInDestinationColorSpaceDefault() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(destination.blendsInDestinationColorSpace == false)
    }

    @Test("Is clamped default")
    func isClampedDefault() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(destination.isClamped == false)
    }

    @Test("Is clamped is settable")
    func isClampedSettable() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        destination.isClamped = true
        #expect(destination.isClamped == true)
    }

    @Test("Is dithered default")
    func isDitheredDefault() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(destination.isDithered == false)
    }

    @Test("Is dithered is settable")
    func isDitheredSettable() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        destination.isDithered = true
        #expect(destination.isDithered == true)
    }

    @Test("Is flipped default")
    func isFlippedDefault() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(destination.isFlipped == false)
    }

    @Test("Is flipped is settable")
    func isFlippedSettable() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        destination.isFlipped = true
        #expect(destination.isFlipped == true)
    }
}

// MARK: - CIRenderDestination Equatable/Hashable Tests

@Suite("CIRenderDestination Equatable and Hashable")
struct CIRenderDestinationEquatableHashableTests {

    @Test("Same instance is equal")
    func sameInstanceEqual() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(destination == destination)
    }

    @Test("Different instances are not equal")
    func differentInstancesNotEqual() {
        let dest1 = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        let dest2 = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(dest1 != dest2)
    }

    @Test("Same instance has same hash")
    func sameInstanceSameHash() {
        let destination = CIRenderDestination(
            width: 100,
            height: 100,
            pixelFormat: .RGBA8,
            commandBuffer: nil,
            mtlTextureProvider: nil
        )
        #expect(destination.hashValue == destination.hashValue)
    }
}

// MARK: - CIRenderInfo Tests

@Suite("CIRenderInfo")
struct CIRenderInfoTests {

    @Test("Render info kernel execution time is non-negative")
    func kernelExecutionTimeNonNegative() {
        // Create a render task directly to get render info
        var pixelData = [UInt8](repeating: 0, count: 100 * 100 * 4)
        let destination = pixelData.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 100,
                height: 100,
                bytesPerRow: 100 * 4,
                format: .RGBA8
            )
        }

        let task = CIRenderTask(destination: destination)
        let info = try? task.waitUntilCompleted()
        #expect(info?.kernelExecutionTime ?? 0 >= 0)
    }

    @Test("Render info pass count is at least 1")
    func passCountAtLeastOne() {
        var pixelData = [UInt8](repeating: 0, count: 100 * 100 * 4)
        let destination = pixelData.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 100,
                height: 100,
                bytesPerRow: 100 * 4,
                format: .RGBA8
            )
        }

        let task = CIRenderTask(destination: destination)
        let info = try? task.waitUntilCompleted()
        #expect(info?.passCount ?? 0 >= 1)
    }

    @Test("Render info pixels processed matches dimensions")
    func pixelsProcessedMatchesDimensions() {
        var pixelData = [UInt8](repeating: 0, count: 100 * 100 * 4)
        let destination = pixelData.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 100,
                height: 100,
                bytesPerRow: 100 * 4,
                format: .RGBA8
            )
        }

        let task = CIRenderTask(destination: destination)
        let info = try? task.waitUntilCompleted()
        #expect(info?.pixelsProcessed == 10000)
    }

    @Test("Render info kernel compile time is non-negative")
    func kernelCompileTimeNonNegative() {
        var pixelData = [UInt8](repeating: 0, count: 100 * 100 * 4)
        let destination = pixelData.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 100,
                height: 100,
                bytesPerRow: 100 * 4,
                format: .RGBA8
            )
        }

        let task = CIRenderTask(destination: destination)
        let info = try? task.waitUntilCompleted()
        #expect(info?.kernelCompileTime ?? 0 >= 0)
    }
}

// MARK: - CIRenderTask Tests

@Suite("CIRenderTask")
struct CIRenderTaskTests {

    @Test("Task has destination")
    func taskHasDestination() {
        var pixelData = [UInt8](repeating: 0, count: 50 * 50 * 4)
        let destination = pixelData.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 50,
                height: 50,
                bytesPerRow: 50 * 4,
                format: .RGBA8
            )
        }

        let task = CIRenderTask(destination: destination)
        #expect(task.destination === destination)
    }

    @Test("Wait until completed returns info")
    func waitUntilCompletedReturnsInfo() throws {
        var pixelData = [UInt8](repeating: 0, count: 50 * 50 * 4)
        let destination = pixelData.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 50,
                height: 50,
                bytesPerRow: 50 * 4,
                format: .RGBA8
            )
        }

        let task = CIRenderTask(destination: destination)
        let info = try task.waitUntilCompleted()
        #expect(info.pixelsProcessed == 2500)
    }
}

// MARK: - CIRenderInfo/CIRenderTask Equatable/Hashable Tests

@Suite("CIRenderInfo and CIRenderTask Equatable and Hashable")
struct CIRenderInfoTaskEquatableHashableTests {

    @Test("Render info same instance equal")
    func renderInfoSameInstanceEqual() throws {
        var pixelData = [UInt8](repeating: 0, count: 10 * 10 * 4)
        let destination = pixelData.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 10,
                height: 10,
                bytesPerRow: 10 * 4,
                format: .RGBA8
            )
        }

        let task = CIRenderTask(destination: destination)
        let info = try task.waitUntilCompleted()
        #expect(info == info)
    }

    @Test("Render task same instance equal")
    func renderTaskSameInstanceEqual() {
        var pixelData = [UInt8](repeating: 0, count: 10 * 10 * 4)
        let destination = pixelData.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 10,
                height: 10,
                bytesPerRow: 10 * 4,
                format: .RGBA8
            )
        }

        let task = CIRenderTask(destination: destination)
        #expect(task == task)
    }

    @Test("Different render tasks are not equal")
    func differentRenderTasksNotEqual() {
        var pixelData1 = [UInt8](repeating: 0, count: 10 * 10 * 4)
        let destination1 = pixelData1.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 10,
                height: 10,
                bytesPerRow: 10 * 4,
                format: .RGBA8
            )
        }

        var pixelData2 = [UInt8](repeating: 0, count: 10 * 10 * 4)
        let destination2 = pixelData2.withUnsafeMutableBytes { ptr in
            CIRenderDestination(
                bitmapData: ptr.baseAddress!,
                width: 10,
                height: 10,
                bytesPerRow: 10 * 4,
                format: .RGBA8
            )
        }

        let task1 = CIRenderTask(destination: destination1)
        let task2 = CIRenderTask(destination: destination2)
        #expect(task1 != task2)
    }
}
