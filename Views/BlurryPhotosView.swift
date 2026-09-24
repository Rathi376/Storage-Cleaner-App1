import SwiftUI

/// Screen displaying detected blurry photos for manual review and selection.
struct BlurryPhotosView: View {
    @State var viewModel: BlurryPhotosViewModel
    @State private var showReview = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Top controls
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)

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
                        .padding(.bottom, 100)
                    }

                    // Bottom bar
                    if viewModel.selectedCount > 0 {
                        bottomBar
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
                        showReview = true
                    }
                    .foregroundStyle(CSTheme.accentPink)
                    .fontWeight(.semibold)
                }
            }
        }
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
                .foregroundStyle(CSTheme.accentPink)

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
                    Text("\(viewModel.selectedCount) photos selected")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text(viewModel.formattedSelectedSize)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CSTheme.accentPink)
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

    // MARK: - Photo Card

    private func blurryPhotoCard(_ item: PhotoItem) -> some View {
        Button {
            viewModel.toggleSelection(item.id)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    if let image = viewModel.thumbnailCache[item.id] {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(CSTheme.surfaceLight)
                            .frame(height: 150)
                            .overlay {
                                ProgressView()
                                    .tint(CSTheme.textTertiary)
                            }
                    }

                    // Checkbox
                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(item.isSelected ? CSTheme.accentPink : .white.opacity(0.6))
                        .shadow(radius: 2)
                        .padding(8)

                    // Blurry indicator pill
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.metering.matrix")
                                    .font(.system(size: 10))
                                Text("Potentially Blurry")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(CSTheme.destructive.opacity(0.85))
                            .clipShape(Capsule())

                            Spacer()
                        }
                        .padding(6)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Date & Size info
                HStack {
                    Text(item.formattedDate)
                        .font(.system(size: 11))
                        .foregroundStyle(CSTheme.textSecondary)

                    Spacer()

                    Text(item.formattedSize)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(CSTheme.accentPink)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
            .csCard()
            .overlay(
                RoundedRectangle(cornerRadius: CSTheme.cardRadius)
                    .stroke(item.isSelected ? CSTheme.accentPink : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.checkmark")
                .font(.system(size: 50))
                .foregroundStyle(CSTheme.accentGreen)

            Text("No Blurry Photos Found")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(CSTheme.textPrimary)

            Text("All analyzed photos have sufficient sharpness.")
                .font(.system(size: 15))
                .foregroundStyle(CSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
