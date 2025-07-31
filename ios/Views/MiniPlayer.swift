//
//  MiniPlayer.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI
import AVKit

// MARK: - Mini Player Style
enum MiniPlayerStyle {
    case regular
    case floating
}

// MARK: - Main Mini Player
struct MiniPlayer: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @State private var isPlayingState = false
    let style: MiniPlayerStyle
    
    init(serviceManager: DRServiceManager, selectionState: SelectionState, style: MiniPlayerStyle = .regular) {
        self.serviceManager = serviceManager
        self.selectionState = selectionState
        self.style = style
    }
    
    var body: some View {
        if let playingChannel = serviceManager.playingChannel {
            switch style {
            case .regular:
                RegularMiniPlayerContent(
                    playingChannel: playingChannel,
                    serviceManager: serviceManager,
                    selectionState: selectionState
                )
            case .floating:
                FloatingMiniPlayerContent(
                    playingChannel: playingChannel,
                    serviceManager: serviceManager,
                    selectionState: selectionState
                )
            }
        }
    }
}

// MARK: - Regular Mini Player Content
struct RegularMiniPlayerContent: View {
    let playingChannel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    
    var body: some View {
        VStack(spacing: 0) {
            // Mini player content
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: 0.0) // Placeholder for live radio
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    .scaleEffect(y: 0.5)
                
                // Main player content
                HStack(spacing: 12) {
                    // Channel artwork
                    ChannelArtworkView(
                        playingChannel: playingChannel,
                        serviceManager: serviceManager,
                        size: 48
                    )
                    
                    // Channel info
                    VStack(alignment: .leading, spacing: 2) {
                        if let track = serviceManager.currentTrack {
                            if track.isCurrentlyPlaying {
                                // Show channel and program when track is currently playing
                                let programTitle = serviceManager.getCurrentProgram(for: playingChannel)?.title ?? "Live"
                                Text("\(playingChannel.displayName) - \(programTitle)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            } else {
                                // Show track info when track is not currently playing
                                Text(track.displayText)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        } else if let currentProgram = serviceManager.getCurrentProgram(for: playingChannel) {
                            Text(playingChannel.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                
                            Text(currentProgram.cleanTitle())
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        } else {
                            Text("Live Now")
                                .font(.caption)
                                .foregroundColor(.red)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                                            // Controls
                        HStack(spacing: 16) {
                            // AirPlay button
                            AirPlayButtonView(size: 32)
                            
                            // Play/Pause button
                            Button(action: {
                                serviceManager.togglePlayback(for: playingChannel)
                            }) {
                                Image(systemName: serviceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(channelColor)
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(0.25)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .onTapGesture {
            // Open FullPlayer when MiniPlayer is tapped
            // This will be handled by the parent view
        }
    }
    
    // Generate consistent color for channel
    private var channelColor: Color {
        let hash = abs(playingChannel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.7 + Double(hash % 20) / 100.0
        let brightness = 0.8 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

// MARK: - Floating Mini Player Content
struct FloatingMiniPlayerContent: View {
    let playingChannel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @State private var showingFullPlayer = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Channel artwork
            ChannelArtworkView(
                playingChannel: playingChannel,
                serviceManager: serviceManager,
                size: 40
            )
            
            // Channel info
            VStack(alignment: .leading, spacing: 2) {
                if let track = serviceManager.currentTrack {
                    if track.isCurrentlyPlaying {
                        // Show channel-program as heading and track as subheading
                        let programTitle = serviceManager.getCurrentProgram(for: playingChannel)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(playingChannel.title) - \(programTitle?.cleanTitle() ?? "")")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(track.displayText)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    } else {
                        // Show channel as heading and program as subheading
                        let programTitle = serviceManager.getCurrentProgram(for: playingChannel)?.cleanTitle() ?? "Live"
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playingChannel.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(programTitle)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                } else if let currentProgram = serviceManager.getCurrentProgram(for: playingChannel) {
                    Text(playingChannel.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(currentProgram.cleanTitle())
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                } else {
                    Text(serviceManager.isPlaying ? "Live Now" : "Paused")
                        .font(.caption)
                        .foregroundColor(serviceManager.isPlaying ? .red : .gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 16) {
                // AirPlay button
                AirPlayButtonView(size: 28)
                
                // Play/Pause button
                Button(action: {
                    serviceManager.togglePlayback(for: playingChannel)
                }) {
                    Image(systemName: serviceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25) // 50% rounded corners
                .fill(.ultraThinMaterial)
                .opacity(0.9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .offset(y: -50) // Move up to sit on top of tab bar
        .onTapGesture {
            showingFullPlayer = true
        }
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerSheet(serviceManager: serviceManager, selectionState: selectionState)
        }
    }
}

// MARK: - Shared Channel Artwork View
struct ChannelArtworkView: View {
    let playingChannel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
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
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
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
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
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

// MARK: - Convenience Initializers
extension MiniPlayer {
    static func floating(serviceManager: DRServiceManager, selectionState: SelectionState) -> MiniPlayer {
        MiniPlayer(serviceManager: serviceManager, selectionState: selectionState, style: .floating)
    }
}

#Preview {
    VStack(spacing: 20) {
        MiniPlayer(
            serviceManager: DRServiceManager(),
            selectionState: SelectionState(),
            style: .regular
        )
        
        MiniPlayer(
            serviceManager: DRServiceManager(),
            selectionState: SelectionState(),
            style: .floating
        )
    }
} 
