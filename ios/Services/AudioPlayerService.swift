//
//  AudioPlayerService.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import Foundation
import AVFoundation
import Combine
import UIKit
import MediaPlayer
import AVKit

// MARK: - iOS Audio Player Service

class AudioPlayerService: NSObject, ObservableObject {
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var error: String?
    
    // Control for screen sleep behavior
    @Published var preventScreenSleep = false
    
    // AirPlay properties
    @Published var isAirPlayActive = false
    @Published var currentAirPlayRoute: AVAudioSessionRouteDescription?
    
    // Command Center properties
    private var commandCenter: MPRemoteCommandCenter?
    private var nowPlayingInfoCenter: MPNowPlayingInfoCenter?
    
    override init() {
        super.init()
        setupCommandCenter()
        // Allow screen sleep by default on app launch
        setPreventScreenSleep(false)
        // Audio session will be setup when first needed
    }
    
    deinit {
        removeTimeObserver()
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Clean up Command Center
        cleanupCommandCenter()
    }
    
    private var audioSessionSetup = false
    
    // MARK: - Screen Sleep Control
    
    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = preventScreenSleep
    }
    
    // MARK: - AirPlay Support
    
    private func setupAirPlayMonitoring() {
        // Monitor route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // Initial route check
        updateAirPlayStatus()
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.updateAirPlayStatus()
        }
    }
    

    
    private func updateAirPlayStatus() {
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        
        // Check if AirPlay is active
        let isAirPlay = currentRoute.outputs.contains { output in
            output.portType == .airPlay
        }
        
        // Check if external audio is active (AirPlay, Bluetooth, etc.)
        let externalPortTypes: [AVAudioSession.Port] = [.airPlay, .bluetoothA2DP, .bluetoothLE, .bluetoothHFP]
        let isExternalAudio = currentRoute.outputs.contains { output in
            externalPortTypes.contains(output.portType)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isAirPlayActive = isAirPlay
            self?.currentAirPlayRoute = isExternalAudio ? currentRoute : nil
        }
    }
    

    
    // MARK: - Command Center Setup
    
    private func setupCommandCenter() {
        // Get the shared command center
        commandCenter = MPRemoteCommandCenter.shared()
        nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        
        // Configure play command
        commandCenter?.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        
        // Configure pause command
        commandCenter?.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // Configure stop command
        commandCenter?.stopCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }
        
        // Configure toggle play/pause command
        commandCenter?.togglePlayPauseCommand.addTarget { [weak self] _ in
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
    }
    
    private func cleanupCommandCenter() {
        // Remove all command targets
        commandCenter?.playCommand.removeTarget(nil)
        commandCenter?.pauseCommand.removeTarget(nil)
        commandCenter?.stopCommand.removeTarget(nil)
        commandCenter?.togglePlayPauseCommand.removeTarget(nil)
        
        // Clear now playing info
        nowPlayingInfoCenter?.nowPlayingInfo = nil
    }
    
    // MARK: - Command Center Info Updates
    
    func updateCommandCenterInfo(channel: DRChannel, program: DREpisode?) {
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
    }
    
    private func loadImageForCommandCenter(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    completion(image)
                } else {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    private func setDefaultCommandCenterArtwork(nowPlayingInfo: [String: Any]) {
        var updatedInfo = nowPlayingInfo
        
        // Create a simple default artwork with radio icon
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let defaultImage = renderer.image { context in
            // Background gradient
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor] as CFArray,
                                    locations: [0.0, 1.0])!
            
            context.cgContext.drawLinearGradient(gradient,
                                               start: CGPoint(x: 0, y: 0),
                                               end: CGPoint(x: size.width, y: size.height),
                                               options: [])
            
            // Radio icon
            let iconSize: CGFloat = 120
            let iconRect = CGRect(x: (size.width - iconSize) / 2,
                                y: (size.height - iconSize) / 2,
                                width: iconSize,
                                height: iconSize)
            
            let iconConfig = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)
            let radioIcon = UIImage(systemName: "antenna.radiowaves.left.and.right", withConfiguration: iconConfig)
            radioIcon?.withTintColor(.white, renderingMode: .alwaysOriginal)
                .draw(in: iconRect)
        }
        
        updatedInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: defaultImage.size) { _ in defaultImage }
        nowPlayingInfoCenter?.nowPlayingInfo = updatedInfo
    }
    
    func updateCommandCenterPlaybackState() {
        var nowPlayingInfo = nowPlayingInfoCenter?.nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfoCenter?.nowPlayingInfo = nowPlayingInfo
    }
    
    func clearCommandCenterInfo() {
        nowPlayingInfoCenter?.nowPlayingInfo = nil
    }
    

    
    func play(url: URL) {
        isLoading = true
        error = nil
        
        // Setup and activate audio session when starting playback
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Set category first
            try audioSession.setCategory(.playback, mode: .default)
            
            // Then activate
            try audioSession.setActive(true)
            
            // Optionally prevent screen sleep during playback
            // You can control this manually or let it be automatic
            // setPreventScreenSleep(true)
            
            // Setup AirPlay monitoring if not already done
            if !audioSessionSetup {
                setupAirPlayMonitoring()
                audioSessionSetup = true
            }
        } catch {
            print("❌ AudioPlayerService: Failed to setup/activate audio session: \(error)")
        }
        
        // Create new player item
        let playerItem = AVPlayerItem(url: url)
        
        // Remove existing time observer
        removeTimeObserver()
        
        // Create new player
        player = AVPlayer(playerItem: playerItem)
        
        // Add time observer with longer interval to allow screen sleep
        let interval = CMTime(seconds: 5.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
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
        
        // Deactivate audio session when pausing to allow screen sleep
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Silent error handling
        }
        
        // Update Command Center playback state
        updateCommandCenterPlaybackState()
    }
    
    func resume() {
        player?.play()
        isPlaying = true
        
        // Reactivate audio session when resuming
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Ensure category is set correctly
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            // Silent error handling
        }
        
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
        
        // Deactivate audio session when stopping playback
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Silent error handling
        }
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
    
    // MARK: - Screen Sleep Control
    
    func setPreventScreenSleep(_ prevent: Bool) {
        preventScreenSleep = prevent
        updateIdleTimer()
    }
    

} 
