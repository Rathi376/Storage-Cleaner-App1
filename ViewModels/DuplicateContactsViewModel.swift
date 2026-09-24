import SwiftUI

/// ViewModel for the Duplicate Contacts screen.
@MainActor
@Observable
final class DuplicateContactsViewModel {

    var result: ContactScanResult

    init(result: ContactScanResult) {
        self.result = result
    }

    var totalSelectedCount: Int { result.totalSelectedCount }

    // MARK: - Selection

    func toggleSelection(groupId: String, contactId: String) {
        guard let gi = result.groups.firstIndex(where: { $0.id == groupId }),
              let ci = result.groups[gi].contacts.firstIndex(where: { $0.id == contactId }) else { return }
        result.groups[gi].contacts[ci].isSelected.toggle()
    }

    func selectAllInGroup(groupId: String) {
        guard let gi = result.groups.firstIndex(where: { $0.id == groupId }) else { return }
        // Select all except the first (primary) contact
        for i in result.groups[gi].contacts.indices {
            result.groups[gi].contacts[i].isSelected = i > 0
        }
    }

    func deselectAllInGroup(groupId: String) {
        guard let gi = result.groups.firstIndex(where: { $0.id == groupId }) else { return }
        for i in result.groups[gi].contacts.indices {
            result.groups[gi].contacts[i].isSelected = false
        }
    }

    // MARK: - Review

    func buildReviewPayload() -> ReviewPayload {
        ReviewPayload(
            photoIdentifiers: [],
            screenshotIdentifiers: [],
            videoIdentifiers: [],
            contactIdentifiers: result.selectedContactIdentifiers,
            estimatedPhotoBytes: 0,
            estimatedScreenshotBytes: 0,
            estimatedVideoBytes: 0
        )
    }

    // MARK: - Merge

    func mergeGroup(_ groupId: String) async throws {
        guard let gi = result.groups.firstIndex(where: { $0.id == groupId }) else { return }
        let group = result.groups[gi]

        guard let primary = group.contacts.first else { return }
        let secondaryIds = group.contacts.dropFirst().map(\.id)

        try await ContactsService.shared.mergeContacts(
            primaryIdentifier: primary.id,
            secondaryIdentifiers: secondaryIds
        )

        // Remove the merged group from results
        result.groups.remove(at: gi)
    }
}
