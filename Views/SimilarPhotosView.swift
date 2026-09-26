import SwiftUI

/// Similar Photos view showing grouped duplicate/similar photos with both Grid Mode and interactive iOS Swipe Deck Mode.
struct SimilarPhotosView: View {
    @State var viewModel: PhotoScannerViewModel
    @State private var showReview = false
    @State private var viewMode: ViewMode = .grid
    @State private var swipeGroup: PhotoGroup?

    enum ViewMode: String, CaseIterable, Identifiable {
        case grid = "Grid"
        case swipe = "Swipe Mode"
        var id: String { rawValue }
    }

    var body: some View {
        Group {
            if viewModel.result.groups.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // View Mode Segmented Picker
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
                        swipeDeckView
                    }
                }
            }
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle("Similar Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.totalSelectedCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Review") {
                        CSTheme.hapticImpact(.light)
                        showReview = true
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CSTheme.accentBlue)
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
            ScrollView {
                VStack(spacing: 16) {
                    summaryBanner

                    ForEach(viewModel.result.groups) { group in
                        photoGroupCard(group)
                    }

                    Spacer(minLength: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }

            if viewModel.totalSelectedCount > 0 {
                floatingBottomBar
            }
        }
    }

    // MARK: - Swipe Deck View

    private var swipeDeckView: some View {
        // Collect all non-recommended candidate items for swiping
        let allCandidates = viewModel.result.groups.flatMap { group in
            group.items.filter { !$0.isRecommended }
        }

        let bestItem = viewModel.result.groups.first?.recommendedItem

        return PhotoSwipeDeckView(
            title: "Swipe to Clean",
            items: Binding(
                get: { allCandidates },
                set: { updatedCandidates in
                    // Update selection in viewModel groups
                    for updated in updatedCandidates {
                        for gi in viewModel.result.groups.indices {
                            if let ii = viewModel.result.groups[gi].items.firstIndex(where: { $0.id == updated.id }) {
                                viewModel.result.groups[gi].items[ii].isSelected = updated.isSelected
                            }
                        }
                    }
                }
            ),
            recommendedItem: bestItem,
            onSelectionChanged: { itemId, isSelected in
                for gi in viewModel.result.groups.indices {
                    if let ii = viewModel.result.groups[gi].items.firstIndex(where: { $0.id == itemId }) {
                        viewModel.result.groups[gi].items[ii].isSelected = isSelected
                    }
                }
            },
            onFinish: {
                viewMode = .grid
                if viewModel.totalSelectedCount > 0 {
                    showReview = true
                }
            }
        )
    }

    // MARK: - Summary Banner

    private var summaryBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "photo.stack.fill")
                .csIconBadge(color: CSTheme.accentBlue, size: 36, iconSize: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(viewModel.result.totalGroups) Similar Groups")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)
                Text("\(viewModel.result.totalDuplicateCount) potential duplicate photos")
                    .font(.system(size: 12))
                    .foregroundStyle(CSTheme.textSecondary)
            }

            Spacer()

            if viewModel.totalSelectedCount > 0 {
                Text(viewModel.formattedSelectedSize)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(CSTheme.accentBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(CSTheme.accentBlue.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .csCard(padding: 12)
    }

    // MARK: - Floating Bottom Bar

    private var floatingBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(CSTheme.cardBorder)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.totalSelectedCount) photos selected")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text("Reclaims \(viewModel.formattedSelectedSize)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(CSTheme.accentBlue)
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

    private func photoGroupCard(_ group: PhotoGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(CSTheme.accentBlue)
                        .frame(width: 6, height: 6)
                    Text("\(group.items.count) Photos")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button("Select All") {
                        CSTheme.hapticImpact(.light)
                        viewModel.selectAllInGroup(groupId: group.id)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CSTheme.accentBlue)

                    Text("•")
                        .foregroundStyle(CSTheme.textTertiary)

                    Button("Deselect") {
                        CSTheme.hapticImpact(.light)
                        viewModel.deselectAllInGroup(groupId: group.id)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CSTheme.textTertiary)
                }
            }

            // Photo grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(group.items) { item in
                    photoThumbnail(item, groupId: group.id)
                }
            }
        }
        .csCard()
        .onAppear {
            viewModel.loadThumbnails(for: group)
        }
    }

    // MARK: - Thumbnail

    private func photoThumbnail(_ item: PhotoItem, groupId: String) -> some View {
        Button {
            CSTheme.hapticImpact(.light)
            viewModel.toggleSelection(groupId: groupId, itemId: item.id)
        } label: {
            ZStack(alignment: .topLeading) {
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

                // Selection & Badges Overlay
                VStack {
                    HStack {
                        if item.isRecommended {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9))
                                Text("Best")
                                    .font(.system(size: 10, weight: .heavy))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color(red: 0.1, green: 0.7, blue: 0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(radius: 2)
                        }
                        Spacer()
                        if !item.isRecommended {
                            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(item.isSelected ? CSTheme.accentBlue : .white.opacity(0.8))
                                .shadow(color: .black.opacity(0.4), radius: 2)
                        }
                    }
                    Spacer()
                    HStack {
                        Text(item.formattedSize)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        Spacer()
                    }
                }
                .padding(6)

                if item.isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(CSTheme.accentBlue, lineWidth: 2.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                Image(systemName: "photo.badge.checkmark")
                    .font(.system(size: 38))
                    .foregroundStyle(CSTheme.accentGreen)
            }

            VStack(spacing: 6) {
                Text("No Similar Photos")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)

                Text("Your photo library has no duplicate or similar photo clusters.")
                    .font(.system(size: 14))
                    .foregroundStyle(CSTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
