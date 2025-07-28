//
//  DetailView.swift
//  macos
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
            VStack(spacing: 24) {
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
            .padding(20)
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
        VStack(spacing: 20) {
            // Channel artwork
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
                .frame(width: 120, height: 120)
                .shadow(color: channelColor.opacity(0.3), radius: 12, x: 0, y: 6)
                .overlay {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.white)
                }
            
            // Channel info
            VStack(spacing: 8) {
                Text(channel.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let region = region {
                    Text(region.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("DR Radio Channel")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(channelColor.opacity(0.2))
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct DetailProgramSection: View {
    let program: DREpisode
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tv")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Now Playing")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Live indicator
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
            
            VStack(alignment: .leading, spacing: 8) {
                Text(program.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                if !program.description.isEmpty {
                    Text(program.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                if let startTime = program.startDate {
                    Text("Started: \(startTime, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct DetailStreamSection: View {
    let channel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Stream Info")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                Image(systemName: serviceManager.playingChannel?.id == channel.id && serviceManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                SoundbarAnimation(
                    isPlaying: serviceManager.playingChannel?.id == channel.id && serviceManager.isPlaying,
                    color: .white
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
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
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: channelColor.opacity(0.3), radius: 8, x: 0, y: 4)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isCopyable {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    showingCopiedAlert = true
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                .alert("Copied!", isPresented: $showingCopiedAlert) {
                    Button("OK") { }
                } message: {
                    Text("Value copied to clipboard")
                }
            }
        }
        .padding(.vertical, 4)
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