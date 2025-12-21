//
//  ImageAnalyzer.swift
//  OpenCoreImage
//
//  Shared image processing utilities for detection algorithms.
//

import Foundation
import OpenCoreGraphics

/// Shared image processing utilities for detection algorithms.
///
/// This struct provides common image processing operations used by various
/// detection algorithms, including edge detection, binarization, connected
/// component analysis, and morphological operations.
internal struct ImageAnalyzer: Sendable {

    // MARK: - Types

    /// Represents a connected component in a binary image.
    struct Component {
        var minX: Int
        var maxX: Int
        var minY: Int
        var maxY: Int
        var pixelCount: Int

        /// Width of the bounding box (inclusive of both min and max)
        var width: Int { maxX - minX + 1 }
        /// Height of the bounding box (inclusive of both min and max)
        var height: Int { maxY - minY + 1 }
    }

    /// Represents a contour (set of edge points) in an image.
    struct Contour {
        var points: [(x: Int, y: Int)]
    }

    /// Represents a quadrilateral shape.
    struct Quadrilateral {
        var topLeft: CGPoint
        var topRight: CGPoint
        var bottomLeft: CGPoint
        var bottomRight: CGPoint
    }

    // MARK: - Properties

    private let context: CIContext?

    // MARK: - Initialization

    init(context: CIContext?) {
        self.context = context
    }

    // MARK: - Pixel Data Extraction

    /// Extracts RGBA pixel data from a CIImage.
    ///
    /// - Parameter image: The source image
    /// - Returns: Array of pixel data in RGBA format, or nil if extraction fails
    func getPixelData(from image: CIImage) -> [UInt8]? {
        let ctx = context ?? CIContext()
        let extent = image.extent

        guard !extent.isInfinite else { return nil }

        let width = Int(extent.width)
        let height = Int(extent.height)

        guard width > 0 && height > 0 else { return nil }

        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        ctx.render(
            image,
            toBitmap: &pixelData,
            rowBytes: width * 4,
            bounds: extent,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )

        return pixelData
    }

    // MARK: - Edge Detection

    /// Applies Sobel edge detection to the image.
    ///
    /// - Parameters:
    ///   - pixelData: RGBA pixel data
    ///   - width: Image width
    ///   - height: Image height
    /// - Returns: Edge magnitude for each pixel (grayscale)
    func applySobelEdgeDetection(pixelData: [UInt8], width: Int, height: Int) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: width * height)

        let sobelX: [[Int]] = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]]
        let sobelY: [[Int]] = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]]

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                var gx = 0
                var gy = 0

                for ky in 0..<3 {
                    for kx in 0..<3 {
                        let px = x + kx - 1
                        let py = y + ky - 1
                        let index = (py * width + px) * 4

                        // Convert to grayscale
                        let gray = Int(pixelData[index]) * 299 / 1000 +
                                   Int(pixelData[index + 1]) * 587 / 1000 +
                                   Int(pixelData[index + 2]) * 114 / 1000

                        gx += gray * sobelX[ky][kx]
                        gy += gray * sobelY[ky][kx]
                    }
                }

                let magnitude = min(255, Int(sqrt(Double(gx * gx + gy * gy))))
                result[y * width + x] = UInt8(magnitude)
            }
        }

        return result
    }

    // MARK: - Binarization

    /// Binarizes an image using adaptive thresholding.
    ///
    /// - Parameters:
    ///   - pixelData: RGBA pixel data
    ///   - width: Image width
    ///   - height: Image height
    /// - Returns: Binary mask where true indicates dark pixels
    func binarizeImage(pixelData: [UInt8], width: Int, height: Int) -> [Bool] {
        var result = [Bool](repeating: false, count: width * height)

        // Calculate average brightness
        var total = 0
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                let gray = Int(pixelData[index]) * 299 / 1000 +
                           Int(pixelData[index + 1]) * 587 / 1000 +
                           Int(pixelData[index + 2]) * 114 / 1000
                total += gray
            }
        }
        let threshold = total / (width * height)

        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                let gray = Int(pixelData[index]) * 299 / 1000 +
                           Int(pixelData[index + 1]) * 587 / 1000 +
                           Int(pixelData[index + 2]) * 114 / 1000
                result[y * width + x] = gray < threshold
            }
        }

        return result
    }

    // MARK: - Connected Component Analysis

    /// Finds connected components in a binary mask.
    ///
    /// - Parameters:
    ///   - mask: Binary mask
    ///   - width: Image width
    ///   - height: Image height
    /// - Returns: Array of connected components
    func findConnectedComponents(mask: [Bool], width: Int, height: Int) -> [Component] {
        var visited = [Bool](repeating: false, count: width * height)
        var components: [Component] = []

        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                if mask[index] && !visited[index] {
                    var component = Component(minX: x, maxX: x, minY: y, maxY: y, pixelCount: 0)
                    floodFill(mask: mask, visited: &visited, x: x, y: y,
                              width: width, height: height, component: &component)
                    if component.pixelCount > 0 {
                        components.append(component)
                    }
                }
            }
        }

        return components
    }

    /// Flood fill algorithm to mark connected pixels.
    private func floodFill(mask: [Bool], visited: inout [Bool], x: Int, y: Int,
                           width: Int, height: Int, component: inout Component) {
        var stack = [(x, y)]

        while !stack.isEmpty {
            let (cx, cy) = stack.removeLast()

            guard cx >= 0 && cx < width && cy >= 0 && cy < height else { continue }

            let index = cy * width + cx
            guard mask[index] && !visited[index] else { continue }

            visited[index] = true
            component.pixelCount += 1
            component.minX = min(component.minX, cx)
            component.maxX = max(component.maxX, cx)
            component.minY = min(component.minY, cy)
            component.maxY = max(component.maxY, cy)

            // Add neighbors (4-connected)
            stack.append((cx + 1, cy))
            stack.append((cx - 1, cy))
            stack.append((cx, cy + 1))
            stack.append((cx, cy - 1))
        }
    }

    // MARK: - Morphological Operations

    /// Applies morphological dilation to edge data.
    ///
    /// - Parameters:
    ///   - edges: Edge magnitude data
    ///   - width: Image width
    ///   - height: Image height
    ///   - kernelSize: Size of dilation kernel
    /// - Returns: Dilated edge data
    func morphologicalDilate(edges: [UInt8], width: Int, height: Int, kernelSize: Int) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: width * height)
        let halfKernel = kernelSize / 2

        for y in halfKernel..<(height - halfKernel) {
            for x in halfKernel..<(width - halfKernel) {
                var maxVal: UInt8 = 0

                for ky in -halfKernel...halfKernel {
                    for kx in -halfKernel...halfKernel {
                        let index = (y + ky) * width + (x + kx)
                        maxVal = max(maxVal, edges[index])
                    }
                }

                result[y * width + x] = maxVal
            }
        }

        return result
    }

    // MARK: - Contour Detection

    /// Finds contours in edge data.
    ///
    /// - Parameters:
    ///   - edges: Edge magnitude data
    ///   - width: Image width
    ///   - height: Image height
    /// - Returns: Array of detected contours
    func findContours(edges: [UInt8], width: Int, height: Int) -> [Contour] {
        var contours: [Contour] = []
        var visited = [Bool](repeating: false, count: width * height)
        let threshold: UInt8 = 100

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let index = y * width + x
                if edges[index] > threshold && !visited[index] {
                    var contour = Contour(points: [])
                    traceContour(edges: edges, visited: &visited, x: x, y: y,
                                 width: width, height: height, threshold: threshold,
                                 contour: &contour)
                    if contour.points.count > 10 {
                        contours.append(contour)
                    }
                }
            }
        }

        return contours
    }

    /// Traces a contour starting from a given point.
    private func traceContour(edges: [UInt8], visited: inout [Bool], x: Int, y: Int,
                              width: Int, height: Int, threshold: UInt8,
                              contour: inout Contour) {
        var stack = [(x, y)]

        while !stack.isEmpty {
            let (cx, cy) = stack.removeLast()

            guard cx > 0 && cx < width - 1 && cy > 0 && cy < height - 1 else { continue }

            let index = cy * width + cx
            guard edges[index] > threshold && !visited[index] else { continue }

            visited[index] = true
            contour.points.append((cx, cy))

            // Check 8-connected neighbors
            for dy in -1...1 {
                for dx in -1...1 {
                    if dx != 0 || dy != 0 {
                        stack.append((cx + dx, cy + dy))
                    }
                }
            }
        }
    }

    // MARK: - Quadrilateral Approximation

    /// Approximates a contour to a quadrilateral.
    ///
    /// - Parameter contour: The input contour
    /// - Returns: A quadrilateral if the contour can be approximated, nil otherwise
    func approximateToQuadrilateral(contour: Contour) -> Quadrilateral? {
        guard contour.points.count >= 4 else { return nil }

        // Find bounding box
        let minX = contour.points.map { $0.x }.min()!
        let maxX = contour.points.map { $0.x }.max()!
        let minY = contour.points.map { $0.y }.min()!
        let maxY = contour.points.map { $0.y }.max()!

        let width = maxX - minX
        let height = maxY - minY

        guard width > 10 && height > 10 else { return nil }

        // Find corner points as points closest to each corner of bounding box
        var topLeft = contour.points[0]
        var topRight = contour.points[0]
        var bottomLeft = contour.points[0]
        var bottomRight = contour.points[0]

        var minDistTL = Int.max
        var minDistTR = Int.max
        var minDistBL = Int.max
        var minDistBR = Int.max

        for point in contour.points {
            let distTL = (point.x - minX) * (point.x - minX) + (point.y - minY) * (point.y - minY)
            let distTR = (point.x - maxX) * (point.x - maxX) + (point.y - minY) * (point.y - minY)
            let distBL = (point.x - minX) * (point.x - minX) + (point.y - maxY) * (point.y - maxY)
            let distBR = (point.x - maxX) * (point.x - maxX) + (point.y - maxY) * (point.y - maxY)

            if distTL < minDistTL { minDistTL = distTL; topLeft = point }
            if distTR < minDistTR { minDistTR = distTR; topRight = point }
            if distBL < minDistBL { minDistBL = distBL; bottomLeft = point }
            if distBR < minDistBR { minDistBR = distBR; bottomRight = point }
        }

        return Quadrilateral(
            topLeft: CGPoint(x: CGFloat(topLeft.x), y: CGFloat(topLeft.y)),
            topRight: CGPoint(x: CGFloat(topRight.x), y: CGFloat(topRight.y)),
            bottomLeft: CGPoint(x: CGFloat(bottomLeft.x), y: CGFloat(bottomLeft.y)),
            bottomRight: CGPoint(x: CGFloat(bottomRight.x), y: CGFloat(bottomRight.y))
        )
    }

    // MARK: - Color Space Conversion

    /// Converts RGB values to YCbCr color space.
    ///
    /// - Parameters:
    ///   - r: Red component (0-255)
    ///   - g: Green component (0-255)
    ///   - b: Blue component (0-255)
    /// - Returns: Tuple of (Y, Cb, Cr) values
    func rgbToYCbCr(r: Float, g: Float, b: Float) -> (y: Float, cb: Float, cr: Float) {
        let y = 0.299 * r + 0.587 * g + 0.114 * b
        let cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b
        let cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b
        return (y, cb, cr)
    }

    /// Checks if YCbCr values correspond to skin color.
    ///
    /// - Parameters:
    ///   - y: Y component
    ///   - cb: Cb component
    ///   - cr: Cr component
    /// - Returns: True if the color is likely skin-colored
    func isSkinColor(y: Float, cb: Float, cr: Float) -> Bool {
        return y > 80 && cb > 85 && cb < 135 && cr > 135 && cr < 180
    }

    /// Converts RGB pixel to grayscale.
    ///
    /// - Parameters:
    ///   - r: Red component (0-255)
    ///   - g: Green component (0-255)
    ///   - b: Blue component (0-255)
    /// - Returns: Grayscale value (0-255)
    func toGrayscale(r: Int, g: Int, b: Int) -> Int {
        return r * 299 / 1000 + g * 587 / 1000 + b * 114 / 1000
    }
}
