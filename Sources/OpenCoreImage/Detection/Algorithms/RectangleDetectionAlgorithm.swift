//
//  RectangleDetectionAlgorithm.swift
//  OpenCoreImage
//
//  Rectangle detection algorithm using Sobel edge detection and contour analysis.
//

import Foundation

/// Rectangle detection algorithm using edge detection and contour approximation.
///
/// This algorithm works by:
/// 1. Applying Sobel edge detection
/// 2. Finding contours in the edge image
/// 3. Approximating contours to quadrilaterals
/// 4. Filtering by size and shape
internal struct RectangleDetectionAlgorithm {

    // MARK: - Detection

    /// Detects rectangles in the given image.
    ///
    /// - Parameters:
    ///   - image: The source image
    ///   - analyzer: Image analyzer for pixel processing
    ///   - options: Detection options
    ///   - minFeatureSize: Minimum feature size as fraction of image dimension
    ///   - maxFeatureCount: Maximum number of features to return
    /// - Returns: Array of detected rectangle features
    static func detect(
        in image: CIImage,
        using analyzer: ImageAnalyzer,
        options: [String: Any]?,
        minFeatureSize: Float,
        maxFeatureCount: Int
    ) -> [CIRectangleFeature] {
        let extent = image.extent

        guard let pixelData = analyzer.getPixelData(from: image) else {
            return []
        }

        let width = Int(extent.width)
        let height = Int(extent.height)

        // Apply Sobel edge detection
        let edges = analyzer.applySobelEdgeDetection(pixelData: pixelData, width: width, height: height)

        // Find contours
        let contours = analyzer.findContours(edges: edges, width: width, height: height)

        // Convert contours to rectangle features
        return createRectangleFeatures(
            from: contours,
            using: analyzer,
            width: width,
            height: height,
            minFeatureSize: minFeatureSize,
            maxFeatureCount: maxFeatureCount
        )
    }

    // MARK: - Private Helpers

    /// Creates rectangle features from contours.
    private static func createRectangleFeatures(
        from contours: [ImageAnalyzer.Contour],
        using analyzer: ImageAnalyzer,
        width: Int,
        height: Int,
        minFeatureSize: Float,
        maxFeatureCount: Int
    ) -> [CIRectangleFeature] {
        var features: [CIRectangleFeature] = []
        let minSize = max(Int(minFeatureSize * Float(min(width, height))), 10)

        for contour in contours {
            // Approximate contour to quadrilateral
            if let quad = analyzer.approximateToQuadrilateral(contour: contour) {
                let quadWidth = max(quad.topRight.x - quad.topLeft.x,
                                    quad.bottomRight.x - quad.bottomLeft.x)
                let quadHeight = max(quad.topLeft.y - quad.bottomLeft.y,
                                     quad.topRight.y - quad.bottomRight.y)

                if Int(quadWidth) >= minSize && Int(quadHeight) >= minSize {
                    let bounds = CGRect(
                        x: min(quad.topLeft.x, quad.bottomLeft.x),
                        y: min(quad.bottomLeft.y, quad.bottomRight.y),
                        width: quadWidth,
                        height: quadHeight
                    )

                    // Flip Y coordinates for Core Image coordinate system
                    let flippedTopLeft = CGPoint(x: quad.topLeft.x, y: CGFloat(height) - quad.topLeft.y)
                    let flippedTopRight = CGPoint(x: quad.topRight.x, y: CGFloat(height) - quad.topRight.y)
                    let flippedBottomLeft = CGPoint(x: quad.bottomLeft.x, y: CGFloat(height) - quad.bottomLeft.y)
                    let flippedBottomRight = CGPoint(x: quad.bottomRight.x, y: CGFloat(height) - quad.bottomRight.y)

                    let flippedBounds = CGRect(
                        x: bounds.origin.x,
                        y: CGFloat(height) - bounds.origin.y - bounds.height,
                        width: bounds.width,
                        height: bounds.height
                    )

                    let rect = CIRectangleFeature(
                        bounds: flippedBounds,
                        topLeft: flippedTopLeft,
                        topRight: flippedTopRight,
                        bottomLeft: flippedBottomLeft,
                        bottomRight: flippedBottomRight
                    )
                    features.append(rect)

                    if features.count >= maxFeatureCount {
                        break
                    }
                }
            }
        }

        return features
    }
}
