//
//  HomeView.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @State private var selectedChannel: DRChannel?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.black.opacity(0.95),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HomeHeader()
                        
                        if serviceManager.isLoading {
                            LoadingView()
                        } else if let error = serviceManager.error {
                            ErrorView(error: error) {
                                serviceManager.loadChannels()
                            }
                        } else if serviceManager.availableChannels.isEmpty {
                            EmptyStateView()
                                            } else {
                        DRChannelsSection(
                            serviceManager: serviceManager,
                            onChannelTap: { channel in
                                selectedChannel = channel
                            }
                        )
                    }
                    
                    // Playback error alert
                    if let playbackError = serviceManager.playbackError {
                        PlaybackErrorAlert(
                            error: playbackError,
                            onDismiss: {
                                serviceManager.clearPlaybackError()
                            }
                        )
                    }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Space for bottom tab bar
                }
            }
        }
        .sheet(item: $selectedChannel) { channel in
            ChannelDetailsSheet(
                channel: channel,
                serviceManager: serviceManager,
                selectionState: selectionState
            )
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text("Loading channels...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error loading channels")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Retry") {
                retryAction()
            }
            .foregroundColor(.blue)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "radio")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No channels available")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Try refreshing to load channels")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Home Header
struct HomeHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lyt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Live Danish Radio")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // User profile picture
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
        }
        .padding(.top, 8)
    }
}



// MARK: - DR Channels Section
struct DRChannelsSection: View {
    @ObservedObject var serviceManager: DRServiceManager
    let onChannelTap: (DRChannel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("DR")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Channels grid with horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [
                    GridItem(.flexible(minimum: 80, maximum: 100)),
                    GridItem(.flexible(minimum: 80, maximum: 100)),
                    GridItem(.flexible(minimum: 80, maximum: 100))
                ], spacing: 12) {
                    ForEach(serviceManager.availableChannels) { channel in
                        DRChannelCard(
                            channel: channel,
                            serviceManager: serviceManager,
                            onTap: onChannelTap
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Channel count info
            Text("\(serviceManager.availableChannels.count) channels available")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
    }
}

struct DRChannelCard: View {
    let channel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    let onTap: (DRChannel) -> Void
    
    private var channelColor: Color {
        let hash = abs(channel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.7 + Double(hash % 20) / 100.0
        let brightness = 0.8 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    private var channelIcon: String {
        switch channel.slug.lowercased() {
        case "p1":
            return "newspaper" // News and current affairs
        case "p2":
            return "music.note.list" // Classical and cultural
        case "p3":
            return "music.mic" // Youth and popular music
        case "p4":
            return "location" // Regional/local
        case "p5":
            return "heart" // Easy listening
        case "p6":
            return "guitars" // Alternative music
        case "p7":
            return "music.note" // Mixed music
        case "p8":
            return "music.note.list" // Jazz
        default:
            return "antenna.radiowaves.left.and.right" // Default radio icon
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            channelColor.opacity(0.9),
                            channelColor.opacity(0.7),
                            channelColor.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 80)
                .overlay {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("LIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            // Channel icon
                            Image(systemName: channelIcon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Button(action: {
                                serviceManager.togglePlayback(for: channel)
                            }) {
                                Image(systemName: serviceManager.playingChannel?.id == channel.id && serviceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Spacer()
                        
                        Text(channel.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                }
        }
        .frame(width: 140, height: 80)
        .onTapGesture {
            onTap(channel)
        }
    }
}

// MARK: - Playback Error Alert
struct PlaybackErrorAlert: View {
    let error: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                Text("Playback Error")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(0.9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: error)
    }
}

#Preview {
    HomeView(
        serviceManager: DRServiceManager(),
        selectionState: SelectionState()
    )
} 