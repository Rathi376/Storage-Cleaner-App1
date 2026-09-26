import SwiftUI
import Photos

/// Interactive iOS-native Swipe Mode (Card Deck) for quickly reviewing duplicate and similar photos.
/// Swipe Left -> Mark for Deletion (Red)
/// Swipe Right -> Keep / Save (Green)
struct PhotoSwipeDeckView: View {
    let title: String
    @Binding var items: [PhotoItem]
    var recommendedItem: PhotoItem?
    var onSelectionChanged: ((String, Bool) -> Void)?
    var onFinish: () -> Void

    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var thumbnailCache: [String: UIImage] = [:]
    @State private var history: [(index: Int, previousSelected: Bool)] = []
    @State private var showCompareBest = false

    private let dragThreshold: CGFloat = 110

    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation & Stats Bar
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer(minLength: 8)

            // Center Card Deck
            if currentIndex < items.count {
                ZStack {
                    // Next card underneath (peek effect)
                    if currentIndex + 1 < items.count {
                        cardView(item: items[currentIndex + 1], isCurrent: false)
                            .scaleEffect(0.94)
                            .offset(y: 14)
                            .opacity(0.65)
                    }

                    // Active draggable card
                    cardView(item: items[currentIndex], isCurrent: true)
                        .offset(x: dragOffset.width, y: dragOffset.height * 0.2)
                        .rotationEffect(.degrees(Double(dragOffset.width / 18)))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    handleDragEnd(value: value)
                                }
                        )
                }
                .padding(.horizontal, 20)
                .frame(maxHeight: .infinity)
            } else {
                completedDeckView
            }

            Spacer(minLength: 12)

            // Bottom Action Controls
            if currentIndex < items.count {
                controlBar
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            preloadThumbnails(around: currentIndex)
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Swipe Mode")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(CSTheme.accentBlue)

                    Text(currentIndex < items.count ? "Photo \(currentIndex + 1) of \(items.count)" : "All Reviewed")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)
                }

                Spacer()

                // Recommended photo comparison pill (if exists)
                if recommendedItem != nil {
                    Button {
                        CSTheme.hapticImpact(.light)
                        showCompareBest.toggle()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "photo.fill.on.rectangle.fill")
                                .font(.system(size: 11))
                            Text(showCompareBest ? "Hide Best" : "View Best")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(CSTheme.accentGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(CSTheme.accentGreen.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }

            // Progress Bar
            ProgressView(value: Double(min(currentIndex, items.count)), total: Double(max(items.count, 1)))
                .tint(CSTheme.accentBlue)

            // Best Photo Reference Drawer (when toggled)
            if showCompareBest, let best = recommendedItem {
                bestPhotoComparisonBanner(best: best)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .csCard(padding: 12)
    }

    private func bestPhotoComparisonBanner(best: PhotoItem) -> some View {
        HStack(spacing: 12) {
            if let img = thumbnailCache[best.id] {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(CSTheme.surfaceLight)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onAppear { loadThumbnail(for: best.id) }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                    Text("Recommended Best Photo")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CSTheme.textPrimary)
                }
                Text("\(best.formattedSize) • \(best.dimensionsString)")
                    .font(.system(size: 11))
                    .foregroundStyle(CSTheme.textSecondary)
            }

            Spacer()

            Text("KEEP")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(CSTheme.accentGreen)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(CSTheme.accentGreen.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(8)
        .background(CSTheme.surfaceLight.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Card View

    private func cardView(item: PhotoItem, isCurrent: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            // Main Photo
            ZStack {
                Color(uiColor: .secondarySystemGroupedBackground)

                if let image = thumbnailCache[item.id] {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(CSTheme.accentBlue)
                        Text("Loading photo…")
                            .font(.system(size: 13))
                            .foregroundStyle(CSTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        loadThumbnail(for: item.id)
                    }
                }
            }

            // Swipe Direction Badges
            if isCurrent {
                // DELETE stamp (appears when dragging left)
                if dragOffset.width < -20 {
                    Text("DELETE")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(CSTheme.accentRed)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(CSTheme.accentRed, lineWidth: 3)
                        )
                        .rotationEffect(.degrees(15))
                        .opacity(Double(min(abs(dragOffset.width) / dragThreshold, 1.0)))
                        .padding(20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }

                // KEEP stamp (appears when dragging right)
                if dragOffset.width > 20 {
                    Text("KEEP")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(CSTheme.accentGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(CSTheme.accentGreen, lineWidth: 3)
                        )
                        .rotationEffect(.degrees(-15))
                        .opacity(Double(min(dragOffset.width / dragThreshold, 1.0)))
                        .padding(20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }

            // Photo Metadata Overlay (Bottom bar inside card)
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.formattedSize)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(item.formattedDate)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    Text(item.dimensionsString)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.4))
                        .clipShape(Capsule())
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CSTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 24) {
            // Undo Button
            Button {
                undoLastSwipe()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(history.isEmpty ? CSTheme.textTertiary : CSTheme.accentYellow)
                    .frame(width: 48, height: 48)
                    .background(CSTheme.cardBackground)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(CSTheme.cardBorder, lineWidth: 1))
            }
            .disabled(history.isEmpty)
            .buttonStyle(CSBounceButtonStyle())

            // Swipe Left / Delete Action Button
            Button {
                swipeLeft()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Delete")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(CSTheme.deleteGradient)
                .clipShape(Capsule())
                .shadow(color: Color.red.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(CSBounceButtonStyle())

            // Swipe Right / Keep Action Button
            Button {
                swipeRight()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .heavy))
                    Text("Keep")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color(red: 0.1, green: 0.75, blue: 0.45)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.green.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(CSBounceButtonStyle())
        }
    }

    // MARK: - Completed Deck View

    private var completedDeckView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(CSTheme.accentGreen.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(CSTheme.accentGreen)
            }

            VStack(spacing: 6) {
                Text("Deck Review Complete")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(CSTheme.textPrimary)

                let selected = items.filter(\.isSelected)
                let selectedBytes = selected.reduce(0) { $0 + $1.estimatedBytes }

                Text("\(selected.count) of \(items.count) photos marked for deletion (\(ByteFormatter.string(from: selectedBytes))).")
                    .font(.system(size: 14))
                    .foregroundStyle(CSTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    CSTheme.hapticImpact(.medium)
                    onFinish()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                        Text("Done")
                    }
                    .csPrimaryButton()
                }
                .buttonStyle(CSBounceButtonStyle())

                if !history.isEmpty {
                    Button {
                        undoLastSwipe()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo Last Decision")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CSTheme.accentBlue)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Drag & Swipe Logic

    private func handleDragEnd(value: DragGesture.Value) {
        if value.translation.width < -dragThreshold {
            swipeLeft()
        } else if value.translation.width > dragThreshold {
            swipeRight()
        } else {
            // Return to center
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
        }
    }

    private func swipeLeft() {
        // DELETE: mark as selected
        guard currentIndex < items.count else { return }
        CSTheme.hapticNotification(.warning)

        let targetIndex = currentIndex
        let previousSelected = items[targetIndex].isSelected

        withAnimation(.easeOut(duration: 0.22)) {
            dragOffset = CGSize(width: -500, height: 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            items[targetIndex].isSelected = true
            onSelectionChanged?(items[targetIndex].id, true)
            history.append((index: targetIndex, previousSelected: previousSelected))
            currentIndex += 1
            dragOffset = .zero
            preloadThumbnails(around: currentIndex)
        }
    }

    private func swipeRight() {
        // KEEP: mark as NOT selected
        guard currentIndex < items.count else { return }
        CSTheme.hapticImpact(.medium)

        let targetIndex = currentIndex
        let previousSelected = items[targetIndex].isSelected

        withAnimation(.easeOut(duration: 0.22)) {
            dragOffset = CGSize(width: 500, height: 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            items[targetIndex].isSelected = false
            onSelectionChanged?(items[targetIndex].id, false)
            history.append((index: targetIndex, previousSelected: previousSelected))
            currentIndex += 1
            dragOffset = .zero
            preloadThumbnails(around: currentIndex)
        }
    }

    private func undoLastSwipe() {
        guard let last = history.popLast() else { return }
        CSTheme.hapticImpact(.light)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            currentIndex = last.index
            items[last.index].isSelected = last.previousSelected
            onSelectionChanged?(items[last.index].id, last.previousSelected)
            dragOffset = .zero
        }
    }

    // MARK: - Thumbnail Preloading

    private func loadThumbnail(for id: String) {
        guard thumbnailCache[id] == nil else { return }
        Task {
            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
            guard let asset else { return }
            let targetSize = CGSize(width: 600, height: 600)
            if let image = await PhotoLibraryService.shared.loadThumbnail(for: asset, targetSize: targetSize) {
                thumbnailCache[id] = image
            }
        }
    }

    private func preloadThumbnails(around index: Int) {
        for i in index..<min(index + 3, items.count) {
            loadThumbnail(for: items[i].id)
        }
        if let best = recommendedItem {
            loadThumbnail(for: best.id)
        }
    }
}
