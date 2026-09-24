import SwiftUI

/// ViewModel for the Review screen. Shows what will be deleted and handles cleanup.
@MainActor
@Observable
final class ReviewViewModel {

    var payload: ReviewPayload
    var isDeleting = false
    var deletionError: String?
    var cleanupSummary: CleanupSummary?
    var showConfirmation = false

    init(payload: ReviewPayload) {
        self.payload = payload
    }

    var formattedEstimatedSize: String {
        ByteFormatter.string(from: payload.totalEstimatedBytes)
    }

    // MARK: - Deletion

    /// Request confirmation before deletion.
    func requestDeletion() {
        showConfirmation = true
    }

    /// Execute the cleanup. Only called after explicit user confirmation.
    func confirmAndClean() async {
        isDeleting = true
        deletionError = nil

        do {
            let summary = try await CleanupService.shared.performCleanup(payload: payload)
            cleanupSummary = summary
        } catch {
            deletionError = error.localizedDescription
        }

        isDeleting = false
    }
}
