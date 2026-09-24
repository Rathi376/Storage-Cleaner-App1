import SwiftUI
import Photos

/// ViewModel for the Screenshots screen.
@MainActor
@Observable
final class ScreenshotViewModel {

    var items: [PhotoItem]
    var thumbnailCache: [String: UIImage] = [:]

    init(items: [PhotoItem]) {
        self.items = items
    }

    var selectedCount: Int { items.filter(\.isSelected).count }

    var selectedBytes: Int64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.estimatedBytes }
    }

    var formattedSelectedSize: String {
        ByteFormatter.string(from: selectedBytes)
    }

    var totalBytes: Int64 {
        items.reduce(0) { $0 + $1.estimatedBytes }
    }

    // MARK: - Selection

    func toggleSelection(_ id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isSelected.toggle()
    }

    func selectAll() {
        for i in items.indices { items[i].isSelected = true }
    }

    func deselectAll() {
        for i in items.indices { items[i].isSelected = false }
    }

    // MARK: - Thumbnails

    func loadThumbnails(startIndex: Int = 0, count: Int = 50) {
        let end = min(startIndex + count, items.count)
        guard startIndex < end else { return }

        Task {
            for i in startIndex..<end {
                let item = items[i]
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
        let selectedIds = items.filter(\.isSelected).map(\.id)
        return ReviewPayload(
            photoIdentifiers: [],
            screenshotIdentifiers: selectedIds,
            videoIdentifiers: [],
            contactIdentifiers: [],
            estimatedPhotoBytes: 0,
            estimatedScreenshotBytes: selectedBytes,
            estimatedVideoBytes: 0
        )
    }
}
