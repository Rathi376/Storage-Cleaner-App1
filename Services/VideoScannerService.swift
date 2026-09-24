import Photos
import Foundation

/// Scans the photo library for screenshots and large videos.
/// All processing is on-device.
actor VideoScannerService {

    static let shared = VideoScannerService()

    private init() {}

    /// Scan for screenshots and return PhotoItems.
    func scanScreenshots(
        assets: [PHAsset],
        onProgress: @Sendable @MainActor (ScanProgress) -> Void
    ) async -> [PhotoItem] {
        let total = assets.count
        var items: [PhotoItem] = []
        items.reserveCapacity(total)

        let service = PhotoLibraryService.shared

        for (index, asset) in assets.enumerated() {
            if index % 100 == 0 {
                await onProgress(ScanProgress(
                    currentStep: "Scanning screenshots…",
                    processedCount: index,
                    totalCount: total,
                    isComplete: false
                ))
            }

            let estimatedBytes = service.estimateFileSize(for: asset)

            items.append(PhotoItem(
                id: asset.localIdentifier,
                creationDate: asset.creationDate,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                estimatedBytes: estimatedBytes,
                isSelected: false,
                isRecommended: false,
                qualityScore: 0
            ))
        }

        await onProgress(ScanProgress(
            currentStep: "Complete",
            processedCount: total,
            totalCount: total,
            isComplete: true
        ))

        return items
    }

    /// Scan for large videos and return VideoItems sorted by size descending.
    func scanLargeVideos(
        assets: [PHAsset],
        onProgress: @Sendable @MainActor (ScanProgress) -> Void
    ) async -> [VideoItem] {
        let total = assets.count
        var items: [VideoItem] = []
        items.reserveCapacity(total)

        let service = PhotoLibraryService.shared

        for (index, asset) in assets.enumerated() {
            if index % 50 == 0 {
                await onProgress(ScanProgress(
                    currentStep: "Scanning videos…",
                    processedCount: index,
                    totalCount: total,
                    isComplete: false
                ))
            }

            let estimatedBytes = service.estimateVideoFileSize(for: asset)

            items.append(VideoItem(
                id: asset.localIdentifier,
                creationDate: asset.creationDate,
                duration: asset.duration,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                estimatedBytes: estimatedBytes,
                isSelected: false
            ))
        }

        // Sort by size descending
        items.sort { $0.estimatedBytes > $1.estimatedBytes }

        await onProgress(ScanProgress(
            currentStep: "Complete",
            processedCount: total,
            totalCount: total,
            isComplete: true
        ))

        return items
    }
}
