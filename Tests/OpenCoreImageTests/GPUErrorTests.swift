//
//  GPUErrorTests.swift
//  OpenCoreImage
//
//  Tests for GPUError error types and descriptions.
//

import Testing
import Foundation
@testable import OpenCoreImage

// MARK: - Error Case Tests

@Suite("GPUError Cases")
struct GPUErrorCasesTests {

    @Test("WebGPU not available error")
    func webGPUNotAvailableError() {
        let error = GPUError.webGPUNotAvailable
        #expect(error.errorDescription?.contains("WebGPU") == true)
        #expect(error.errorDescription?.contains("not available") == true)
    }

    @Test("Adapter not available error")
    func adapterNotAvailableError() {
        let error = GPUError.adapterNotAvailable
        #expect(error.errorDescription?.contains("adapter") == true)
    }

    @Test("Device not available error")
    func deviceNotAvailableError() {
        let error = GPUError.deviceNotAvailable
        #expect(error.errorDescription?.contains("device") == true)
    }

    @Test("Shader not found error with name")
    func shaderNotFoundError() {
        let error = GPUError.shaderNotFound("CICustomFilter")
        #expect(error.errorDescription?.contains("Shader not found") == true)
        #expect(error.errorDescription?.contains("CICustomFilter") == true)
    }

    @Test("Compilation failed error with message")
    func compilationFailedError() {
        let error = GPUError.compilationFailed("Syntax error at line 10")
        #expect(error.errorDescription?.contains("compilation failed") == true)
        #expect(error.errorDescription?.contains("Syntax error at line 10") == true)
    }

    @Test("Pipeline creation failed error with message")
    func pipelineCreationFailedError() {
        let error = GPUError.pipelineCreationFailed("Invalid bind group layout")
        #expect(error.errorDescription?.contains("Pipeline creation failed") == true)
        #expect(error.errorDescription?.contains("Invalid bind group layout") == true)
    }

    @Test("Rendering failed error with message")
    func renderingFailedError() {
        let error = GPUError.renderingFailed("Command buffer submission failed")
        #expect(error.errorDescription?.contains("Rendering failed") == true)
        #expect(error.errorDescription?.contains("Command buffer submission failed") == true)
    }

    @Test("Texture upload failed error with message")
    func textureUploadFailedError() {
        let error = GPUError.textureUploadFailed("Texture format not supported")
        #expect(error.errorDescription?.contains("Texture upload failed") == true)
        #expect(error.errorDescription?.contains("Texture format not supported") == true)
    }

    @Test("Texture readback failed error with message")
    func textureReadbackFailedError() {
        let error = GPUError.textureReadbackFailed("Buffer mapping failed")
        #expect(error.errorDescription?.contains("Texture readback failed") == true)
        #expect(error.errorDescription?.contains("Buffer mapping failed") == true)
    }

    @Test("Invalid parameters error with message")
    func invalidParametersError() {
        let error = GPUError.invalidParameters("Radius must be positive")
        #expect(error.errorDescription?.contains("Invalid parameters") == true)
        #expect(error.errorDescription?.contains("Radius must be positive") == true)
    }

    @Test("Unsupported filter error with name")
    func unsupportedFilterError() {
        let error = GPUError.unsupportedFilter("CIDepthOfField")
        #expect(error.errorDescription?.contains("Unsupported filter") == true)
        #expect(error.errorDescription?.contains("CIDepthOfField") == true)
    }
}

// MARK: - Error Protocol Conformance Tests

@Suite("GPUError Protocol Conformance")
struct GPUErrorProtocolConformanceTests {

    @Test("Conforms to Error protocol")
    func conformsToError() {
        let error: Error = GPUError.webGPUNotAvailable
        #expect(error is GPUError)
    }

    @Test("Conforms to LocalizedError protocol")
    func conformsToLocalizedError() {
        let error: LocalizedError = GPUError.webGPUNotAvailable
        #expect(error.errorDescription != nil)
    }

    @Test("All cases have non-nil error descriptions")
    func allCasesHaveDescriptions() {
        let errors: [GPUError] = [
            .webGPUNotAvailable,
            .adapterNotAvailable,
            .deviceNotAvailable,
            .shaderNotFound("test"),
            .compilationFailed("test"),
            .pipelineCreationFailed("test"),
            .renderingFailed("test"),
            .textureUploadFailed("test"),
            .textureReadbackFailed("test"),
            .invalidParameters("test"),
            .unsupportedFilter("test")
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription?.isEmpty == false)
        }
    }
}

// MARK: - Error Equality Tests

@Suite("GPUError Matching")
struct GPUErrorMatchingTests {

    @Test("Same error cases match in switch")
    func sameCasesMatchInSwitch() {
        let error = GPUError.webGPUNotAvailable

        switch error {
        case .webGPUNotAvailable:
            break  // Expected
        default:
            Issue.record("Should match webGPUNotAvailable")
        }
    }

    @Test("Associated values are preserved")
    func associatedValuesPreserved() {
        let shaderName = "CITestFilter"
        let error = GPUError.shaderNotFound(shaderName)

        if case .shaderNotFound(let name) = error {
            #expect(name == shaderName)
        } else {
            Issue.record("Should match shaderNotFound")
        }
    }

    @Test("Different associated values create different errors")
    func differentAssociatedValuesAreDifferent() {
        let error1 = GPUError.shaderNotFound("Filter1")
        let error2 = GPUError.shaderNotFound("Filter2")

        if case .shaderNotFound(let name1) = error1,
           case .shaderNotFound(let name2) = error2 {
            #expect(name1 != name2)
        } else {
            Issue.record("Both should match shaderNotFound")
        }
    }
}

// MARK: - Error Description Content Tests

@Suite("GPUError Description Content")
struct GPUErrorDescriptionContentTests {

    @Test("WebGPU not available description is informative")
    func webGPUNotAvailableDescriptionContent() {
        let error = GPUError.webGPUNotAvailable
        let description = error.errorDescription!

        #expect(description.contains("WebGPU"))
        #expect(description.contains("environment") || description.contains("available"))
    }

    @Test("Shader not found includes shader name")
    func shaderNotFoundIncludesName() {
        let shaderName = "CIGaussianBlur"
        let error = GPUError.shaderNotFound(shaderName)
        let description = error.errorDescription!

        #expect(description.contains(shaderName))
    }

    @Test("Compilation failed includes error details")
    func compilationFailedIncludesDetails() {
        let message = "Unexpected token at position 42"
        let error = GPUError.compilationFailed(message)
        let description = error.errorDescription!

        #expect(description.contains(message))
    }

    @Test("Unsupported filter includes filter name")
    func unsupportedFilterIncludesName() {
        let filterName = "CICustomKernel"
        let error = GPUError.unsupportedFilter(filterName)
        let description = error.errorDescription!

        #expect(description.contains(filterName))
    }
}

// MARK: - Error Usage Pattern Tests

@Suite("GPUError Usage Patterns")
struct GPUErrorUsagePatternsTests {

    @Test("Error can be thrown and caught")
    func errorCanBeThrownAndCaught() {
        func throwingFunction() throws {
            throw GPUError.webGPUNotAvailable
        }

        do {
            try throwingFunction()
            Issue.record("Should have thrown")
        } catch let error as GPUError {
            if case .webGPUNotAvailable = error {
                // Expected
            } else {
                Issue.record("Wrong GPUError case")
            }
        } catch {
            Issue.record("Wrong error type caught")
        }
    }

    @Test("Error can be converted to Any")
    func errorCanBeConvertedToAny() {
        let error: GPUError = .shaderNotFound("test")
        let anyError: Any = error

        #expect(anyError is GPUError)
    }

    @Test("Error can be used in Result type")
    func errorCanBeUsedInResult() {
        let result: Result<String, GPUError> = .failure(.deviceNotAvailable)

        switch result {
        case .success:
            Issue.record("Should be failure")
        case .failure(let error):
            if case .deviceNotAvailable = error {
                // Expected
            } else {
                Issue.record("Wrong GPUError case")
            }
        }
    }
}

// MARK: - Specific Error Case Tests

@Suite("GPUError Specific Cases")
struct GPUErrorSpecificCasesTests {

    @Test("Pipeline error for shader compilation")
    func pipelineErrorForShaderCompilation() {
        let error = GPUError.pipelineCreationFailed("Shader module compilation failed")
        #expect(error.errorDescription?.contains("Pipeline") == true)
    }

    @Test("Texture error for invalid dimensions")
    func textureErrorForInvalidDimensions() {
        let error = GPUError.textureUploadFailed("Texture dimensions exceed maximum")
        #expect(error.errorDescription?.contains("Texture") == true)
        #expect(error.errorDescription?.contains("dimensions") == true)
    }

    @Test("Invalid parameters for negative values")
    func invalidParametersForNegativeValues() {
        let error = GPUError.invalidParameters("Blur radius cannot be negative")
        #expect(error.errorDescription?.contains("negative") == true)
    }

    @Test("Unsupported filter for custom kernel")
    func unsupportedFilterForCustomKernel() {
        let error = GPUError.unsupportedFilter("CICustomMetalKernel")
        #expect(error.errorDescription?.contains("CICustomMetalKernel") == true)
    }

    @Test("Rendering failed for timeout")
    func renderingFailedForTimeout() {
        let error = GPUError.renderingFailed("GPU operation timed out")
        #expect(error.errorDescription?.contains("timed out") == true)
    }

    @Test("Readback failed for buffer size mismatch")
    func readbackFailedForBufferSizeMismatch() {
        let error = GPUError.textureReadbackFailed("Buffer size does not match texture size")
        #expect(error.errorDescription?.contains("Buffer") == true)
    }
}

// MARK: - Error Category Tests

@Suite("GPUError Categories")
struct GPUErrorCategoryTests {

    @Test("Initialization errors")
    func initializationErrors() {
        let initErrors: [GPUError] = [
            .webGPUNotAvailable,
            .adapterNotAvailable,
            .deviceNotAvailable
        ]

        for error in initErrors {
            let description = error.errorDescription!
            // Init errors should not contain filter-specific terms
            #expect(!description.contains("Shader"))
            #expect(!description.contains("filter"))
        }
    }

    @Test("Shader-related errors")
    func shaderRelatedErrors() {
        let shaderErrors: [GPUError] = [
            .shaderNotFound("test"),
            .compilationFailed("test")
        ]

        for error in shaderErrors {
            let description = error.errorDescription!
            #expect(description.contains("Shader") || description.contains("compilation"))
        }
    }

    @Test("Runtime errors")
    func runtimeErrors() {
        let runtimeErrors: [GPUError] = [
            .pipelineCreationFailed("test"),
            .renderingFailed("test"),
            .textureUploadFailed("test"),
            .textureReadbackFailed("test")
        ]

        for error in runtimeErrors {
            let description = error.errorDescription!
            #expect(description.contains("failed") || description.contains("Failed"))
        }
    }

    @Test("Validation errors")
    func validationErrors() {
        let validationErrors: [GPUError] = [
            .invalidParameters("test"),
            .unsupportedFilter("test")
        ]

        for error in validationErrors {
            let description = error.errorDescription!
            #expect(description.contains("Invalid") || description.contains("Unsupported"))
        }
    }
}
