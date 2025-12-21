//
//  TextDetectionAlgorithm.swift
//  OpenCoreImage
//
//  Text detection algorithm using edge detection and morphological analysis.
//

import Foundation

/// Text detection algorithm using edge detection and morphological operations.
///
/// This algorithm works by:
/// 1. Applying Sobel edge detection
/// 2. Using morphological dilation to connect text characters
/// 3. Finding connected components
/// 4. Filtering by aspect ratio (text regions are typically wider than tall)
internal struct TextDetectionAlgorithm {

    // MARK: - Detection

    /// Detects text regions in the given image.
    ///
    /// - Parameters:
    ///   - image: The source image
    ///   - analyzer: Image analyzer for pixel processing
    ///   - options: Detection options
    ///   - minFeatureSize: Minimum feature size as fraction of image dimension
    ///   - maxFeatureCount: Maximum number of features to return
    /// - Returns: Array of detected text features
    static func detect(
        in image: CIImage,
        using analyzer: ImageAnalyzer,
        options: [String: Any]?,
        minFeatureSize: Float,
        maxFeatureCount: Int
    ) -> [CITextFeature] {
        let extent = image.extent

        guard let pixelData = analyzer.getPixelData(from: image) else {
            return []
        }

        let width = Int(extent.width)
        let height = Int(extent.height)

        // Apply edge detection
        let edges = analyzer.applySobelEdgeDetection(pixelData: pixelData, width: width, height: height)

        // Apply morphological dilation to connect text characters
        let dilated = analyzer.morphologicalDilate(edges: edges, width: width, height: height, kernelSize: 3)

        // Find connected components
        let binaryMask = dilated.map { $0 > 128 }
        let components = analyzer.findConnectedComponents(mask: binaryMask, width: width, height: height)

        // Create text features
        return createTextFeatures(
            from: components,
            width: width,
            height: height,
            minFeatureSize: minFeatureSize,
            maxFeatureCount: maxFeatureCount
        )
    }

    // MARK: - Private Helpers

    /// Creates text features from connected components.
    private static func createTextFeatures(
        from components: [ImageAnalyzer.Component],
        width: Int,
        height: Int,
        minFeatureSize: Float,
        maxFeatureCount: Int
    ) -> [CITextFeature] {
        var features: [CITextFeature] = []
        let minSize = max(Int(minFeatureSize * Float(min(width, height))), 8)

        for component in components {
            let compWidth = component.width
            let compHeight = component.height

            // Text regions typically have width > height
            let aspectRatio = Float(compWidth) / Float(max(compHeight, 1))

            if compWidth >= minSize && compHeight >= minSize / 2 && aspectRatio > 1.5 {
                let topLeft = CGPoint(x: CGFloat(component.minX), y: CGFloat(height - component.minY))
                let topRight = CGPoint(x: CGFloat(component.maxX), y: CGFloat(height - component.minY))
                let bottomLeft = CGPoint(x: CGFloat(component.minX), y: CGFloat(height - component.maxY))
                let bottomRight = CGPoint(x: CGFloat(component.maxX), y: CGFloat(height - component.maxY))

                let bounds = CGRect(
                    x: CGFloat(component.minX),
                    y: CGFloat(height - component.maxY),
                    width: CGFloat(compWidth),
                    height: CGFloat(compHeight)
                )

                let text = CITextFeature(
                    bounds: bounds,
                    topLeft: topLeft,
                    topRight: topRight,
                    bottomLeft: bottomLeft,
                    bottomRight: bottomRight
                )
                features.append(text)

                if features.count >= maxFeatureCount {
                    break
                }
            }
        }

        return features
    }
}
