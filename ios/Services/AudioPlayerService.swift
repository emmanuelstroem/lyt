//
//  AudioPlayerService.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import Foundation
import AVFoundation
import Combine
import Accelerate
import UIKit
import MediaPlayer

// MARK: - iOS Audio Player Service

class AudioPlayerService: ObservableObject {
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var error: String?
    @Published var audioSpectrum: [Float] = Array(repeating: 0.0, count: 8)
    
    private var audioEngine: AVAudioEngine?
    private var spectrumTimer: Timer?
    
    init() {
        setupAudioSession()
    }
    
    deinit {
        removeTimeObserver()
        stopSpectrumAnalysis()
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupAudioSession() {
        do {
            print("🎵 AudioPlayerService: Setting up audio session")
            let audioSession = AVAudioSession.sharedInstance()
            
            // Simple, reliable audio session setup
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            print("🎵 AudioPlayerService: Audio session setup successful")
        } catch {
            print("❌ AudioPlayerService: Failed to setup audio session: \(error)")
        }
    }
    
    func play(url: URL) {
        print("🎵 AudioPlayerService: Starting playback for URL: \(url)")
        isLoading = true
        error = nil
        
        // Create new player item
        let playerItem = AVPlayerItem(url: url)
        
        // Remove existing time observer
        removeTimeObserver()
        
        // Create new player
        player = AVPlayer(playerItem: playerItem)
        print("🎵 AudioPlayerService: Created AVPlayer with item")
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        // Observe player item status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                print("🎵 AudioPlayerService: Player item status changed to: \(status)")
                switch status {
                case .readyToPlay:
                    print("🎵 AudioPlayerService: Ready to play, starting playback")
                    self?.isLoading = false
                    self?.duration = playerItem.duration.seconds
                    self?.player?.play()
                    self?.isPlaying = true
                    self?.startSpectrumAnalysis()
                case .failed:
                    print("🎵 AudioPlayerService: Failed to load audio: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                    if let error = playerItem.error {
                        print("🎵 AudioPlayerService: Detailed error: \(error)")
                    }
                    self?.isLoading = false
                    self?.error = playerItem.error?.localizedDescription ?? "Failed to load audio"
                case .unknown:
                    print("🎵 AudioPlayerService: Player item status is unknown")
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
                print("🎵 AudioPlayerService: Time control status changed to: \(status)")
                switch status {
                case .playing:
                    print("🎵 AudioPlayerService: Now playing")
                    self?.isPlaying = true
                    self?.startSpectrumAnalysis()
                case .paused:
                    print("🎵 AudioPlayerService: Paused")
                    self?.isPlaying = false
                    self?.stopSpectrumAnalysis()
                case .waitingToPlayAtSpecifiedRate:
                    print("🎵 AudioPlayerService: Waiting to play")
                    self?.isLoading = true
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func pause() {
        print("🎵 AudioPlayerService: Pausing playback")
        player?.pause()
        isPlaying = false
        stopSpectrumAnalysis()
    }
    
    func resume() {
        print("🎵 AudioPlayerService: Resuming playback")
        player?.play()
        isPlaying = true
        startSpectrumAnalysis()
    }
    
    func stop() {
        print("🎵 AudioPlayerService: Stopping playback")
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        removeTimeObserver()
        stopSpectrumAnalysis()
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
    
    // MARK: - Audio Spectrum Analysis
    
    private func startSpectrumAnalysis() {
        stopSpectrumAnalysis()
        
        // Create a timer to simulate audio spectrum data
        // In a real implementation, this would use AVAudioEngine with audio taps
        spectrumTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateSpectrum()
        }
    }
    
    private func stopSpectrumAnalysis() {
        spectrumTimer?.invalidate()
        spectrumTimer = nil
        
        // Reset spectrum to zero
        DispatchQueue.main.async {
            self.audioSpectrum = Array(repeating: 0.0, count: 8)
        }
    }
    
    private func updateSpectrum() {
        guard isPlaying else { return }
        
        // Generate realistic audio spectrum data
        var newSpectrum: [Float] = []
        
        for i in 0..<8 {
            // Create a more realistic frequency response pattern
            let baseFrequency = Float(i) * 0.15
            let time = Date().timeIntervalSince1970
            let frequency = baseFrequency + Float(sin(time * 2.0 + Double(i))) * 0.1
            let amplitude = Float(sin(time * 3.0 + Double(i) * 0.5)) * 0.5 + 0.5
            
            // Add some randomness to make it more realistic
            let randomFactor = Float.random(in: 0.7...1.3)
            let value = min(1.0, max(0.0, frequency * amplitude * randomFactor))
            
            newSpectrum.append(value)
        }
        
        DispatchQueue.main.async {
            self.audioSpectrum = newSpectrum
        }
    }
} 
