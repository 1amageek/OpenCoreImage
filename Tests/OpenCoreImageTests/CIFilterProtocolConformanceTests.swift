//
//  CIFilterProtocolConformanceTests.swift
//  OpenCoreImage
//
//  Tests that `CIFilter(name:)` instances can be used through their corresponding
//  per-filter protocols (e.g. `CIGaussianBlur`), and that the typed properties
//  on those protocols read from and write to the same `_inputValues` backing
//  store as `setValue(_:forKey:)` / `value(forKey:)`.
//
//  Note: Because the unconditional extensions in `CIFilterProtocolConformances.swift`
//  make `CIFilter` conform to each of these protocols at compile time, we use a
//  plain upcast (`as any P`) to obtain the protocol-typed value. This verifies
//  the conformance is wired up AND that the typed properties route through the
//  shared `_inputValues` dictionary.
//

import Testing
import Foundation
@testable import OpenCoreImage

// MARK: - CIGaussianBlur Conformance

@Suite("CIGaussianBlur Protocol Conformance")
struct CIGaussianBlurConformanceTests {

    @Test("CIFilter is usable as any CIGaussianBlur")
    func protocolUsable() {
        let f = CIFilter(name: "CIGaussianBlur")!
        let _: any CIGaussianBlur = f
    }

    @Test("Default radius is 10.0 (Apple default)")
    func defaultRadius() {
        let f = CIFilter(name: "CIGaussianBlur")!
        let p: any CIGaussianBlur = f
        #expect(p.radius == 10.0)
    }

    @Test("Setting radius via protocol writes to KVC backing")
    func protocolWriteVisibleViaKVC() {
        let f = CIFilter(name: "CIGaussianBlur")!
        let p: any CIGaussianBlur = f
        p.radius = 25.0
        #expect(f.value(forKey: kCIInputRadiusKey) as? Float == 25.0)
    }

    @Test("Setting radius via KVC is visible through protocol getter")
    func kvcWriteVisibleViaProtocol() {
        let f = CIFilter(name: "CIGaussianBlur")!
        f.setValue(Float(5.0), forKey: kCIInputRadiusKey)
        let p: any CIGaussianBlur = f
        #expect(p.radius == 5.0)
    }

    @Test("Setting inputImage via protocol is visible through KVC")
    func protocolInputImageVisibleViaKVC() {
        let f = CIFilter(name: "CIGaussianBlur")!
        let p: any CIGaussianBlur = f
        let image = CIImage(color: .red)
        p.inputImage = image
        #expect(f.value(forKey: kCIInputImageKey) is CIImage)
    }
}

// MARK: - CIBoxBlur Conformance

@Suite("CIBoxBlur Protocol Conformance")
struct CIBoxBlurConformanceTests {

    @Test("CIFilter is usable as any CIBoxBlur")
    func protocolUsable() {
        let f = CIFilter(name: "CIBoxBlur")!
        let _: any CIBoxBlur = f
    }

    @Test("Default radius returns shared default 10.0 when unset")
    func defaultRadius() {
        let f = CIFilter(name: "CIBoxBlur")!
        let p: any CIBoxBlur = f
        // CIBoxBlur reuses the CIGaussianBlur radius conformance, which
        // defaults to 10.0 when no value is set.
        #expect(p.radius == 10.0)
    }

    @Test("Setting radius via protocol writes to KVC backing")
    func protocolWriteVisibleViaKVC() {
        let f = CIFilter(name: "CIBoxBlur")!
        let p: any CIBoxBlur = f
        p.radius = 4.0
        #expect(f.value(forKey: kCIInputRadiusKey) as? Float == 4.0)
    }

    @Test("KVC write visible through protocol getter")
    func kvcWriteVisibleViaProtocol() {
        let f = CIFilter(name: "CIBoxBlur")!
        f.setValue(Float(2.5), forKey: kCIInputRadiusKey)
        let p: any CIBoxBlur = f
        #expect(p.radius == 2.5)
    }
}

// MARK: - CIDiscBlur Conformance

@Suite("CIDiscBlur Protocol Conformance")
struct CIDiscBlurConformanceTests {

    @Test("CIFilter is usable as any CIDiscBlur")
    func protocolUsable() {
        let f = CIFilter(name: "CIDiscBlur")!
        let _: any CIDiscBlur = f
    }

    @Test("Default radius returns shared default 10.0 when unset")
    func defaultRadius() {
        let f = CIFilter(name: "CIDiscBlur")!
        let p: any CIDiscBlur = f
        #expect(p.radius == 10.0)
    }

    @Test("Setting radius via protocol writes to KVC backing")
    func protocolWriteVisibleViaKVC() {
        let f = CIFilter(name: "CIDiscBlur")!
        let p: any CIDiscBlur = f
        p.radius = 6.0
        #expect(f.value(forKey: kCIInputRadiusKey) as? Float == 6.0)
    }

    @Test("KVC write visible through protocol getter")
    func kvcWriteVisibleViaProtocol() {
        let f = CIFilter(name: "CIDiscBlur")!
        f.setValue(Float(1.5), forKey: kCIInputRadiusKey)
        let p: any CIDiscBlur = f
        #expect(p.radius == 1.5)
    }
}

// MARK: - CIMotionBlur Conformance

@Suite("CIMotionBlur Protocol Conformance")
struct CIMotionBlurConformanceTests {

    @Test("CIFilter is usable as any CIMotionBlur")
    func protocolUsable() {
        let f = CIFilter(name: "CIMotionBlur")!
        let _: any CIMotionBlur = f
    }

    @Test("Default radius is 10.0 and default angle is 0.0")
    func defaults() {
        let f = CIFilter(name: "CIMotionBlur")!
        let p: any CIMotionBlur = f
        #expect(p.radius == 10.0)
        #expect(p.angle == 0.0)
    }

    @Test("Setting angle via protocol writes to KVC backing")
    func protocolAngleVisibleViaKVC() {
        let f = CIFilter(name: "CIMotionBlur")!
        let p: any CIMotionBlur = f
        p.angle = 1.25
        #expect(f.value(forKey: kCIInputAngleKey) as? Float == 1.25)
    }

    @Test("KVC angle write visible through protocol getter")
    func kvcAngleVisibleViaProtocol() {
        let f = CIFilter(name: "CIMotionBlur")!
        f.setValue(Float(0.75), forKey: kCIInputAngleKey)
        let p: any CIMotionBlur = f
        #expect(p.angle == 0.75)
    }

    @Test("Setting radius via protocol writes to KVC backing")
    func protocolRadiusVisibleViaKVC() {
        let f = CIFilter(name: "CIMotionBlur")!
        let p: any CIMotionBlur = f
        p.radius = 8.0
        #expect(f.value(forKey: kCIInputRadiusKey) as? Float == 8.0)
    }
}

// MARK: - CIColorControls Conformance

@Suite("CIColorControls Protocol Conformance")
struct CIColorControlsConformanceTests {

    @Test("CIFilter is usable as any CIColorControls")
    func protocolUsable() {
        let f = CIFilter(name: "CIColorControls")!
        let _: any CIColorControls = f
    }

    @Test("Apple defaults: brightness 0, contrast 1, saturation 1")
    func defaults() {
        let f = CIFilter(name: "CIColorControls")!
        let p: any CIColorControls = f
        #expect(p.brightness == 0.0)
        #expect(p.contrast == 1.0)
        #expect(p.saturation == 1.0)
    }

    @Test("Protocol writes visible via KVC")
    func protocolWritesVisibleViaKVC() {
        let f = CIFilter(name: "CIColorControls")!
        let p: any CIColorControls = f
        p.brightness = 0.25
        p.contrast = 1.5
        p.saturation = 0.5
        #expect(f.value(forKey: "inputBrightness") as? Float == 0.25)
        #expect(f.value(forKey: "inputContrast") as? Float == 1.5)
        #expect(f.value(forKey: "inputSaturation") as? Float == 0.5)
    }

    @Test("KVC writes visible through protocol getters")
    func kvcWritesVisibleViaProtocol() {
        let f = CIFilter(name: "CIColorControls")!
        f.setValue(Float(-0.1), forKey: "inputBrightness")
        f.setValue(Float(2.0), forKey: "inputContrast")
        f.setValue(Float(0.25), forKey: "inputSaturation")
        let p: any CIColorControls = f
        #expect(p.brightness == -0.1)
        #expect(p.contrast == 2.0)
        #expect(p.saturation == 0.25)
    }
}

// MARK: - CISepiaTone Conformance

@Suite("CISepiaTone Protocol Conformance")
struct CISepiaToneConformanceTests {

    @Test("CIFilter is usable as any CISepiaTone")
    func protocolUsable() {
        let f = CIFilter(name: "CISepiaTone")!
        let _: any CISepiaTone = f
    }

    @Test("Default intensity is 1.0 (Apple default)")
    func defaultIntensity() {
        let f = CIFilter(name: "CISepiaTone")!
        let p: any CISepiaTone = f
        #expect(p.intensity == 1.0)
    }

    @Test("Protocol write visible via KVC")
    func protocolWriteVisibleViaKVC() {
        let f = CIFilter(name: "CISepiaTone")!
        let p: any CISepiaTone = f
        p.intensity = 0.8
        #expect(f.value(forKey: "inputIntensity") as? Float == 0.8)
    }

    @Test("KVC write visible through protocol getter")
    func kvcWriteVisibleViaProtocol() {
        let f = CIFilter(name: "CISepiaTone")!
        f.setValue(Float(0.3), forKey: "inputIntensity")
        let p: any CISepiaTone = f
        #expect(p.intensity == 0.3)
    }
}
