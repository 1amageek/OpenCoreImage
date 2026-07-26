import Foundation
import Testing
@testable import OpenCoreImage

@Suite("CI render result ownership")
struct CIRenderResultTests {
    @Test("Result owns bytes independently of the source value")
    func ownsPixelBytes() throws {
        var source = Data([255, 0, 0, 255])
        let result = try CIRenderResult(
            pixelData: source,
            width: 1,
            height: 1,
            colorSpace: .deviceRGB
        )

        source[0] = 0

        #expect(result.pixelData == Data([255, 0, 0, 255]))
        let image = try result.makeCGImage()
        #expect(image.width == 1)
        #expect(image.height == 1)
        #expect(image.data == Data([255, 0, 0, 255]))
    }

    @Test("Result rejects a mismatched byte count")
    func rejectsMismatchedByteCount() {
        #expect(throws: CIError.self) {
            try CIRenderResult(
                pixelData: Data([0, 0, 0]),
                width: 1,
                height: 1,
                colorSpace: .deviceRGB
            )
        }
    }

    @Test("Result rejects overflowing dimensions before materialization")
    func rejectsOverflowingDimensions() {
        #expect(throws: CIError.self) {
            try CIRenderResult(
                pixelData: Data(),
                width: Int.max,
                height: 2,
                colorSpace: .deviceRGB
            )
        }
    }

    @Test("Async rendering rejects formats whose byte layout is not implemented")
    func rejectsUnsupportedAsyncOutputFormat() async {
        let context = CIContext()
        let image = CIImage(color: .red)

        do {
            _ = try await context.createCGImageAsync(
                image,
                from: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .BGRA8
            )
            Issue.record("Expected unsupported output format to throw")
        } catch let error as CIError {
            #expect(error == .unsupportedFormat(.BGRA8))
        } catch {
            Issue.record("Expected CIError, received \(error)")
        }
    }
}
