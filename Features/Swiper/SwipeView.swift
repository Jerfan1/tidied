import SwiftUI
import PhotosUI

struct SwipeView: View {
    let onDismiss: () -> Void
    let onProfile: () -> Void
    
    @State private var viewModel = SwipeViewModel()
    @State private var isVideoPlayerPresented = false
    
    private let swipeThreshold: CGFloat = 100
    private let photoService = PhotoLibraryService.shared
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.hasNoPhotos {
                EmptyLibraryView(
                    onOpenSettings: openSettings,
                    onSelectPhotos: presentLimitedLibraryPicker,
                    onRetry: { Task { await viewModel.reloadMedia() } },
                    isLimitedAccess: photoService.checkCurrentStatus() == .limited
                )
            } else if viewModel.isFinished {
                DeletionSummaryView(
                    keptCount: viewModel.keptCount,
                    deleteCount: viewModel.deleteCount,
                    onConfirmDelete: { try await viewModel.executeDeletes() },
                    onCancel: { viewModel.cancelAndReset() }
                )
            } else {
                mainInterface
            }
        }
        .fullScreenCover(isPresented: $isVideoPlayerPresented) {
            if let item = viewModel.currentItem {
                VideoPlayerView(asset: item.asset, isPresented: $isVideoPlayerPresented)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(.sage)
            Text("Loading your photos...")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
        }
    }
    
    private var mainInterface: some View {
        VStack(spacing: 0) {
            // Top navigation - clean like Swipewipe
            topNavigation
            
            Spacer().frame(height: Spacing.md)
            
            // Card area
            cardArea
            
            Spacer().frame(height: Spacing.lg)
            
            // Bottom action labels
            bottomActions
            
            Spacer().frame(height: Spacing.xl)
        }
    }
    
    private var topNavigation: some View {
        HStack {
            // Back button
            Button(action: onDismiss) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    if let item = viewModel.currentItem {
                        Text(item.monthYearText)
                            .font(.labelMedium)
                    }
                }
                .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            // Counter
            Text("\(viewModel.currentIndex + 1)/\(viewModel.totalCount)")
                .font(.counter)
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            // Profile button
            Button(action: onProfile) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }
    
    private var cardArea: some View {
        ZStack {
            // Media card
            if let item = viewModel.currentItem {
                ZStack {
                    MediaCardView(
                        item: item,
                        thumbnail: viewModel.currentThumbnail,
                        livePhoto: viewModel.currentLivePhoto,
                        isVideoPlaying: $isVideoPlayerPresented
                    )
                    
                    // KEEP label overlay
                    Text("KEEP")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.keepGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .stroke(Color.keepGreen, lineWidth: 3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                        .rotationEffect(.degrees(-15))
                        .opacity(keepLabelOpacity)
                        .offset(x: -20, y: -40)
                    
                    // DELETE label overlay
                    Text("DELETE")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.deleteRed)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .stroke(Color.deleteRed, lineWidth: 3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                        .rotationEffect(.degrees(15))
                        .opacity(deleteLabelOpacity)
                        .offset(x: 20, y: -40)
                }
                .padding(.horizontal, Spacing.lg)
                .offset(viewModel.dragOffset)
                .rotationEffect(.degrees(rotationAngle))
                .gesture(
                    DragGesture()
                        .onChanged { viewModel.dragOffset = $0.translation }
                        .onEnded { handleSwipeEnd(translation: $0.translation) }
                )
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var bottomActions: some View {
        HStack(spacing: Spacing.xxl) {
            // Undo (small, subtle)
            Button(action: { viewModel.undo() }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textTertiary)
                    .frame(width: 40, height: 40)
                    .background(Color.divider)
                    .clipShape(Circle())
            }
            .disabled(!viewModel.canUndo)
            .opacity(viewModel.canUndo ? 1 : 0.3)
            
            // DELETE label
            Button(action: { viewModel.deleteCurrent() }) {
                Text("DELETE")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.deleteRed)
                    .frame(width: 90)
            }
            
            // KEEP label
            Button(action: { viewModel.keepCurrent() }) {
                Text("KEEP")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.keepGreen)
                    .frame(width: 90)
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    private func presentLimitedLibraryPicker() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: rootViewController) { _ in
            Task { await viewModel.reloadMedia() }
        }
    }
    
    private var deleteIndicatorOpacity: Double {
        guard viewModel.dragOffset.width < 0 else { return 0 }
        return min(abs(viewModel.dragOffset.width) / swipeThreshold, 1.0)
    }
    
    private var keepIndicatorOpacity: Double {
        guard viewModel.dragOffset.width > 0 else { return 0 }
        return min(viewModel.dragOffset.width / swipeThreshold, 1.0)
    }
    
    private var keepLabelOpacity: Double {
        guard viewModel.dragOffset.width > 25 else { return 0 }
        return min((viewModel.dragOffset.width - 25.0) / 75.0, 1.0)
    }
    
    private var deleteLabelOpacity: Double {
        guard viewModel.dragOffset.width < -25 else { return 0 }
        return min((abs(viewModel.dragOffset.width) - 25.0) / 75.0, 1.0)
    }
    
    private var rotationAngle: Double {
        (viewModel.dragOffset.width / 500) * 15
    }
    
    private func handleSwipeEnd(translation: CGSize) {
        if translation.width > swipeThreshold {
            viewModel.keepCurrent()
        } else if translation.width < -swipeThreshold {
            viewModel.deleteCurrent()
        } else {
            viewModel.resetPosition()
        }
    }
}
