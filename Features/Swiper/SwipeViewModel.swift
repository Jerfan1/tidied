import SwiftUI
import Photos
import Observation

@MainActor
@Observable
class SwipeViewModel {
    // MARK: - State
    var currentIndex: Int = 0
    var currentItem: MediaItem?
    var currentThumbnail: UIImage?
    var currentLivePhoto: PHLivePhoto?
    var dragOffset: CGSize = .zero
    var canUndo: Bool = false
    var isFinished: Bool = false
    var isLoading: Bool = true
    var hasNoPhotos: Bool = false

    // MARK: - Private State
    private var allAssets: PHFetchResult<PHAsset>?
    private var assetsToDelete: [PHAsset] = []
    private var undoStack: [SwipeAction] = []
    private let photoService = PhotoLibraryService.shared
    private let progressTracker = ProgressTracker.shared
    private let hapticManager = HapticManager.shared
    private let statsService = StatsService.shared

    // MARK: - Computed Properties
    var totalCount: Int {
        allAssets?.count ?? 0
    }

    var deleteCount: Int {
        assetsToDelete.count
    }

    var keptCount: Int {
        currentIndex - deleteCount
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }

    // MARK: - Initialization
    init() {
        Task {
            await loadMedia()
        }
    }

    // MARK: - Media Loading
    func loadMedia() async {
        isLoading = true
        allAssets = photoService.fetchAllMedia()

        // Check if no photos available
        if totalCount == 0 {
            hasNoPhotos = true
            isLoading = false
            return
        }
        
        hasNoPhotos = false

        // Resume from saved progress
        let savedIndex = progressTracker.lastSwipedIndex
        if savedIndex > 0 && savedIndex < totalCount {
            currentIndex = savedIndex
        }

        await loadCurrentItem()
        isLoading = false
    }
    
    func reloadMedia() async {
        currentIndex = 0
        isFinished = false
        await loadMedia()
    }

    func loadCurrentItem() async {
        guard let assets = allAssets, currentIndex < assets.count else {
            isFinished = true
            return
        }

        let asset = assets.object(at: currentIndex)
        let item = MediaItem(asset: asset)
        currentItem = item

        // Load thumbnail
        let screenSize = await UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.size ?? CGSize(width: 390, height: 844)
        let targetSize = CGSize(width: screenSize.width * 2, height: screenSize.height * 2)

        currentThumbnail = await photoService.loadThumbnail(for: asset, targetSize: targetSize)

        // If live photo, load it
        if item.mediaType == .livePhoto {
            currentLivePhoto = await photoService.loadLivePhoto(for: asset, targetSize: targetSize)
        } else {
            currentLivePhoto = nil
        }

        // Prefetch next items
        await prefetchNextItems()
    }

    private func prefetchNextItems() async {
        guard let assets = allAssets else { return }

        let screenSize = await UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.size ?? CGSize(width: 390, height: 844)
        let targetSize = CGSize(width: screenSize.width * 2, height: screenSize.height * 2)

        // Prefetch next 2-3 items
        for offset in 1...3 {
            let nextIndex = currentIndex + offset
            guard nextIndex < assets.count else { break }

            let nextAsset = assets.object(at: nextIndex)
            _ = await photoService.loadThumbnail(for: nextAsset, targetSize: targetSize)
        }
    }

    // MARK: - Swipe Actions
    func keepCurrent() {
        guard let item = currentItem else { return }

        // Record action
        let action = SwipeAction(index: currentIndex, asset: item.asset, type: .kept)
        undoStack = [action] // Only keep last action
        canUndo = true
        
        // Track stats
        statsService.recordSwipe(kept: true)

        // Animate off screen
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: 500, height: 0)
        }

        // Haptic feedback
        hapticManager.impact(.light)

        // Advance to next
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000) // 0.25s
            await advanceToNext()
        }
    }

    func deleteCurrent() {
        guard let item = currentItem else { return }

        // Add to delete list
        assetsToDelete.append(item.asset)

        // Record action
        let action = SwipeAction(index: currentIndex, asset: item.asset, type: .deleted)
        undoStack = [action]
        canUndo = true
        
        // Track stats
        statsService.recordSwipe(kept: false)

        // Animate off screen
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: -500, height: 0)
        }

        // Haptic feedback
        hapticManager.impact(.medium)

        // Advance to next
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000) // 0.25s
            await advanceToNext()
        }
    }

    private func advanceToNext() async {
        currentIndex += 1
        progressTracker.lastSwipedIndex = currentIndex
        dragOffset = .zero
        await loadCurrentItem()
    }

    func undo() {
        guard let lastAction = undoStack.popLast() else { return }

        // If it was a delete, remove from delete list
        if lastAction.type == .deleted {
            assetsToDelete.removeAll { $0.localIdentifier == lastAction.asset.localIdentifier }
        }

        // Go back to that index
        currentIndex = lastAction.index
        canUndo = false

        // Haptic feedback
        hapticManager.impact(.light)

        // Reload item
        Task {
            dragOffset = .zero
            await loadCurrentItem()
        }
    }

    func resetPosition() {
        withAnimation(.spring(response: 0.3)) {
            dragOffset = .zero
        }
    }

    // MARK: - Completion
    func executeDeletes() async throws {
        guard !assetsToDelete.isEmpty else { return }
        
        // Estimate storage freed (rough estimate: 3MB per photo/video average)
        let estimatedMB = Double(assetsToDelete.count) * 3.0
        
        try await photoService.deleteAssets(assetsToDelete)
        
        // Record stats
        statsService.recordDeletion(count: assetsToDelete.count, estimatedSizeMB: estimatedMB)
        
        assetsToDelete.removeAll()
        progressTracker.reset()
    }

    func cancelAndReset() {
        assetsToDelete.removeAll()
        progressTracker.reset()
    }
}
