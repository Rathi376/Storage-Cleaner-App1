import SwiftUI
import Photos
import AVKit

/// Screen displaying large videos sorted by size with batch selection and AVKit video previews.
struct LargeVideosView: View {
    @State var viewModel: LargeVideoViewModel
    @State private var showReview = false
    @State private var previewPlayer: AVPlayer?
    @State private var isShowingPreview = false
    @State private var isPreparingPreview = false

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Top stats & selection controls
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.items) { item in
                                videoRow(item)
                                    .onAppear {
                                        viewModel.loadThumbnail(for: item)
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 90)
                    }

                    // Floating Glass Bottom Bar
                    if viewModel.selectedCount > 0 {
                        floatingBottomBar
                    }
                }
            }
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle("Large Videos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.selectedCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Review") {
                        CSTheme.hapticImpact(.light)
                        showReview = true
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CSTheme.accentOrange)
                }
            }
        }
        .navigationDestination(isPresented: $showReview) {
            ReviewView(viewModel: ReviewViewModel(payload: viewModel.buildReviewPayload()))
        }
        .sheet(isPresented: $isShowingPreview, onDismiss: {
            previewPlayer?.pause()
            previewPlayer = nil
        }) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    if let player = previewPlayer {
                        VideoPlayer(player: player)
                            .onAppear { player.play() }
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .navigationTitle("Video Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isShowingPreview = false
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CSTheme.accentOrange)
                    }
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("\(viewModel.selectedCount) of \(viewModel.items.count) selected")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CSTheme.textSecondary)

            Spacer()

            HStack(spacing: 12) {
                Button("Select All") {
                    CSTheme.hapticImpact(.light)
                    viewModel.selectAll()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(CSTheme.accentOrange)

                Text("•")
                    .foregroundStyle(CSTheme.textTertiary)

                Button("Deselect") {
                    CSTheme.hapticImpact(.light)
                    viewModel.deselectAll()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CSTheme.textTertiary)
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
                    Text("\(viewModel.selectedCount) videos selected")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text("Reclaims \(viewModel.formattedSelectedSize)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(CSTheme.accentOrange)
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

    // MARK: - Video Row

    private func videoRow(_ item: VideoItem) -> some View {
        HStack(spacing: 14) {
            // Video thumbnail with play preview button
            Button {
                CSTheme.hapticImpact(.light)
                playVideo(item)
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let image = viewModel.thumbnailCache[item.id] {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 92, height: 72)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(CSTheme.surfaceLight)
                            .frame(width: 92, height: 72)
                            .overlay {
                                ProgressView()
                                    .tint(CSTheme.textTertiary)
                            }
                    }

                    // Play icon overlay
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: 1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    // Duration pill
                    Text(item.formattedDuration)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.75))
                        .clipShape(Capsule())
                        .padding(4)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            // Info (taps toggle selection)
            Button {
                CSTheme.hapticImpact(.light)
                viewModel.toggleSelection(item.id)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(item.formattedSize)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(CSTheme.textPrimary)

                            if item.pixelWidth >= 3840 || item.pixelHeight >= 2160 {
                                Text("4K")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(CSTheme.accentOrange)
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            } else if item.pixelWidth >= 1920 || item.pixelHeight >= 1080 {
                                Text("HD")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(CSTheme.accentCyan)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(CSTheme.accentCyan.opacity(0.18))
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                        }

                        Text(item.formattedDate)
                            .font(.system(size: 12))
                            .foregroundStyle(CSTheme.textSecondary)

                        Text("\(item.pixelWidth) × \(item.pixelHeight)")
                            .font(.system(size: 11))
                            .foregroundStyle(CSTheme.textTertiary)
                    }

                    Spacer()

                    // Selection Checkmark
                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(item.isSelected ? CSTheme.accentOrange : CSTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .csCard(padding: 12)
        .overlay(
            RoundedRectangle(cornerRadius: CSTheme.cardRadius, style: .continuous)
                .stroke(item.isSelected ? CSTheme.accentOrange.opacity(0.8) : Color.clear, lineWidth: 1.5)
        )
    }

    // MARK: - Video Playback

    private func playVideo(_ item: VideoItem) {
        guard !isPreparingPreview else { return }
        isPreparingPreview = true

        Task {
            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [item.id], options: nil).firstObject
            if let asset, let playerItem = await PhotoLibraryService.shared.requestPlayerItem(for: asset) {
                previewPlayer = AVPlayer(playerItem: playerItem)
                isShowingPreview = true
            }
            isPreparingPreview = false
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CSTheme.accentOrange.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "video.badge.checkmark")
                    .font(.system(size: 38))
                    .foregroundStyle(CSTheme.accentOrange)
            }

            VStack(spacing: 6) {
                Text("No Large Videos")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)

                Text("No videos taking excessive space were found.")
                    .font(.system(size: 14))
                    .foregroundStyle(CSTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
