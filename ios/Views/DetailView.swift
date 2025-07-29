//
//  DetailView.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI



struct DetailView: View {
    let channel: DRChannel
    let region: ChannelRegion?
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @Environment(\.dismiss) private var dismiss
    
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
                        // Channel artwork
                        ChannelArtworkSection(channel: channel, serviceManager: serviceManager)
                        
                        // Channel info
                        ChannelInfoSection(channel: channel)
                        
                        // Current program
                        if let currentProgram = serviceManager.currentLiveProgram {
                            CurrentProgramSection(program: currentProgram)
                        }
                        
                        // Playback controls
                        PlaybackControlsSection(
                            channel: channel,
                            serviceManager: serviceManager
                        )
                        
                        // Related channels
                        RelatedChannelsSection(serviceManager: serviceManager)
                        
                        // About section (at the bottom)
                        AboutSection(channel: channel, serviceManager: serviceManager)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(channel.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Share channel
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.purple)
                    }
                }
            }
        }
    }
}

// MARK: - Channel Artwork Section

struct ChannelArtworkSection: View {
    let channel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Large channel artwork
            if let currentProgram = serviceManager.getCurrentProgram(for: channel),
               let imageURL = currentProgram.primaryImageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 20)
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
                        .overlay {
                            VStack(spacing: 16) {
                                // Live indicator
                                HStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 12, height: 12)
                                    
                                    Text("LIVE")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                
                                Spacer()
                                
                                // Channel icon and name
                                VStack(spacing: 12) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 48, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text(channel.displayName)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Spacer()
                            }
                        }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: channelColor.opacity(0.3), radius: 12, x: 0, y: 6)
            } else {
                RoundedRectangle(cornerRadius: 20)
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
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 16) {
                            // Live indicator
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                
                                Text("LIVE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            Spacer()
                            
                            // Channel icon and name
                            VStack(spacing: 12) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 48, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text(channel.displayName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                        }
                    }
                    .shadow(color: channelColor.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
    }
    
    private var channelColor: Color {
        let hash = abs(channel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.7 + Double(hash % 20) / 100.0
        let brightness = 0.8 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

// MARK: - Channel Info Section

struct ChannelInfoSection: View {
    let channel: DRChannel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("DR Radio Channel")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(channel.presentationUrl ?? "nil")
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
}

// MARK: - Current Program Section

struct CurrentProgramSection: View {
    let program: DREpisode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tv")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Current Program")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if program.isLive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Program Image
            if let imageURL = program.primaryImageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.gray)
                        }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(program.cleanTitle())
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(program.description ?? "no description")
                        .font(.body)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("Started \(program.startDate ?? Date(), style: .time)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Playback Controls Section

struct PlaybackControlsSection: View {
    let channel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Main play button
            Button(action: {
                serviceManager.togglePlayback(for: channel)
            }) {
                HStack(spacing: 16) {
                    Image(systemName: serviceManager.playingChannel?.id == channel.id && serviceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(channelColor)
                    

                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            
            // Additional controls
            HStack(spacing: 20) {
                Button(action: {
                    // AirPlay
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "airplayaudio")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("AirPlay")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // Share
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("Share")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var channelColor: Color {
        let hash = abs(channel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.7 + Double(hash % 20) / 100.0
        let brightness = 0.8 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

// MARK: - About Section

struct AboutSection: View {
    let channel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if let currentProgram = serviceManager.getCurrentProgram(for: channel) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentProgram.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if let description = currentProgram.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.gray)
                            .lineLimit(nil)
                    } else {
                        Text("No description available for the current program.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .italic()
                    }
                    
                    // Show program type and duration
                    HStack {
                        Text(currentProgram.type)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .clipShape(Capsule())
                        
                        Text(formatDuration(currentProgram.duration))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Text("No current program information available")
                    .font(.body)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Related Channels Section

struct RelatedChannelsSection: View {
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Channels")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(serviceManager.availableChannels.prefix(5)) { channel in
                        RelatedChannelCard(channel: channel)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct RelatedChannelCard: View {
    let channel: DRChannel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Channel artwork
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            channelColor.opacity(0.8),
                            channelColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 80)
                .overlay {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            
            // Channel name
            Text(channel.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 120)
    }
    
    private var channelColor: Color {
        let hash = abs(channel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.6 + Double(hash % 20) / 100.0
        let brightness = 0.7 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

#Preview {
    DetailView(
        channel: DRChannel(
            id: "test-channel",
            title: "Test Channel",
            slug: "test",
            type: "Channel",
            presentationUrl: "https://example.com"
        ),
        region: nil,
        serviceManager: DRServiceManager(),
        selectionState: SelectionState()
    )
} 
