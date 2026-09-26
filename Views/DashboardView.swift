import SwiftUI

/// The main dashboard showing storage overview and scan categories.
/// Designed with iOS native aesthetics, Apple storage segmented gauge, and smooth micro-interactions.
struct DashboardView: View {
    @Environment(DashboardViewModel.self) private var vm

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Storage Overview Card
                storageCard

                // Action Area: Scan Button or Progress Card
                if vm.isScanning {
                    scanProgressCard
                } else {
                    scanButton
                }

                // Permission Notices
                if vm.photosPermission == .limited {
                    limitedAccessBanner
                }

                if vm.photosPermission == .denied || vm.photosPermission == .restricted {
                    deniedAccessBanner
                }

                // Reclaimable summary banner (if scanned)
                if vm.hasScanned && vm.reclaimableBytes > 0 {
                    reclaimableCard
                }

                // Category List
                if vm.hasScanned {
                    categoriesSection
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
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
                CSTheme.hapticImpact(.medium)
                vm.startFullScan()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("CleanSpace scans your photo library entirely on this device to find duplicate photos, screenshots, blurry photos, and large videos.")
        }
    }

    // MARK: - Storage Card

    private var storageCard: some View {
        VStack(spacing: 20) {
            // Top Ring & Used Storage Callout
            HStack(spacing: 22) {
                // Circular Ring Meter
                ZStack {
                    Circle()
                        .stroke(CSTheme.surfaceLight, lineWidth: 14)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(min(max(vm.storageInfo.usedPercentage, 0.01), 1.0)))
                        .stroke(
                            CSTheme.primaryGradient,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: vm.storageInfo.usedPercentage)

                    VStack(spacing: 2) {
                        Text("\(Int(vm.storageInfo.usedPercentage * 100))%")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(CSTheme.textPrimary)
                        Text("Used")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CSTheme.textSecondary)
                    }
                }

                // Storage Key Stats
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iPhone Storage")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CSTheme.textSecondary)
                        Text(ByteFormatter.string(from: vm.storageInfo.usedBytes))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(CSTheme.textPrimary)
                        Text("of \(ByteFormatter.string(from: vm.storageInfo.totalBytes)) Total")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(CSTheme.textTertiary)
                    }

                    HStack(spacing: 16) {
                        statPill(title: "Free", value: ByteFormatter.string(from: vm.storageInfo.freeBytes), color: CSTheme.accentGreen)
                        if vm.hasScanned {
                            statPill(title: "Cleanable", value: ByteFormatter.string(from: vm.reclaimableBytes), color: CSTheme.accentBlue)
                        }
                    }
                }

                Spacer()
            }

            // iOS-style Segmented Storage Bar
            VStack(alignment: .leading, spacing: 8) {
                storageSegmentedBar

                // Legend
                HStack(spacing: 12) {
                    legendItem(title: "Photos", color: CSTheme.accentBlue)
                    legendItem(title: "Videos", color: CSTheme.accentOrange)
                    legendItem(title: "Shots", color: CSTheme.accentCyan)
                    legendItem(title: "Other", color: CSTheme.textTertiary)
                    Spacer()
                }
                .font(.system(size: 11, weight: .medium))
            }
        }
        .csCard()
    }

    private func statPill(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CSTheme.textTertiary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var storageSegmentedBar: some View {
        GeometryReader { proxy in
            let total = max(Double(vm.storageInfo.totalBytes), 1.0)
            let photoW = proxy.size.width * CGFloat(Double(vm.similarPhotoBytes) / total)
            let videoW = proxy.size.width * CGFloat(Double(vm.largeVideoBytes) / total)
            let shotW = proxy.size.width * CGFloat(Double(vm.screenshotBytes) / total)
            let usedW = proxy.size.width * CGFloat(Double(vm.storageInfo.usedBytes) / total)
            let otherW = max(0, usedW - (photoW + videoW + shotW))

            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(CSTheme.surfaceLight)

                HStack(spacing: 2) {
                    if photoW > 2 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(CSTheme.accentBlue)
                            .frame(width: max(photoW, 4))
                    }
                    if videoW > 2 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(CSTheme.accentOrange)
                            .frame(width: max(videoW, 4))
                    }
                    if shotW > 2 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(CSTheme.accentCyan)
                            .frame(width: max(shotW, 4))
                    }
                    if otherW > 4 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray3))
                            .frame(width: otherW)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .frame(height: 12)
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(title)
                .foregroundStyle(CSTheme.textSecondary)
        }
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        Button {
            CSTheme.hapticImpact(.medium)
            vm.handleScanTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: vm.hasScanned ? "arrow.clockwise" : "sparkle.magnifyingglass")
                    .font(.system(size: 20, weight: .bold))
                Text(vm.hasScanned ? "Scan Again" : "Start Smart Scan")
                    .font(.system(size: 17, weight: .bold))
            }
            .csPrimaryButton()
        }
        .buttonStyle(CSBounceButtonStyle())
    }

    // MARK: - Scan Progress Card

    private var scanProgressCard: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(CSTheme.accentBlue)
                    Text(vm.scanProgress.currentStep)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)
                }
                Spacer()
                if vm.scanProgress.totalCount > 0 {
                    Text("\(Int(vm.scanProgress.fraction * 100))%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(CSTheme.accentBlue)
                }
            }

            ProgressView(value: vm.scanProgress.fraction)
                .tint(CSTheme.accentBlue)
                .animation(.easeInOut(duration: 0.25), value: vm.scanProgress.fraction)

            if vm.scanProgress.totalCount > 0 {
                HStack {
                    Text(vm.scanProgress.displayText)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(CSTheme.textTertiary)
                    Spacer()
                    Text("Analyzing on-device")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CSTheme.accentGreen)
                }
            }
        }
        .csCard()
    }

    // MARK: - Reclaimable Card

    private var reclaimableCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 22))
                .foregroundStyle(CSTheme.accentGreen)
                .frame(width: 44, height: 44)
                .background(CSTheme.accentGreen.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Potential Space to Clean")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CSTheme.textSecondary)
                Text(ByteFormatter.string(from: vm.reclaimableBytes))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(CSTheme.accentGreen)
            }

            Spacer()

            NavigationLink {
                CleanTabView()
            } label: {
                Text("Clean")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(CSTheme.accentGreen)
                    .clipShape(Capsule())
            }
        }
        .csCard()
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Cleanup Categories")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 4)

            categoryRow(
                icon: "photo.stack.fill",
                title: "Similar Photos",
                count: vm.similarPhotoCount,
                bytes: vm.similarPhotoBytes,
                color: CSTheme.accentBlue,
                destination: similarPhotosDestination
            )

            categoryRow(
                icon: "camera.viewfinder",
                title: "Screenshots",
                count: vm.screenshotCount,
                bytes: vm.screenshotBytes,
                color: CSTheme.accentCyan,
                destination: screenshotsDestination
            )

            categoryRow(
                icon: "video.fill",
                title: "Large Videos",
                count: vm.largeVideoCount,
                bytes: vm.largeVideoBytes,
                color: CSTheme.accentOrange,
                destination: videosDestination
            )

            categoryRow(
                icon: "camera.metering.matrix",
                title: "Blurry Photos",
                count: vm.blurryPhotoCount,
                bytes: vm.blurryPhotoBytes,
                color: CSTheme.accentPink,
                destination: blurryPhotosDestination
            )

            categoryRow(
                icon: "person.2.fill",
                title: "Duplicate Contacts",
                count: vm.duplicateContactCount,
                bytes: 0,
                color: CSTheme.accentGreen,
                destination: contactsDestination
            )
        }
    }

    @ViewBuilder
    private func categoryRow<Destination: View>(
        icon: String,
        title: String,
        count: Int,
        bytes: Int64,
        color: Color,
        destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .csIconBadge(color: color)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)

                    HStack(spacing: 6) {
                        Text("\(count) items")
                            .font(.system(size: 13))
                            .foregroundStyle(CSTheme.textSecondary)

                        if bytes > 0 {
                            Text("•")
                                .foregroundStyle(CSTheme.textTertiary)
                            Text(ByteFormatter.string(from: bytes))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(color)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CSTheme.textTertiary)
            }
            .csCard()
        }
        .buttonStyle(CSBounceButtonStyle())
    }

    // MARK: - Permission Banners

    private var limitedAccessBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(CSTheme.accentOrange)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text("Limited Photo Access")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CSTheme.textPrimary)
                Text("Allow full access in Settings for complete scan results.")
                    .font(.system(size: 12))
                    .foregroundStyle(CSTheme.textSecondary)
            }

            Spacer()

            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(CSTheme.accentOrange)
        }
        .csCard()
    }

    private var deniedAccessBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(CSTheme.accentRed)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Photo Permission Needed")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text("CleanSpace requires photo access to find duplicates and large files.")
                        .font(.system(size: 12))
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
                .background(CSTheme.accentBlue)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
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
