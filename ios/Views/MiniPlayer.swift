//
//  MiniPlayer.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI
import AVKit

struct MiniPlayer: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @State private var showingInfoSheet = false
    @State private var showingAirPlaySheet = false
    @State private var isPlayingState = false
    
    var body: some View {
        if let playingChannel = serviceManager.playingChannel {
            VStack(spacing: 0) {
                // Mini player content
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: 0.0) // Placeholder for now
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                        .scaleEffect(y: 0.5)
                    
                    // Main player content
                    HStack(spacing: 12) {
                        // Channel artwork
                        if let currentProgram = serviceManager.getCurrentProgram(for: playingChannel),
                           let imageURL = currentProgram.primaryImageURL,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                channelColor.opacity(0.9),
                                                channelColor.opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            channelColor.opacity(0.9),
                                            channelColor.opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                }
                        }
                        
                        // Channel info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playingChannel.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            if let currentProgram = serviceManager.getCurrentProgram(for: playingChannel) {
                                Text(currentProgram.title)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            } else {
                                Text("Live Now")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Controls
                        HStack(spacing: 16) {
                            // AirPlay button
                            Button(action: {
                                showingAirPlaySheet = true
                            }) {
                                Image(systemName: "airplayaudio")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            // Play/Pause button
                            Button(action: {
                                serviceManager.togglePlayback(for: playingChannel)
                            }) {
                                Image(systemName: serviceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(channelColor)
                            }
                            
                            // Info button
                            Button(action: {
                                showingInfoSheet = true
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .opacity(0.25)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .sheet(isPresented: $showingInfoSheet) {
                DetailView(
                    channel: playingChannel,
                    region: selectionState.selectedRegion,
                    serviceManager: serviceManager,
                    selectionState: selectionState
                )
            }
            .sheet(isPresented: $showingAirPlaySheet) {
                AirPlaySheet()
            }
        }
    }
    
    // Generate consistent color for channel
    private var channelColor: Color {
        guard let playingChannel = serviceManager.playingChannel else { return .purple }
        let hash = abs(playingChannel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.7 + Double(hash % 20) / 100.0
        let brightness = 0.8 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

// MARK: - AirPlay Sheet

struct AirPlaySheet: View {
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
                
                VStack(spacing: 24) {
                    // AirPlay icon
                    Image(systemName: "airplayaudio")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.purple)
                    
                    Text("AirPlay")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Select a device to stream audio")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    // Device list (placeholder)
                    VStack(spacing: 12) {
                        AirPlayDeviceRow(name: "Living Room TV", isConnected: true)
                        AirPlayDeviceRow(name: "Kitchen Speaker", isConnected: false)
                        AirPlayDeviceRow(name: "Bedroom TV", isConnected: false)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("AirPlay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
        }
    }
}

struct AirPlayDeviceRow: View {
    let name: String
    let isConnected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isConnected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isConnected ? .green : .gray)
            
            Text(name)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            if isConnected {
                Text("Connected")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
    }
}

#Preview {
    MiniPlayer(
        serviceManager: DRServiceManager(),
        selectionState: SelectionState()
    )
} 