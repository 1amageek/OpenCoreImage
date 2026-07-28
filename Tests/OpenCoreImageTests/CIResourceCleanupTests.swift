import Testing
@testable import OpenCoreImage

@Suite("CI Resource Cleanup")
struct CIResourceCleanupTests {
    private enum ProbeError: Error {
        case expected
    }

    @Test("Cleanup runs exactly once after success")
    func cleanupAfterSuccess() async throws {
        var released: [Int] = []

        let result = try await withCIResourceCleanup(
            cleanup: { released.append(42) },
            operation: { 43 }
        )

        #expect(result == 43)
        #expect(released == [42])
    }

    @Test("Cleanup runs exactly once after failure")
    func cleanupAfterFailure() async {
        var released: [Int] = []

        do {
            _ = try await withCIResourceCleanup(
                cleanup: { released.append(42) },
                operation: { throw ProbeError.expected }
            ) as Int
            Issue.record("Expected the operation to throw")
        } catch ProbeError.expected {
            #expect(released == [42])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
