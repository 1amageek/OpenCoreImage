// OpenCoreImage WASM browser tests, authored as Swift Testing `@Test`
// functions that run inside headless Chromium via BrowserTestRunner.
//
// Boot flow (reactor-ABI):
//   1. `setup()` is exported to JS via `@_cdecl` + `--export=setup`.
//   2. `WasmTestingReactor.boot` installs the JavaScriptKit executor and
//      touches module-scope globals to avoid the reactor-ABI global-init
//      race (see MEMORY + ReactorBoot.swift for background).
//   3. `performRenderSetup()` evaluates CIColorInvert through WebGPU and
//      captures GPU readback bytes.
//   4. `BrowserTestRunner.run()` spawns the Swift Testing ABI v0 entry point.

import Foundation
import Testing
import WasmTesting
import OpenCoreImage
import OpenCoreGraphics

// MARK: - Captured state (so a later render-path test has a hook)

nonisolated(unsafe) var statusText: String = "initializing"
nonisolated(unsafe) var renderError: String?
nonisolated(unsafe) var invertedPixelData: Data?
nonisolated(unsafe) var renderedPixels: [String: [UInt8]] = [:]

@_cdecl("setup")
public func setup() {
    WasmTestingReactor.boot(
        touchGlobals: {
            statusText = "initializing"
            renderError = nil
            invertedPixelData = nil
            renderedPixels = [:]
        },
        then: {
            await performRenderSetup()
            BrowserTestRunner.run()
        }
    )
}

@MainActor
private func performRenderSetup() async {
    let width = 4
    let height = 4
    var sourceData = Data(capacity: width * height * 4)
    for _ in 0..<(width * height) {
        sourceData.append(contentsOf: [255, 0, 0, 255])
    }

    let source = CIImage(
        bitmapData: sourceData,
        bytesPerRow: width * 4,
        size: CGSize(width: width, height: height),
        format: .RGBA8,
        colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
    )
    let output = source.applyingFilter("CIColorInvert")
    let context = CIContext()

    do {
        let image = try await context.createCGImageAsync(output, from: source.extent)
        guard let data = image.data else {
            renderError = "CIColorInvert output has no pixel data"
            statusText = "error"
            return
        }
        invertedPixelData = data

        let adjustmentSource = makeImage(pixel: [64, 128, 192, 255])
        renderedPixels["exposure"] = try await renderFirstPixel(
            adjustmentSource.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: 1.0]),
            extent: adjustmentSource.extent,
            context: context
        )
        renderedPixels["gamma"] = try await renderFirstPixel(
            adjustmentSource.applyingFilter("CIGammaAdjust", parameters: ["inputPower": 2.0]),
            extent: adjustmentSource.extent,
            context: context
        )
        renderedPixels["controls"] = try await renderFirstPixel(
            adjustmentSource.applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: 0.1,
                kCIInputContrastKey: 1.0,
                kCIInputSaturationKey: 1.0,
            ]),
            extent: adjustmentSource.extent,
            context: context
        )
        renderedPixels["sepia"] = try await renderFirstPixel(
            adjustmentSource.applyingFilter("CISepiaTone", parameters: [kCIInputIntensityKey: 1.0]),
            extent: adjustmentSource.extent,
            context: context
        )

        let foreground = makeImage(pixel: [255, 0, 0, 128])
        let background = makeImage(pixel: [0, 0, 255, 255])
        guard let blended = CIBlendKernel.sourceOver.apply(
            foreground: foreground,
            background: background
        ) else {
            throw SmokeRenderError.missingBlendOutput
        }
        renderedPixels["sourceOver"] = try await renderFirstPixel(
            blended,
            extent: foreground.extent,
            context: context
        )

        let multiplyForeground = makeImage(pixel: [128, 64, 255, 255])
        let multiplyBackground = makeImage(pixel: [128, 255, 64, 255])
        let multiplied = multiplyForeground.applyingFilter(
            "CIMultiplyBlendMode",
            parameters: [kCIInputBackgroundImageKey: multiplyBackground]
        )
        renderedPixels["multiply"] = try await renderFirstPixel(
            multiplied,
            extent: multiplyForeground.extent,
            context: context
        )
        statusText = "ready"
    } catch {
        renderError = String(describing: error)
        statusText = "error"
    }
}

private enum SmokeRenderError: Error {
    case missingPixelData
    case missingBlendOutput
}

private func makeImage(pixel: [UInt8]) -> CIImage {
    CIImage(
        bitmapData: Data(pixel),
        bytesPerRow: 4,
        size: CGSize(width: 1, height: 1),
        format: .RGBA8,
        colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
    )
}

@MainActor
private func renderFirstPixel(
    _ image: CIImage,
    extent: CGRect,
    context: CIContext
) async throws -> [UInt8] {
    let rendered = try await context.createCGImageAsync(image, from: extent)
    guard let data = rendered.data, data.count >= 4 else {
        throw SmokeRenderError.missingPixelData
    }
    return Array(data.prefix(4))
}

// MARK: - Tests
//
// @Suite(.serialized) because the shared `statusText` global is read by
// the first test, and a future mutation test would otherwise race. See
// memory: feedback_wasm_testing_serialized_suite.md

@Suite(.serialized)
struct OCISmokeTests {

    @Test func bootCompleted() throws {
        try #require(
            statusText == "ready",
            "reactor boot did not complete cleanly: \(statusText)"
        )
    }

    @Test func colorInvertRunsThroughWebGPU() throws {
        try #require(renderError == nil, "render failed: \(renderError ?? "unknown")")
        let data = try #require(invertedPixelData)
        #expect(data.count == 4 * 4 * 4)
        #expect(data[0] <= 2, "red channel should be inverted to zero")
        #expect(data[1] >= 253, "green channel should be inverted to one")
        #expect(data[2] >= 253, "blue channel should be inverted to one")
        #expect(data[3] >= 253, "alpha should remain opaque")
    }

    @Test func exposureAdjustRunsThroughWebGPU() throws {
        let pixel = try #require(renderedPixels["exposure"])
        #expect(abs(Int(pixel[0]) - 128) <= 1)
        #expect(pixel[1] >= 254)
        #expect(pixel[2] == 255)
        #expect(pixel[3] == 255)
    }

    @Test func gammaAdjustRunsThroughWebGPU() throws {
        let pixel = try #require(renderedPixels["gamma"])
        #expect(abs(Int(pixel[0]) - 16) <= 1)
        #expect(abs(Int(pixel[1]) - 64) <= 1)
        #expect(abs(Int(pixel[2]) - 145) <= 1)
        #expect(pixel[3] == 255)
    }

    @Test func colorControlsRunsThroughWebGPU() throws {
        let pixel = try #require(renderedPixels["controls"])
        #expect(abs(Int(pixel[0]) - 90) <= 1)
        #expect(abs(Int(pixel[1]) - 154) <= 1)
        #expect(abs(Int(pixel[2]) - 218) <= 1)
        #expect(pixel[3] == 255)
    }

    @Test func sepiaToneRunsThroughWebGPU() throws {
        let pixel = try #require(renderedPixels["sepia"])
        #expect(abs(Int(pixel[0]) - 159) <= 2)
        #expect(abs(Int(pixel[1]) - 142) <= 2)
        #expect(abs(Int(pixel[2]) - 111) <= 2)
        #expect(pixel[3] == 255)
    }

    @Test func sourceOverBlendKernelRunsThroughWebGPU() throws {
        let pixel = try #require(renderedPixels["sourceOver"])
        #expect(abs(Int(pixel[0]) - 128) <= 1)
        #expect(pixel[1] <= 1)
        #expect(abs(Int(pixel[2]) - 127) <= 1)
        #expect(pixel[3] == 255)
    }

    @Test func multiplyBlendModeRunsThroughWebGPU() throws {
        let pixel = try #require(renderedPixels["multiply"])
        #expect(abs(Int(pixel[0]) - 64) <= 1)
        #expect(abs(Int(pixel[1]) - 64) <= 1)
        #expect(abs(Int(pixel[2]) - 64) <= 1)
        #expect(pixel[3] == 255)
    }

    @Test func ciColorPreservesRGBA() throws {
        let color = CIColor(red: 0.25, green: 0.5, blue: 0.75, alpha: 0.9)
        #expect(abs(color.red - 0.25) < 0.001, "red drift: \(color.red)")
        #expect(abs(color.green - 0.5) < 0.001, "green drift: \(color.green)")
        #expect(abs(color.blue - 0.75) < 0.001, "blue drift: \(color.blue)")
        #expect(abs(color.alpha - 0.9) < 0.001, "alpha drift: \(color.alpha)")
        #expect(color.numberOfComponents == 4)
    }

    @Test func ciColorStringRoundtrip() throws {
        let color = CIColor(string: "0.1 0.2 0.3 0.4")
        #expect(abs(color.red - 0.1) < 0.001)
        #expect(abs(color.green - 0.2) < 0.001)
        #expect(abs(color.blue - 0.3) < 0.001)
        #expect(abs(color.alpha - 0.4) < 0.001)
    }

    @Test func ciVectorFourComponent() throws {
        let v = CIVector(x: 1, y: 2, z: 3, w: 4)
        #expect(v.count == 4)
        #expect(v.x == 1)
        #expect(v.y == 2)
        #expect(v.z == 3)
        #expect(v.w == 4)
        #expect(v.value(at: 0) == 1)
        #expect(v.value(at: 3) == 4)
    }

    @Test func ciVectorFromCGPointAndRect() throws {
        let point = CIVector(cgPoint: CGPoint(x: 7, y: 11))
        #expect(point.count == 2)
        #expect(point.x == 7)
        #expect(point.y == 11)

        let rect = CIVector(cgRect: CGRect(x: 1, y: 2, width: 3, height: 4))
        #expect(rect.count == 4)
        #expect(rect.value(at: 0) == 1)
        #expect(rect.value(at: 1) == 2)
        #expect(rect.value(at: 2) == 3)
        #expect(rect.value(at: 3) == 4)
    }

    @Test func ciImageFromColorHasInfiniteExtent() throws {
        let image = CIImage(color: CIColor(red: 1, green: 0, blue: 0))
        #expect(image.extent.isInfinite, "CIImage(color:) should have infinite extent")
    }
}
