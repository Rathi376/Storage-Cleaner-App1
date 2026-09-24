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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.items) { item in
                                videoRow(item)
                                    .onAppear {
                                        viewModel.loadThumbnail(for: item)
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }

                    // Floating / pinned bottom bar
                    if viewModel.selectedCount > 0 {
                        bottomBar
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
                        showReview = true
                    }
                    .foregroundStyle(CSTheme.accentOrange)
                    .fontWeight(.semibold)
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
                    CSTheme.background.ignoresSafeArea()
                    if let player = previewPlayer {
                        VideoPlayer(player: player)
                            .onAppear { player.play() }
                    } else {
                        ProgressView()
                            .tint(CSTheme.accentOrange)
                    }
                }
                .navigationTitle("Video Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isShowingPreview = false
                        }
                        .foregroundStyle(CSTheme.accentOrange)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("\(viewModel.selectedCount) of \(viewModel.items.count) selected")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CSTheme.textSecondary)

            Spacer()

            HStack(spacing: 16) {
                Button("Select All") {
                    viewModel.selectAll()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CSTheme.accentOrange)

                Button("Deselect") {
                    viewModel.deselectAll()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CSTheme.textTertiary)
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
                    Text("\(viewModel.selectedCount) videos selected")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text(viewModel.formattedSelectedSize)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CSTheme.accentOrange)
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

    // MARK: - Video Row

    private func videoRow(_ item: VideoItem) -> some View {
        HStack(spacing: 14) {
            // Video thumbnail with duration badge and play button
            Button {
                playVideo(item)
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let image = viewModel.thumbnailCache[item.id] {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 96, height: 72)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(CSTheme.surfaceLight)
                            .frame(width: 96, height: 72)
                            .overlay {
                                ProgressView()
                                    .tint(CSTheme.textTertiary)
                            }
                    }

                    // Play icon overlay
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: 1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    // Duration pill
                    Text(item.formattedDuration)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.75))
                        .clipShape(Capsule())
                        .padding(4)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            // Info (taps toggle selection)
            Button {
                viewModel.toggleSelection(item.id)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.formattedSize)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(CSTheme.textPrimary)

                            if item.pixelWidth >= 3840 || item.pixelHeight >= 2160 {
                                Text("4K")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(CSTheme.accentOrange)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(CSTheme.accentOrange.opacity(0.18))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else if item.pixelWidth >= 1920 || item.pixelHeight >= 1080 {
                                Text("HD")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(CSTheme.accentCyan)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(CSTheme.accentCyan.opacity(0.18))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }

                        Text(item.formattedDate)
                            .font(.system(size: 13))
                            .foregroundStyle(CSTheme.textSecondary)

                        Text("\(item.pixelWidth) × \(item.pixelHeight)")
                            .font(.system(size: 12))
                            .foregroundStyle(CSTheme.textTertiary)
                    }

                    Spacer()

                    // Checkmark toggle
                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(item.isSelected ? CSTheme.accentOrange : CSTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .csCard()
        .overlay(
            RoundedRectangle(cornerRadius: CSTheme.cardRadius)
                .stroke(item.isSelected ? CSTheme.accentOrange.opacity(0.6) : Color.clear, lineWidth: 1.5)
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
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 50))
                .foregroundStyle(CSTheme.textTertiary)

            Text("No Large Videos Found")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(CSTheme.textPrimary)

            Text("No videos exceeding 50 MB were found in your library.")
                .font(.system(size: 15))
                .foregroundStyle(CSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
