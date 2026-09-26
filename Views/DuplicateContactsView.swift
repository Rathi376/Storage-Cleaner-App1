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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.result.groups) { group in
                                contactGroupCard(group)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 90)
                    }

                    // Floating Glass Bottom Bar
                    if viewModel.totalSelectedCount > 0 {
                        floatingBottomBar
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
                        CSTheme.hapticImpact(.light)
                        showReview = true
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CSTheme.accentGreen)
                }
            }
        }
        .navigationDestination(isPresented: $showReview) {
            ReviewView(viewModel: ReviewViewModel(payload: viewModel.buildReviewPayload()))
        }
        .alert("Merge Error", isPresented: $showMergeError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(mergeErrorMessage ?? "An error occurred while merging contacts.")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("\(viewModel.result.totalGroups) duplicate groups found")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CSTheme.textSecondary)

            Spacer()

            if viewModel.totalSelectedCount > 0 {
                Text("\(viewModel.totalSelectedCount) copies selected")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(CSTheme.accentGreen)
            }
        }
    }

    // MARK: - Floating Bottom Bar

    private var floatingBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(CSTheme.cardBorder)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.totalSelectedCount) duplicate contacts")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text("Ready for safe cleanup")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CSTheme.accentGreen)
                }

                Spacer()

                Button {
                    CSTheme.hapticImpact(.medium)
                    showReview = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text("Review")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(CSTheme.deleteGradient)
                    .clipShape(Capsule())
                    .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(CSBounceButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Group Card

    private func contactGroupCard(_ group: DuplicateContactGroup) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Group Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.contacts.first?.fullName ?? "Contact")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)

                    Text(group.matchReason)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CSTheme.accentBlue)
                }

                Spacer()

                // Merge Button
                Button {
                    CSTheme.hapticImpact(.medium)
                    mergeGroup(group.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.merge")
                            .font(.system(size: 11, weight: .bold))
                        Text("Merge")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(CSTheme.accentBlue)
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
                CSTheme.hapticImpact(.light)
                viewModel.toggleSelection(groupId: groupId, contactId: contact.id)
            }
        } label: {
            HStack(spacing: 12) {
                // Initials Circle
                ZStack {
                    Circle()
                        .fill(isPrimary ? CSTheme.accentGreen.opacity(0.18) : CSTheme.surfaceLight)
                        .frame(width: 38, height: 38)

                    Text(contact.initials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isPrimary ? CSTheme.accentGreen : CSTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(contact.fullName.isEmpty ? "No Name" : contact.fullName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(CSTheme.textPrimary)

                        if isPrimary {
                            Text("Keep")
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
                            .font(.system(size: 12))
                            .foregroundStyle(CSTheme.textSecondary)
                    } else if let email = contact.emailAddresses.first {
                        Text(email)
                            .font(.system(size: 12))
                            .foregroundStyle(CSTheme.textSecondary)
                    }
                }

                Spacer()

                if !isPrimary {
                    Image(systemName: contact.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(contact.isSelected ? CSTheme.accentGreen : CSTheme.textTertiary)
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
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CSTheme.accentGreen.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 38))
                    .foregroundStyle(CSTheme.accentGreen)
            }

            VStack(spacing: 6) {
                Text("No Duplicate Contacts")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)

                Text("Your contacts list is well-organized with no duplicate entries.")
                    .font(.system(size: 14))
                    .foregroundStyle(CSTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
