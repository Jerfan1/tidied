import SwiftUI
import PhotosUI

struct MonthSwipeView: View {
    let month: PhotoMonth
    let onDismiss: () -> Void
    let onProfile: () -> Void
    
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var currentThumbnail: UIImage?
    @State private var currentLivePhoto: PHLivePhoto?
    @State private var isVideoPlayerPresented = false
    @State private var isZoomPresented = false // For separate zoom overlay
    
    // Preloading cache
    @State private var thumbnailCache: [Int: UIImage] = [:]
    
    // Action tracking
    @State private var actions: [SwipeAction] = []
    @State private var keptCount = 0
    @State private var deleteCount = 0
    @State private var favouriteCount = 0
    @State private var isFinished = false
    
    // Addiction engine
    @StateObject private var addiction = AddictionEngine.shared
    
    private let swipeThreshold: CGFloat = 100
    private let verticalSwipeThreshold: CGFloat = 80
    private let photoService = PhotoLibraryService.shared
    private let monthService = PhotoMonthService.shared
    private let stats = StatsService.shared
    
    private var currentAsset: PHAsset? {
        guard currentIndex < month.assets.count else { return nil }
        return month.assets[currentIndex]
    }
    
    private var progress: Double {
        guard month.totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(month.totalCount)
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            if isFinished {
                MonthCompletionView(
                    month: month,
                    keptCount: keptCount,
                    deleteCount: deleteCount,
                    favouriteCount: favouriteCount,
                    onConfirmDelete: executeDeletes,
                    onCancel: onDismiss,
                    onMarkComplete: markMonthDone
                )
            } else {
                mainInterface
            }
            
            // Zoom Overlay
            if isZoomPresented, let image = currentThumbnail {
                ZoomOverlayView(image: image, isPresented: $isZoomPresented)
                    .transition(.opacity)
            }
            
            // Milestone toast overlay
            if addiction.showMilestone, let milestone = addiction.milestoneType {
                VStack {
                    MilestoneToast(milestone: milestone)
                        .padding(.top, 100)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .onAppear {
            print("📸 MonthSwipeView appeared")
            print("📸 Month: \(month.displayName)")
            print("📸 Total assets: \(month.assets.count)")
            
            // Resume from saved position
            let savedPosition = monthService.getSavedPosition(for: month)
            if savedPosition > 0 && savedPosition < month.assets.count {
                currentIndex = savedPosition
                print("📸 Resuming from position: \(savedPosition)")
            }
            
            // Load pending actions (keep/delete decisions from previous session)
            let savedActions = monthService.loadPendingActions(for: month)
            if !savedActions.isEmpty {
                actions = savedActions
                // Restore counts
                keptCount = savedActions.filter { $0.type == .kept }.count
                deleteCount = savedActions.filter { $0.type == .deleted }.count
                favouriteCount = savedActions.filter { $0.type == .favourited }.count
                print("📸 Restored \(savedActions.count) pending actions")
            }
            
            addiction.startSession()
            preloadInitialImages()
        }
        .fullScreenCover(isPresented: $isVideoPlayerPresented) {
            if let asset = currentAsset {
                VideoPlayerView(asset: asset, isPresented: $isVideoPlayerPresented)
            }
        }
    }
    
    private var mainInterface: some View {
        VStack(spacing: 0) {
            // Top navigation
            topNavigation
            Spacer().frame(height: Spacing.md)
            
            // Card area
            cardArea
            
            Spacer().frame(height: Spacing.lg)
            
            // Bottom actions
            bottomActions
            Spacer().frame(height: Spacing.xl)
        }
    }
    
    private var topNavigation: some View {
        VStack(spacing: 8) {
            HStack {
                // Back button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.roseLight)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Fire indicator (when swiping fast)
                FireIndicator(isActive: addiction.isOnFire)
                
                // Live storage counter
                if addiction.sessionStorageFreed > 0 {
                    LiveStorageCounter(megabytesFreed: addiction.sessionStorageFreed)
                }
                
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.roseLight, lineWidth: 3)
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.rose, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.rose)
                }
            }
            
            // Month name + counter (below)
            HStack {
                Text(month.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("•")
                    .foregroundColor(.textTertiary)
                
                Text("\(currentIndex + 1)/\(month.totalCount)")
                    .font(.system(size: 13))
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }
    
    private var cardArea: some View {
        ZStack {
            // Invisible touch area - allows swiping anywhere
            Color.clear
                .contentShape(Rectangle())
            
            if month.assets.isEmpty {
                // No photos in this month
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.textTertiary)
                    Text("No photos in this month")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
            } else if let asset = currentAsset {
                let item = MediaItem(asset: asset)
                
                ZStack {
                    MediaCardView(
                        item: item,
                        thumbnail: currentThumbnail,
                        livePhoto: currentLivePhoto,
                        isVideoPlaying: $isVideoPlayerPresented
                    )
                    .onTapGesture(count: 2) {
                        withAnimation { isZoomPresented = true }
                    }
                    
                    // KEEP label (right swipe)
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                            Text("KEEP")
                                .font(.system(size: 28, weight: .bold))
                        }
                        .foregroundColor(.keepGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.95))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.keepGreen, lineWidth: 3))
                        .rotationEffect(.degrees(-12))
                        .opacity(keepLabelOpacity)
                        .offset(x: -15, y: -50)
                        
                        // DELETE label (left swipe)
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24, weight: .bold))
                            Text("NOPE")
                                .font(.system(size: 28, weight: .bold))
                        }
                        .foregroundColor(.rose)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.95))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.rose, lineWidth: 3))
                        .rotationEffect(.degrees(12))
                        .opacity(deleteLabelOpacity)
                        .offset(x: 15, y: -50)
                        
                        // FAVOURITE label (up swipe)
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 22, weight: .bold))
                            Text("FAV")
                                .font(.system(size: 24, weight: .bold))
                        }
                        .foregroundColor(.favouriteGold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.95))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.favouriteGold, lineWidth: 3))
                        .opacity(favouriteLabelOpacity)
                        .offset(y: 60)
                }
                .padding(.horizontal, Spacing.lg)
                .offset(dragOffset)
                .rotationEffect(.degrees(rotationAngle))
            }
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle()) // Makes entire area swipeable
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    handleSwipeEnd(translation: value.translation)
                }
        )
    }
    
    private var canUndo: Bool {
        currentIndex > 0 && !actions.isEmpty
    }
    
    private var bottomActions: some View {
        HStack(spacing: 12) {
            // UNDO button (small, on the left)
            Button(action: undoLast) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(canUndo ? .textSecondary : .textTertiary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.divider)
                    )
            }
            .disabled(!canUndo)
            .opacity(canUndo ? 1 : 0.4)
            
            Spacer()
            
            // DELETE pill button
            Button(action: deleteCurrent) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                    Text("Delete")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.rose)
                .fixedSize()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.roseLight)
                )
            }
            
            // FAVOURITE button (icon only)
            Button(action: favouriteCurrent) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.favouriteGold)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.favouriteGold.opacity(0.15))
                    )
            }
            
            // KEEP pill button
            Button(action: keepCurrent) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                    Text("Keep")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.keepGreen)
                .fixedSize()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.keepGreen.opacity(0.15))
                )
            }
            
            Spacer()
            
            // Invisible spacer to balance the undo button
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, Spacing.md)
    }
    
// MARK: - Swipe Opacity Calculations

private var keepLabelOpacity: Double {
    guard dragOffset.width > 25 else { return 0 }
    return min(Double(dragOffset.width - 25) / 75.0, 1.0)
}

private var deleteLabelOpacity: Double {
    guard dragOffset.width < -25 else { return 0 }
    return min(Double(abs(dragOffset.width) - 25) / 75.0, 1.0)
}

private var favouriteLabelOpacity: Double {
    guard dragOffset.height < -25 else { return 0 }
    return min(Double(abs(dragOffset.height) - 25) / 55.0, 1.0)
}

private var rotationAngle: Double {
    Double(dragOffset.width) / 500.0 * 12.0
}
    
    // MARK: - Actions
    
    private func handleSwipeEnd(translation: CGSize) {
        // Check for vertical swipe first (favourite)
        if translation.height < -verticalSwipeThreshold && abs(translation.width) < swipeThreshold {
            favouriteCurrent()
            return
        }
        
        // Horizontal swipes
        if translation.width > swipeThreshold {
            keepCurrent()
        } else if translation.width < -swipeThreshold {
            deleteCurrent()
        } else {
            // Reset position
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
        }
    }
    
    private func keepCurrent() {
        guard let asset = currentAsset else { return }
        
        actions.append(SwipeAction(index: currentIndex, asset: asset, type: .kept))
        keptCount += 1
        
        // Track in addiction engine
        addiction.recordSwipe(isDelete: false)
        
        // Save pending actions so they persist if user leaves
        monthService.savePendingActions(actions, for: month)
        
        HapticManager.shared.impact(.light)
        animateToNextCard(direction: .right)
    }
    
    private func deleteCurrent() {
        guard let asset = currentAsset else { return }
        
        actions.append(SwipeAction(index: currentIndex, asset: asset, type: .deleted))
        deleteCount += 1
        
        // Track in addiction engine
        addiction.recordSwipe(isDelete: true)
        
        // Save pending actions so they persist if user leaves
        monthService.savePendingActions(actions, for: month)
        
        HapticManager.shared.impact(.medium)
        animateToNextCard(direction: .left)
    }
    
    private func favouriteCurrent() {
        guard let asset = currentAsset else { return }
        
        // Mark as favourite in Photos
        Task {
            try? await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest(for: asset)
                request.isFavorite = true
            }
        }
        
        actions.append(SwipeAction(index: currentIndex, asset: asset, type: .favourited))
        favouriteCount += 1
        keptCount += 1  // Favourites are also kept
        
        // Save pending actions so they persist if user leaves
        monthService.savePendingActions(actions, for: month)
        
        HapticManager.shared.notification(.success)
        animateToNextCard(direction: .up)
    }
    
    private func undoLast() {
        guard canUndo, let lastAction = actions.last else { return }
        
        // Remove the last action
        actions.removeLast()
        
        // Update counts
        switch lastAction.type {
        case .kept:
            keptCount -= 1
        case .deleted:
            deleteCount -= 1
        case .favourited:
            favouriteCount -= 1
            keptCount -= 1  // Favourites also counted as kept
        }
        
        // Go back one index
        currentIndex -= 1
        
        // Save updated pending actions
        monthService.savePendingActions(actions, for: month)
        
        // Save updated position
        monthService.saveCurrentPosition(for: month, index: currentIndex)
        
        // Load the previous media
        if let cached = thumbnailCache[currentIndex] {
            currentThumbnail = cached
        }
        loadCurrentMedia()
        
        HapticManager.shared.impact(.light)
    }
    
    private func animateToNextCard(direction: SwipeDirection) {
        // First, briefly show the label by setting dragOffset to trigger opacity
        let labelOffset: CGSize
        let flyOutOffset: CGSize
        
        switch direction {
        case .right:
            labelOffset = CGSize(width: 100, height: 0)
            flyOutOffset = CGSize(width: 500, height: 0)
        case .left:
            labelOffset = CGSize(width: -100, height: 0)
            flyOutOffset = CGSize(width: -500, height: 0)
        case .up:
            labelOffset = CGSize(width: 0, height: -100)
            flyOutOffset = CGSize(width: 0, height: -500)
        }
        
        // If dragOffset is near zero (button press), show label first
        if abs(dragOffset.width) < 50 && abs(dragOffset.height) < 50 {
            withAnimation(.easeOut(duration: 0.1)) {
                dragOffset = labelOffset
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) {
                    dragOffset = flyOutOffset
                }
            }
        } else {
            // Already swiping, just fly out
            withAnimation(.easeOut(duration: 0.25)) {
                dragOffset = flyOutOffset
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dragOffset = .zero
            currentIndex += 1
            
            // Save progress after EVERY swipe
            monthService.saveCurrentPosition(for: month, index: currentIndex)
            
            if currentIndex >= month.totalCount {
                withAnimation {
                    isFinished = true
                }
            } else {
                // Use cached thumbnail if available for instant display
                if let cached = thumbnailCache[currentIndex] {
                    currentThumbnail = cached
                }
                loadCurrentMedia()
                cleanupOldCache()
            }
        }
    }
    
    private func loadCurrentMedia() {
        guard let asset = currentAsset else { return }
        
        currentLivePhoto = nil
        let size = CGSize(width: 800, height: 800)
        
        // Check cache first
        if let cached = thumbnailCache[currentIndex] {
            currentThumbnail = cached
        }
        
        Task {
            // Load current if not cached
            if thumbnailCache[currentIndex] == nil {
                let thumbnail = await photoService.loadThumbnail(for: asset, targetSize: size)
                await MainActor.run {
                    currentThumbnail = thumbnail
                    thumbnailCache[currentIndex] = thumbnail
                }
            }
            
            // Preload next 3 images
            await preloadUpcoming(from: currentIndex + 1, count: 3, size: size)
            
            // Load live photo if applicable
            let item = MediaItem(asset: asset)
            if item.mediaType == .livePhoto {
                let livePhoto = await photoService.loadLivePhoto(for: asset, targetSize: size)
                await MainActor.run {
                    currentLivePhoto = livePhoto
                }
            }
        }
    }
    
    private func preloadUpcoming(from startIndex: Int, count: Int, size: CGSize) async {
        for i in startIndex..<min(startIndex + count, month.assets.count) {
            // Skip if already cached
            if thumbnailCache[i] != nil { continue }
            
            let asset = month.assets[i]
            let thumbnail = await photoService.loadThumbnail(for: asset, targetSize: size)
            await MainActor.run {
                thumbnailCache[i] = thumbnail
            }
        }
    }
    
    private func preloadInitialImages() {
        let size = CGSize(width: 800, height: 800)
        Task {
            // Preload from current position (handles both fresh start and resume)
            await preloadUpcoming(from: currentIndex, count: 3, size: size)
            
            // Set the current image
            if let current = thumbnailCache[currentIndex] {
                await MainActor.run {
                    currentThumbnail = current
                }
            }
        }
    }
    
    private func cleanupOldCache() {
        // Keep only nearby images in cache (current -2 to current +5)
        let keepRange = max(0, currentIndex - 2)...min(month.assets.count - 1, currentIndex + 5)
        thumbnailCache = thumbnailCache.filter { keepRange.contains($0.key) }
    }
    
    private func markMonthDone() {
        print("✅ Marking month as complete: \(month.displayName)")
        var updatedMonth = month
        updatedMonth.reviewedCount = month.totalCount
        monthService.markMonthCompleted(updatedMonth)
        
        // Save this month's name for the paywall message
        UserDefaults.standard.set(month.displayName, forKey: "tidied_last_completed_month")
        
        // Clear pending actions since month is done
        monthService.clearPendingActions(for: month)
        
        // Update stats
        stats.recordSession(
            deleted: deleteCount, 
            reviewed: actions.count,
            favourited: favouriteCount
        )
        stats.recordMonthCompleted()
    }
    
    private func executeDeletes() async throws {
        let assetsToDelete = actions
            .filter { $0.type == .deleted }
            .map { $0.asset }
        
        if !assetsToDelete.isEmpty {
            try await photoService.deleteAssets(assetsToDelete)
        }
    }
    
    enum SwipeDirection {
        case left
        case right
        case up
    }
}

// MARK: - Month Completion View

struct MonthCompletionView: View {
    let month: PhotoMonth
    let keptCount: Int
    let deleteCount: Int
    let favouriteCount: Int
    let onConfirmDelete: () async throws -> Void
    let onCancel: () -> Void
    let onMarkComplete: () -> Void
    
    @State private var isDeleting = false
    @State private var showSuccess = false
    @State private var animateIn = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            if showSuccess {
                successView
            } else {
                reviewView
            }
        }
        .onAppear {
            // Mark month as complete as soon as review is finished
            onMarkComplete()
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }
    
    private var reviewView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Checkmark icon
            ZStack {
                Circle()
                    .fill(Color.roseLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.rose)
            }
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)
            
            // Title
            VStack(spacing: Spacing.sm) {
                Text("\(month.displayName)")
                    .font(.titleMedium)
                    .foregroundColor(.rose)
                
                Text("complete!")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
            }
            .opacity(animateIn ? 1 : 0)
            
            // Stats in pill style
            HStack(spacing: Spacing.md) {
                StatPill(count: deleteCount, label: "delete", color: .rose)
                StatPill(count: keptCount, label: "keep", color: .keepGreen)
                if favouriteCount > 0 {
                    StatPill(count: favouriteCount, label: "fav", color: .favouriteGold)
                }
            }
            .padding(.vertical, Spacing.lg)
            .opacity(animateIn ? 1 : 0)
            
            Spacer()
            
            // Actions
            VStack(spacing: Spacing.md) {
                if deleteCount > 0 {
                    Button(action: performDeletion) {
                        HStack(spacing: 8) {
                            if isDeleting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14))
                                Text("Delete \(deleteCount) photos")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.rose)
                        .clipShape(Capsule())
                    }
                    .disabled(isDeleting)
                    .padding(.horizontal, Spacing.lg)
                }
                
                Button(action: onCancel) {
                    Text("Back to months")
                        .font(.labelLarge)
                        .foregroundColor(.textSecondary)
                        .padding(.vertical, 14)
                }
                .disabled(isDeleting)
            }
            .opacity(animateIn ? 1 : 0)
            
            Spacer().frame(height: Spacing.xxl)
        }
    }
    
    private var successView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            ZStack {
                // Celebration rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.rose.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                        .frame(width: CGFloat(120 + i * 30), height: CGFloat(120 + i * 30))
                }
                
                Circle()
                    .fill(Color.roseLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.rose)
            }
            .scaleEffect(showSuccess ? 1 : 0.5)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSuccess)
            
            VStack(spacing: Spacing.md) {
                Text("\(month.displayName)")
                    .font(.titleMedium)
                    .foregroundColor(.rose)
                
                Text("all done!")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
                
                if deleteCount > 0 {
                    Text("~\(deleteCount * 3) MB freed")
                        .font(.labelLarge)
                        .foregroundColor(.rose)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.roseLight)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            Button(action: onCancel) {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.rose)
                .clipShape(Capsule())
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
    }
    
    private func performDeletion() {
        isDeleting = true
        Task {
            do {
                try await onConfirmDelete()
                await MainActor.run {
                    isDeleting = false
                    showConfetti = true
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSuccess = true
                    }
                    HapticManager.shared.notification(.success)
                    
                    // Request App Store review at win moment (after confetti)
                    ReviewManager.shared.requestReviewIfAppropriate(deletedCount: deleteCount)
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    HapticManager.shared.notification(.error)
                }
            }
        }
    }
}

// MARK: - Stat Pill Component
struct StatPill: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .frame(width: 70)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

