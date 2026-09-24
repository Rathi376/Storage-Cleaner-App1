import Photos
import Foundation

/// Coordinates the actual deletion of selected assets and contacts.
/// Never deletes automatically — all operations require prior user confirmation.
final class CleanupService: Sendable {

    static let shared = CleanupService()

    private init() {}

    /// Execute cleanup for the given review payload.
    /// Returns a summary of what was freed.
    /// IMPORTANT: This must only be called after the user has explicitly confirmed.
    func performCleanup(payload: ReviewPayload) async throws -> CleanupSummary {
        var summary = CleanupSummary.empty

        // Delete photos
        if !payload.photoIdentifiers.isEmpty {
            try await PhotoLibraryService.shared.deleteAssets(identifiers: payload.photoIdentifiers)
            summary.photosCount = payload.photoIdentifiers.count
            summary.photosFreed = payload.estimatedPhotoBytes
        }

        // Delete screenshots
        if !payload.screenshotIdentifiers.isEmpty {
            try await PhotoLibraryService.shared.deleteAssets(identifiers: payload.screenshotIdentifiers)
            summary.screenshotsCount = payload.screenshotIdentifiers.count
            summary.screenshotsFreed = payload.estimatedScreenshotBytes
        }

        // Delete videos
        if !payload.videoIdentifiers.isEmpty {
            try await PhotoLibraryService.shared.deleteAssets(identifiers: payload.videoIdentifiers)
            summary.videosCount = payload.videoIdentifiers.count
            summary.videosFreed = payload.estimatedVideoBytes
        }

        // Delete contacts
        if !payload.contactIdentifiers.isEmpty {
            try await ContactsService.shared.deleteContacts(identifiers: payload.contactIdentifiers)
            summary.contactsRemoved = payload.contactIdentifiers.count
        }

        summary.currentAvailableBytes = StorageService.shared.getStorageInfo().freeBytes
        return summary
    }
}
