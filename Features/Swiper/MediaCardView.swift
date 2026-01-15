import SwiftUI
import PhotosUI

struct MediaCardView: View {
    let item: MediaItem
    let thumbnail: UIImage?
    let livePhoto: PHLivePhoto?
    @Binding var isVideoPlaying: Bool
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                photoContent(thumbnail)
            } else if let livePhoto = livePhoto {
                livePhotoContent(livePhoto)
            } else {
                placeholderContent
            }
            
            // Video play indicator
            if item.mediaType == .video {
                videoOverlay
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        .contentShape(Rectangle()) // Makes entire area tappable for swipes
    }
    
    private func photoContent(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    private func livePhotoContent(_ livePhoto: PHLivePhoto) -> some View {
        LivePhotoView(livePhoto: livePhoto)
            .aspectRatio(contentMode: .fit)
    }
    
    private var placeholderContent: some View {
        Color.clear
            .overlay(
                ProgressView()
                    .tint(.textSecondary)
            )
    }
    
    private var videoOverlay: some View {
        Button(action: { isVideoPlaying = true }) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .offset(x: 2)
            }
        }
    }
}

