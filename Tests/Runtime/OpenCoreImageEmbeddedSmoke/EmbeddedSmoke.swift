import OpenCoreImage

private enum EmbeddedSmokeError: Error {
    case geometryContractViolated
    case urlContractViolated
    case byteStorageContractViolated
    case vectorContractViolated
    case colorContractViolated
    case filterContractViolated
    case contextContractViolated
    case fileRoundTripContractViolated
    case fileFailureContractViolated
}

@main
struct OpenCoreImageEmbeddedSmoke {
    static func main() throws {
        try run()
    }

    static func run() throws {
        let rect = CGRect(x: 8, y: 6, width: -4, height: -2).standardized
        guard rect == CGRect(x: 4, y: 4, width: 4, height: 2),
              CGRect.infinite.isInfinite,
              rect.intersection(CGRect(x: 6, y: 3, width: 4, height: 3))
                == CGRect(x: 6, y: 4, width: 2, height: 2),
              !rect.contains(CGPoint(x: rect.maxX, y: rect.minY)),
              !rect.intersects(CGRect(x: rect.maxX, y: rect.minY, width: 2, height: 2)),
              rect.intersection(CGRect(x: rect.maxX, y: rect.minY, width: 2, height: 2))
                == CGRect(x: rect.maxX, y: rect.minY, width: 0, height: 2) else {
            throw EmbeddedSmokeError.geometryContractViolated
        }

        guard let webURL = URL(string: "https://example.com/assets/image.png"),
              !webURL.isFileURL,
              webURL.absoluteString == "https://example.com/assets/image.png",
              webURL.path == "/assets/image.png",
              let authorityOnlyURL = URL(string: "https://example.com?size=large"),
              authorityOnlyURL.path.isEmpty,
              URL(string: "1nvalid://example.com") == nil else {
            throw EmbeddedSmokeError.urlContractViolated
        }

        var bytes = Data(capacity: 5)
        bytes.append(contentsOf: [72, 101, 108, 108, 111])
        guard String(data: bytes, encoding: .utf8) == "Hello" else {
            throw EmbeddedSmokeError.byteStorageContractViolated
        }

        let vector = CIVector(string: "[1.5 2.5 3.5]")
        guard vector.count == 3,
              vector.x == 1.5,
              vector.y == 2.5,
              vector.z == 3.5 else {
            throw EmbeddedSmokeError.vectorContractViolated
        }

        let color = CIColor(red: 0.25, green: 0.5, blue: 0.75, alpha: 1)
        guard color.numberOfComponents == 4,
              color.red == 0.25,
              color.green == 0.5,
              color.blue == 0.75,
              color.alpha == 1 else {
            throw EmbeddedSmokeError.colorContractViolated
        }

        guard let filter = CIFilter(name: "CIGaussianBlur") else {
            throw EmbeddedSmokeError.filterContractViolated
        }
        filter.setValue(7.5, forKey: kCIInputRadiusKey)
        guard filter.value(forKey: kCIInputRadiusKey) as? Double == 7.5 else {
            throw EmbeddedSmokeError.filterContractViolated
        }

        let context = CIContext()
        guard context.workingFormat == .RGBAf,
              context.workingColorSpace != nil else {
            throw EmbeddedSmokeError.contextContractViolated
        }

        let roundTripURL = URL(fileURLWithPath: "/smoke/opencoreimage-roundtrip.bin")
        try bytes.write(to: roundTripURL)
        guard try Data(contentsOf: roundTripURL) == bytes else {
            throw EmbeddedSmokeError.fileRoundTripContractViolated
        }

        let missingURL = URL(fileURLWithPath: "/missing/opencoreimage-smoke.png")
        guard CIImage(contentsOf: missingURL) == nil else {
            throw EmbeddedSmokeError.fileFailureContractViolated
        }
    }
}

@_cdecl("runOpenCoreImageEmbeddedSmoke")
public func runOpenCoreImageEmbeddedSmoke() {
    do {
        try OpenCoreImageEmbeddedSmoke.run()
    } catch {
        fatalError("OpenCoreImage Embedded smoke failed")
    }
}
