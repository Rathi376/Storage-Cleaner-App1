import UIKit
import Photos

/// Detects potentially blurry photos using explainable variance of the Laplacian on downsampled thumbnails.
final class BlurDetectionService: Sendable {

    static let shared = BlurDetectionService()

    private init() {}

    /// Calculates sharpness score using variance of the Laplacian on a grayscale downsampled bitmap.
    /// Conservative threshold ensures only genuinely low-sharpness images are flagged.
    func evaluateSharpness(image: UIImage, threshold: Double = 18.0) -> (isBlurry: Bool, score: Double) {
        let width = 100
        let height = 100
        guard let cgImage = image.cgImage else { return (false, 100) }

        var pixelData = [UInt8](repeating: 0, count: width * height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return (false, 100)
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 3x3 Discrete Laplacian kernel
        var laplacianValues = [Double]()
        laplacianValues.reserveCapacity((width - 2) * (height - 2))
        var sum: Double = 0

        for y in 1..<(height - 1) {
            let rowAbove = (y - 1) * width
            let rowCurrent = y * width
            let rowBelow = (y + 1) * width

            for x in 1..<(width - 1) {
                let center = Double(pixelData[rowCurrent + x])
                let top = Double(pixelData[rowAbove + x])
                let bottom = Double(pixelData[rowBelow + x])
                let left = Double(pixelData[rowCurrent + x - 1])
                let right = Double(pixelData[rowCurrent + x + 1])

                let laplacian = top + bottom + left + right - (4.0 * center)
                laplacianValues.append(laplacian)
                sum += laplacian
            }
        }

        guard !laplacianValues.isEmpty else { return (false, 100) }

        let mean = sum / Double(laplacianValues.count)
        var varianceSum: Double = 0
        for val in laplacianValues {
            let diff = val - mean
            varianceSum += diff * diff
        }

        let variance = varianceSum / Double(laplacianValues.count)
        return (variance < threshold, variance)
    }

    /// Evaluates assets on a background task and returns photos detected as potentially blurry.
    func scanBlurryPhotos(
        assets: [PHAsset],
        onProgress: (@Sendable @MainActor (ScanProgress) -> Void)? = nil
    ) async -> [PhotoItem] {
        var blurryItems: [PhotoItem] = []
        let total = min(assets.count, 250) // Fast, responsive limit for mobile
        let targetSize = CGSize(width: 150, height: 150)

        for i in 0..<total {
            if i % 15 == 0 {
                if let onProgress {
                    await onProgress(ScanProgress(
                        currentStep: "Analyzing photo sharpness…",
                        processedCount: i,
                        totalCount: total,
                        isComplete: false
                    ))
                }
            }

            let asset = assets[i]
            if let thumbnail = await PhotoLibraryService.shared.loadThumbnail(for: asset, targetSize: targetSize) {
                let (isBlurry, score) = evaluateSharpness(image: thumbnail)
                if isBlurry {
                    let size = PhotoLibraryService.shared.estimateFileSize(for: asset)
                    let item = PhotoItem(
                        id: asset.localIdentifier,
                        creationDate: asset.creationDate,
                        pixelWidth: asset.pixelWidth,
                        pixelHeight: asset.pixelHeight,
                        estimatedBytes: size,
                        isSelected: false, // Never auto-selected for deletion
                        isRecommended: false,
                        qualityScore: score
                    )
                    blurryItems.append(item)
                }
            }
        }

        if let onProgress {
            await onProgress(ScanProgress(
                currentStep: "Sharpness analysis complete",
                processedCount: total,
                totalCount: total,
                isComplete: true
            ))
        }

        return blurryItems
    }
}
