//
//  ContentView.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI



struct ContentView: View {
    @StateObject private var serviceManager = DRServiceManager()
    @StateObject private var selectionState = SelectionState()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main TabView
            TabView {
                // Home Tab
                HomeView(serviceManager: serviceManager, selectionState: selectionState)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                
                // Search Tab
                SearchView(serviceManager: serviceManager, selectionState: selectionState)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
            }
            .accentColor(.purple)
            
            // Floating MiniPlayer
            FloatingMiniPlayer(serviceManager: serviceManager, selectionState: selectionState)
        }
    }
}

// MARK: - Floating MiniPlayer
struct FloatingMiniPlayer: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @State private var showingFullPlayer = false
    
    private var channelIcon: String {
        guard let playingChannel = serviceManager.playingChannel else {
            return "antenna.radiowaves.left.and.right"
        }
        
        switch playingChannel.slug.lowercased() {
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
        HStack(spacing: 12) {
            // Channel artwork
            if let playingChannel = serviceManager.playingChannel,
               let currentProgram = serviceManager.getCurrentProgram(for: playingChannel),
               let imageURL = currentProgram.primaryImageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.8), .blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: channelIcon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.8), .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: channelIcon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
            }
            
            // Channel info
            VStack(alignment: .leading, spacing: 2) {
                Text(serviceManager.playingChannel?.title ?? "No Channel")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(serviceManager.isPlaying ? "Live Now" : "Paused")
                    .font(.caption)
                    .foregroundColor(serviceManager.isPlaying ? .red : .gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 16) {
                // AirPlay button
                Button(action: {}) {
                    Image(systemName: "airplayaudio")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                // Play/Pause button
                Button(action: {
                    if let playingChannel = serviceManager.playingChannel {
                        serviceManager.togglePlayback(for: playingChannel)
                    }
                }) {
                    Image(systemName: serviceManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25) // 50% rounded corners
                .fill(.ultraThinMaterial)
                .opacity(0.9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .offset(y: -50) // Move up to sit on top of tab bar
        .onTapGesture {
            showingFullPlayer = true
        }
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerSheet(serviceManager: serviceManager, selectionState: selectionState)
        }
    }
}

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
                                        Text(currentProgram.title.replacingOccurrences(of: channel.title, with: ""))
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
                                    
                                    SoundbarAnimation(isPlaying: serviceManager.playingChannel?.id == channel.id && serviceManager.isPlaying, color: .purple, audioPlayer: serviceManager.audioPlayer)
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
                                        Image(systemName: "heart")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Text("Favorite")
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
                                    
                                    Text(currentProgram.title)
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

// MARK: - Placeholder Views
struct SearchView: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    
    var body: some View {
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
            
            VStack(spacing: 20) {
                Text("Search")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Search functionality coming soon...")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
}



#Preview {
    ContentView()
}
