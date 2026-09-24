import Foundation

/// Summary of a cleanup operation, shown on the Space Freed screen.
struct CleanupSummary: Sendable {
    var photosCount: Int
    var photosFreed: Int64
    var screenshotsCount: Int
    var screenshotsFreed: Int64
    var videosCount: Int
    var videosFreed: Int64
    var contactsRemoved: Int
    var currentAvailableBytes: Int64

    var totalItems: Int {
        photosCount + screenshotsCount + videosCount + contactsRemoved
    }

    var totalFreed: Int64 {
        photosFreed + screenshotsFreed + videosFreed
    }

    var formattedTotal: String {
        ByteFormatter.string(from: totalFreed)
    }

    var formattedAvailable: String {
        ByteFormatter.string(from: currentAvailableBytes)
    }

    static let empty = CleanupSummary(
        photosCount: 0,
        photosFreed: 0,
        screenshotsCount: 0,
        screenshotsFreed: 0,
        videosCount: 0,
        videosFreed: 0,
        contactsRemoved: 0,
        currentAvailableBytes: 0
    )
}

/// Items selected for review before deletion.
struct ReviewPayload: Sendable {
    var photoIdentifiers: [String]
    var screenshotIdentifiers: [String]
    var videoIdentifiers: [String]
    var contactIdentifiers: [String]

    var estimatedPhotoBytes: Int64
    var estimatedScreenshotBytes: Int64
    var estimatedVideoBytes: Int64

    var totalEstimatedBytes: Int64 {
        estimatedPhotoBytes + estimatedScreenshotBytes + estimatedVideoBytes
    }

    var totalItemCount: Int {
        photoIdentifiers.count + screenshotIdentifiers.count +
        videoIdentifiers.count + contactIdentifiers.count
    }

    var isEmpty: Bool { totalItemCount == 0 }

    static let empty = ReviewPayload(
        photoIdentifiers: [],
        screenshotIdentifiers: [],
        videoIdentifiers: [],
        contactIdentifiers: [],
        estimatedPhotoBytes: 0,
        estimatedScreenshotBytes: 0,
        estimatedVideoBytes: 0
    )
}

/// Scan progress tracking.
struct ScanProgress: Sendable {
    var currentStep: String
    var processedCount: Int
    var totalCount: Int
    var isComplete: Bool

    var fraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(processedCount) / Double(totalCount)
    }

    var displayText: String {
        if totalCount > 0 {
            return "\(processedCount.formatted()) / \(totalCount.formatted())"
        }
        return currentStep
    }

    static let idle = ScanProgress(currentStep: "Ready", processedCount: 0, totalCount: 0, isComplete: false)
}
