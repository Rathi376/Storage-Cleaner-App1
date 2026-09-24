import Photos
import UIKit

/// A single photo asset with metadata for display and comparison.
struct PhotoItem: Identifiable, Sendable {
    let id: String              // PHAsset localIdentifier
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let estimatedBytes: Int64
    var isSelected: Bool
    var isRecommended: Bool
    var qualityScore: Double = 0.0

    var resolution: Int { pixelWidth * pixelHeight }

    var formattedSize: String {
        ByteFormatter.string(from: estimatedBytes)
    }

    var formattedDate: String {
        guard let date = creationDate else { return "Unknown" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    var dimensionsString: String {
        "\(pixelWidth) × \(pixelHeight)"
    }
}

/// A group of visually similar photos. The best photo is marked as recommended.
struct PhotoGroup: Identifiable, Sendable {
    let id: String
    var items: [PhotoItem]

    var selectedCount: Int {
        items.filter(\.isSelected).count
    }

    var selectedBytes: Int64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.estimatedBytes }
    }

    var recommendedItem: PhotoItem? {
        items.first(where: \.isRecommended)
    }

    var nonRecommendedItems: [PhotoItem] {
        items.filter { !$0.isRecommended }
    }
}

/// Result of scanning the photo library for duplicates/similar photos.
struct PhotoScanResult: Sendable {
    var groups: [PhotoGroup]

    var totalGroups: Int { groups.count }

    var totalDuplicateCount: Int {
        groups.reduce(0) { $0 + $1.items.count - 1 } // minus the best in each group
    }

    var totalSelectedCount: Int {
        groups.reduce(0) { $0 + $1.selectedCount }
    }

    var totalSelectedBytes: Int64 {
        groups.reduce(0) { $0 + $1.selectedBytes }
    }

    var selectedAssetIdentifiers: [String] {
        groups.flatMap { $0.items.filter(\.isSelected).map(\.id) }
    }

    static let empty = PhotoScanResult(groups: [])
}
