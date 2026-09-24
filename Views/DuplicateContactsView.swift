import SwiftUI

/// Screen displaying duplicate contact groups with options to merge or remove copies.
struct DuplicateContactsView: View {
    @State var viewModel: DuplicateContactsViewModel
    @State private var showReview = false
    @State private var mergingGroupId: String?
    @State private var mergeErrorMessage: String?
    @State private var showMergeError = false

    var body: some View {
        Group {
            if viewModel.result.groups.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Top summary bar
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)

                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.result.groups) { group in
                                contactGroupCard(group)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }

                    // Bottom bar for deleting selected duplicates
                    if viewModel.totalSelectedCount > 0 {
                        bottomBar
                    }
                }
            }
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle("Duplicate Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.totalSelectedCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Review") {
                        showReview = true
                    }
                    .foregroundStyle(CSTheme.accentPink)
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationDestination(isPresented: $showReview) {
            ReviewView(viewModel: ReviewViewModel(payload: viewModel.buildReviewPayload()))
        }
        .alert("Merge Error", isPresented: $showMergeError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(mergeErrorMessage ?? "An unknown error occurred while merging.")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("\(viewModel.result.totalGroups) duplicate groups found")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CSTheme.textSecondary)

            Spacer()

            if viewModel.totalSelectedCount > 0 {
                Text("\(viewModel.totalSelectedCount) selected")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CSTheme.accentPink)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(CSTheme.cardBorder)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.totalSelectedCount) duplicate contacts")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text("Ready for safe removal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CSTheme.accentPink)
                }

                Spacer()

                Button {
                    showReview = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Review")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(CSTheme.deleteGradient)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(CSTheme.cardBackground)
        }
    }

    // MARK: - Group Card

    private func contactGroupCard(_ group: DuplicateContactGroup) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Group Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.contacts.first?.fullName ?? "Unknown Contact")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)

                    Text(group.matchReason)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CSTheme.accentPink)
                }

                Spacer()

                // Merge Button
                Button {
                    mergeGroup(group.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.merge")
                        Text("Merge")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(CSTheme.scanButtonGradient)
                    .clipShape(Capsule())
                }
            }

            Divider()
                .overlay(CSTheme.cardBorder)

            // Contact items in group
            VStack(spacing: 8) {
                ForEach(Array(group.contacts.enumerated()), id: \.element.id) { index, contact in
                    contactRow(contact: contact, groupId: group.id, isPrimary: index == 0)
                }
            }
        }
        .csCard()
    }

    // MARK: - Contact Row

    private func contactRow(contact: ContactItem, groupId: String, isPrimary: Bool) -> some View {
        Button {
            if !isPrimary {
                viewModel.toggleSelection(groupId: groupId, contactId: contact.id)
            }
        } label: {
            HStack(spacing: 12) {
                // Initials Circle
                ZStack {
                    Circle()
                        .fill(isPrimary ? CSTheme.accentGreen.opacity(0.2) : CSTheme.surfaceLight)
                        .frame(width: 40, height: 40)

                    Text(contact.initials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isPrimary ? CSTheme.accentGreen : CSTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(contact.fullName.isEmpty ? "No Name" : contact.fullName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(CSTheme.textPrimary)

                        if isPrimary {
                            Text("Primary")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(CSTheme.accentGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(CSTheme.accentGreen.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    if let phone = contact.phoneNumbers.first {
                        Text(phone)
                            .font(.system(size: 13))
                            .foregroundStyle(CSTheme.textSecondary)
                    } else if let email = contact.emailAddresses.first {
                        Text(email)
                            .font(.system(size: 13))
                            .foregroundStyle(CSTheme.textSecondary)
                    }
                }

                Spacer()

                if !isPrimary {
                    Image(systemName: contact.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(contact.isSelected ? CSTheme.accentPink : CSTheme.textTertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func mergeGroup(_ groupId: String) {
        Task {
            do {
                try await viewModel.mergeGroup(groupId)
            } catch {
                mergeErrorMessage = error.localizedDescription
                showMergeError = true
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 50))
                .foregroundStyle(CSTheme.accentGreen)

            Text("No Duplicate Contacts")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(CSTheme.textPrimary)

            Text("Your address book is clean and has no duplicate entries.")
                .font(.system(size: 15))
                .foregroundStyle(CSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
