//
//  AudioPlayerService.swift
//  ipados
//
//  Created by Emmanuel on 27/07/2025.
//

import Foundation
import AVFoundation
import Combine

// MARK: - iPadOS Audio Player Service

class AudioPlayerService: ObservableObject {
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        setupAudioSession()
    }
    
    deinit {
        removeTimeObserver()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
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
                case .paused:
                    self?.isPlaying = false
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
    }
    
    func resume() {
        player?.play()
        isPlaying = true
    }
    
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        removeTimeObserver()
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