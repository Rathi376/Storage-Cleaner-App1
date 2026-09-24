import SwiftUI
import Photos

/// ViewModel for the Large Videos screen.
@MainActor
@Observable
final class LargeVideoViewModel {

    var items: [VideoItem]
    var thumbnailCache: [String: UIImage] = [:]

    init(items: [VideoItem]) {
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

    func loadThumbnail(for item: VideoItem) {
        guard thumbnailCache[item.id] == nil else { return }
        Task {
            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [item.id], options: nil).firstObject
            guard let asset else { return }
            if let image = await PhotoLibraryService.shared.loadThumbnail(for: asset, targetSize: CGSize(width: 300, height: 200)) {
                thumbnailCache[item.id] = image
            }
        }
    }

    // MARK: - Review

    func buildReviewPayload() -> ReviewPayload {
        let selectedIds = items.filter(\.isSelected).map(\.id)
        return ReviewPayload(
            photoIdentifiers: [],
            screenshotIdentifiers: [],
            videoIdentifiers: selectedIds,
            contactIdentifiers: [],
            estimatedPhotoBytes: 0,
            estimatedScreenshotBytes: 0,
            estimatedVideoBytes: selectedBytes
        )
    }
}
