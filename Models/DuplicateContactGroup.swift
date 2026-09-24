import Contacts
import Foundation

/// A single contact entry extracted from the Contacts framework.
struct ContactItem: Identifiable, Sendable {
    let id: String              // CNContact.identifier
    let givenName: String
    let familyName: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
    var isSelected: Bool

    var fullName: String {
        [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var initials: String {
        let g = givenName.first.map(String.init) ?? ""
        let f = familyName.first.map(String.init) ?? ""
        let result = g + f
        return result.isEmpty ? "?" : result
    }
}

/// A group of contacts identified as potential duplicates.
struct DuplicateContactGroup: Identifiable, Sendable {
    let id: String
    let matchReason: String     // e.g. "Same name & phone number"
    var contacts: [ContactItem]

    var selectedCount: Int {
        contacts.filter(\.isSelected).count
    }
}

/// Result of scanning for duplicate contacts.
struct ContactScanResult: Sendable {
    var groups: [DuplicateContactGroup]

    var totalGroups: Int { groups.count }

    var totalDuplicateCount: Int {
        groups.reduce(0) { $0 + $1.contacts.count - 1 }
    }

    var totalSelectedCount: Int {
        groups.reduce(0) { $0 + $1.selectedCount }
    }

    var selectedContactIdentifiers: [String] {
        groups.flatMap { $0.contacts.filter(\.isSelected).map(\.id) }
    }

    static let empty = ContactScanResult(groups: [])
}
