import SwiftUI
import Photos

/// ViewModel for the Blurry Photos screen.
@MainActor
@Observable
final class BlurryPhotosViewModel {

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

    func loadThumbnails(startIndex: Int, count: Int = 20) {
        let endIndex = min(startIndex + count, items.count)
        guard startIndex < endIndex else { return }

        let slice = items[startIndex..<endIndex]
        for item in slice where thumbnailCache[item.id] == nil {
            Task {
                let asset = PHAsset.fetchAssets(withLocalIdentifiers: [item.id], options: nil).firstObject
                guard let asset else { return }
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
            photoIdentifiers: selectedIds,
            screenshotIdentifiers: [],
            videoIdentifiers: [],
            contactIdentifiers: [],
            estimatedPhotoBytes: selectedBytes,
            estimatedScreenshotBytes: 0,
            estimatedVideoBytes: 0
        )
    }
}
