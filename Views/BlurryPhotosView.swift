import SwiftUI

/// Screen displaying detected blurry photos with Grid and interactive Swipe Mode.
struct BlurryPhotosView: View {
    @State var viewModel: BlurryPhotosViewModel
    @State private var showReview = false
    @State private var viewMode: ViewMode = .grid

    enum ViewMode: String, CaseIterable, Identifiable {
        case grid = "Grid"
        case swipe = "Swipe Mode"
        var id: String { rawValue }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Mode Switcher
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    if viewMode == .grid {
                        gridView
                    } else {
                        swipeView
                    }
                }
            }
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle("Blurry Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.selectedCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Review") {
                        CSTheme.hapticImpact(.light)
                        showReview = true
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CSTheme.accentPink)
                }
            }
        }
        .navigationDestination(isPresented: $showReview) {
            ReviewView(viewModel: ReviewViewModel(payload: viewModel.buildReviewPayload()))
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(viewModel.items) { item in
                        blurryPhotoCard(item)
                            .onAppear {
                                if let index = viewModel.items.firstIndex(where: { $0.id == item.id }) {
                                    viewModel.loadThumbnails(startIndex: index, count: 12)
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }

            if viewModel.selectedCount > 0 {
                floatingBottomBar
            }
        }
    }

    // MARK: - Swipe View

    private var swipeView: some View {
        PhotoSwipeDeckView(
            title: "Swipe Blurry Photos",
            items: $viewModel.items,
            recommendedItem: nil,
            onSelectionChanged: { _, _ in },
            onFinish: {
                viewMode = .grid
                if viewModel.selectedCount > 0 {
                    showReview = true
                }
            }
        )
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
                .foregroundStyle(CSTheme.accentPink)

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
                    Text("\(viewModel.selectedCount) photos selected")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text("Reclaims \(viewModel.formattedSelectedSize)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(CSTheme.accentPink)
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

    // MARK: - Photo Card

    private func blurryPhotoCard(_ item: PhotoItem) -> some View {
        Button {
            CSTheme.hapticImpact(.light)
            viewModel.toggleSelection(item.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    if let image = viewModel.thumbnailCache[item.id] {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(CSTheme.surfaceLight)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                ProgressView()
                                    .tint(CSTheme.textTertiary)
                            }
                    }

                    // Selection Checkmark
                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(item.isSelected ? CSTheme.accentPink : .white.opacity(0.8))
                        .shadow(color: .black.opacity(0.4), radius: 2)
                        .padding(8)

                    // Blurry indicator pill
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 3) {
                                Image(systemName: "camera.metering.matrix")
                                    .font(.system(size: 9))
                                Text("Blurry")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.85))
                            .clipShape(Capsule())

                            Spacer()
                        }
                        .padding(6)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Date & Size info
                HStack {
                    Text(item.formattedDate)
                        .font(.system(size: 11))
                        .foregroundStyle(CSTheme.textSecondary)

                    Spacer()

                    Text(item.formattedSize)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(CSTheme.accentPink)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
            .csCard(padding: 8)
            .overlay(
                RoundedRectangle(cornerRadius: CSTheme.cardRadius, style: .continuous)
                    .stroke(item.isSelected ? CSTheme.accentPink : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CSTheme.accentGreen.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(CSTheme.accentGreen)
            }

            VStack(spacing: 6) {
                Text("No Blurry Photos")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)

                Text("All scanned photos in your library have great sharpness.")
                    .font(.system(size: 14))
                    .foregroundStyle(CSTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
