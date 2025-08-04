//
//  RadioView.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI

struct RadioView: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @State private var searchText = ""
    @State private var isLoading = false
    
    var filteredChannels: [DRChannel] {
        if searchText.isEmpty {
            return serviceManager.availableChannels
        } else {
            return serviceManager.availableChannels.filter { channel in
                channel.displayName.localizedCaseInsensitiveContains(searchText)
            }
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
                
                VStack(spacing: 0) {
                    // Search bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    // Channel list
                    if serviceManager.isLoading {
                        LoadingView()
                    } else if let error = serviceManager.error {
                        ErrorView(error: error) {
                            serviceManager.loadChannels()
                        }
                    } else if filteredChannels.isEmpty {
                        EmptyStateView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredChannels) { channel in
                                                                    RadioChannelCard(
                                    channel: channel,
                                    serviceManager: serviceManager,
                                    onTap: {
                                        // Start streaming the channel
                                        serviceManager.playChannel(channel)
                                        selectionState.selectChannel(channel, showSheet: false)
                                    }
                                )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100) // Space for mini player
                        }
                    }
                }
            }
            .navigationTitle("Radio")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            // Load channels if not already loaded
            if serviceManager.availableChannels.isEmpty {
                serviceManager.loadChannels()
            }
        }
    }
}

// MARK: - Radio Channel Card

struct RadioChannelCard: View {
    let channel: DRChannel
    let serviceManager: DRServiceManager
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var currentProgram: DREpisode?
    @State private var currentTrack: DRTrack?
    
    private var channelColor: Color {
        // Generate a consistent color based on channel ID
        let hash = abs(channel.id.hashValue)
        let hue = Double(hash % 360) / 360.0
        let saturation = 0.6 + Double(hash % 20) / 100.0
        let brightness = 0.7 + Double(hash % 20) / 100.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    

    
    var body: some View {
        Button(role: .none, action: onTap) {
            HStack(spacing: 16) {
                // Channel artwork with real image or fallback
                AsyncImage(url: getChannelImageURL()) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: channelColor.opacity(0.3), radius: 4, x: 0, y: 2)
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
                        .frame(width: 60, height: 60)
                        .shadow(color: channelColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        .overlay {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                }
                
                // Channel info
                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Show current program or track info
                    if let program = getCurrentProgram() {
                        Text(program.cleanTitle())
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else if let track = getCurrentTrack() {
                        Text(track.displayText)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text(channel.type.capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            loadChannelData()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getChannelImageURL() -> URL? {
        // Try to get image from current program first
        if let program = getCurrentProgram(),
           let imageURLString = program.primaryImageURL {
            return URL(string: imageURLString)
        }
        
        // Try to get image from any cached program for this channel
        let channelPrograms = serviceManager.getCachedPrograms(for: channel)
        if let programWithImage = channelPrograms.first(where: { $0.primaryImageURL != nil }),
           let imageURLString = programWithImage.primaryImageURL {
            return URL(string: imageURLString)
        }
        
        return nil
    }
    
    private func getCurrentProgram() -> DREpisode? {
        return serviceManager.getCurrentProgram(for: channel)
    }
    
    private func getCurrentTrack() -> DRTrack? {
        return serviceManager.currentTrack
    }
    
    private func loadChannelData() {
        // Load current program and track data for this channel
        currentProgram = getCurrentProgram()
        currentTrack = getCurrentTrack()
    }
}





#Preview {
    RadioView(
        serviceManager: DRServiceManager(),
        selectionState: SelectionState()
    )
} 