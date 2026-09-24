import SwiftUI

/// Clean tab showing recent scan results and quick access to categories.
struct CleanTabView: View {
    @Environment(DashboardViewModel.self) private var vm

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !vm.hasScanned {
                    emptyState
                } else {
                    // Quick summary
                    summaryCard

                    // Quick actions
                    VStack(spacing: 14) {
                        Text("Quick Clean")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(CSTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if vm.similarPhotoCount > 0 {
                            quickAction(
                                icon: "photo.on.rectangle.angled",
                                title: "Similar Photos",
                                subtitle: "\(vm.similarPhotoCount) duplicates found",
                                color: CSTheme.accentPurple
                            ) {
                                SimilarPhotosView(viewModel: PhotoScannerViewModel(result: vm.photoScanResult))
                            }
                        }

                        if vm.screenshotCount > 0 {
                            quickAction(
                                icon: "camera.viewfinder",
                                title: "Screenshots",
                                subtitle: "\(vm.screenshotCount) screenshots",
                                color: CSTheme.accentCyan
                            ) {
                                ScreenshotsView(viewModel: ScreenshotViewModel(items: vm.screenshots))
                            }
                        }

                        if vm.largeVideoCount > 0 {
                            quickAction(
                                icon: "video.fill",
                                title: "Large Videos",
                                subtitle: "\(vm.largeVideoCount) videos",
                                color: CSTheme.accentOrange
                            ) {
                                LargeVideosView(viewModel: LargeVideoViewModel(items: vm.videos))
                            }
                        }

                        if vm.blurryPhotoCount > 0 {
                            quickAction(
                                icon: "camera.metering.matrix",
                                title: "Blurry Photos",
                                subtitle: "\(vm.blurryPhotoCount) potentially blurry",
                                color: CSTheme.accentPink
                            ) {
                                BlurryPhotosView(viewModel: BlurryPhotosViewModel(items: vm.blurryPhotos))
                            }
                        }

                        if vm.duplicateContactCount > 0 {
                            quickAction(
                                icon: "person.2.fill",
                                title: "Duplicate Contacts",
                                subtitle: "\(vm.duplicateContactCount) duplicates",
                                color: CSTheme.accentPink
                            ) {
                                DuplicateContactsView(viewModel: DuplicateContactsViewModel(result: vm.contactScanResult))
                            }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle("Clean")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(CSTheme.primaryGradient)

            Text("No Scan Results Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(CSTheme.textPrimary)

            Text("Go to the Home tab and tap Scan Now to find items you can clean up.")
                .font(.system(size: 15))
                .foregroundStyle(CSTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(CSTheme.accentGreen)
                Text("Scan Complete")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)
                Spacer()
            }

            HStack(spacing: 20) {
                summaryItem("Photos", "\(vm.similarPhotoCount)")
                summaryItem("Screenshots", "\(vm.screenshotCount)")
                summaryItem("Videos", "\(vm.largeVideoCount)")
                summaryItem("Contacts", "\(vm.duplicateContactCount)")
            }
        }
        .csCard()
    }

    private func summaryItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(CSTheme.textPrimary)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func quickAction<Destination: View>(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(CSTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CSTheme.textTertiary)
            }
            .csCard()
        }
    }
}
