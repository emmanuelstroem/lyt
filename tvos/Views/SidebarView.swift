//
//  SidebarView.swift
//  tvos
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @State private var searchText = ""
    
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
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $searchText)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
            
            // Channel list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredChannels) { channel in
                        SidebarChannelCard(
                            channel: channel,
                            isSelected: selectionState.selectedChannel?.id == channel.id,
                            isPlaying: serviceManager.playingChannel?.id == channel.id,
                            onTap: {
                                selectionState.selectChannel(channel, showSheet: false)
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)
            }
            .refreshable {
                await serviceManager.refreshNowPlaying()
            }
        }
        .navigationTitle("Channels")
    }
}

// MARK: - Sidebar Channel Card

struct SidebarChannelCard: View {
    let channel: DRChannel
    let isSelected: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
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
        Button(role: .none, action: onTap) {
            HStack(spacing: 20) {
                // Channel artwork
                RoundedRectangle(cornerRadius: 12)
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
                    .frame(width: 60, height: 60)
                    .shadow(color: channelColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    .overlay {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                
                // Channel info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(channel.displayName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Playing indicator
                        if isPlaying {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(channelColor)
                        }
                    }
                    
                    Text("DR Radio Channel")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(channelColor)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? channelColor : Color.clear,
                        lineWidth: 3
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())

    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("Search channels...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 18))
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
        )
    }
}

#Preview {
    SidebarView(
        serviceManager: DRServiceManager(),
        selectionState: SelectionState()
    )
} 