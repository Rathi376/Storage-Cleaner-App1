import SwiftUI

/// Clean tab showing recent scan results, space breakdown, and quick category access.
struct CleanTabView: View {
    @Environment(DashboardViewModel.self) private var vm

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !vm.hasScanned {
                    emptyState
                } else {
                    // Quick summary hero card
                    summaryCard

                    // Quick cleanup categories
                    VStack(spacing: 12) {
                        HStack {
                            Text("Quick Clean")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(CSTheme.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 4)

                        if vm.similarPhotoCount > 0 {
                            quickActionRow(
                                icon: "photo.stack.fill",
                                title: "Similar Photos",
                                subtitle: "\(vm.similarPhotoCount) duplicate copies",
                                size: ByteFormatter.string(from: vm.similarPhotoBytes),
                                color: CSTheme.accentBlue
                            ) {
                                SimilarPhotosView(viewModel: PhotoScannerViewModel(result: vm.photoScanResult))
                            }
                        }

                        if vm.screenshotCount > 0 {
                            quickActionRow(
                                icon: "camera.viewfinder",
                                title: "Screenshots",
                                subtitle: "\(vm.screenshotCount) screenshots",
                                size: ByteFormatter.string(from: vm.screenshotBytes),
                                color: CSTheme.accentCyan
                            ) {
                                ScreenshotsView(viewModel: ScreenshotViewModel(items: vm.screenshots))
                            }
                        }

                        if vm.largeVideoCount > 0 {
                            quickActionRow(
                                icon: "video.fill",
                                title: "Large Videos",
                                subtitle: "\(vm.largeVideoCount) videos",
                                size: ByteFormatter.string(from: vm.largeVideoBytes),
                                color: CSTheme.accentOrange
                            ) {
                                LargeVideosView(viewModel: LargeVideoViewModel(items: vm.videos))
                            }
                        }

                        if vm.blurryPhotoCount > 0 {
                            quickActionRow(
                                icon: "camera.metering.matrix",
                                title: "Blurry Photos",
                                subtitle: "\(vm.blurryPhotoCount) low-sharpness photos",
                                size: ByteFormatter.string(from: vm.blurryPhotoBytes),
                                color: CSTheme.accentPink
                            ) {
                                BlurryPhotosView(viewModel: BlurryPhotosViewModel(items: vm.blurryPhotos))
                            }
                        }

                        if vm.duplicateContactCount > 0 {
                            quickActionRow(
                                icon: "person.2.fill",
                                title: "Duplicate Contacts",
                                subtitle: "\(vm.duplicateContactCount) duplicate contacts",
                                size: "Review",
                                color: CSTheme.accentGreen
                            ) {
                                DuplicateContactsView(viewModel: DuplicateContactsViewModel(result: vm.contactScanResult))
                            }
                        }
                    }
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle("Clean")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(CSTheme.accentBlue.opacity(0.12))
                    .frame(width: 90, height: 90)

                Image(systemName: "sparkles")
                    .font(.system(size: 42))
                    .foregroundStyle(CSTheme.accentBlue)
            }

            VStack(spacing: 6) {
                Text("No Scan Results Yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)

                Text("Run a scan from the Home tab to detect similar photos, screenshots, blurry photos, and large videos.")
                    .font(.system(size: 14))
                    .foregroundStyle(CSTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 60)
    }

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(CSTheme.accentGreen)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Library Analyzed")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text("Ready for safe cleanup")
                        .font(.system(size: 12))
                        .foregroundStyle(CSTheme.textSecondary)
                }

                Spacer()

                Text(ByteFormatter.string(from: vm.reclaimableBytes))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(CSTheme.accentGreen)
            }

            Divider()
                .overlay(CSTheme.cardBorder)

            HStack(spacing: 12) {
                summaryMetric(title: "Photos", value: "\(vm.similarPhotoCount)", color: CSTheme.accentBlue)
                summaryMetric(title: "Screenshots", value: "\(vm.screenshotCount)", color: CSTheme.accentCyan)
                summaryMetric(title: "Videos", value: "\(vm.largeVideoCount)", color: CSTheme.accentOrange)
                summaryMetric(title: "Contacts", value: "\(vm.duplicateContactCount)", color: CSTheme.accentGreen)
            }
        }
        .csCard()
    }

    private func summaryMetric(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func quickActionRow<Destination: View>(
        icon: String,
        title: String,
        subtitle: String,
        size: String,
        color: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .csIconBadge(color: color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(CSTheme.textSecondary)
                }

                Spacer()

                Text(size)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CSTheme.textTertiary)
            }
            .csCard()
        }
        .buttonStyle(CSBounceButtonStyle())
    }
}
