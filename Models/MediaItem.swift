import Photos
import Foundation

struct MediaItem: Identifiable {
    let id: String
    let asset: PHAsset
    let mediaType: MediaType
    let creationDate: Date?
    let duration: TimeInterval?

    enum MediaType {
        case photo
        case livePhoto
        case video
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDate: String? {
        guard let date = creationDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    // Short format like "DEC '18" for top nav
    var monthYearText: String {
        guard let date = creationDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM ''yy"
        return formatter.string(from: date).uppercased()
    }

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.creationDate = asset.creationDate

        // Determine media type
        if asset.mediaType == .video {
            self.mediaType = .video
            self.duration = asset.duration
        } else if asset.mediaSubtypes.contains(.photoLive) {
            self.mediaType = .livePhoto
            self.duration = nil
        } else {
            self.mediaType = .photo
            self.duration = nil
        }
    }
}


