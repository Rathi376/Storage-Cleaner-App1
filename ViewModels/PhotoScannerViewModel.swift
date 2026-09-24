import SwiftUI
import Photos

/// ViewModel for the Similar Photos screen.
/// Manages photo groups, selection, and review payload creation.
@MainActor
@Observable
final class PhotoScannerViewModel {

    var result: PhotoScanResult
    var thumbnailCache: [String: UIImage] = [:]
    var isLoadingThumbnails = false

    init(result: PhotoScanResult) {
        self.result = result
    }

    var totalSelectedCount: Int { result.totalSelectedCount }
    var totalSelectedBytes: Int64 { result.totalSelectedBytes }

    var formattedSelectedSize: String {
        ByteFormatter.string(from: totalSelectedBytes)
    }

    // MARK: - Selection

    func toggleSelection(groupId: String, itemId: String) {
        guard let gi = result.groups.firstIndex(where: { $0.id == groupId }),
              let ii = result.groups[gi].items.firstIndex(where: { $0.id == itemId }) else { return }

        // Never allow selecting the recommended item
        guard !result.groups[gi].items[ii].isRecommended else { return }
        result.groups[gi].items[ii].isSelected.toggle()
    }

    func selectAllInGroup(groupId: String) {
        guard let gi = result.groups.firstIndex(where: { $0.id == groupId }) else { return }
        for i in result.groups[gi].items.indices {
            if !result.groups[gi].items[i].isRecommended {
                result.groups[gi].items[i].isSelected = true
            }
        }
    }

    func deselectAllInGroup(groupId: String) {
        guard let gi = result.groups.firstIndex(where: { $0.id == groupId }) else { return }
        for i in result.groups[gi].items.indices {
            result.groups[gi].items[i].isSelected = false
        }
    }

    // MARK: - Thumbnails

    func loadThumbnails(for group: PhotoGroup) {
        Task {
            for item in group.items {
                guard thumbnailCache[item.id] == nil else { continue }
                let asset = PHAsset.fetchAssets(withLocalIdentifiers: [item.id], options: nil).firstObject
                guard let asset else { continue }
                if let image = await PhotoLibraryService.shared.loadThumbnail(for: asset) {
                    thumbnailCache[item.id] = image
                }
            }
        }
    }

    // MARK: - Review

    func buildReviewPayload() -> ReviewPayload {
        ReviewPayload(
            photoIdentifiers: result.selectedAssetIdentifiers,
            screenshotIdentifiers: [],
            videoIdentifiers: [],
            contactIdentifiers: [],
            estimatedPhotoBytes: totalSelectedBytes,
            estimatedScreenshotBytes: 0,
            estimatedVideoBytes: 0
        )
    }
}
