import SwiftUI

/// Review & Confirmation view prior to performing any deletions.
/// Satisfies the strict safety requirement: requires explicit user confirmation.
struct ReviewView: View {
    @State var viewModel: ReviewViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(DashboardViewModel.self) private var dashboardVM: DashboardViewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let summary = viewModel.cleanupSummary {
                    successView(summary: summary)
                } else {
                    reviewContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle(viewModel.cleanupSummary == nil ? "Review Cleanup" : "Space Freed")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isDeleting || viewModel.cleanupSummary != nil)
        .overlay {
            if viewModel.isDeleting {
                deletingOverlay
            }
        }
        .confirmationDialog(
            "Confirm Deletion",
            isPresented: $viewModel.showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(viewModel.payload.totalItemCount) Selected Items", role: .destructive) {
                Task {
                    await viewModel.confirmAndClean()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove \(viewModel.payload.totalItemCount) items to free up approximately \(viewModel.formattedEstimatedSize). Deleted photos and videos can still be restored from Recently Deleted within 30 days.")
        }
        .alert("Cleanup Error", isPresented: Binding(
            get: { viewModel.deletionError != nil },
            set: { if !$0 { viewModel.deletionError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.deletionError ?? "An error occurred during cleanup.")
        }
    }

    // MARK: - Review Content

    private var reviewContent: some View {
        VStack(spacing: 20) {
            // Header Hero Banner
            VStack(spacing: 8) {
                Text(viewModel.formattedEstimatedSize)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(CSTheme.primaryGradient)

                Text("Storage to Reclaim")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CSTheme.textSecondary)

                Text("\(viewModel.payload.totalItemCount) items selected for removal")
                    .font(.system(size: 13))
                    .foregroundStyle(CSTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .csCard()

            // Breakdown Sections
            VStack(alignment: .leading, spacing: 12) {
                Text("Summary Breakdown")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)

                if !viewModel.payload.photoIdentifiers.isEmpty {
                    breakdownRow(
                        icon: "photo.on.rectangle.angled",
                        color: CSTheme.accentPurple,
                        title: "Similar Photos",
                        count: "\(viewModel.payload.photoIdentifiers.count) photos",
                        size: ByteFormatter.string(from: viewModel.payload.estimatedPhotoBytes)
                    )
                }

                if !viewModel.payload.screenshotIdentifiers.isEmpty {
                    breakdownRow(
                        icon: "camera.viewfinder",
                        color: CSTheme.accentCyan,
                        title: "Screenshots",
                        count: "\(viewModel.payload.screenshotIdentifiers.count) screenshots",
                        size: ByteFormatter.string(from: viewModel.payload.estimatedScreenshotBytes)
                    )
                }

                if !viewModel.payload.videoIdentifiers.isEmpty {
                    breakdownRow(
                        icon: "video.fill",
                        color: CSTheme.accentOrange,
                        title: "Large Videos",
                        count: "\(viewModel.payload.videoIdentifiers.count) videos",
                        size: ByteFormatter.string(from: viewModel.payload.estimatedVideoBytes)
                    )
                }

                if !viewModel.payload.contactIdentifiers.isEmpty {
                    breakdownRow(
                        icon: "person.2.fill",
                        color: CSTheme.accentPink,
                        title: "Duplicate Contacts",
                        count: "\(viewModel.payload.contactIdentifiers.count) contacts",
                        size: "Metadata"
                    )
                }
            }

            // Safety notice
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 20))
                    .foregroundStyle(CSTheme.accentGreen)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Safety Guarantee")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)

                    Text("Photos and videos will be moved to the Recently Deleted album in Apple Photos, giving you 30 days to recover them if needed.")
                        .font(.system(size: 12))
                        .foregroundStyle(CSTheme.textSecondary)
                }
            }
            .csCard()

            Spacer(minLength: 20)

            // Explicit deletion confirmation button
            Button {
                viewModel.requestDeletion()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                    Text("Delete Selected Items")
                }
                .csDestructiveButton()
            }
        }
    }

    // MARK: - Breakdown Row

    private func breakdownRow(icon: String, color: Color, title: String, count: String, size: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CSTheme.textPrimary)
                Text(count)
                    .font(.system(size: 12))
                    .foregroundStyle(CSTheme.textSecondary)
            }

            Spacer()

            Text(size)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .csCard()
    }

    // MARK: - Success View

    private func successView(summary: CleanupSummary) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            // Celebration Icon
            ZStack {
                Circle()
                    .fill(CSTheme.accentGreen.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(CSTheme.accentGreen)
            }

            VStack(spacing: 8) {
                Text("Great! You freed \(summary.formattedTotal)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(CSTheme.successGradient)
                    .multilineTextAlignment(.center)

                Text("Your storage has been instantly optimized")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(CSTheme.textSecondary)
            }

            // Current Available Storage Callout
            if summary.currentAvailableBytes > 0 {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(CSTheme.accentCyan.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "internaldrive.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(CSTheme.accentCyan)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Available Storage")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CSTheme.textSecondary)
                        Text(summary.formattedAvailable)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(CSTheme.textPrimary)
                    }
                    Spacer()
                }
                .csCard()
            }

            // Category breakdown
            VStack(alignment: .leading, spacing: 14) {
                Text("Category Breakdown")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)

                if summary.photosCount > 0 {
                    categoryResultRow(
                        icon: "photo.on.rectangle.angled",
                        color: CSTheme.accentPurple,
                        title: "Photos",
                        count: "\(summary.photosCount) items removed",
                        size: ByteFormatter.string(from: summary.photosFreed)
                    )
                }

                if summary.screenshotsCount > 0 {
                    categoryResultRow(
                        icon: "camera.viewfinder",
                        color: CSTheme.accentCyan,
                        title: "Screenshots",
                        count: "\(summary.screenshotsCount) items removed",
                        size: ByteFormatter.string(from: summary.screenshotsFreed)
                    )
                }

                if summary.videosCount > 0 {
                    categoryResultRow(
                        icon: "video.fill",
                        color: CSTheme.accentOrange,
                        title: "Videos",
                        count: "\(summary.videosCount) items removed",
                        size: ByteFormatter.string(from: summary.videosFreed)
                    )
                }

                if summary.contactsRemoved > 0 {
                    categoryResultRow(
                        icon: "person.2.fill",
                        color: CSTheme.accentPink,
                        title: "Contacts",
                        count: "\(summary.contactsRemoved) duplicates removed",
                        size: "Cleaned"
                    )
                }
            }
            .csCard()

            Spacer(minLength: 24)

            VStack(spacing: 12) {
                Button {
                    dismiss()
                    dashboardVM?.startFullScan()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan Again")
                    }
                    .csPrimaryButton()
                }

                Button {
                    dismiss()
                    dashboardVM?.refreshStorageInfo()
                } label: {
                    Text("Done")
                        .csSecondaryButton()
                }
            }
        }
    }

    private func categoryResultRow(icon: String, color: Color, title: String, count: String, size: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CSTheme.textPrimary)
                Text(count)
                    .font(.system(size: 12))
                    .foregroundStyle(CSTheme.textSecondary)
            }

            Spacer()

            Text(size)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }

    // MARK: - Deleting Overlay

    private var deletingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.4)

                Text("Safely Cleaning Storage...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(CSTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(CSTheme.cardBorder, lineWidth: 1)
            )
        }
    }
}
