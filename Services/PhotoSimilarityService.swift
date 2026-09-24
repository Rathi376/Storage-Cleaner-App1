import Photos
import UIKit
import CoreImage

/// Performs on-device photo similarity analysis.
///
/// Strategy:
/// 1. Generate small thumbnail for each photo (32×32 grayscale).
/// 2. Create a perceptual hash (average hash) from the thumbnail.
/// 3. Group photos by hash similarity using Hamming distance.
/// 4. Within each group, score photos by resolution, size, and estimated quality.
/// 5. Mark the highest-scoring photo as "recommended."
///
/// This approach is lightweight, runs entirely on-device, and avoids loading
/// full-resolution images, keeping memory usage low.
actor PhotoSimilarityService {

    static let shared = PhotoSimilarityService()

    private let imageManager = PHCachingImageManager()
    private let ciContext = CIContext()

    /// Hamming distance threshold for considering two photos as "similar."
    /// Lower = stricter matching. 5 out of 64 bits ≈ 92% similarity.
    private let similarityThreshold = 5

    private init() {
        imageManager.allowsCachingHighQualityImages = false
    }

    // MARK: - Public API

    /// Scan all photos for similar groups.
    /// Reports progress via the callback.
    func findSimilarPhotos(
        assets: [PHAsset],
        onProgress: @Sendable @MainActor (ScanProgress) -> Void
    ) async -> PhotoScanResult {

        let total = assets.count
        guard total > 0 else { return .empty }

        // Step 1: Compute hashes
        var hashes: [(PHAsset, UInt64)] = []
        hashes.reserveCapacity(total)

        for (index, asset) in assets.enumerated() {
            if index % 50 == 0 {
                let progress = ScanProgress(
                    currentStep: "Analyzing photos…",
                    processedCount: index,
                    totalCount: total,
                    isComplete: false
                )
                await onProgress(progress)
            }

            if let hash = await computeAverageHash(for: asset) {
                hashes.append((asset, hash))
            }
        }

        // Step 2: Group by similarity
        await onProgress(ScanProgress(
            currentStep: "Finding similar photos…",
            processedCount: total,
            totalCount: total,
            isComplete: false
        ))

        let groups = groupBySimilarity(hashes: hashes)

        // Step 3: Score and build result
        var photoGroups: [PhotoGroup] = []
        let service = PhotoLibraryService.shared

        for (groupIndex, group) in groups.enumerated() {
            var items: [PhotoItem] = []

            for asset in group {
                let estimatedBytes = service.estimateFileSize(for: asset)
                let score = calculateQualityScore(for: asset, estimatedBytes: estimatedBytes)

                items.append(PhotoItem(
                    id: asset.localIdentifier,
                    creationDate: asset.creationDate,
                    pixelWidth: asset.pixelWidth,
                    pixelHeight: asset.pixelHeight,
                    estimatedBytes: estimatedBytes,
                    isSelected: false,
                    isRecommended: false,
                    qualityScore: score
                ))
            }

            // Sort by quality score descending
            items.sort { $0.qualityScore > $1.qualityScore }

            // Mark the best as recommended (never pre-selected for deletion)
            if !items.isEmpty {
                items[0].isRecommended = true
                // Pre-select non-recommended for user convenience, user can override
                for i in 1..<items.count {
                    items[i].isSelected = true
                }
            }

            photoGroups.append(PhotoGroup(
                id: "group_\(groupIndex)",
                items: items
            ))
        }

        await onProgress(ScanProgress(
            currentStep: "Complete",
            processedCount: total,
            totalCount: total,
            isComplete: true
        ))

        return PhotoScanResult(groups: photoGroups)
    }

    // MARK: - Perceptual Hashing

    /// Compute an average hash for a photo asset.
    /// Loads a tiny 8×8 thumbnail, converts to grayscale, and computes a 64-bit hash.
    private func computeAverageHash(for asset: PHAsset) async -> UInt64? {
        guard let image = await loadSmallThumbnail(for: asset, size: CGSize(width: 8, height: 8)) else {
            return nil
        }

        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)

        // Convert to grayscale
        guard let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = grayscaleFilter.outputImage else { return nil }
        guard let grayCG = ciContext.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        // Get pixel data
        let width = grayCG.width
        let height = grayCG.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: &pixelData,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }

        context.draw(grayCG, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Compute average brightness
        var totalBrightness: UInt64 = 0
        let pixelCount = width * height
        for i in 0..<pixelCount {
            let offset = i * bytesPerPixel
            let r = UInt64(pixelData[offset])
            let g = UInt64(pixelData[offset + 1])
            let b = UInt64(pixelData[offset + 2])
            totalBrightness += (r + g + b) / 3
        }
        let average = totalBrightness / UInt64(pixelCount)

        // Build hash
        var hash: UInt64 = 0
        for i in 0..<min(64, pixelCount) {
            let offset = i * bytesPerPixel
            let r = UInt64(pixelData[offset])
            let g = UInt64(pixelData[offset + 1])
            let b = UInt64(pixelData[offset + 2])
            let brightness = (r + g + b) / 3
            if brightness >= average {
                hash |= (1 << i)
            }
        }

        return hash
    }

    /// Hamming distance between two 64-bit hashes.
    private func hammingDistance(_ a: UInt64, _ b: UInt64) -> Int {
        (a ^ b).nonzeroBitCount
    }

    /// Group assets by perceptual hash similarity using union-find.
    private func groupBySimilarity(hashes: [(PHAsset, UInt64)]) -> [[PHAsset]] {
        let count = hashes.count
        var parent = Array(0..<count)

        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x {
                parent[x] = parent[parent[x]] // path compression
                x = parent[x]
            }
            return x
        }

        func union(_ a: Int, _ b: Int) {
            let ra = find(a)
            let rb = find(b)
            if ra != rb { parent[ra] = rb }
        }

        // Compare hashes pairwise
        for i in 0..<count {
            for j in (i + 1)..<count {
                if hammingDistance(hashes[i].1, hashes[j].1) <= similarityThreshold {
                    union(i, j)
                }
            }
        }

        // Collect groups
        var groups: [Int: [PHAsset]] = [:]
        for i in 0..<count {
            let root = find(i)
            groups[root, default: []].append(hashes[i].0)
        }

        // Only return groups with 2+ similar photos
        return groups.values.filter { $0.count >= 2 }
    }

    // MARK: - Quality Scoring

    /// Calculate a quality score for a photo.
    /// Factors: resolution, file size, dimensions balance.
    /// Score is 0–100. Higher is better.
    private func calculateQualityScore(for asset: PHAsset, estimatedBytes: Int64) -> Double {
        var score: Double = 0

        // Resolution score (up to 40 points)
        // 12MP = 40 points, scales linearly
        let megapixels = Double(asset.pixelWidth * asset.pixelHeight) / 1_000_000.0
        score += min(megapixels / 12.0 * 40.0, 40.0)

        // File size score (up to 30 points)
        // Larger file generally means more detail/less compression
        let megabytes = Double(estimatedBytes) / 1_000_000.0
        score += min(megabytes / 5.0 * 30.0, 30.0)

        // Aspect ratio score (up to 15 points)
        // Prefer standard aspect ratios (close to 4:3 or 16:9)
        let aspectRatio = Double(max(asset.pixelWidth, asset.pixelHeight)) /
                          Double(max(1, min(asset.pixelWidth, asset.pixelHeight)))
        if aspectRatio >= 1.0 && aspectRatio <= 2.0 {
            score += 15.0
        } else {
            score += max(0, 15.0 - (aspectRatio - 2.0) * 5.0)
        }

        // Recency bonus (up to 15 points)
        // More recent photos get a slight preference
        if let date = asset.creationDate {
            let age = -date.timeIntervalSinceNow
            let daysOld = age / 86400
            score += max(0, 15.0 - daysOld / 365.0 * 5.0)
        }

        return min(score, 100.0)
    }

    // MARK: - Helpers

    private func loadSmallThumbnail(for asset: PHAsset, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = false
            options.resizeMode = .exact
            options.isSynchronous = true

            imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
