//
//  AudioPlayerService.swift
//  macos
//
//  Created by Emmanuel on 27/07/2025.
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer

// MARK: - macOS Audio Player Service

class AudioPlayerService: ObservableObject {
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var error: String?
    
    // Command Center properties
    private var commandCenter: MPRemoteCommandCenter?
    private var nowPlayingInfoCenter: MPNowPlayingInfoCenter?
    
    init() {
        setupAudioSession()
        setupCommandCenter()
    }
    
    deinit {
        removeTimeObserver()
        
        // Clean up Command Center
        cleanupCommandCenter()
    }
    
    private func setupAudioSession() {
        // macOS doesn't require audio session setup like iOS
        // The system handles audio routing automatically
    }
    
    // MARK: - Command Center Setup
    
    private func setupCommandCenter() {
        print("🎵 AudioPlayerService: Setting up Command Center")
        
        // Get the shared command center
        commandCenter = MPRemoteCommandCenter.shared()
        nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        
        // Configure play command
        commandCenter?.playCommand.addTarget { [weak self] _ in
            print("🎵 Command Center: Play command received")
            self?.resume()
            return .success
        }
        
        // Configure pause command
        commandCenter?.pauseCommand.addTarget { [weak self] _ in
            print("🎵 Command Center: Pause command received")
            self?.pause()
            return .success
        }
        
        // Configure stop command
        commandCenter?.stopCommand.addTarget { [weak self] _ in
            print("🎵 Command Center: Stop command received")
            self?.stop()
            return .success
        }
        
        // Configure toggle play/pause command
        commandCenter?.togglePlayPauseCommand.addTarget { [weak self] _ in
            print("🎵 Command Center: Toggle play/pause command received")
            if self?.isPlaying == true {
                self?.pause()
            } else {
                self?.resume()
            }
            return .success
        }
        
        // Disable seeking commands since this is live radio
        commandCenter?.seekForwardCommand.isEnabled = false
        commandCenter?.seekBackwardCommand.isEnabled = false
        commandCenter?.skipForwardCommand.isEnabled = false
        commandCenter?.skipBackwardCommand.isEnabled = false
        commandCenter?.changePlaybackPositionCommand.isEnabled = false
        
        print("🎵 AudioPlayerService: Command Center setup complete")
    }
    
    private func cleanupCommandCenter() {
        print("🎵 AudioPlayerService: Cleaning up Command Center")
        
        // Remove all command targets
        commandCenter?.playCommand.removeTarget(nil)
        commandCenter?.pauseCommand.removeTarget(nil)
        commandCenter?.stopCommand.removeTarget(nil)
        commandCenter?.togglePlayPauseCommand.removeTarget(nil)
        
        // Clear now playing info
        nowPlayingInfoCenter?.nowPlayingInfo = nil
        
        print("🎵 AudioPlayerService: Command Center cleanup complete")
    }
    
    // MARK: - Command Center Info Updates
    
    func updateCommandCenterInfo(channel: DRChannel, program: DREpisode?) {
        print("🎵 AudioPlayerService: Updating Command Center info")
        
        var nowPlayingInfo: [String: Any] = [:]
        
        // Basic info
        nowPlayingInfo[MPMediaItemPropertyTitle] = program?.title ?? channel.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = channel.title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "DR Radio"
        
        // Set duration to 0 for live radio (no progress bar)
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
        
        // Set playback rate
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Set default artwork if no program image
        if let program = program, let imageURLString = program.primaryImageURL, let imageURL = URL(string: imageURLString) {
            // Load image asynchronously
            loadImageForCommandCenter(from: imageURL) { [weak self] image in
                if let image = image {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    self?.nowPlayingInfoCenter?.nowPlayingInfo = nowPlayingInfo
                    print("🎵 AudioPlayerService: Updated Command Center with program artwork")
                } else {
                    // Fallback to default artwork
                    self?.setDefaultCommandCenterArtwork(nowPlayingInfo: nowPlayingInfo)
                }
            }
        } else {
            // Use default artwork
            setDefaultCommandCenterArtwork(nowPlayingInfo: nowPlayingInfo)
        }
        
        // Update the now playing info
        nowPlayingInfoCenter?.nowPlayingInfo = nowPlayingInfo
        
        print("🎵 AudioPlayerService: Command Center info updated")
    }
    
    private func loadImageForCommandCenter(from url: URL, completion: @escaping (NSImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let image = NSImage(data: data) {
                    completion(image)
                } else {
                    print("❌ AudioPlayerService: Failed to load image for Command Center: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                }
            }
        }.resume()
    }
    
    private func setDefaultCommandCenterArtwork(nowPlayingInfo: [String: Any]) {
        var updatedInfo = nowPlayingInfo
        
        // Create a simple default artwork with radio icon
        let size = NSSize(width: 300, height: 300)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Background gradient
        let gradient = NSGradient(colors: [NSColor.systemBlue, NSColor.systemPurple])!
        gradient.draw(in: NSRect(origin: .zero, size: size), angle: 45)
        
        // Radio icon
        let iconSize: CGFloat = 120
        let iconRect = NSRect(x: (size.width - iconSize) / 2,
                             y: (size.height - iconSize) / 2,
                             width: iconSize,
                             height: iconSize)
        
        let radioIcon = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: nil)
        radioIcon?.draw(in: iconRect)
        
        image.unlockFocus()
        
        updatedInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        nowPlayingInfoCenter?.nowPlayingInfo = updatedInfo
        
        print("🎵 AudioPlayerService: Set default Command Center artwork")
    }
    
    func updateCommandCenterPlaybackState() {
        print("🎵 AudioPlayerService: Updating Command Center playback state")
        
        var nowPlayingInfo = nowPlayingInfoCenter?.nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfoCenter?.nowPlayingInfo = nowPlayingInfo
        
        print("🎵 AudioPlayerService: Command Center playback state updated - isPlaying: \(isPlaying)")
    }
    
    func clearCommandCenterInfo() {
        print("🎵 AudioPlayerService: Clearing Command Center info")
        nowPlayingInfoCenter?.nowPlayingInfo = nil
    }
    
    func play(url: URL) {
        isLoading = true
        error = nil
        
        // Create new player item
        let playerItem = AVPlayerItem(url: url)
        
        // Remove existing time observer
        removeTimeObserver()
        
        // Create new player
        player = AVPlayer(playerItem: playerItem)
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        // Observe player item status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.isLoading = false
                    self?.duration = playerItem.duration.seconds
                    self?.player?.play()
                    self?.isPlaying = true
                    // Update Command Center playback state
                    self?.updateCommandCenterPlaybackState()
                case .failed:
                    self?.isLoading = false
                    self?.error = playerItem.error?.localizedDescription ?? "Failed to load audio"
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe playback status
        player?.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .playing:
                    self?.isPlaying = true
                    // Update Command Center playback state
                    self?.updateCommandCenterPlaybackState()
                case .paused:
                    self?.isPlaying = false
                    // Update Command Center playback state
                    self?.updateCommandCenterPlaybackState()
                case .waitingToPlayAtSpecifiedRate:
                    self?.isLoading = true
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        // Update Command Center playback state
        updateCommandCenterPlaybackState()
    }
    
    func resume() {
        player?.play()
        isPlaying = true
        // Update Command Center playback state
        updateCommandCenterPlaybackState()
    }
    
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        removeTimeObserver()
        // Clear Command Center info
        clearCommandCenterInfo()
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    private func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    func setVolume(_ volume: Float) {
        player?.volume = volume
    }
} 