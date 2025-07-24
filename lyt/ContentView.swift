//
//  ContentView.swift
//  lyt
//
//  Created by Emmanuel on 24/07/2025.
//

import SwiftUI

// MARK: - Platform-Specific Colors
// Based on https://mar.codes/apple-colors for proper cross-platform compatibility

private var backgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlBackgroundColor)
    #elseif os(tvOS)
    Color.black // tvOS typically uses black backgrounds
    #else // iOS
    Color(.systemBackground)
    #endif
}

private var secondaryBackgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlColor)
    #elseif os(tvOS)
    Color(.systemGray) // tvOS has systemGray but not systemGray6
    #else // iOS
    Color(.systemGray6)
    #endif
}

private var tertiaryBackgroundColor: Color {
    #if os(macOS)
    Color(NSColor.separatorColor)
    #elseif os(tvOS)
    Color(.systemGray) // tvOS has limited color options
    #else // iOS
    Color(.systemGray4)
    #endif
}

private var separatorColor: Color {
    #if os(macOS)
    Color(NSColor.separatorColor)
    #elseif os(tvOS)
    Color(.systemGray) // tvOS fallback
    #else // iOS
    Color(.separator)
    #endif
}

private var labelColor: Color {
    #if os(macOS)
    Color(NSColor.labelColor)
    #elseif os(tvOS)
    Color.white // tvOS typically uses white text
    #else // iOS
    Color(.label)
    #endif
}

private var secondaryLabelColor: Color {
    #if os(macOS)
    Color(NSColor.secondaryLabelColor)
    #elseif os(tvOS)
    Color.gray // tvOS fallback
    #else // iOS
    Color(.secondaryLabel)
    #endif
}

private var cardBackgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlBackgroundColor)
    #elseif os(tvOS)
    Color(.systemGray).opacity(0.3) // Semi-transparent for tvOS cards
    #else // iOS
    Color(.systemBackground)
    #endif
}

private var fillColor: Color {
    #if os(macOS)
    Color(NSColor.controlColor)
    #elseif os(tvOS)
    Color(.systemGray).opacity(0.5)
    #else // iOS
    Color(.systemFill)
    #endif
}

// MARK: - Main ContentView

struct ContentView: View {
    @StateObject private var serviceManager = DRServiceManager()
    @StateObject private var navigationState = ChannelNavigationState()
    @State private var screenSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    backgroundColor.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Main content based on navigation level
                        switch navigationState.currentLevel {
                        case .channelGroups:
                            ChannelGroupsView(
                                serviceManager: serviceManager,
                                navigationState: navigationState,
                                screenSize: geometry.size
                            )
                            .onAppear {
                                print("📱 ContentView: Displaying ChannelGroupsView")
                                print("   - Available channels: \(serviceManager.appState.availableChannels.map { $0.slug })")
                            }
                            
                        case .regions(let group):
                            RegionsView(
                                group: group,
                                serviceManager: serviceManager,
                                navigationState: navigationState,
                                screenSize: geometry.size
                            )
                            .onAppear {
                                print("📱 ContentView: Displaying RegionsView for group: \(group.name)")
                                print("   - Group isRegional: \(group.isRegional)")
                                print("   - Group channels: \(group.channels.map { $0.slug })")
                            }
                            
                        case .playing(_):
                            NowPlayingView(
                                serviceManager: serviceManager,
                                navigationState: navigationState,
                                screenSize: geometry.size
                            )
                            .onAppear {
                                print("📱 ContentView: Displaying NowPlayingView")
                                print("   - Selected channel: \(navigationState.selectedChannel?.title ?? "nil")")
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Loading overlay
                    if serviceManager.isLoading {
                        AppleMusicLoadingView()
                    }
                    
                    // Now playing bar (when not in playing view)
                    if case .playing(_) = navigationState.currentLevel {
                        // Don't show bar in playing view
                    } else if let channel = navigationState.selectedChannel,
                              let currentLiveProgram = serviceManager.currentLiveProgram {
                        VStack {
                            Spacer()
                            MiniNowPlayingBar(
                                liveProgram: currentLiveProgram,
                                onTap: {
                                    navigationState.selectChannel(channel)
                                }
                            )
                        }
                    }
                }
                .navigationTitle(navigationTitle)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                #endif
                .refreshable {
                    await serviceManager.refreshNowPlaying()
                }
                .toolbar {
                    ToolbarItem(placement: toolbarPlacement) {
                        if case .channelGroups = navigationState.currentLevel {
                            EmptyView()
                        } else {
                            Button("Back") {
                                navigationState.navigateBack()
                            }
                        }
                    }
                }
            }
            #if os(macOS)
            .navigationViewStyle(.automatic)
            #endif
            .onAppear {
                screenSize = geometry.size
                Task {
                    await serviceManager.refreshNowPlaying()
                }
            }
            .onChange(of: geometry.size) { newSize in
                screenSize = newSize
            }
            .onChange(of: navigationState.selectedChannel) { newChannel in
                print("📱 ContentView: onChange(selectedChannel) triggered")
                print("   - New channel: \(newChannel?.title ?? "nil") (\(newChannel?.slug ?? "nil"))")
                print("   - Previous serviceManager selected: \(serviceManager.selectedChannel?.slug ?? "nil")")
                
                if let channel = newChannel {
                    print("   - Calling serviceManager.selectChannel(\(channel.slug))")
                    serviceManager.selectChannel(channel)
                } else {
                    print("   - New channel is nil, not calling serviceManager")
                }
            }
        }
    }
    
    private var navigationTitle: String {
        switch navigationState.currentLevel {
        case .channelGroups:
            return "Radio"
        case .regions(let group):
            return group.name
        case .playing(let channel):
            return channel.displayName
        }
    }
    
    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .navigation
        #else
        .navigationBarLeading
        #endif
    }
}

// MARK: - Channel Groups View

struct ChannelGroupsView: View {
    @ObservedObject var serviceManager: DRServiceManager
    let navigationState: ChannelNavigationState
    let screenSize: CGSize
    
    @State private var channelGroups: [ChannelGroup] = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: ChannelLayoutHelper.gridColumns(for: screenSize),
                spacing: 20
            ) {
                ForEach(channelGroups) { group in
                    ChannelGroupCard(
                        group: group,
                        screenSize: screenSize,
                        onTap: {
                            navigationState.selectGroup(group)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .onAppear {
            updateChannelGroups()
        }
        .onChange(of: serviceManager.appState.availableChannels) { _ in
            updateChannelGroups()
        }
    }
    
    private func updateChannelGroups() {
        channelGroups = ChannelOrganizer.organizeChannels(serviceManager.appState.availableChannels)
    }
}

// MARK: - Regions View

struct RegionsView: View {
    let group: ChannelGroup
    @ObservedObject var serviceManager: DRServiceManager
    let navigationState: ChannelNavigationState
    let screenSize: CGSize
    
    var regions: [ChannelRegion] {
        ChannelOrganizer.getRegionsForGroup(group.channels, groupPrefix: group.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Group description
                VStack(spacing: 12) {
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [group.swiftUIColor.opacity(0.8), group.swiftUIColor.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay {
                                Text(group.name)
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name)
                                .font(.title.weight(.bold))
                                .foregroundColor(labelColor)
                            
                            Text(group.description)
                                .font(.subheadline)
                                .foregroundColor(secondaryLabelColor)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                
                // Regions grid
                LazyVGrid(
                    columns: ChannelLayoutHelper.gridColumns(for: screenSize, isRegionalView: true),
                    spacing: 16
                ) {
                    ForEach(regions) { region in
                        RegionCard(
                            region: region,
                            groupColor: group.swiftUIColor,
                            screenSize: screenSize,
                            onTap: {
                                navigationState.selectChannel(region.channel)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Now Playing View

struct NowPlayingView: View {
    @ObservedObject var serviceManager: DRServiceManager
    let navigationState: ChannelNavigationState
    let screenSize: CGSize
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                if let currentLiveProgram = serviceManager.currentLiveProgram {
                    // Hero section
                    NowPlayingHeroView(
                        liveProgram: currentLiveProgram,
                        screenSize: screenSize
                    )
                    
                    // Stream details
                    StreamDetailsView(liveProgram: currentLiveProgram)
                    
                    // Additional program info for larger screens
                    if !ChannelLayoutHelper.shouldUseCompactLayout(for: screenSize) {
                        ExtendedProgramInfoView(liveProgram: currentLiveProgram)
                    }
                } else {
                    // No program data
                    NoDataView()
                }
                
                // Error message
                if let errorMessage = serviceManager.errorMessage {
                    AppleMusicErrorView(message: errorMessage) {
                        Task {
                            await serviceManager.refreshNowPlaying()
                        }
                    }
                }
                
                #if DEBUG
                // Debug info
                if let currentLiveProgram = serviceManager.currentLiveProgram {
                    DebugInfoView(liveProgram: currentLiveProgram)
                }
                #endif
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Channel Group Card

struct ChannelGroupCard: View {
    let group: ChannelGroup
    let screenSize: CGSize
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Channel "album art"
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [group.swiftUIColor.opacity(0.8), group.swiftUIColor.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: ChannelLayoutHelper.cardHeight(for: screenSize) - 80)
                    .overlay {
                        VStack(spacing: 8) {
                            Text(group.name)
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(.white)
                            
                            if group.isRegional {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                    Text("\(group.channels.count) regions")
                                        .font(.caption.weight(.medium))
                                }
                                .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                
                // Channel info
                VStack(spacing: 6) {
                    Text(group.name)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                    
                    Text(group.description)
                        .font(.subheadline)
                        .foregroundColor(secondaryLabelColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(16)
            .background(cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: false)
    }
}

// MARK: - Region Card

struct RegionCard: View {
    let region: ChannelRegion
    let groupColor: Color
    let screenSize: CGSize
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Region visual
                RoundedRectangle(cornerRadius: 8)
                    .fill(groupColor.opacity(0.15))
                    .frame(height: ChannelLayoutHelper.cardHeight(for: screenSize, isRegionalView: true) - 50)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.title2)
                                .foregroundColor(groupColor)
                            
                            Text(region.displayName)
                                .font(.caption.weight(.bold))
                                .foregroundColor(groupColor)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(groupColor.opacity(0.3), lineWidth: 1)
                    )
                
                // Region name
                Text(region.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(labelColor)
                    .lineLimit(1)
            }
            .padding(12)
            .background(cardBackgroundColor)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enhanced Now Playing Hero

struct NowPlayingHeroView: View {
    let liveProgram: DRLiveProgram
    let screenSize: CGSize
    
    var body: some View {
        let isCompact = ChannelLayoutHelper.shouldUseCompactLayout(for: screenSize)
        
        VStack(spacing: isCompact ? 16 : 24) {
            if isCompact {
                compactHeroLayout
            } else {
                expandedHeroLayout
            }
        }
        .padding(isCompact ? 20 : 30)
        .background(cardBackgroundColor)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
    
    private var compactHeroLayout: some View {
        VStack(spacing: 16) {
            albumArtSection
            programInfoSection
        }
    }
    
    private var expandedHeroLayout: some View {
        HStack(spacing: 30) {
            albumArtSection
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 16) {
                liveIndicatorSection
                programInfoSection
            }
        }
    }
    
    private var albumArtSection: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [liveProgram.channel.swiftUIColor.opacity(0.8), liveProgram.channel.swiftUIColor.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 140, height: 140)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "radio.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text(liveProgram.channel.displayName)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .shadow(color: liveProgram.channel.swiftUIColor.opacity(0.4), radius: 15, x: 0, y: 8)
    }
    
    private var liveIndicatorSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                Text("LIVE")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.red)
            }
            
            Text(liveProgram.channel.displayName)
                .font(.headline.weight(.medium))
                .foregroundColor(secondaryLabelColor)
            
            Text(liveProgram.channel.category)
                .font(.caption)
                .foregroundColor(secondaryLabelColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(fillColor)
                .cornerRadius(10)
        }
    }
    
    private var programInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(liveProgram.title)
                    .font(.title.weight(.bold))
                    .foregroundColor(labelColor)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            if let series = liveProgram.series {
                Text(series.title)
                    .font(.headline.weight(.medium))
                    .foregroundColor(liveProgram.channel.swiftUIColor)
            }
            
            if let description = liveProgram.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(secondaryLabelColor)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            
            // Time and Duration
            HStack {
                Text("\(liveProgram.startTime.timeString) - \(liveProgram.endTime.timeString)")
                    .font(.subheadline)
                    .foregroundColor(secondaryLabelColor)
                
                Spacer()
                
                Text(liveProgram.formattedDuration)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(secondaryLabelColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(fillColor)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Extended Program Info (Large Screens)

struct ExtendedProgramInfoView: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Program Details")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(labelColor)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if !liveProgram.categories.isEmpty {
                    InfoCard(
                        title: "Categories",
                        content: liveProgram.categories.joined(separator: " • "),
                        icon: "tag.fill"
                    )
                }
                
                InfoCard(
                    title: "Duration",
                    content: liveProgram.formattedDuration,
                    icon: "clock.fill"
                )
                
                if let series = liveProgram.series {
                    InfoCard(
                        title: "Series",
                        content: series.title,
                        icon: "tv.fill"
                    )
                }
                
                InfoCard(
                    title: "Channel",
                    content: liveProgram.channel.displayName,
                    icon: "radio.fill"
                )
            }
        }
        .padding(20)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

struct InfoCard: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(secondaryLabelColor)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(secondaryLabelColor)
                
                Spacer()
            }
            
            Text(content)
                .font(.subheadline.weight(.medium))
                .foregroundColor(labelColor)
                .lineLimit(2)
        }
        .padding(12)
        .background(fillColor)
        .cornerRadius(10)
    }
}

// MARK: - Mini Now Playing Bar

struct MiniNowPlayingBar: View {
    let liveProgram: DRLiveProgram
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Mini album art
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [liveProgram.channel.swiftUIColor.opacity(0.8), liveProgram.channel.swiftUIColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "radio.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                
                // Program info
                VStack(alignment: .leading, spacing: 2) {
                    Text(liveProgram.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                    
                    Text(liveProgram.channel.displayName)
                        .font(.caption)
                        .foregroundColor(secondaryLabelColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.medium))
                    .foregroundColor(secondaryLabelColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - No Data View

struct NoDataView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "radio")
                .font(.system(size: 60))
                .foregroundColor(secondaryLabelColor)
            
            Text("No program information available")
                .font(.headline)
                .foregroundColor(secondaryLabelColor)
            
            Text("Pull down to refresh")
                .font(.subheadline)
                .foregroundColor(secondaryLabelColor)
        }
        .padding(40)
    }
}

// MARK: - Support Views (Unchanged from original)

struct StreamDetailsView: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stream Quality")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(labelColor)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(liveProgram.audioAssets, id: \.url) { asset in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(asset.isHLS ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(asset.isHLS ? "High Quality" : "Standard Quality")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(labelColor)
                            
                            Text(asset.format + (asset.bitrate != nil ? " • \(asset.bitrate!)kbps" : ""))
                                .font(.caption)
                                .foregroundColor(secondaryLabelColor)
                        }
                        
                        Spacer()
                        
                        if asset.isStreamLive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("Live")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if asset != liveProgram.audioAssets.last {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(cardBackgroundColor)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct AppleMusicLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Loading...")
                    .font(.headline.weight(.medium))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}

struct AppleMusicErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.title3.weight(.semibold))
                .foregroundColor(labelColor)
            
            Text(message)
                .font(.body)
                .foregroundColor(secondaryLabelColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            Button("Try Again", action: onRetry)
                .font(.body.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
        }
        .padding(24)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#if DEBUG
struct DebugInfoView: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔧 DEBUG INFO")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.cornerRadius(4))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Program ID: \(liveProgram.id)")
                    .font(.caption)
                    .foregroundColor(secondaryLabelColor)
                
                Text("Learn ID: \(liveProgram.learnId)")
                    .font(.caption)
                    .foregroundColor(secondaryLabelColor)
                
                Text("Channel: \(liveProgram.channel.slug)")
                    .font(.caption)
                    .foregroundColor(secondaryLabelColor)
                
                if let streamURL = liveProgram.streamURL {
                    Text("Stream: \(streamURL.prefix(50))...")
                        .font(.caption)
                        .foregroundColor(secondaryLabelColor)
                }
            }
        }
        .padding()
        .background(secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
#endif

#Preview {
    ContentView()
}
