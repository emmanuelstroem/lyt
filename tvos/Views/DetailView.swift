//
//  DetailView.swift
//  tvos
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI



struct DetailView: View {
    let channel: DRChannel
    let region: ChannelRegion?
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero section
                DetailHeroSection(
                    channel: channel,
                    region: region,
                    serviceManager: serviceManager
                )
                
                // Program details
                if let liveProgram = serviceManager.currentLiveProgram {
                    DetailProgramSection(
                        program: liveProgram,
                        serviceManager: serviceManager
                    )
                }
                
                // Stream info
                DetailStreamSection(
                    channel: channel,
                    serviceManager: serviceManager
                )
                
                // Play button
                DetailPlayButton(
                    channel: channel,
                    serviceManager: serviceManager
                )
            }
            .padding(32)
        }
        .navigationTitle("Channel Details")
    }
}

// MARK: - Detail Sections

struct DetailHeroSection: View {
    let channel: DRChannel
    let region: ChannelRegion?
    @ObservedObject var serviceManager: DRServiceManager
    
    // Default color for channels
    private var channelColor: Color {
        // Generate a consistent color based on channel ID
        let hash = abs(channel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.6 + Double(hash % 20) / 100.0
        let brightness = 0.7 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Channel artwork
            RoundedRectangle(cornerRadius: 24)
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
                .frame(width: 160, height: 160)
                .shadow(color: channelColor.opacity(0.3), radius: 16, x: 0, y: 8)
                .overlay {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundColor(.white)
                }
            
            // Channel info
            VStack(spacing: 12) {
                Text(channel.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let region = region {
                    Text(region.name)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Text("DR Radio Channel")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(channelColor.opacity(0.2))
                    )
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct DetailProgramSection: View {
    let program: DREpisode
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "tv")
                    .font(.title)
                    .foregroundColor(.blue)
                
                Text("Now Playing")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Live indicator
                if program.isLive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(program.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                if !program.description.isEmpty {
                    Text(program.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(4)
                }
                
                if let startTime = program.startDate {
                    Text("Started: \(startTime, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
    }
}

struct DetailStreamSection: View {
    let channel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title)
                    .foregroundColor(.green)
                
                Text("Stream Information")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 16) {
                InfoRow(
                    icon: "network",
                    title: "Channel Slug",
                    value: channel.slug,
                    isCopyable: true
                )
                
                InfoRow(
                    icon: "info.circle",
                    title: "Channel ID",
                    value: channel.id,
                    isCopyable: true
                )
                
                InfoRow(
                    icon: "link",
                    title: "Presentation URL",
                    value: channel.presentationUrl,
                    isCopyable: true
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
    }
}

struct DetailPlayButton: View {
    let channel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    
    // Default color for channels
    private var channelColor: Color {
        // Generate a consistent color based on channel ID
        let hash = abs(channel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.6 + Double(hash % 20) / 100.0
        let brightness = 0.7 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    var body: some View {
        Button(action: {
            serviceManager.togglePlayback(for: channel)
        }) {
            HStack(spacing: 16) {
                Image(systemName: serviceManager.playingChannel?.id == channel.id && serviceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                
                SoundbarAnimation(
                    isPlaying: serviceManager.playingChannel?.id == channel.id && serviceManager.isPlaying,
                    color: .white
                )
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(channelColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let isCopyable: Bool
    
    @State private var showingCopiedAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isCopyable {
                Button(action: {
                    // tvOS doesn't have a clipboard, so we'll just show a message
                    showingCopiedAlert = true
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .alert("Value copied to clipboard", isPresented: $showingCopiedAlert) {
                    Button("OK") { }
                }
            }
        }
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