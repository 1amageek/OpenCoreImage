//
//  FaceDetectionAlgorithm.swift
//  OpenCoreImage
//
//  Face detection algorithm using YCbCr skin color analysis.
//

import Foundation

/// Face detection algorithm using skin color analysis in YCbCr color space.
///
/// This algorithm works by:
/// 1. Converting pixels to YCbCr color space
/// 2. Identifying skin-colored pixels based on chromatic thresholds
/// 3. Finding connected components in the skin mask
/// 4. Filtering components by size and aspect ratio
/// 5. Estimating facial feature positions
internal struct FaceDetectionAlgorithm {

    // MARK: - Detection

    /// Detects faces in the given image using skin color analysis.
    ///
    /// - Parameters:
    ///   - image: The source image
    ///   - analyzer: Image analyzer for pixel processing
    ///   - options: Detection options
    ///   - minFeatureSize: Minimum feature size as fraction of image dimension
    ///   - maxFeatureCount: Maximum number of features to return
    /// - Returns: Array of detected face features
    static func detect(
        in image: CIImage,
        using analyzer: ImageAnalyzer,
        options: [String: Any]?,
        minFeatureSize: Float,
        maxFeatureCount: Int
    ) -> [CIFaceFeature] {
        let extent = image.extent

        guard let pixelData = analyzer.getPixelData(from: image) else {
            return []
        }

        let width = Int(extent.width)
        let height = Int(extent.height)

        // Create skin mask
        let skinMask = createSkinMask(
            pixelData: pixelData,
            width: width,
            height: height,
            analyzer: analyzer
        )

        // Find connected components
        let components = analyzer.findConnectedComponents(mask: skinMask, width: width, height: height)

        // Filter and convert to face features
        return createFaceFeatures(
            from: components,
            width: width,
            height: height,
            minFeatureSize: minFeatureSize,
            maxFeatureCount: maxFeatureCount
        )
    }

    // MARK: - Private Helpers

    /// Creates a binary mask of skin-colored pixels.
    private static func createSkinMask(
        pixelData: [UInt8],
        width: Int,
        height: Int,
        analyzer: ImageAnalyzer
    ) -> [Bool] {
        var skinMask = [Bool](repeating: false, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                guard index + 2 < pixelData.count else { continue }

                let r = Float(pixelData[index])
                let g = Float(pixelData[index + 1])
                let b = Float(pixelData[index + 2])

                let (yVal, cb, cr) = analyzer.rgbToYCbCr(r: r, g: g, b: b)

                if analyzer.isSkinColor(y: yVal, cb: cb, cr: cr) {
                    skinMask[y * width + x] = true
                }
            }
        }

        return skinMask
    }

    /// Creates face features from connected components.
    private static func createFaceFeatures(
        from components: [ImageAnalyzer.Component],
        width: Int,
        height: Int,
        minFeatureSize: Float,
        maxFeatureCount: Int
    ) -> [CIFaceFeature] {
        var features: [CIFaceFeature] = []
        let minSize = max(Int(minFeatureSize * Float(min(width, height))), 20)

        for component in components {
            let compWidth = component.width
            let compHeight = component.height

            // Face-like aspect ratio (0.5 to 2.0)
            let aspectRatio = Float(compWidth) / Float(max(compHeight, 1))

            if compWidth >= minSize && compHeight >= minSize &&
               aspectRatio > 0.5 && aspectRatio < 2.0 {

                let bounds = CGRect(
                    x: CGFloat(component.minX),
                    y: CGFloat(height - component.maxY),  // Flip Y coordinate
                    width: CGFloat(compWidth),
                    height: CGFloat(compHeight)
                )

                let face = CIFaceFeature(bounds: bounds)
                face.setFaceAngle(0, hasFaceAngle: false)

                // Estimate facial feature positions
                estimateFacialFeatures(
                    face: face,
                    component: component,
                    height: height
                )

                features.append(face)

                if features.count >= maxFeatureCount {
                    break
                }
            }
        }

        return features
    }

    /// Estimates eye and mouth positions based on component geometry.
    private static func estimateFacialFeatures(
        face: CIFaceFeature,
        component: ImageAnalyzer.Component,
        height: Int
    ) {
        let compWidth = component.width

        let centerX = CGFloat(component.minX + compWidth / 2)
        let topY = CGFloat(height - component.minY)
        let bottomY = CGFloat(height - component.maxY)
        let faceHeight = topY - bottomY

        // Eyes are typically at about 1/3 from top
        let eyeY = topY - faceHeight * 0.35
        let leftEyeX = centerX - CGFloat(compWidth) * 0.2
        let rightEyeX = centerX + CGFloat(compWidth) * 0.2

        face.setLeftEyePosition(CGPoint(x: leftEyeX, y: eyeY), hasLeftEye: true)
        face.setRightEyePosition(CGPoint(x: rightEyeX, y: eyeY), hasRightEye: true)

        // Mouth is typically at about 2/3 from top
        let mouthY = topY - faceHeight * 0.75
        face.setMouthPosition(CGPoint(x: centerX, y: mouthY), hasMouth: true)
    }
}
