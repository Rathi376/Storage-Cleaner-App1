import SwiftUI

/// Review & Confirmation view prior to performing any deletions.
/// Satisfies the strict safety requirement: requires explicit user confirmation.
struct ReviewView: View {
    @State var viewModel: ReviewViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(DashboardViewModel.self) private var dashboardVM: DashboardViewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let summary = viewModel.cleanupSummary {
                    successView(summary: summary)
                } else {
                    reviewContent
                }
            }
            .padding(.horizontal, 16)
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
            Button("Delete \(viewModel.payload.totalItemCount) Items", role: .destructive) {
                CSTheme.hapticImpact(.heavy)
                Task {
                    await viewModel.confirmAndClean()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove \(viewModel.payload.totalItemCount) items to free up approximately \(viewModel.formattedEstimatedSize). Deleted photos and videos can still be restored from Recently Deleted in Apple Photos for up to 30 days.")
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
        VStack(spacing: 18) {
            // Header Hero Banner
            VStack(spacing: 6) {
                Text(viewModel.formattedEstimatedSize)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(CSTheme.primaryGradient)

                Text("Space to Reclaim")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)

                Text("\(viewModel.payload.totalItemCount) items selected for cleanup")
                    .font(.system(size: 13))
                    .foregroundStyle(CSTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .csCard()

            // Breakdown Sections
            VStack(alignment: .leading, spacing: 12) {
                Text("Cleanup Summary")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)
                    .padding(.horizontal, 4)

                if !viewModel.payload.photoIdentifiers.isEmpty {
                    breakdownRow(
                        icon: "photo.stack.fill",
                        color: CSTheme.accentBlue,
                        title: "Photos",
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
                        color: CSTheme.accentGreen,
                        title: "Duplicate Contacts",
                        count: "\(viewModel.payload.contactIdentifiers.count) contacts",
                        size: "Clean"
                    )
                }
            }

            // Safety Guarantee Card
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 22))
                    .foregroundStyle(CSTheme.accentGreen)
                    .frame(width: 40, height: 40)
                    .background(CSTheme.accentGreen.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Safety Guarantee")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)

                    Text("Photos and videos are safely placed in your Recently Deleted album in Apple Photos for 30 days.")
                        .font(.system(size: 12))
                        .foregroundStyle(CSTheme.textSecondary)
                        .lineSpacing(2)
                }
            }
            .csCard()

            Spacer(minLength: 16)

            // Explicit Deletion Confirmation Button
            Button {
                CSTheme.hapticImpact(.medium)
                viewModel.requestDeletion()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                    Text("Delete Selected Items")
                }
                .csDestructiveButton()
            }
            .buttonStyle(CSBounceButtonStyle())
        }
    }

    // MARK: - Breakdown Row

    private func breakdownRow(icon: String, color: Color, title: String, count: String, size: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .csIconBadge(color: color, size: 36, iconSize: 16)

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
        .csCard(padding: 12)
    }

    // MARK: - Success View

    private func successView(summary: CleanupSummary) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)

            // Celebration Icon
            ZStack {
                Circle()
                    .fill(CSTheme.accentGreen.opacity(0.14))
                    .frame(width: 90, height: 90)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(CSTheme.accentGreen)
            }

            VStack(spacing: 6) {
                Text("Cleaned \(summary.formattedTotal)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(CSTheme.successGradient)
                    .multilineTextAlignment(.center)

                Text("Your storage was successfully recovered")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CSTheme.textSecondary)
            }

            // Current Available Storage Callout
            if summary.currentAvailableBytes > 0 {
                HStack(spacing: 14) {
                    Image(systemName: "internaldrive.fill")
                        .csIconBadge(color: CSTheme.accentBlue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Available iPhone Storage")
                            .font(.system(size: 12, weight: .medium))
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
            VStack(alignment: .leading, spacing: 10) {
                Text("Summary of Cleaned Items")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)
                    .padding(.horizontal, 4)

                if summary.photosCount > 0 {
                    categoryResultRow(
                        icon: "photo.stack.fill",
                        color: CSTheme.accentBlue,
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
                        color: CSTheme.accentGreen,
                        title: "Contacts",
                        count: "\(summary.contactsRemoved) duplicates removed",
                        size: "Cleaned"
                    )
                }
            }

            Spacer(minLength: 20)

            VStack(spacing: 10) {
                Button {
                    CSTheme.hapticImpact(.medium)
                    dismiss()
                    dashboardVM?.startFullScan()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan Again")
                    }
                    .csPrimaryButton()
                }
                .buttonStyle(CSBounceButtonStyle())

                Button {
                    CSTheme.hapticImpact(.light)
                    dismiss()
                    dashboardVM?.refreshStorageInfo()
                } label: {
                    Text("Done")
                        .csSecondaryButton()
                }
                .buttonStyle(CSBounceButtonStyle())
            }
        }
    }

    private func categoryResultRow(icon: String, color: Color, title: String, count: String, size: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .csIconBadge(color: color, size: 32, iconSize: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CSTheme.textPrimary)
                Text(count)
                    .font(.system(size: 12))
                    .foregroundStyle(CSTheme.textSecondary)
            }

            Spacer()

            Text(size)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .csCard(padding: 10)
    }

    // MARK: - Deleting Overlay

    private var deletingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.3)

                Text("Safely Cleaning Storage...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(radius: 12)
        }
    }
}
