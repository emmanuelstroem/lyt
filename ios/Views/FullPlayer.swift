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
        
        // Get the current program and use its category-based icon
        if let currentProgram = serviceManager.getCurrentProgram(for: currentChannel) {
            return currentProgram.categoryIcon
        }
        
        // Fallback to default radio icon if no current program
        return "antenna.radiowaves.left.and.right"
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
                                if let track = serviceManager.currentTrack {
                                    if track.isCurrentlyPlaying {
                                        // Show channel-program as heading and track as subheading
                                        let programTitle = serviceManager.getCurrentProgram(for: currentChannel)?.cleanTitle() ?? "Live"
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(currentChannel.title) - \(programTitle)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            
                                            Text(track.displayText)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    } else {
                                        // Show channel as heading and program as subheading
                                        let programTitle = serviceManager.getCurrentProgram(for: currentChannel)?.cleanTitle() ?? "Live"
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(currentChannel.title)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            
                                            Text(programTitle)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                } else if let currentProgram = serviceManager.getCurrentProgram(for: currentChannel) {
                                    Text(currentChannel.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    
                                    Text(currentProgram.cleanTitle())
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                } else {
                                    Text("DR Radio Channel")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
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
                        // Play Controls with Skip Buttons
                        HStack(spacing: 40) {
                            // Skip back button
                            Button(action: {
                                // Skip back 30 seconds (go to live for live radio)
                                serviceManager.audioPlayer.skipBackward(by: 30)
                            }) {
                                Image(systemName: "gobackward.30")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
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
                            
                            // Skip forward button
                            Button(action: {
                                // Skip forward (go to live for live radio)
                                serviceManager.audioPlayer.skipForward()
                            }) {
                                Image(systemName: "goforward.plus")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                                                // Secondary Controls
                        HStack(spacing: 24) {
                            AirPlayButtonView(size: 48)
                                .frame(width: 48, height: 48)
                        }
                    }
                    .padding(.horizontal, 20)
                    
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