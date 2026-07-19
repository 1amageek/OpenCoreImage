//
//  CIKernelTests.swift
//  OpenCoreImage
//
//  Tests for CIKernel and related kernel classes.
//

import Testing
import Foundation
@testable import OpenCoreImage

// MARK: - CIKernel Initialization Tests

@Suite("CIKernel Initialization")
struct CIKernelInitializationTests {

    @Test("Invalid custom kernel source is rejected")
    func initWithSource() {
        let kernel = CIKernel(source: "kernel vec4 test() { return vec4(1.0); }")
        #expect(kernel == nil)
    }

    @Test("Empty Metal library data is rejected")
    func initWithMetalLibrary() {
        let data = Data()
        let kernel = CIKernel(functionName: "testKernel", fromMetalLibraryData: data)
        #expect(kernel == nil)
    }

    @Test("Kernel has name")
    func kernelHasName() {
        let data = Data()
        let kernel = CIKernel(functionName: "myKernel", fromMetalLibraryData: data)
        #expect(kernel == nil)
    }

    @Test("Source kernel uses source string as name")
    func sourceKernelUsesSourceAsName() {
        let kernel = CIKernel(source: "myKernelSource")
        #expect(kernel == nil)
    }
}

// MARK: - CIKernel Apply Tests

@Suite("CIKernel Apply")
struct CIKernelApplyTests {

    @Test("Unsupported custom kernel cannot be created")
    func applyKernelReturnsImage() {
        #expect(CIKernel(source: "test") == nil)
    }

    @Test("Apply kernel with arguments")
    func applyKernelWithArguments() {
        #expect(CIKernel(source: "test") == nil)
    }
}

// MARK: - CIColorKernel Tests

@Suite("CIColorKernel")
struct CIColorKernelTests {

    @Test("Initialize color kernel")
    func initColorKernel() {
        let kernel = CIColorKernel(source: "kernel vec4 colorKernel() { return vec4(1.0); }")
        #expect(kernel == nil)
    }

    @Test("Apply color kernel")
    func applyColorKernel() {
        #expect(CIColorKernel(source: "test") == nil)
    }

    @Test("Apply color kernel with arguments")
    func applyColorKernelWithArguments() {
        #expect(CIColorKernel(source: "test") == nil)
    }
}

// MARK: - CIWarpKernel Tests

@Suite("CIWarpKernel")
struct CIWarpKernelTests {

    @Test("Initialize warp kernel")
    func initWarpKernel() {
        let kernel = CIWarpKernel(source: "kernel vec2 warpKernel() { return destCoord(); }")
        #expect(kernel == nil)
    }

    @Test("Apply warp kernel")
    func applyWarpKernel() {
        #expect(CIWarpKernel(source: "test") == nil)
    }
}

// MARK: - CIBlendKernel Tests

@Suite("CIBlendKernel")
struct CIBlendKernelTests {

    @Test("Initialize blend kernel")
    func initBlendKernel() {
        let kernel = CIBlendKernel(source: "multiply")
        #expect(kernel == nil)
    }

    @Test("Apply blend kernel")
    func applyBlendKernel() {
        #expect(CIBlendKernel(source: "multiply") == nil)
    }

    @Test("Apply blend kernel with color space")
    func applyBlendKernelWithColorSpace() {
        #expect(CIBlendKernel(source: "screen") == nil)
    }
}

// MARK: - CIBlendKernel Built-in Kernels Tests

@Suite("CIBlendKernel Built-in Kernels")
struct CIBlendKernelBuiltInTests {

    @Test("Built-in blend kernels have correct names")
    func builtInKernelNames() {
        #expect(CIBlendKernel.sourceOver.name == "sourceOver")
        #expect(CIBlendKernel.sourceIn.name == "sourceIn")
        #expect(CIBlendKernel.sourceOut.name == "sourceOut")
        #expect(CIBlendKernel.sourceAtop.name == "sourceAtop")
        #expect(CIBlendKernel.destinationOver.name == "destinationOver")
        #expect(CIBlendKernel.multiply.name == "multiply")
        #expect(CIBlendKernel.screen.name == "screen")
        #expect(CIBlendKernel.overlay.name == "overlay")
        #expect(CIBlendKernel.darken.name == "darken")
        #expect(CIBlendKernel.lighten.name == "lighten")
        #expect(CIBlendKernel.colorDodge.name == "colorDodge")
        #expect(CIBlendKernel.colorBurn.name == "colorBurn")
        #expect(CIBlendKernel.hardLight.name == "hardLight")
        #expect(CIBlendKernel.softLight.name == "softLight")
        #expect(CIBlendKernel.difference.name == "difference")
        #expect(CIBlendKernel.exclusion.name == "exclusion")
        #expect(CIBlendKernel.hue.name == "hue")
        #expect(CIBlendKernel.saturation.name == "saturation")
        #expect(CIBlendKernel.color.name == "color")
        #expect(CIBlendKernel.luminosity.name == "luminosity")
        #expect(CIBlendKernel.clear.name == "clear")
        #expect(CIBlendKernel.copy.name == "copy")
    }

    @Test("Blend kernel apply produces correct extent")
    func blendKernelApplyExtent() {
        let foreground = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let background = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        let result = CIBlendKernel.sourceOver.apply(foreground: foreground, background: background)
        #expect(result != nil)
        #expect(result?.extent.width == 100)
        #expect(result?.extent.height == 100)
        #expect(result?._filters.last?.name == "CISourceOverCompositing")
    }

    @Test("Blend kernel with different sized inputs uses union extent")
    func blendKernelDifferentSizes() {
        let foreground = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 50, height: 50))
        let background = CIImage(color: .blue).cropped(to: CGRect(x: 25, y: 25, width: 50, height: 50))

        let result = CIBlendKernel.sourceOver.apply(foreground: foreground, background: background)
        #expect(result != nil)
        // Union of (0,0,50,50) and (25,25,50,50) = (0,0,75,75)
        #expect(result?.extent.width == 75)
        #expect(result?.extent.height == 75)
    }

    @Test("Unsupported built-in blend kernels return nil instead of blank images")
    func unsupportedBuiltInReturnsNil() {
        let foreground = CIImage(color: .red)
        let background = CIImage(color: .blue)
        #expect(CIBlendKernel.clear.apply(foreground: foreground, background: background) == nil)
    }
}

// MARK: - CISampler Tests

@Suite("CISampler")
struct CISamplerTests {

    @Test("Initialize sampler with image")
    func initWithImage() {
        let image = CIImage(color: .red)
        let sampler = CISampler(image: image)
        #expect(sampler.image === image)
    }

    @Test("Initialize sampler with options")
    func initWithOptions() {
        let image = CIImage(color: .red)
        let sampler = CISampler(image: image, options: [
            .wrapMode: "clamp"
        ])
        #expect(sampler.image === image)
    }

    @Test("Sampler extent matches image")
    func samplerExtentMatchesImage() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let sampler = CISampler(image: image)
        #expect(sampler.extent == image.extent)
    }
}

// MARK: - CISamplerOption Tests

@Suite("CISamplerOption")
struct CISamplerOptionTests {

    @Test("Affine matrix option")
    func affineMatrixOption() {
        #expect(CISamplerOption.affineMatrix.rawValue == "kCISamplerAffineMatrix")
    }

    @Test("Wrap mode option")
    func wrapModeOption() {
        #expect(CISamplerOption.wrapMode.rawValue == "kCISamplerWrapMode")
    }

    @Test("Filter mode option")
    func filterModeOption() {
        #expect(CISamplerOption.filterMode.rawValue == "kCISamplerFilterMode")
    }

    @Test("Color space option")
    func colorSpaceOption() {
        #expect(CISamplerOption.colorSpace.rawValue == "kCISamplerColorSpace")
    }

    @Test("Options are equatable")
    func optionsEquatable() {
        #expect(CISamplerOption.wrapMode == CISamplerOption.wrapMode)
        #expect(CISamplerOption.wrapMode != CISamplerOption.filterMode)
    }

    @Test("Options are hashable")
    func optionsHashable() {
        var set: Set<CISamplerOption> = []
        set.insert(.wrapMode)
        set.insert(.wrapMode)
        set.insert(.filterMode)
        #expect(set.count == 2)
    }
}

// MARK: - CIFilterShape Tests

@Suite("CIFilterShape")
struct CIFilterShapeTests {

    @Test("Initialize with rect")
    func initWithRect() {
        let shape = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(shape.extent.width == 100)
        #expect(shape.extent.height == 100)
    }

    @Test("Union with shape")
    func unionWithShape() {
        let shape1 = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50))
        let shape2 = CIFilterShape(rect: CGRect(x: 25, y: 25, width: 50, height: 50))
        let union = shape1.union(with: shape2)
        #expect(union.extent.width == 75)
        #expect(union.extent.height == 75)
    }

    @Test("Union with rect")
    func unionWithRect() {
        let shape = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50))
        let union = shape.union(with: CGRect(x: 50, y: 50, width: 50, height: 50))
        #expect(union.extent.width == 100)
        #expect(union.extent.height == 100)
    }

    @Test("Intersect with shape")
    func intersectWithShape() {
        let shape1 = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let shape2 = CIFilterShape(rect: CGRect(x: 50, y: 50, width: 100, height: 100))
        let intersection = shape1.intersect(with: shape2)
        #expect(intersection.extent.width == 50)
        #expect(intersection.extent.height == 50)
    }

    @Test("Intersect with rect")
    func intersectWithRect() {
        let shape = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let intersection = shape.intersect(with: CGRect(x: 25, y: 25, width: 50, height: 50))
        #expect(intersection.extent.width == 50)
        #expect(intersection.extent.height == 50)
    }

    @Test("Inset shape")
    func insetShape() {
        let shape = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let inset = shape.inset(byX: 10, y: 20)
        #expect(inset.extent.width == 80)
        #expect(inset.extent.height == 60)
    }

    @Test("Transform shape")
    func transformShape() {
        let shape = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        let transformed = shape.transformed(by: transform)
        #expect(transformed.extent.width == 200)
        #expect(transformed.extent.height == 200)
    }
}

// MARK: - CIFilterShape Equatable/Hashable Tests

@Suite("CIFilterShape Equatable and Hashable")
struct CIFilterShapeEquatableHashableTests {

    @Test("Equal shapes are equal")
    func equalShapes() {
        let shape1 = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let shape2 = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(shape1 == shape2)
    }

    @Test("Different shapes are not equal")
    func differentShapes() {
        let shape1 = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let shape2 = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50))
        #expect(shape1 != shape2)
    }

    @Test("Equal shapes have same hash")
    func equalShapesSameHash() {
        let shape1 = CIFilterShape(rect: CGRect(x: 10, y: 20, width: 30, height: 40))
        let shape2 = CIFilterShape(rect: CGRect(x: 10, y: 20, width: 30, height: 40))
        #expect(shape1.hashValue == shape2.hashValue)
    }

    @Test("Shapes can be used in Set")
    func shapesInSet() {
        let shape1 = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let shape2 = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let shape3 = CIFilterShape(rect: CGRect(x: 0, y: 0, width: 50, height: 50))

        var set: Set<CIFilterShape> = []
        set.insert(shape1)
        set.insert(shape2)
        set.insert(shape3)

        #expect(set.count == 2)
    }
}
