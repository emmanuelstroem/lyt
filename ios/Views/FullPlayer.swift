//
//  FullPlayer.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI

// MARK: - Full Player Sheet
struct FullPlayerSheet: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @Environment(\.dismiss) private var dismiss
    @State private var currentTime: Double = 0
    @State private var totalTime: Double = 100
    
    // Get the current playing channel from serviceManager
    private var currentChannel: DRChannel? {
        serviceManager.playingChannel
    }
    
    private var channelColor: Color {
        guard let currentChannel = currentChannel else { return .purple }
        let hash = abs(currentChannel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.7 + Double(hash % 20) / 100.0
        let brightness = 0.8 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    private var channelIcon: String {
        guard let currentChannel = currentChannel else {
            return "antenna.radiowaves.left.and.right"
        }
        
        switch currentChannel.slug.lowercased() {
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
                
                if let currentChannel = currentChannel {
                    VStack(spacing: 40) {
                        // Channel Artwork
                        VStack(spacing: 20) {
                            if let currentProgram = serviceManager.getCurrentProgram(for: currentChannel),
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
                                                Image(systemName: channelIcon)
                                                    .font(.system(size: 64, weight: .medium))
                                                    .foregroundColor(.white)
                                                
                                                Text(currentChannel.title)
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.center)
                                            }
                                        }
                                }
                                .frame(width: 280, height: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 20)
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
                                    .frame(width: 280, height: 280)
                                    .overlay {
                                        VStack(spacing: 16) {
                                            Image(systemName: channelIcon)
                                                .font(.system(size: 64, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Text(currentChannel.title)
                                                .font(.title)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    .shadow(radius: 20)
                            }
                        }
                    
                    // Channel Info
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentChannel.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("DR Radio Channel")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Live indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                
                                Text("LIVE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Current Program
                        if let currentEpisode = MockData.mockEpisodeForChannel(currentChannel.id) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Now Playing")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                
                                Text(currentEpisode.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text(currentEpisode.description ?? "Live radio broadcast")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(3)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Progress Bar (for live radio, this could show time since start)
                    VStack(spacing: 8) {
                        HStack {
                            Text("Live")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("24/7")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        ProgressView(value: currentTime, total: totalTime)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                            .scaleEffect(y: 2)
                    }
                    .padding(.horizontal, 20)
                    
                    // Main Controls
                    VStack(spacing: 24) {
                        // Play/Pause Button
                        Button(action: {
                            if let playingChannel = serviceManager.playingChannel {
                                serviceManager.togglePlayback(for: playingChannel)
                            }
                        }) {
                            Image(systemName: serviceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 80, weight: .medium))
                                .foregroundColor(.purple)
                        }
                        
                        // Secondary Controls
                        HStack(spacing: 40) {
                            Button(action: {}) {
                                VStack(spacing: 4) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Text("Previous")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {}) {
                                VStack(spacing: 4) {
                                    Image(systemName: "airplayaudio")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Text("AirPlay")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {}) {
                                VStack(spacing: 4) {
                                    Image(systemName: "heart")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Text("Favorite")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {}) {
                                VStack(spacing: 4) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Text("Next")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 40)
                } else {
                    // No channel playing
                    VStack(spacing: 20) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("No Channel Playing")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.purple)
                    }
                }
            }
        }
    }
}

#Preview {
    FullPlayerSheet(
        serviceManager: DRServiceManager(),
        selectionState: SelectionState()
    )
} 