import Photos
import Foundation

/// A video asset with metadata for display and selection.
struct VideoItem: Identifiable, Sendable {
    let id: String              // PHAsset localIdentifier
    let creationDate: Date?
    let duration: TimeInterval
    let pixelWidth: Int
    let pixelHeight: Int
    let estimatedBytes: Int64
    var isSelected: Bool

    var formattedSize: String {
        ByteFormatter.string(from: estimatedBytes)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "0:%02d", seconds)
        }
    }

    var formattedDate: String {
        guard let date = creationDate else { return "Unknown" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
