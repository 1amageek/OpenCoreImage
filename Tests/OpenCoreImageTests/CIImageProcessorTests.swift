//
//  CIImageProcessorTests.swift
//  OpenCoreImage
//

import Testing
@testable import OpenCoreImage

@Suite("CIImageProcessorKernel Unsupported Execution")
struct CIImageProcessorTests {

    @Test("Single-output apply reports unsupported execution")
    func singleOutputApplyThrows() {
        #expect(throws: CIError.self) {
            _ = try CIImageProcessorKernel.apply(
                withExtent: CGRect(x: 0, y: 0, width: 4, height: 4),
                inputs: nil,
                arguments: nil
            )
        }
    }

    @Test("Multiple-output apply reports unsupported execution")
    func multipleOutputApplyThrows() {
        #expect(throws: CIError.self) {
            _ = try CIImageProcessorKernel.apply(
                withExtents: [CIVector(cgRect: CGRect(x: 0, y: 0, width: 4, height: 4))],
                inputs: nil,
                arguments: nil
            )
        }
    }
}
