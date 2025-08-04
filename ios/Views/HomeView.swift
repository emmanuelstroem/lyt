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
    
    // Helper function to extract channel name without slug
    private func extractChannelName(from title: String) -> String {
        // Remove common DR prefixes and suffixes
        var cleanTitle = title
            .replacingOccurrences(of: "DR ", with: "")
            .replacingOccurrences(of: "DR-", with: "")
            .replacingOccurrences(of: "DR_", with: "")
        
        // Remove any trailing numbers or common suffixes
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If it's just a number (like "P1", "P2"), return as is
        if cleanTitle.matches(of: /^P\d+$/).count > 0 {
            return cleanTitle
        }
        
        // For longer names, take the first word or first few characters
        let words = cleanTitle.components(separatedBy: .whitespaces)
        if let firstWord = words.first, !firstWord.isEmpty {
            return firstWord
        }
        
        // Fallback to first 4 characters
        return String(cleanTitle.prefix(4))
    }
    

    
    private var channelColor: Color {
        // DR Radio channel color themes
        switch channel.title.lowercased() {
            case let title where title.contains("p1"):
                return Color.orange // Dark Orange for P1
            case let title where title.contains("p2"):
                return Color.blue // Blue for P2
            case let title where title.contains("p3"):
                return Color.green // Neon Green for P3
            case let title where title.contains("p4"):
                return Color.yellow // Light Orange/Yellow for P4
            case let title where title.contains("p5"):
                return Color.pink // Pink for P5
            case let title where title.contains("p6"):
                return Color.gray // Gray for P6
            case let title where title.contains("p8"):
                return Color.purple // Purple for P8
            default:
                // Fallback to hash-based color for other channels
                let hash = abs(channel.id.hashValue)
                let hue = Double(hash % 360) / 360.0
                let saturation = 0.7 + Double(hash % 20) / 100.0
                let brightness = 0.8 + Double(hash % 20) / 100.0
                return Color(hue: hue, saturation: saturation, brightness: brightness)
        }
    }
    
    
    
    var body: some View {
        ZStack {
            // Background image or gradient
            if let currentProgram = serviceManager.getCurrentProgram(for: channel),
               let imageURL = currentProgram.primaryImageURL,
               let url = URL(string: imageURL) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 80)
                        .clipped()
                        .blur(radius: 2)
                } placeholder: {
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
                }
            } else {
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
            }
            
            // Dark overlay for better text readability
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .frame(width: 140, height: 80)
            
            // Content overlay
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        serviceManager.togglePlayback(for: channel)
                    }) {
                        Image(systemName: serviceManager.playingChannel?.id == channel.id && serviceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // Bottom section with channel title and region
                HStack(alignment: .bottom, spacing: 4) {
                    // Channel title in square view
                    KnockoutTextView(
                        text: extractChannelName(from: channel.name),
                        backgroundColor: channelColor
                    )
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
                    
                    // Region text inline with channel title
                    if let district = channel.district {
                        Text(" \(district)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(channelColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                }
                //                .frame(maxWidth: .infinity, alignment: .leading)
            }
            //            .padding(4)
            .frame(width: 140, height: 80)
        }
        .frame(width: 140, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
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



struct KnockoutTextView: View {
    var text: String
    var backgroundColor: Color = .blue
    
    var body: some View {
        ZStack {
            // Square with transparent text
            TextMaskView(text: text, backgroundColor: backgroundColor)
        }
    }
}

struct TextMaskView: View {
    var text: String
    var backgroundColor: Color
    
    var body: some View {
        // Solid color square
        backgroundColor
            .overlay {
                // Transparent text mask
                GeometryReader { geo in
                    Text(text)
                        .font(.system(size: geo.size.width * 0.6, weight: .black, design: .default))
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .foregroundColor(.black)
                        .blendMode(.destinationOut) // Punch out the text
                }
            }
            .compositingGroup() // Required for destinationOut to work properly
    }
}
