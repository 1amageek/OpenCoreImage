//
//  QRCodeDetectionAlgorithm.swift
//  OpenCoreImage
//
//  QR code detection algorithm using finder pattern matching.
//

import Foundation

/// QR code detection algorithm using finder pattern recognition.
///
/// This algorithm works by:
/// 1. Binarizing the image
/// 2. Scanning for finder patterns (1:1:3:1:1 black-white ratio)
/// 3. Verifying patterns vertically
/// 4. Grouping patterns into valid QR code arrangements
internal struct QRCodeDetectionAlgorithm {

    // MARK: - Types

    /// Represents a QR code finder pattern.
    struct FinderPattern {
        var x: Int
        var y: Int
        var moduleSize: Float
    }

    /// Represents sorted finder patterns for a QR code.
    struct SortedPatterns {
        var topLeft: FinderPattern
        var topRight: FinderPattern
        var bottomLeft: FinderPattern
    }

    // MARK: - Detection

    /// Detects QR codes in the given image.
    ///
    /// - Parameters:
    ///   - image: The source image
    ///   - analyzer: Image analyzer for pixel processing
    ///   - options: Detection options
    ///   - minFeatureSize: Minimum feature size as fraction of image dimension
    ///   - maxFeatureCount: Maximum number of features to return
    /// - Returns: Array of detected QR code features
    static func detect(
        in image: CIImage,
        using analyzer: ImageAnalyzer,
        options: [String: Any]?,
        minFeatureSize: Float,
        maxFeatureCount: Int
    ) -> [CIQRCodeFeature] {
        let extent = image.extent

        guard let pixelData = analyzer.getPixelData(from: image) else {
            return []
        }

        let width = Int(extent.width)
        let height = Int(extent.height)

        // Binarize image
        let binary = analyzer.binarizeImage(pixelData: pixelData, width: width, height: height)

        // Find finder patterns
        let finderPatterns = findFinderPatterns(binary: binary, width: width, height: height)

        // Group patterns into QR codes
        let qrCodes = groupFinderPatternsIntoQRCodes(finderPatterns)

        // Create features
        return createQRCodeFeatures(
            from: qrCodes,
            height: height,
            maxFeatureCount: maxFeatureCount
        )
    }

    // MARK: - Finder Pattern Detection

    /// Scans for finder patterns in the binary image.
    private static func findFinderPatterns(binary: [Bool], width: Int, height: Int) -> [FinderPattern] {
        var patterns: [FinderPattern] = []

        // Scan horizontally for 1:1:3:1:1 pattern
        for y in 0..<height {
            var stateCount = [0, 0, 0, 0, 0]
            var currentState = 0

            for x in 0..<width {
                let pixel = binary[y * width + x]

                if pixel {
                    // Black pixel
                    if currentState == 1 || currentState == 3 {
                        currentState += 1
                    }
                    stateCount[currentState] += 1
                } else {
                    // White pixel
                    if currentState == 0 || currentState == 2 || currentState == 4 {
                        stateCount[currentState] += 1
                    } else {
                        if currentState == 4 {
                            // Check if we have a valid finder pattern
                            if isFinderPattern(stateCount) {
                                let centerX = x - stateCount[4] - stateCount[3] - stateCount[2] / 2
                                let totalWidth = stateCount.reduce(0, +)
                                let moduleSize = Float(totalWidth) / 7.0

                                // Verify vertically
                                if verifyFinderPatternVertically(binary: binary, x: centerX, y: y,
                                                                 width: width, height: height,
                                                                 moduleSize: moduleSize) {
                                    patterns.append(FinderPattern(x: centerX, y: y, moduleSize: moduleSize))
                                }
                            }
                            // Shift state
                            stateCount[0] = stateCount[2]
                            stateCount[1] = stateCount[3]
                            stateCount[2] = stateCount[4]
                            stateCount[3] = 1
                            stateCount[4] = 0
                            currentState = 3
                        } else {
                            currentState += 1
                            stateCount[currentState] += 1
                        }
                    }
                }
            }
        }

        return removeDuplicatePatterns(patterns)
    }

    /// Checks if state counts match the 1:1:3:1:1 finder pattern ratio.
    private static func isFinderPattern(_ stateCount: [Int]) -> Bool {
        let totalWidth = stateCount.reduce(0, +)
        if totalWidth < 7 { return false }

        let moduleSize = Float(totalWidth) / 7.0
        let maxVariance = moduleSize / 2.0

        // Check 1:1:3:1:1 ratio
        let expected: [Float] = [1.0, 1.0, 3.0, 1.0, 1.0]
        for i in 0..<5 {
            let variance = abs(Float(stateCount[i]) - moduleSize * expected[i])
            if variance > maxVariance * expected[i] {
                return false
            }
        }

        return true
    }

    /// Verifies a finder pattern by checking vertically.
    private static func verifyFinderPatternVertically(
        binary: [Bool],
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        moduleSize: Float
    ) -> Bool {
        guard x >= 0 && x < width else { return false }

        var stateCount = [0, 0, 0, 0, 0]
        var currentY = y

        // Count upward
        while currentY >= 0 && binary[currentY * width + x] {
            stateCount[2] += 1
            currentY -= 1
        }
        while currentY >= 0 && !binary[currentY * width + x] {
            stateCount[1] += 1
            currentY -= 1
        }
        while currentY >= 0 && binary[currentY * width + x] {
            stateCount[0] += 1
            currentY -= 1
        }

        // Count downward
        currentY = y + 1
        while currentY < height && binary[currentY * width + x] {
            stateCount[2] += 1
            currentY += 1
        }
        while currentY < height && !binary[currentY * width + x] {
            stateCount[3] += 1
            currentY += 1
        }
        while currentY < height && binary[currentY * width + x] {
            stateCount[4] += 1
            currentY += 1
        }

        return isFinderPattern(stateCount)
    }

    /// Removes duplicate finder patterns that are too close together.
    private static func removeDuplicatePatterns(_ patterns: [FinderPattern]) -> [FinderPattern] {
        var result: [FinderPattern] = []

        for pattern in patterns {
            var isDuplicate = false
            for existing in result {
                let distance = sqrt(pow(Float(pattern.x - existing.x), 2) +
                                    pow(Float(pattern.y - existing.y), 2))
                if distance < pattern.moduleSize * 5 {
                    isDuplicate = true
                    break
                }
            }
            if !isDuplicate {
                result.append(pattern)
            }
        }

        return result
    }

    // MARK: - QR Code Grouping

    /// Groups finder patterns into valid QR code arrangements.
    private static func groupFinderPatternsIntoQRCodes(_ patterns: [FinderPattern]) -> [[FinderPattern]] {
        var groups: [[FinderPattern]] = []

        guard patterns.count >= 3 else { return groups }

        // Try to find groups of 3 patterns that form a right angle
        for i in 0..<patterns.count {
            for j in (i + 1)..<patterns.count {
                for k in (j + 1)..<patterns.count {
                    let p1 = patterns[i]
                    let p2 = patterns[j]
                    let p3 = patterns[k]

                    // Check if they have similar module sizes
                    let avgModuleSize = (p1.moduleSize + p2.moduleSize + p3.moduleSize) / 3
                    let maxVariance = avgModuleSize * 0.5

                    if abs(p1.moduleSize - avgModuleSize) < maxVariance &&
                       abs(p2.moduleSize - avgModuleSize) < maxVariance &&
                       abs(p3.moduleSize - avgModuleSize) < maxVariance {

                        // Check if they form a reasonable QR code shape
                        if isValidQRCodeArrangement([p1, p2, p3]) {
                            groups.append([p1, p2, p3])
                        }
                    }
                }
            }
        }

        return groups
    }

    /// Checks if three patterns form a valid QR code arrangement.
    private static func isValidQRCodeArrangement(_ patterns: [FinderPattern]) -> Bool {
        guard patterns.count == 3 else { return false }

        // Calculate distances between all pairs
        let d01 = distance(patterns[0], patterns[1])
        let d02 = distance(patterns[0], patterns[2])
        let d12 = distance(patterns[1], patterns[2])

        // The longest side should be approximately sqrt(2) times the shorter sides
        let sides = [d01, d02, d12].sorted()

        // Check if it forms roughly a right triangle
        let ratio = sides[2] / sides[0]
        return ratio > 1.2 && ratio < 1.8
    }

    /// Calculates distance between two finder patterns.
    private static func distance(_ p1: FinderPattern, _ p2: FinderPattern) -> Float {
        return sqrt(pow(Float(p1.x - p2.x), 2) + pow(Float(p1.y - p2.y), 2))
    }

    // MARK: - Pattern Sorting

    /// Sorts finder patterns into top-left, top-right, and bottom-left positions.
    private static func sortFinderPatterns(_ patterns: [FinderPattern]) -> SortedPatterns {
        // Find the pattern that forms the right angle (top-left)
        let d01 = distance(patterns[0], patterns[1])
        let d02 = distance(patterns[0], patterns[2])
        let d12 = distance(patterns[1], patterns[2])

        var topLeft: FinderPattern
        var other1: FinderPattern
        var other2: FinderPattern

        if d01 > d02 && d01 > d12 {
            // 0 and 1 are farthest apart, so 2 is top-left
            topLeft = patterns[2]
            other1 = patterns[0]
            other2 = patterns[1]
        } else if d02 > d01 && d02 > d12 {
            // 0 and 2 are farthest apart, so 1 is top-left
            topLeft = patterns[1]
            other1 = patterns[0]
            other2 = patterns[2]
        } else {
            // 1 and 2 are farthest apart, so 0 is top-left
            topLeft = patterns[0]
            other1 = patterns[1]
            other2 = patterns[2]
        }

        // Determine which is top-right and which is bottom-left
        // using cross product
        let v1 = (other1.x - topLeft.x, other1.y - topLeft.y)
        let v2 = (other2.x - topLeft.x, other2.y - topLeft.y)
        let cross = v1.0 * v2.1 - v1.1 * v2.0

        let topRight: FinderPattern
        let bottomLeft: FinderPattern

        if cross > 0 {
            topRight = other2
            bottomLeft = other1
        } else {
            topRight = other1
            bottomLeft = other2
        }

        return SortedPatterns(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft)
    }

    // MARK: - Feature Creation

    /// Creates QR code features from grouped finder patterns.
    private static func createQRCodeFeatures(
        from qrCodes: [[FinderPattern]],
        height: Int,
        maxFeatureCount: Int
    ) -> [CIQRCodeFeature] {
        var features: [CIQRCodeFeature] = []

        for qrCode in qrCodes {
            guard qrCode.count == 3 else { continue }

            // Sort patterns to identify top-left, top-right, bottom-left
            let sorted = sortFinderPatterns(qrCode)

            let topLeft = CGPoint(x: CGFloat(sorted.topLeft.x), y: CGFloat(height - sorted.topLeft.y))
            let topRight = CGPoint(x: CGFloat(sorted.topRight.x), y: CGFloat(height - sorted.topRight.y))
            let bottomLeft = CGPoint(x: CGFloat(sorted.bottomLeft.x), y: CGFloat(height - sorted.bottomLeft.y))

            // Estimate bottom-right
            let bottomRight = CGPoint(
                x: topRight.x + (bottomLeft.x - topLeft.x),
                y: bottomLeft.y + (topRight.y - topLeft.y)
            )

            let minX = min(topLeft.x, bottomLeft.x)
            let maxX = max(topRight.x, bottomRight.x)
            let minY = min(bottomLeft.y, bottomRight.y)
            let maxY = max(topLeft.y, topRight.y)

            let bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

            let qrFeature = CIQRCodeFeature(
                bounds: bounds,
                topLeft: topLeft,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight,
                messageString: nil,  // Decoding requires full QR decoder
                symbolDescriptor: nil
            )
            features.append(qrFeature)

            if features.count >= maxFeatureCount {
                break
            }
        }

        return features
    }
}
