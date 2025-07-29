//
//  ChannelDetailsSheet.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI

// MARK: - Channel Details Sheet
struct ChannelDetailsSheet: View {
    let channel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @Environment(\.dismiss) private var dismiss
    
    private var channelColor: Color {
        let hash = abs(channel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.7 + Double(hash % 20) / 100.0
        let brightness = 0.8 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Channel Artwork Section
                        VStack(spacing: 16) {
                            if let currentProgram = serviceManager.getCurrentProgram(for: channel),
                               let imageURL = currentProgram.landscapeImageURL,
                               let url = URL(string: imageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
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
                                            VStack(spacing: 12) {
                                                Image(systemName: "antenna.radiowaves.left.and.right")
                                                    .font(.system(size: 48, weight: .medium))
                                                    .foregroundColor(.white)
                                                
                                                Text(channel.title)
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
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
                                        VStack(spacing: 12) {
                                            Image(systemName: "antenna.radiowaves.left.and.right")
                                                .font(.system(size: 48, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Text(channel.title)
                                                .font(.title)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .shadow(color: channelColor.opacity(0.3), radius: 12, x: 0, y: 6)
                            }
                        }
                        
                        // Channel Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(channel.title)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    if let currentProgram = serviceManager.getCurrentProgram(for: channel) {
                                        // remove channel title from current program title
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
                        
                        // Playback Controls Section
                        VStack(spacing: 16) {
                            // Main play button
                            Button(action: {
                                serviceManager.togglePlayback(for: channel)
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: serviceManager.playingChannel?.id == channel.id && serviceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(.purple)
                                    

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
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            // Secondary controls
                            HStack(spacing: 20) {
                                Button(action: {}) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "airplayaudio")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Text("AirPlay")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Button(action: {}) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Text("Share")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Channel Description
                        VStack(alignment: .leading, spacing: 12) {
                            // Current Program
                            if let currentProgram = serviceManager.getCurrentProgram(for: channel) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Program")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .textCase(.uppercase)
                                    
                                    Text(currentProgram.cleanTitle())
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    if let description = currentProgram.description {
                                        Text(description)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .lineLimit(3)
                                    } else {
                                        Text("Live radio broadcast")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .lineLimit(3)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
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