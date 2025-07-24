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
            ZStack {
                // Background
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main Content
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Hero Section - Currently Playing
                            if let currentLiveProgram = serviceManager.appState.currentLiveProgram {
                                NowPlayingHeroView(liveProgram: currentLiveProgram)
                            } else if let nowPlaying = serviceManager.appState.nowPlaying {
                                LegacyNowPlayingHeroView(nowPlaying: nowPlaying)
                            }
                            
                            // Channel Selection Section
                            ChannelGridView(
                                channels: serviceManager.appState.availableChannels,
                                selectedChannel: serviceManager.appState.selectedChannel,
                                onChannelSelected: { channel in
                                    serviceManager.selectChannel(channel)
                                }
                            )
                            
                            // Stream Details Section
                            if let currentLiveProgram = serviceManager.appState.currentLiveProgram {
                                StreamDetailsView(liveProgram: currentLiveProgram)
                            }
                            
                            // Error Message
                            if let errorMessage = serviceManager.errorMessage {
                                AppleMusicErrorView(message: errorMessage) {
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
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 100) // Space for now playing bar
                    }
                    
                    Spacer()
                }
                
                // Loading Overlay
                if serviceManager.isLoading {
                    AppleMusicLoadingView()
                }
                
                // Now Playing Bar (Apple Music style)
                VStack {
                    Spacer()
                    if let currentLiveProgram = serviceManager.appState.currentLiveProgram {
                        NowPlayingBar(liveProgram: currentLiveProgram)
                    }
                }
            }
            .navigationTitle("Radio")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .refreshable {
                await serviceManager.refreshNowPlaying()
            }
            .task {
                await serviceManager.refreshNowPlaying()
            }
        }
        #if os(macOS)
        .navigationViewStyle(.automatic)
        #endif
    }
}

// MARK: - Now Playing Hero Section

struct NowPlayingHeroView: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(spacing: 16) {
            // Album Art Section
            HStack {
                // Large Album Art Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [liveProgram.channel.swiftUIColor.opacity(0.8), liveProgram.channel.swiftUIColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay {
                        VStack {
                            Image(systemName: "radio.fill")
                                .font(.title)
                                .foregroundColor(.white)
                            Text(liveProgram.channel.displayName)
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(color: liveProgram.channel.swiftUIColor.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Spacer()
                
                // Live indicator and channel info
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.red)
                    }
                    
                    Text(liveProgram.channel.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(secondaryLabelColor)
                    
                    Text(liveProgram.channel.category)
                        .font(.caption)
                        .foregroundColor(secondaryLabelColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(fillColor)
                        .cornerRadius(8)
                }
            }
            
            // Program Information
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(liveProgram.title)
                        .font(.title2.weight(.bold))
                        .foregroundColor(labelColor)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                
                if let series = liveProgram.series {
                    Text(series.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(liveProgram.channel.swiftUIColor)
                }
                
                if let description = liveProgram.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(secondaryLabelColor)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Time and Duration
                HStack {
                    Text("\(liveProgram.startTime.timeString) - \(liveProgram.endTime.timeString)")
                        .font(.caption)
                        .foregroundColor(secondaryLabelColor)
                    
                    Spacer()
                    
                    Text(liveProgram.formattedDuration)
                        .font(.caption.weight(.medium))
                        .foregroundColor(secondaryLabelColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(fillColor)
                        .cornerRadius(6)
                }
            }
        }
        .padding(20)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Channel Grid (Apple Music Style)

struct ChannelGridView: View {
    let channels: [DRChannel]
    let selectedChannel: DRChannel?
    let onChannelSelected: (DRChannel) -> Void
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stations")
                    .font(.title2.weight(.bold))
                    .foregroundColor(labelColor)
                Spacer()
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(channels, id: \.id) { channel in
                    ChannelCard(
                        channel: channel,
                        isSelected: selectedChannel?.id == channel.id,
                        onTap: { onChannelSelected(channel) }
                    )
                }
            }
        }
    }
}

struct ChannelCard: View {
    let channel: DRChannel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Channel "Album Art"
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [channel.swiftUIColor.opacity(0.8), channel.swiftUIColor.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "radio.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text(channel.name)
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? channel.swiftUIColor : Color.clear, lineWidth: 2)
                    )
                
                // Channel Info
                VStack(spacing: 4) {
                    Text(channel.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                    
                    Text(channel.category)
                        .font(.caption)
                        .foregroundColor(secondaryLabelColor)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(cardBackgroundColor)
            .cornerRadius(12)
            .shadow(color: .black.opacity(isSelected ? 0.15 : 0.05), radius: isSelected ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stream Details Section

struct StreamDetailsView: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stream Quality")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(labelColor)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(liveProgram.audioAssets, id: \.url) { asset in
                    HStack(spacing: 12) {
                        // Quality Icon
                        Circle()
                            .fill(asset.isHLS ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(asset.isHLS ? "High Quality" : "Standard Quality")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(labelColor)
                            
                            Text(asset.format + (asset.bitrate != nil ? " • \(asset.bitrate!)kbps" : ""))
                                .font(.caption)
                                .foregroundColor(secondaryLabelColor)
                        }
                        
                        Spacer()
                        
                        if asset.isStreamLive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("Live")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if asset != liveProgram.audioAssets.last {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(cardBackgroundColor)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Now Playing Bar (Apple Music Style)

struct NowPlayingBar: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        HStack(spacing: 12) {
            // Mini album art
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [liveProgram.channel.swiftUIColor.opacity(0.8), liveProgram.channel.swiftUIColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "radio.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            
            // Program info
            VStack(alignment: .leading, spacing: 2) {
                Text(liveProgram.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(labelColor)
                    .lineLimit(1)
                
                Text(liveProgram.channel.displayName)
                    .font(.caption)
                    .foregroundColor(secondaryLabelColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play/pause button
            Button(action: {
                // TODO: Implement play/pause functionality in Phase 1
            }) {
                Image(systemName: "pause.fill")
                    .font(.title3)
                    .foregroundColor(labelColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Legacy Views for Backward Compatibility

struct LegacyNowPlayingHeroView: View {
    let nowPlaying: DRNowPlaying
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [.blue.opacity(0.8), .blue.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                    .overlay {
                        VStack {
                            Image(systemName: "radio.fill")
                                .font(.title)
                                .foregroundColor(.white)
                            Text(nowPlaying.channel.displayName)
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if nowPlaying.isLive {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(nowPlaying.channel.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(secondaryLabelColor)
                }
            }
            
            if let currentProgram = nowPlaying.currentProgram {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(currentProgram.title)
                            .font(.title2.weight(.bold))
                            .foregroundColor(labelColor)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    
                    if let description = currentProgram.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(secondaryLabelColor)
                            .lineLimit(3)
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(fillColor)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Apple Music Style Support Views

struct AppleMusicLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Loading...")
                    .font(.headline.weight(.medium))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}

struct AppleMusicErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.title3.weight(.semibold))
                .foregroundColor(labelColor)
            
            Text(message)
                .font(.body)
                .foregroundColor(secondaryLabelColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            Button("Try Again", action: onRetry)
                .font(.body.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
        }
        .padding(24)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Debug Info View (Unchanged)

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

#Preview {
    ContentView()
}
