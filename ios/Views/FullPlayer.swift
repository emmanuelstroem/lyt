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
    @State private var volume: Double = 0.7
    
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
    
    private var infoTitle: String {
        guard let currentChannel = currentChannel else { return "No Channel" }
        
        if let track = serviceManager.currentTrack, track.isCurrentlyPlaying {
            let programTitle = serviceManager.getCurrentProgram(for: currentChannel)?.cleanTitle() ?? "Live"
            return "\(currentChannel.title) - \(programTitle)"
        } else {
            return currentChannel.title
        }
    }
    
    private var infoSubtitle: String {
        guard let currentChannel = currentChannel else { return "No program information" }
        
        if let track = serviceManager.currentTrack, track.isCurrentlyPlaying {
            return track.displayText
        } else if let currentProgram = serviceManager.getCurrentProgram(for: currentChannel) {
            return currentProgram.cleanTitle()
        } else {
            return "Live"
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
                    VStack(spacing: 0) {
                        // Top VStack - Artwork Component
                        VStack {
                            PlayerArtworkView(
                                channel: currentChannel,
                                currentProgram: serviceManager.getCurrentProgram(for: currentChannel),
                                channelColor: channelColor,
                                channelIcon: channelIcon
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Bottom VStack - All other components
                        VStack(spacing: 30) {
                            // Info Component
                            PlayerInfoView(
                                title: infoTitle,
                                subtitle: infoSubtitle
                            ) {
                                // Ellipsis button action
                                print("Show more options")
                            }
                            
                            // Progress Bar with centered LIVE text and transparency fade
                            VStack(spacing: 8) {
                                GeometryReader { geometry in
                                    ZStack {
                                        ProgressView(value: currentTime, total: totalTime)
                                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                                            .scaleEffect(y: 2)
                                            .mask(
                                                RadialGradient(
                                                    colors: [
                                                        Color.black.opacity(0.0),
                                                        Color.black.opacity(0.5),
                                                        Color.black.opacity(1.0)
                                                    ],
                                                    center: .center,
                                                    startRadius: 0,
                                                    endRadius: geometry.size.width * 0.5 // 3/4 of half width
                                                )
                                            )
                                        
                                        Text("LIVE")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .opacity(0.8)
                                    }
                                }
                                .frame(height: 20) // Fixed height for the progress view
                            }
                            .padding(.horizontal, 20)
                            
                            // Controls Component
                            PlayerControlsView(
                                isPlaying: serviceManager.isPlaying,
                                onBackwardTap: {
                                    serviceManager.audioPlayer.skipBackward(by: 30)
                                },
                                onPlayPauseTap: {
                                    if let playingChannel = serviceManager.playingChannel {
                                        serviceManager.togglePlayback(for: playingChannel)
                                    }
                                },
                                onForwardTap: {
                                    serviceManager.audioPlayer.skipForward()
                                }
                            )
                            
                            // Volume Component
                            PlayerVolumeView(
                                volume: $volume
                            ) { newVolume in
                                // Handle volume change
                                print("Volume changed to: \(newVolume)")
                            }
                            
                            // Actions Component
                            PlayerActionsView(
                                onQuoteTap: {
                                    print("Quote tapped")
                                },
                                onAirPlayTap: {
                                    print("AirPlay tapped")
                                },
                                onListTap: {
                                    print("List tapped")
                                }
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .overlay(alignment: .top) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
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
