import SwiftUI

/// The main dashboard showing storage overview and scan categories.
struct DashboardView: View {
    @Environment(DashboardViewModel.self) private var vm

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Storage Ring
                storageCard

                // Scan button
                if vm.isScanning {
                    scanProgressCard
                } else {
                    scanButton
                }

                // Limited access banner
                if vm.photosPermission == .limited {
                    limitedAccessBanner
                }

                // Denied access banner
                if vm.photosPermission == .denied || vm.photosPermission == .restricted {
                    deniedAccessBanner
                }

                // Category cards
                if vm.hasScanned {
                    VStack(spacing: 14) {
                        Text("Categories")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(CSTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        categoryCard(
                            icon: "photo.on.rectangle.angled",
                            title: "Similar Photos",
                            count: vm.similarPhotoCount,
                            bytes: vm.similarPhotoBytes,
                            color: CSTheme.accentPurple,
                            destination: similarPhotosDestination
                        )

                        categoryCard(
                            icon: "camera.viewfinder",
                            title: "Screenshots",
                            count: vm.screenshotCount,
                            bytes: vm.screenshotBytes,
                            color: CSTheme.accentCyan,
                            destination: screenshotsDestination
                        )

                        categoryCard(
                            icon: "video.fill",
                            title: "Large Videos",
                            count: vm.largeVideoCount,
                            bytes: vm.largeVideoBytes,
                            color: CSTheme.accentOrange,
                            destination: videosDestination
                        )

                        categoryCard(
                            icon: "camera.metering.matrix",
                            title: "Blurry Photos",
                            count: vm.blurryPhotoCount,
                            bytes: vm.blurryPhotoBytes,
                            color: CSTheme.accentPink,
                            destination: blurryPhotosDestination
                        )

                        categoryCard(
                            icon: "person.2.fill",
                            title: "Duplicate Contacts",
                            count: vm.duplicateContactCount,
                            bytes: 0,
                            color: CSTheme.accentPink,
                            destination: contactsDestination
                        )
                    }
                }

                // Reclaimable summary
                if vm.hasScanned && vm.reclaimableBytes > 0 {
                    reclaimableCard
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle("CleanSpace")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            vm.refreshStorageInfo()
            vm.refreshPermissions()
        }
        .alert("Photos Access", isPresented: Binding(
            get: { vm.showPrePermissionExplanation },
            set: { vm.showPrePermissionExplanation = $0 }
        )) {
            Button("Continue") {
                vm.startFullScan()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("CleanSpace scans your photo library on this device to find photos and videos that may be taking unnecessary space.")
        }
    }

    // MARK: - Storage Card

    private var storageCard: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(CSTheme.surfaceLight, lineWidth: 12)
                    .frame(width: 140, height: 140)

                // Used storage arc
                Circle()
                    .trim(from: 0, to: vm.storageInfo.usedPercentage)
                    .stroke(
                        CSTheme.storageGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: vm.storageInfo.usedPercentage)

                VStack(spacing: 2) {
                    Text(ByteFormatter.string(from: vm.storageInfo.usedBytes))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text("Used")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CSTheme.textSecondary)
                }
            }

            HStack(spacing: 24) {
                storageLabel("Total", ByteFormatter.string(from: vm.storageInfo.totalBytes))
                storageLabel("Free", ByteFormatter.string(from: vm.storageInfo.freeBytes))
                if vm.hasScanned {
                    storageLabel("Reclaimable", ByteFormatter.string(from: vm.reclaimableBytes))
                }
            }
        }
        .csCard()
    }

    private func storageLabel(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(CSTheme.textPrimary)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CSTheme.textTertiary)
        }
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        Button {
            vm.handleScanTap()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                Text(vm.hasScanned ? "Scan Again" : "Scan Now")
            }
            .csPrimaryButton()
        }
    }

    // MARK: - Scan Progress

    private var scanProgressCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text(vm.scanProgress.currentStep)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(CSTheme.textPrimary)
                Spacer()
                if vm.scanProgress.totalCount > 0 {
                    Text(vm.scanProgress.displayText)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(CSTheme.accentCyan)
                }
            }

            ProgressView(value: vm.scanProgress.fraction)
                .tint(CSTheme.accentCyan)
                .animation(.easeInOut, value: vm.scanProgress.fraction)

            if vm.scanProgress.totalCount > 0 {
                Text("\(Int(vm.scanProgress.fraction * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CSTheme.textTertiary)
            }
        }
        .csCard()
    }

    // MARK: - Limited Access Banner

    private var limitedAccessBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(CSTheme.accentOrange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Limited Access")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CSTheme.textPrimary)
                Text("Only selected photos are accessible. Grant full access in Settings for complete results.")
                    .font(.system(size: 12))
                    .foregroundStyle(CSTheme.textSecondary)
            }
            Spacer()
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(CSTheme.accentOrange)
        }
        .csCard()
    }

    private var deniedAccessBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(CSTheme.destructive)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Photo Access Required")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text("Photo access is required to scan your library.")
                        .font(.system(size: 13))
                        .foregroundStyle(CSTheme.textSecondary)
                }
                Spacer()
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(CSTheme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .csCard()
    }

    // MARK: - Category Cards

    @ViewBuilder
    private func categoryCard<Destination: View>(
        icon: String,
        title: String,
        count: Int,
        bytes: Int64,
        color: Color,
        destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)
                    HStack(spacing: 8) {
                        Text("\(count) items")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CSTheme.textSecondary)
                        if bytes > 0 {
                            Text("•")
                                .foregroundStyle(CSTheme.textTertiary)
                            Text(ByteFormatter.string(from: bytes))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(color)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CSTheme.textTertiary)
            }
            .csCard()
        }
    }

    // MARK: - Reclaimable Card

    private var reclaimableCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.up.trash.fill")
                .font(.system(size: 22))
                .foregroundStyle(CSTheme.accentGreen)
            VStack(alignment: .leading, spacing: 4) {
                Text("Estimated Reclaimable")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CSTheme.textSecondary)
                Text(ByteFormatter.string(from: vm.reclaimableBytes))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(CSTheme.accentGreen)
            }
            Spacer()
        }
        .csCard()
    }

    // MARK: - Destinations

    private func similarPhotosDestination() -> some View {
        SimilarPhotosView(viewModel: PhotoScannerViewModel(result: vm.photoScanResult))
    }

    private func screenshotsDestination() -> some View {
        ScreenshotsView(viewModel: ScreenshotViewModel(items: vm.screenshots))
    }

    private func videosDestination() -> some View {
        LargeVideosView(viewModel: LargeVideoViewModel(items: vm.videos))
    }

    private func contactsDestination() -> some View {
        DuplicateContactsView(viewModel: DuplicateContactsViewModel(result: vm.contactScanResult))
    }

    private func blurryPhotosDestination() -> some View {
        BlurryPhotosView(viewModel: BlurryPhotosViewModel(items: vm.blurryPhotos))
    }
}
