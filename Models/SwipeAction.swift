import Photos

struct SwipeAction {
    let index: Int
    let asset: PHAsset
    let type: ActionType

    enum ActionType: String, Codable {
        case kept
        case deleted
        case favourited
    }
}

// Codable version for persistence
struct SavedSwipeAction: Codable {
    let index: Int
    let assetIdentifier: String
    let type: SwipeAction.ActionType
    
    init(from action: SwipeAction) {
        self.index = action.index
        self.assetIdentifier = action.asset.localIdentifier
        self.type = action.type
    }
    
    func toSwipeAction(assets: [PHAsset]) -> SwipeAction? {
        guard index < assets.count else { return nil }
        let asset = assets[index]
        // Verify it's the same asset
        guard asset.localIdentifier == assetIdentifier else { return nil }
        return SwipeAction(index: index, asset: asset, type: type)
    }
}


