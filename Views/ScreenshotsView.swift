import SwiftUI

/// Screenshots screen with a performant grid and batch selection.
struct ScreenshotsView: View {
    @State var viewModel: ScreenshotViewModel
    @State private var showReview = false

    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Top bar
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 6) {
                            ForEach(viewModel.items) { item in
                                screenshotThumbnail(item)
                                    .onAppear {
                                        if let index = viewModel.items.firstIndex(where: { $0.id == item.id }) {
                                            viewModel.loadThumbnails(startIndex: index, count: 20)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.bottom, 100)
                    }

                    // Bottom action bar
                    if viewModel.selectedCount > 0 {
                        bottomBar
                    }
                }
            }
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle("Screenshots")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showReview) {
            ReviewView(viewModel: ReviewViewModel(payload: viewModel.buildReviewPayload()))
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
                .foregroundStyle(CSTheme.accentCyan)

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
                    Text("\(viewModel.selectedCount) screenshots")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text(viewModel.formattedSelectedSize)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CSTheme.accentCyan)
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

    // MARK: - Thumbnail

    private func screenshotThumbnail(_ item: PhotoItem) -> some View {
        Button {
            viewModel.toggleSelection(item.id)
        } label: {
            ZStack(alignment: .topTrailing) {
                if let image = viewModel.thumbnailCache[item.id] {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minHeight: 150)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(CSTheme.surfaceLight)
                        .frame(minHeight: 150)
                }

                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.isSelected ? CSTheme.accentCyan : .white.opacity(0.5))
                    .shadow(radius: 2)
                    .padding(6)

                if item.isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(CSTheme.accentCyan, lineWidth: 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 50))
                .foregroundStyle(CSTheme.textTertiary)

            Text("No Screenshots Found")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(CSTheme.textPrimary)

            Text("No screenshots were found in your photo library.")
                .font(.system(size: 15))
                .foregroundStyle(CSTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
