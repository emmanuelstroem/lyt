//
//  ContentView.swift
//  lyt
//
//  Created by Emmanuel on 24/07/2025.
//

import SwiftUI

// MARK: - Platform-Specific Colors
// Based on https://mar.codes/apple-colors for proper cross-platform compatibility

private var backgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlBackgroundColor)
    #elseif os(tvOS)
    Color.black // tvOS typically uses black backgrounds
    #else // iOS
    Color(.systemBackground)
    #endif
}

private var secondaryBackgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlColor)
    #elseif os(tvOS)
    Color(.systemGray) // tvOS has systemGray but not systemGray6
    #else // iOS
    Color(.systemGray6)
    #endif
}

private var tertiaryBackgroundColor: Color {
    #if os(macOS)
    Color(NSColor.separatorColor)
    #elseif os(tvOS)
    Color(.systemGray) // tvOS has limited color options
    #else // iOS
    Color(.systemGray4)
    #endif
}

private var separatorColor: Color {
    #if os(macOS)
    Color(NSColor.separatorColor)
    #elseif os(tvOS)
    Color(.systemGray) // tvOS fallback
    #else // iOS
    Color(.separator)
    #endif
}

private var labelColor: Color {
    #if os(macOS)
    Color(NSColor.labelColor)
    #elseif os(tvOS)
    Color.white // tvOS typically uses white text
    #else // iOS
    Color(.label)
    #endif
}

private var secondaryLabelColor: Color {
    #if os(macOS)
    Color(NSColor.secondaryLabelColor)
    #elseif os(tvOS)
    Color.gray // tvOS fallback
    #else // iOS
    Color(.secondaryLabel)
    #endif
}

private var cardBackgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlBackgroundColor)
    #elseif os(tvOS)
    Color(.systemGray).opacity(0.3) // Semi-transparent for tvOS cards
    #else // iOS
    Color(.systemBackground)
    #endif
}

private var fillColor: Color {
    #if os(macOS)
    Color(NSColor.controlColor)
    #elseif os(tvOS)
    Color(.systemGray).opacity(0.5)
    #else // iOS
    Color(.systemFill)
    #endif
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var serviceManager = DRServiceManager()
    @State private var selectedChannelIndex = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Channel Selector
                ChannelPickerView(
                    channels: serviceManager.appState.availableChannels,
                    selectedChannel: serviceManager.appState.selectedChannel,
                    onChannelSelected: { channel in
                        serviceManager.selectChannel(channel)
                    }
                )

                // Main Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Current Program Card
                        if let currentLiveProgram = serviceManager.appState.currentLiveProgram {
                            CurrentLiveProgramView(liveProgram: currentLiveProgram)
                        } else if let nowPlaying = serviceManager.appState.nowPlaying {
                            // Fallback to legacy view for backward compatibility
                            CurrentProgramView(nowPlaying: nowPlaying)
                        }
                        
                        // Next Program Card (not available in current API)
                        if let nextProgram = serviceManager.getNextProgram() {
                            NextProgramView(program: nextProgram)
                        }
                        
                        // Stream Info Card
                        if let currentLiveProgram = serviceManager.appState.currentLiveProgram {
                            StreamInfoView(liveProgram: currentLiveProgram)
                        }
                        
                        // Current Track Info (not available in current API)
                        if let trackInfo = serviceManager.getCurrentTrack() {
                            CurrentTrackView(track: trackInfo)
                        }

                        // Error Message
                        if let errorMessage = serviceManager.errorMessage {
                            ErrorView(message: errorMessage) {
                                Task {
                                    await serviceManager.refreshNowPlaying()
                                }
                            }
                        }
                        
                        // Debug Info (Phase 0)
                        #if DEBUG
                        if let currentLiveProgram = serviceManager.appState.currentLiveProgram {
                            DebugInfoView(liveProgram: currentLiveProgram)
                        }
                        #endif
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Lyt")
            .refreshable {
                await serviceManager.refreshNowPlaying()
            }
            .task {
                await serviceManager.refreshNowPlaying()
            }
            .overlay {
                if serviceManager.isLoading {
                    LoadingView()
                }
            }
        }
        #if os(macOS)
        .navigationViewStyle(.automatic)
        #endif
    }
}

// MARK: - Channel Picker

struct ChannelPickerView: View {
    let channels: [DRChannel]
    let selectedChannel: DRChannel?
    let onChannelSelected: (DRChannel) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(channels, id: \.id) { channel in
                    ChannelChip(
                        channel: channel,
                        isSelected: selectedChannel?.id == channel.id,
                        onTap: { onChannelSelected(channel) }
                    )
                }
            }
            .padding(.horizontal)
        }
        .background(secondaryBackgroundColor)
        .frame(height: 60)
    }
}

struct ChannelChip: View {
    let channel: DRChannel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(channel.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : labelColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? channel.swiftUIColor : cardBackgroundColor)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Current Program Views

struct CurrentLiveProgramView: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔴 LIVE")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.cornerRadius(4))
                
                Spacer()
                
                Text(liveProgram.channel.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(secondaryLabelColor)
            }
            
            Text(liveProgram.title)
                .font(.title2.weight(.semibold))
                .foregroundColor(labelColor)
                .multilineTextAlignment(.leading)
            
            if let description = liveProgram.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(secondaryLabelColor)
                    .multilineTextAlignment(.leading)
            }
            
            HStack {
                Text("\(liveProgram.startTime.timeString) - \(liveProgram.endTime.timeString)")
                    .font(.caption)
                    .foregroundColor(secondaryLabelColor)
                
                Spacer()
                
                Text(liveProgram.formattedDuration)
                    .font(.caption.weight(.medium))
                    .foregroundColor(secondaryLabelColor)
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Legacy Views for Backward Compatibility

struct CurrentProgramView: View {
    let nowPlaying: DRNowPlaying
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let currentProgram = nowPlaying.currentProgram {
                HStack {
                    Text(nowPlaying.isLive ? "🔴 LIVE" : "📻")
                        .font(.caption.weight(.bold))
                        .foregroundColor(nowPlaying.isLive ? .white : labelColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((nowPlaying.isLive ? Color.red : fillColor).cornerRadius(4))
                    
                    Spacer()
                    
                    Text(nowPlaying.channel.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(secondaryLabelColor)
                }
                
                Text(currentProgram.title)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(labelColor)
                    .multilineTextAlignment(.leading)
                
                if let description = currentProgram.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(secondaryLabelColor)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    Text("\(currentProgram.startTime.timeString) - \(currentProgram.endTime.timeString)")
                        .font(.caption)
                        .foregroundColor(secondaryLabelColor)
                    
                    Spacer()
                    
                    Text(currentProgram.formattedDuration)
                        .font(.caption.weight(.medium))
                        .foregroundColor(secondaryLabelColor)
                }
            }
        }
        .padding()
        .background(secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct NextProgramView: View {
    let program: DRProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📅 UP NEXT")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.cornerRadius(4))
                
                Spacer()
            }
            
            Text(program.title)
                .font(.headline.weight(.medium))
                .foregroundColor(labelColor)
                .multilineTextAlignment(.leading)
            
            if let description = program.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(secondaryLabelColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            
            Text("\(program.startTime.timeString) - \(program.endTime.timeString)")
                .font(.caption)
                .foregroundColor(secondaryLabelColor)
        }
        .padding()
        .background(secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct CurrentTrackView: View {
    let track: DRTrackInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🎵 NOW PLAYING")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.cornerRadius(4))
                
                Spacer()
            }
            
            if let title = track.title {
                Text(title)
                    .font(.headline.weight(.medium))
                    .foregroundColor(labelColor)
                    .multilineTextAlignment(.leading)
            }
            
            if let artist = track.artist {
                Text("by \(artist)")
                    .font(.subheadline)
                    .foregroundColor(secondaryLabelColor)
                    .multilineTextAlignment(.leading)
            }
            
            if let album = track.album {
                Text("from \(album)")
                    .font(.caption)
                    .foregroundColor(tertiaryBackgroundColor)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Stream Info View

struct StreamInfoView: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📡 STREAM INFO")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.cornerRadius(4))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(liveProgram.audioAssets, id: \.url) { asset in
                    HStack {
                        Text(asset.format)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((asset.isHLS ? Color.blue : Color.orange).cornerRadius(3))
                        
                        Text(asset.isHLS ? "High Quality" : "Standard (\(asset.bitrate ?? 0)kbps)")
                            .font(.caption)
                            .foregroundColor(secondaryLabelColor)
                        
                        Spacer()
                        
                        if asset.isStreamLive {
                            Text("🔴 Live")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Debug Info View

#if DEBUG
struct DebugInfoView: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔧 DEBUG INFO")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.cornerRadius(4))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Program ID: \(liveProgram.id)")
                    .font(.caption)
                    .foregroundColor(secondaryLabelColor)
                
                Text("Learn ID: \(liveProgram.learnId)")
                    .font(.caption)
                    .foregroundColor(secondaryLabelColor)
                
                Text("Channel: \(liveProgram.channel.slug)")
                    .font(.caption)
                    .foregroundColor(secondaryLabelColor)
                
                if let streamURL = liveProgram.streamURL {
                    Text("Stream: \(streamURL.prefix(50))...")
                        .font(.caption)
                        .foregroundColor(secondaryLabelColor)
                }
            }
        }
        .padding()
        .background(secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
#endif

// MARK: - Supporting Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(.headline)
                .foregroundColor(secondaryLabelColor)
        }
        .padding(24)
        .background(cardBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("⚠️ Error")
                .font(.headline.weight(.semibold))
                .foregroundColor(.red)
            
            Text(message)
                .font(.body)
                .foregroundColor(secondaryLabelColor)
                .multilineTextAlignment(.center)
            
            Button("Retry", action: onRetry)
                .font(.body.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.red.cornerRadius(8))
        }
        .padding()
        .background(secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
}
