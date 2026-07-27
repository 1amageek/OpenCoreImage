import Testing
@_spi(OpenSpriteKit) @testable import OpenCoreImage

@Suite("CIFilter configuration revision")
struct CIFilterConfigurationRevisionTests {
    @Test("Every input mutation advances the cache invalidation token")
    func inputMutationsAdvanceRevision() throws {
        let filter = try #require(CIFilter(name: "CIColorControls"))
        let initialRevision = filter._configurationRevision

        filter.setValue(0.5, forKey: kCIInputBrightnessKey)
        let valueRevision = filter._configurationRevision
        #expect(valueRevision > initialRevision)

        filter.setValue(nil, forKey: kCIInputBrightnessKey)
        let removalRevision = filter._configurationRevision
        #expect(removalRevision > valueRevision)

        filter.setDefaults()
        #expect(filter._configurationRevision > removalRevision)
    }

    @Test("Typed filter properties use the same revision source")
    func typedPropertyMutationAdvancesRevision() throws {
        let filter = try #require(CIFilter(name: "CIGaussianBlur"))
        let initialRevision = filter._configurationRevision

        filter.radius = 12

        #expect(filter._configurationRevision > initialRevision)
    }
}
