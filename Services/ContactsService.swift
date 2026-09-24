import Contacts
import Foundation

/// Scans and manages contacts for duplicates.
/// All processing is entirely on-device in a background actor. Contacts never leave the device.
actor ContactsService {

    static let shared = ContactsService()

    private init() {}

    // MARK: - Authorization

    nonisolated var authorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    nonisolated var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    func requestAuthorization() async -> Bool {
        let store = CNContactStore()
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            return false
        }
    }

    // MARK: - Fetching

    /// Scans all contacts and computes duplicate groups off the main thread.
    func scanForDuplicates() throws -> ContactScanResult {
        let contacts = try fetchAllContacts()
        return findDuplicates(contacts: contacts)
    }

    /// Fetch all contacts with name, phone, and email.
    func fetchAllContacts() throws -> [CNContact] {
        let store = CNContactStore()
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
        ]

        var contacts: [CNContact] = []
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        try store.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        return contacts
    }

    // MARK: - Duplicate Detection

    /// Find duplicate contact groups.
    /// Duplicates are identified by matching on BOTH name AND at least one phone/email.
    func findDuplicates(contacts: [CNContact]) -> ContactScanResult {
        var groups: [DuplicateContactGroup] = []
        var processed = Set<String>()

        for (i, contact) in contacts.enumerated() {
            guard !processed.contains(contact.identifier) else { continue }

            let normalizedName = normalizeName(contact)
            guard !normalizedName.isEmpty else { continue }

            let phones = normalizePhones(contact)
            let emails = normalizeEmails(contact)

            var duplicates: [CNContact] = []

            for j in (i + 1)..<contacts.count {
                let other = contacts[j]
                guard !processed.contains(other.identifier) else { continue }

                let otherName = normalizeName(other)
                let otherPhones = normalizePhones(other)
                let otherEmails = normalizeEmails(other)

                // Must match name AND at least one phone or email
                var matchReason: String?

                if normalizedName == otherName && !normalizedName.isEmpty {
                    if !phones.isEmpty && !phones.isDisjoint(with: otherPhones) {
                        matchReason = "Same name & phone number"
                    } else if !emails.isEmpty && !emails.isDisjoint(with: otherEmails) {
                        matchReason = "Same name & email address"
                    } else if phones.isEmpty && otherPhones.isEmpty &&
                              emails.isEmpty && otherEmails.isEmpty {
                        // Both have same name with no phone/email to differentiate
                        matchReason = "Same name (no contact details)"
                    }
                }

                if matchReason != nil {
                    duplicates.append(other)
                }
            }

            if !duplicates.isEmpty {
                let allContacts = [contact] + duplicates
                let reason = determineBestMatchReason(contact, duplicates.first!)

                let contactItems = allContacts.enumerated().map { index, c in
                    ContactItem(
                        id: c.identifier,
                        givenName: c.givenName,
                        familyName: c.familyName,
                        phoneNumbers: c.phoneNumbers.map { $0.value.stringValue },
                        emailAddresses: c.emailAddresses.map { $0.value as String },
                        isSelected: index > 0 // Select non-first duplicates by default
                    )
                }

                groups.append(DuplicateContactGroup(
                    id: "contact_group_\(groups.count)",
                    matchReason: reason,
                    contacts: contactItems
                ))

                for c in allContacts {
                    processed.insert(c.identifier)
                }
            }
        }

        return ContactScanResult(groups: groups)
    }

    // MARK: - Deletion

    /// Delete contacts by their identifiers. Must be called after user confirmation.
    func deleteContacts(identifiers: [String]) throws {
        let store = CNContactStore()
        let keysToFetch: [CNKeyDescriptor] = [CNContactIdentifierKey as CNKeyDescriptor]

        let saveRequest = CNSaveRequest()

        for identifier in identifiers {
            do {
                let contacts = try store.unifiedContacts(matching: CNContact.predicateForContacts(withIdentifiers: [identifier]), keysToFetch: keysToFetch)
                for contact in contacts {
                    let mutable = contact.mutableCopy() as! CNMutableContact
                    saveRequest.delete(mutable)
                }
            } catch {
                continue
            }
        }

        try store.execute(saveRequest)
    }

    /// Merge contacts: keep the primary, combine phone/email from others, delete others.
    func mergeContacts(primaryIdentifier: String, secondaryIdentifiers: [String]) throws {
        let store = CNContactStore()
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
        ]

        // Fetch primary contact
        guard let primary = try store.unifiedContacts(
            matching: CNContact.predicateForContacts(withIdentifiers: [primaryIdentifier]),
            keysToFetch: keysToFetch
        ).first else { return }

        let mutablePrimary = primary.mutableCopy() as! CNMutableContact
        var existingPhones = Set(primary.phoneNumbers.map { $0.value.stringValue })
        var existingEmails = Set(primary.emailAddresses.map { $0.value as String })

        let saveRequest = CNSaveRequest()

        // Gather unique info from secondaries and delete them
        for id in secondaryIdentifiers {
            let secondaries = try store.unifiedContacts(
                matching: CNContact.predicateForContacts(withIdentifiers: [id]),
                keysToFetch: keysToFetch
            )
            for secondary in secondaries {
                // Add unique phone numbers
                for phone in secondary.phoneNumbers {
                    let value = phone.value.stringValue
                    if !existingPhones.contains(value) {
                        mutablePrimary.phoneNumbers.append(phone)
                        existingPhones.insert(value)
                    }
                }
                // Add unique emails
                for email in secondary.emailAddresses {
                    let value = email.value as String
                    if !existingEmails.contains(value) {
                        mutablePrimary.emailAddresses.append(email)
                        existingEmails.insert(value)
                    }
                }
                let mutableSecondary = secondary.mutableCopy() as! CNMutableContact
                saveRequest.delete(mutableSecondary)
            }
        }

        saveRequest.update(mutablePrimary)
        try store.execute(saveRequest)
    }

    // MARK: - Normalization Helpers

    private func normalizeName(_ contact: CNContact) -> String {
        let name = "\(contact.givenName) \(contact.familyName)"
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return name
    }

    private func normalizePhones(_ contact: CNContact) -> Set<String> {
        Set(contact.phoneNumbers.map { phone in
            phone.value.stringValue
                .replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                .suffix(10)
                .description
        }.filter { !$0.isEmpty })
    }

    private func normalizeEmails(_ contact: CNContact) -> Set<String> {
        Set(contact.emailAddresses.map { ($0.value as String).lowercased().trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty })
    }

    private func determineBestMatchReason(_ a: CNContact, _ b: CNContact) -> String {
        let phonesA = normalizePhones(a)
        let phonesB = normalizePhones(b)
        if !phonesA.isEmpty && !phonesA.isDisjoint(with: phonesB) {
            return "Same name & phone number"
        }
        let emailsA = normalizeEmails(a)
        let emailsB = normalizeEmails(b)
        if !emailsA.isEmpty && !emailsA.isDisjoint(with: emailsB) {
            return "Same name & email address"
        }
        return "Same name"
    }
}
