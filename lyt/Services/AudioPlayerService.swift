import Foundation
import AVFoundation
import Combine

/// Audio player service for DR radio streams using AVFoundation
@MainActor
class AudioPlayerService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var playbackState: PlaybackState = .stopped
    @Published var isPlaying: Bool = false
    @Published var currentURL: String?
    @Published var volume: Double = 0.7
    @Published var isMuted: Bool = false
    
    // MARK: - Private Properties
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupAudioSession()
        setupObservers()
    }
    
    deinit {
        // Basic cleanup without actor isolation issues
        player?.pause()
        statusObserver?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Play audio from URL
    func play(url: String) {
        print("🎵 AudioPlayerService: play(url: \(url))")
        
        // If same URL and paused, resume
        if currentURL == url, playbackState == .paused {
            resume()
            return
        }
        
        // Stop current playback if different URL
        if currentURL != url {
            stop()
        }
        
        guard let streamURL = URL(string: url) else {
            print("❌ Invalid URL: \(url)")
            playbackState = .error("Invalid stream URL")
            return
        }
        
        currentURL = url
        playbackState = .loading
        
        // Create new player item and player
        let asset = AVURLAsset(url: streamURL)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        setupPlayerObservers()
        
        // Start playback
        player?.volume = Float(volume)
        player?.isMuted = isMuted
        player?.play()
        
        isPlaying = true
        playbackState = .loading
        
        print("🎵 Started loading stream: \(url)")
    }
    
    /// Pause playback
    func pause() {
        print("⏸️ AudioPlayerService: pause()")
        player?.pause()
        isPlaying = false
        playbackState = .paused
    }
    
    /// Resume playback
    func resume() {
        print("▶️ AudioPlayerService: resume()")
        player?.play()
        isPlaying = true
        playbackState = .playing
    }
    
    /// Stop playback
    func stop() {
        print("⏹️ AudioPlayerService: stop()")
        player?.pause()
        cleanup()
        
        isPlaying = false
        playbackState = .stopped
        currentURL = nil
    }
    
    /// Toggle play/pause
    func togglePlayback() {
        switch playbackState {
        case .playing:
            pause()
        case .paused:
            resume()
        case .stopped, .loading, .error:
            // Need URL to start playback
            break
        }
    }
    
    /// Set volume (0.0 to 1.0)
    func setVolume(_ newVolume: Double) {
        volume = max(0.0, min(1.0, newVolume))
        player?.volume = Float(volume)
        print("🔊 Volume set to: \(volume)")
    }
    
    /// Toggle mute
    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
        print("🔇 Muted: \(isMuted)")
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        #if os(iOS) || os(tvOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("🎵 Audio session configured for playback")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            playbackState = .error("Audio session setup failed")
        }
        #else
        // macOS doesn't require explicit audio session setup
        print("🎵 Audio session not required on macOS")
        #endif
    }
    
    private func setupObservers() {
        // Volume observer
        $volume
            .sink { [weak self] newVolume in
                self?.player?.volume = Float(newVolume)
            }
            .store(in: &cancellables)
        
        // Mute observer
        $isMuted
            .sink { [weak self] muted in
                self?.player?.isMuted = muted
            }
            .store(in: &cancellables)
    }
    
    private func setupPlayerObservers() {
        guard let playerItem = playerItem else { return }
        
        // Player item status observer
        statusObserver = playerItem.observe(\.status) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.handlePlayerItemStatusChange(item.status)
            }
        }
        
        // Player item error notification
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                        print("❌ Player item failed: \(error)")
                        self?.playbackState = .error("Playback failed: \(error.localizedDescription)")
                        self?.isPlaying = false
                    }
                }
            }
            .store(in: &cancellables)
        
        // Player item stalled notification
        NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    print("⚠️ Player item stalled")
                    self?.playbackState = .loading
                }
            }
            .store(in: &cancellables)
    }
    
    private func handlePlayerItemStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            print("✅ Player ready to play")
            if isPlaying {
                playbackState = .playing
            }
        case .failed:
            if let error = playerItem?.error {
                print("❌ Player item failed: \(error)")
                playbackState = .error("Stream failed: \(error.localizedDescription)")
            } else {
                playbackState = .error("Unknown playback error")
            }
            isPlaying = false
        case .unknown:
            print("❓ Player item status unknown")
        @unknown default:
            print("❓ Player item status unknown default")
        }
    }
    
    private func cleanup() {
        // Remove observers
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        statusObserver?.invalidate()
        statusObserver = nil
        
        // Clean up player
        player?.pause()
        player = nil
        playerItem = nil
        
        cancellables.removeAll()
    }
}

// MARK: - Extensions

extension AudioPlayerService {
    
    /// Get formatted playback state for debugging
    var playbackStateDescription: String {
        switch playbackState {
        case .stopped: return "Stopped"
        case .loading: return "Loading..."
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    /// Check if can toggle playback (has URL)
    var canTogglePlayback: Bool {
        return currentURL != nil
    }
    
    /// Get play button title
    var playButtonTitle: String {
        switch playbackState {
        case .playing: return "Pause"
        case .paused, .stopped: return "Play"
        case .loading: return "Loading..."
        case .error: return "Retry"
        }
    }
    
    /// Get play button icon
    var playButtonIcon: String {
        switch playbackState {
        case .playing: return "pause.circle.fill"
        case .paused, .stopped: return "play.circle.fill"
        case .loading: return "arrow.clockwise.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        }
    }
} 