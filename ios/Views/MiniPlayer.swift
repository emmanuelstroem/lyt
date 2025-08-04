//
//  MiniPlayer.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI
import AVKit

// MARK: - Mini Player Configuration
struct MiniPlayerConfig {
    let showAirPlayButton: Bool
    let showPlayPauseButton: Bool
    let showChannelInfo: Bool
    let showArtwork: Bool
    
    static let full = MiniPlayerConfig(
        showAirPlayButton: true,
        showPlayPauseButton: true,
        showChannelInfo: true,
        showArtwork: true
    )
    
    static let minimized = MiniPlayerConfig(
        showAirPlayButton: false,
        showPlayPauseButton: true,
        showChannelInfo: true,
        showArtwork: true
    )
    
    static let liquidGlass = MiniPlayerConfig(
        showAirPlayButton: true, // Will be overridden by environment
        showPlayPauseButton: true,
        showChannelInfo: true,
        showArtwork: true
    )
}

// MARK: - Shared Mini Player Components
struct MiniPlayerComponents: View {
    let playingChannel: DRChannel?
    @EnvironmentObject var serviceManager: DRServiceManager
    @EnvironmentObject var selectionState: SelectionState
    let config: MiniPlayerConfig
    @State private var showingFullPlayer = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork Component
            if config.showArtwork {
                if let playingChannel = playingChannel {
                    ChannelArtworkView(
                        playingChannel: playingChannel,
                        size: 36
                    )
                    .environmentObject(serviceManager)
                    .clipShape(Capsule())
                } else {
                    // Placeholder artwork for "Not Playing" state
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                }
            }
            
            // Channel Info Component
            if config.showChannelInfo {
                VStack(alignment: .leading, spacing: 1) {
                    if let playingChannel = playingChannel {
                        if let track = serviceManager.currentTrack {
                            if track.isCurrentlyPlaying {
                                // Show channel-program as heading and track as subheading
                                let programTitle = serviceManager.getCurrentProgram(for: playingChannel)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(playingChannel.title) - \(programTitle?.cleanTitle() ?? "")")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text(track.displayText)
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            } else {
                                // Show channel as heading and program as subheading
                                let programTitle = serviceManager.getCurrentProgram(for: playingChannel)?.cleanTitle() ?? "Live"
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(playingChannel.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text(programTitle)
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                        } else if let currentProgram = serviceManager.getCurrentProgram(for: playingChannel) {
                            Text(playingChannel.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(currentProgram.cleanTitle())
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        } else {
                            Text(serviceManager.isPlaying ? "Live Now" : "Paused")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(serviceManager.isPlaying ? .red : .gray)
                                .lineLimit(1)
                        }
                    } else {
                        // "Not Playing" state
                        Text("Not Playing")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(serviceManager.availableChannels.isEmpty ? "No channels available" : "Tap play to start")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Controls Component
            HStack(spacing: 12) {
                if config.showAirPlayButton {
                    AirPlayButtonView(size: 24)
                        .opacity(playingChannel != nil ? 1.0 : 0.3)
                        .disabled(playingChannel == nil)
                }
                
                if config.showPlayPauseButton {
                    Button(action: {
                        if let playingChannel = playingChannel {
                            serviceManager.togglePlayback(for: playingChannel)
                        } else if let firstChannel = serviceManager.availableChannels.first {
                            // Play the first channel when nothing is currently playing
                            serviceManager.playChannel(firstChannel)
                        }
                    }) {
                        Image(systemName: serviceManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    .disabled(playingChannel == nil && serviceManager.availableChannels.isEmpty)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .onTapGesture {
            showingFullPlayer = true
        }
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerSheet(serviceManager: serviceManager, selectionState: selectionState)
        }
    }
}

// MARK: - Main Mini Player

struct MiniPlayer: View {
    @EnvironmentObject var serviceManager: DRServiceManager
    @EnvironmentObject var selectionState: SelectionState
    
    var body: some View {
        if #available(iOS 26.0, *) {
            LiquidGlassMiniPlayer()
                .environmentObject(serviceManager)
                .environmentObject(selectionState)

        } else {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    MiniPlayerComponents(
                        playingChannel: serviceManager.playingChannel,
                        config: .full
                    )
                    .environmentObject(serviceManager)
                    .environmentObject(selectionState)
                    .id(serviceManager.playingChannel?.id ?? "no-channel")
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(0.9)
                    )
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 25) // 25 is standard TabBar height
                }
            }
        }
    }
}

// MARK: - LiquidGlass Mini Player (iOS 26+)
@available(iOS 26.0, *)
struct LiquidGlassMiniPlayer: View {
    @EnvironmentObject var serviceManager: DRServiceManager
    @EnvironmentObject var selectionState: SelectionState
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    
    var body: some View {
        switch placement {
            case .inline:
                                    MiniPlayerComponents(
                        playingChannel: serviceManager.playingChannel,
                        config: MiniPlayerConfig(
                            showAirPlayButton: false,
                            showPlayPauseButton: true,
                            showChannelInfo: true,
                            showArtwork: true
                        )
                    )
                    .environmentObject(serviceManager)
                    .environmentObject(selectionState)
                .id(serviceManager.playingChannel?.id ?? "no-channel")
            default:
                MiniPlayerComponents(
                    playingChannel: serviceManager.playingChannel,
                    config: MiniPlayerConfig(
                        showAirPlayButton: true,
                        showPlayPauseButton: true,
                        showChannelInfo: true,
                        showArtwork: true
                    )
                )
                .environmentObject(serviceManager)
                .environmentObject(selectionState)
                .id(serviceManager.playingChannel?.id ?? "no-channel")
        }
    }
}

// MARK: - Shared Channel Artwork View
// MARK: - Shared Channel Artwork View
struct ChannelArtworkView: View {
    let playingChannel: DRChannel
    @EnvironmentObject var serviceManager: DRServiceManager
    let size: CGFloat
    
    private var channelIcon: String {
        // Get the current program and use its category-based icon
        if let currentProgram = serviceManager.getCurrentProgram(for: playingChannel) {
            return currentProgram.categoryIcon
        }
        
        // Fallback to default radio icon if no current program
        return "antenna.radiowaves.left.and.right"
    }
    
    var body: some View {
        if let currentProgram = serviceManager.getCurrentProgram(for: playingChannel),
           let imageURL = currentProgram.primaryImageURL,
           let url = URL(string: imageURL) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.8), .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Image(systemName: channelIcon)
                            .font(.system(size: size * 0.4, weight: .medium))
                            .foregroundColor(.white)
                    }
            }
            .frame(width: size, height: size)
            .clipShape(Capsule())
        } else {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.8), .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: channelIcon)
                        .font(.system(size: size * 0.4, weight: .medium))
                        .foregroundColor(.white)
                }
        }
    }
}

#Preview {
    MiniPlayer()
        .environmentObject(DRServiceManager())
        .environmentObject(SelectionState())
} 
