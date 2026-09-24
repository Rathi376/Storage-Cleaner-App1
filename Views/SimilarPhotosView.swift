import SwiftUI

/// Similar Photos view showing grouped duplicate/similar photos.
struct SimilarPhotosView: View {
    @State var viewModel: PhotoScannerViewModel
    @State private var showReview = false

    var body: some View {
        Group {
            if viewModel.result.groups.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary bar
                        summaryBar

                        // Groups
                        ForEach(viewModel.result.groups) { group in
                            photoGroupCard(group)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
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
                        showReview = true
                    }
                    .foregroundStyle(CSTheme.accentCyan)
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationDestination(isPresented: $showReview) {
            ReviewView(viewModel: ReviewViewModel(payload: viewModel.buildReviewPayload()))
        }
    }

    // MARK: - Summary

    private var summaryBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.totalSelectedCount) selected")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CSTheme.textPrimary)
                Text(viewModel.formattedSelectedSize)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CSTheme.accentPurple)
            }
            Spacer()
            if viewModel.totalSelectedCount > 0 {
                Button {
                    showReview = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Review & Delete")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(CSTheme.deleteGradient)
                    .clipShape(Capsule())
                }
            }
        }
        .csCard()
    }

    // MARK: - Group Card

    private func photoGroupCard(_ group: PhotoGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Group of \(group.items.count)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CSTheme.textPrimary)
                Spacer()
                HStack(spacing: 12) {
                    Button("Select All") {
                        viewModel.selectAllInGroup(groupId: group.id)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CSTheme.accentCyan)

                    Button("Deselect") {
                        viewModel.deselectAllInGroup(groupId: group.id)
                    }
                    .font(.system(size: 13, weight: .medium))
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
            viewModel.toggleSelection(groupId: groupId, itemId: item.id)
        } label: {
            ZStack(alignment: .topLeading) {
                // Image
                if let image = viewModel.thumbnailCache[item.id] {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minHeight: 100)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(CSTheme.surfaceLight)
                        .frame(minHeight: 100)
                        .overlay {
                            ProgressView()
                                .tint(CSTheme.textTertiary)
                        }
                }

                // Selection overlay
                VStack {
                    HStack {
                        if item.isRecommended {
                            Text("Best")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(CSTheme.accentGreen)
                                .clipShape(Capsule())
                        }
                        Spacer()
                        if !item.isRecommended {
                            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(item.isSelected ? CSTheme.accentPurple : .white.opacity(0.6))
                                .shadow(radius: 2)
                        }
                    }
                    Spacer()
                    HStack {
                        Text(item.formattedSize)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                        Spacer()
                    }
                }
                .padding(6)

                // Selection border
                if item.isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(CSTheme.accentPurple, lineWidth: 3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 50))
                .foregroundStyle(CSTheme.textTertiary)

            Text("No Similar Photos Found")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(CSTheme.textPrimary)

            Text("Your photo library looks clean! No duplicate or similar photos were detected.")
                .font(.system(size: 15))
                .foregroundStyle(CSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
