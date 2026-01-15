import SwiftUI
import AVKit
import Photos

struct VideoPlayerView: View {
    let asset: PHAsset
    @Binding var isPresented: Bool

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var timeObserver: Any?
    @State private var showControls = true
    @State private var isFinished = false
    @State private var hideControlsTask: Task<Void, Never>?

    private let photoService = PhotoLibraryService.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                // Video player
                VideoPlayerRepresentable(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if isFinished {
                            replay()
                        } else {
                            togglePlayPause()
                        }
                        showControlsTemporarily()
                    }

                // Center play/pause button (always visible when paused/finished)
                if showControls || !isPlaying || isFinished {
                    Button(action: {
                        if isFinished {
                            replay()
                        } else {
                            togglePlayPause()
                        }
                        showControlsTemporarily()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: isFinished ? "arrow.counterclockwise" : (isPlaying ? "pause.fill" : "play.fill"))
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                                .offset(x: isPlaying || isFinished ? 0 : 3) // Center play icon
                        }
                    }
                    .transition(.opacity)
                }

                // Controls overlay
                VStack {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding()
                    }

                    Spacer()

                    // Scrubber controls
                    if showControls || !isPlaying {
                        VStack(spacing: 8) {
                            // Time slider
                            Slider(value: $currentTime, in: 0...max(duration, 1)) { editing in
                                if editing {
                                    player.pause()
                                } else {
                                    let time = CMTime(seconds: currentTime, preferredTimescale: 600)
                                    player.seek(to: time)
                                    if isPlaying && !isFinished {
                                        player.play()
                                    }
                                    isFinished = false
                                }
                            }
                            .tint(.white)

                            // Time labels
                            HStack {
                                Text(formatTime(currentTime))
                                    .font(.caption)
                                    .foregroundColor(.white)

                                Spacer()

                                Text(formatTime(duration))
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding()
                        .transition(.opacity)
                    }
                }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showControls)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
        .onAppear {
            loadAndPlayVideo()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    private func showControlsTemporarily() {
        showControls = true
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if !Task.isCancelled && isPlaying && !isFinished {
                await MainActor.run {
                    showControls = false
                }
            }
        }
    }

    private func loadAndPlayVideo() {
        Task {
            guard let playerItem = await photoService.loadVideo(for: asset) else { return }

            let assetDuration = try? await playerItem.asset.load(.duration).seconds
            
            await MainActor.run {
                player = AVPlayer(playerItem: playerItem)
                duration = assetDuration ?? 0

                // Start playback
                player?.play()
                isPlaying = true
                showControlsTemporarily()

                // Setup time observer
                let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
                timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                    currentTime = time.seconds
                    
                    // Check if video finished
                    if duration > 0 && time.seconds >= duration - 0.1 {
                        isFinished = true
                        isPlaying = false
                        showControls = true
                    }
                }
                
                // Also observe when video ends
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: playerItem,
                    queue: .main
                ) { _ in
                    isFinished = true
                    isPlaying = false
                    showControls = true
                }
            }
        }
    }

    private func togglePlayPause() {
        guard let player = player else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func replay() {
        guard let player = player else { return }
        
        let start = CMTime.zero
        player.seek(to: start)
        player.play()
        isPlaying = true
        isFinished = false
        showControlsTemporarily()
    }

    private func cleanupPlayer() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player = nil
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct VideoPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.player = player
    }

    class PlayerContainerView: UIView {
        private var playerLayer: AVPlayerLayer?
        
        var player: AVPlayer? {
            didSet {
                if playerLayer == nil {
                    let layer = AVPlayerLayer()
                    layer.videoGravity = .resizeAspect
                    self.layer.addSublayer(layer)
                    playerLayer = layer
                }
                playerLayer?.player = player
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer?.frame = bounds
        }
    }
}

