//
//  ContentView.swift
//  lyt
//
//  Created by Emmanuel on 24/07/2025.
//

import SwiftUI
import Combine

// MARK: - Extracted Component Imports
// These components have been moved to separate files for better organization



// MARK: - Screen Size Categories

enum ScreenSizeCategory {
    case compact    // iPhone
    case regular    // iPad portrait, smaller iPads
    case large      // iPad landscape, macOS
    
    static func category(for size: CGSize) -> ScreenSizeCategory {
        let minDimension = min(size.width, size.height)
        let _ = max(size.width, size.height) // Unused but keeping for potential future use
        
    #if os(macOS)
        // macOS is always large
        return .large
    #elseif os(tvOS)
        // tvOS is always large
        return .large
        #else
        // iOS/iPadOS logic - Updated thresholds for modern devices
        if minDimension < 500 {
            return .compact // iPhone (even largest iPhones have width < 500)
        } else if minDimension < 700 {
            return .regular // iPad portrait or smaller iPad
        } else {
            return .large   // iPad landscape
        }
    #endif
}

    var usesMasterDetailLayout: Bool {
        switch self {
        case .compact:
            return false
        case .regular, .large:
            return true
        }
    }

    var usesSheetPresentation: Bool {
        return self == .compact
    }
}

// MARK: - Selection State



// MARK: - Main ContentView

struct ContentView: View {
    @StateObject private var serviceManager = DRServiceManager()
    @StateObject private var navigationState = ChannelNavigationState()
    @StateObject private var selectionState = SelectionState()
    @State private var screenSize: CGSize = .zero
    @State private var sizeCategory: ScreenSizeCategory = .compact
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                // Choose platform-specific layout
                #if os(tvOS)
                TVLayout(
                    serviceManager: serviceManager,
                    navigationState: navigationState,
                    selectionState: selectionState,
                    screenSize: screenSize
                )
                #elseif os(macOS)
                MacOSLayout(
                    serviceManager: serviceManager,
                    navigationState: navigationState,
                    selectionState: selectionState,
                    screenSize: screenSize
                )
                #else
                // iOS - choose based on screen size
                if sizeCategory.usesMasterDetailLayout {
                    iPadLayout(
                        serviceManager: serviceManager,
                        navigationState: navigationState,
                        selectionState: selectionState,
                        screenSize: screenSize
                    )
                } else {
                    iPhoneLayout(
                        serviceManager: serviceManager,
                        navigationState: navigationState,
                        selectionState: selectionState,
                        screenSize: screenSize
                    )
                }
                #endif
                
                // Loading overlay
                if serviceManager.isLoading {
                    PodcastStyleLoadingView()
                }
                
                // Now playing bar (when not showing details and audio is playing)
                if shouldShowMiniPlayer {
                    VStack {
                        Spacer()
                        PodcastStyleMiniPlayer(
                            liveProgram: serviceManager.currentLiveProgram!,
                                serviceManager: serviceManager,
                            onTap: {
                                if let playingChannel = serviceManager.playingChannel {
                                    if sizeCategory.usesSheetPresentation {
                                        selectionState.selectChannel(playingChannel, showSheet: true)
                                    } else {
                                        selectionState.selectChannel(playingChannel)
                                    }
                                }
                            }
                        )
                    }
                }
            }
                            .onAppear {
                updateScreenSize(geometry.size)
                Task {
                    await serviceManager.refreshNowPlaying()
                }
            }
            .onChange(of: geometry.size) { newSize in
                updateScreenSize(newSize)
            }
            .onChange(of: selectionState.selectedChannel) { newChannel in
                if let channel = newChannel {
                    // Selection changed to: \(channel.title) (category: \(sizeCategory), sheet: \(selectionState.showingChannelSheet))
                    
                    serviceManager.selectChannel(channel)
                    
                    // Only trigger navigation for compact layout when NOT showing sheet
                    if !sizeCategory.usesMasterDetailLayout && !selectionState.showingChannelSheet {
                        navigationState.selectChannel(channel)
                    }
                }
            }
            .sheet(isPresented: $selectionState.showingChannelSheet) {
                if let channel = selectionState.selectedChannel {
                    ChannelDetailSheetView(
                        channel: channel,
                                serviceManager: serviceManager,
                        onDismiss: {
                            selectionState.showingChannelSheet = false
                        }
                    )
                }
            }
            .sheet(isPresented: $selectionState.showingRegionSheet) {
                if let group = selectionState.selectedGroup {
                    RegionSelectionSheetView(
                        group: group,
                                serviceManager: serviceManager,
                        selectionState: selectionState,
                        onDismiss: {
                            selectionState.showingRegionSheet = false
                        }
                    )
                }
            }
        }
    }
    

    
    // MARK: - Content Views
    
    @ViewBuilder
    private var sidebarContent: some View {
        // For larger screens, use a clean list layout instead of 3-column grid
        SidebarListView(
            serviceManager: serviceManager,
            selectionState: selectionState,
            navigationState: navigationState,
            screenSize: screenSize,
            sizeCategory: sizeCategory
        )
    }
    

    

    

    
    @ViewBuilder
    private var detailPanelContent: some View {
        if selectionState.showingNestedNavigation, let selectedChannel = selectionState.selectedChannel {
            // Show channel details with back button when in nested navigation
            VStack(spacing: 0) {
                // Custom navigation bar
                HStack {
                    Button(action: {
                        selectionState.dismissNestedNavigation()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back to Regions")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(selectedChannel.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(labelColor)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(cardBackgroundColor)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .bottom
                )
                
                // Channel detail content
                ChannelDetailView(
                    channel: selectedChannel,
                    region: selectionState.selectedRegion,
                    serviceManager: serviceManager,
                    sizeCategory: sizeCategory
                )
            }
        } else if let selectedChannel = selectionState.selectedChannel {
            ChannelDetailView(
                channel: selectedChannel,
                region: selectionState.selectedRegion,
                serviceManager: serviceManager,
                sizeCategory: sizeCategory
            )
        } else if let selectedGroup = selectionState.selectedGroup {
            if selectedGroup.isRegional {
                // For regional groups, show regions in the detail view
                RegionDetailView(
                    group: selectedGroup,
                    selectionState: selectionState,
                    serviceManager: serviceManager,
                    sizeCategory: sizeCategory
                )
            } else {
                GroupDetailView(
                    group: selectedGroup,
                    serviceManager: serviceManager,
                    sizeCategory: sizeCategory
                )
            }
        } else {
            DetailPlaceholderView()
        }
    }


    

    
    // MARK: - Helper Properties
    
    private var shouldShowMiniPlayer: Bool {
        guard let _ = serviceManager.playingChannel,
              let _ = serviceManager.currentLiveProgram,
              serviceManager.audioPlayer.playbackState != .stopped else {
            return false
        }
        
        // Don't show if we're already showing details for the playing channel
        if sizeCategory.usesMasterDetailLayout {
            return selectionState.selectedChannel?.id != serviceManager.playingChannel?.id
        } else {
            // Check if we're not currently in playing view for this channel
            switch navigationState.currentLevel {
            case .playing(let currentChannel):
                return currentChannel.id != serviceManager.playingChannel?.id
            default:
                return true
            }
        }
    }
    

    
    private func updateScreenSize(_ size: CGSize) {
        screenSize = size
        let newCategory = ScreenSizeCategory.category(for: size)
        
        // Screen size: \(size) -> \(newCategory) (master-detail: \(newCategory.usesMasterDetailLayout))
        
        sizeCategory = newCategory
    }
}

// MARK: - Master Panel Views

struct MasterChannelGroupsView: View {
    let provider: RadioStationProvider
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    let navigationState: ChannelNavigationState
    let screenSize: CGSize
    let sizeCategory: ScreenSizeCategory
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: PodcastLayoutHelper.masterGridColumns(for: sizeCategory),
                spacing: 20
            ) {
                ForEach(provider.channelGroups) { group in
                    MasterChannelGroupCard(
                        group: group,
                        isSelected: selectionState.selectedGroup?.id == group.id,
                        onTap: {
                            selectionState.selectGroup(group)
                            
                            // For regional groups, also navigate to regions view in master panel
                            if group.isRegional {
                            navigationState.selectGroup(group)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
}

struct MasterRegionsView: View {
    let group: ChannelGroup
    @ObservedObject var serviceManager: DRServiceManager
    let navigationState: ChannelNavigationState
    @ObservedObject var selectionState: SelectionState
    let screenSize: CGSize
    let sizeCategory: ScreenSizeCategory
    
    var regions: [ChannelRegion] {
        ChannelOrganizer.getRegionsForGroup(group.channels, groupPrefix: group.id)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: PodcastLayoutHelper.masterRegionGridColumns(for: sizeCategory),
                spacing: 16
            ) {
                ForEach(regions) { region in
                    MasterRegionCard(
                        region: region,
                        groupColor: group.swiftUIColor,
                        isSelected: selectionState.selectedChannel?.id == region.channel.id,
                        onTap: {
                            selectionState.selectChannel(region.channel, inRegion: region)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Back") {
                    navigationState.navigateBack()
                    selectionState.clearSelection()
                }
            }
        }
    }
}

// MARK: - Compact Panel Views

struct CompactChannelGroupsView: View {
    let provider: RadioStationProvider
    @ObservedObject var serviceManager: DRServiceManager
    let navigationState: ChannelNavigationState
    @ObservedObject var selectionState: SelectionState
    let screenSize: CGSize
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: PodcastLayoutHelper.gridColumns(for: screenSize),
                spacing: 24
            ) {
                ForEach(provider.channelGroups) { group in
                    PodcastStyleChannelCard(
                        group: group,
                        screenSize: screenSize,
                        onTap: {
                            if group.isRegional {
                                selectionState.selectGroup(group, showSheet: true)
                            } else if let channel = group.channels.first {
                                selectionState.selectChannel(channel, showSheet: true)
                            }
                        },
                        serviceManager: serviceManager
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 120)
        }
    }
}

struct CompactRegionsView: View {
    let group: ChannelGroup
    @ObservedObject var serviceManager: DRServiceManager
    let navigationState: ChannelNavigationState
    @ObservedObject var selectionState: SelectionState
    let screenSize: CGSize
    
    var regions: [ChannelRegion] {
        ChannelOrganizer.getRegionsForGroup(group.channels, groupPrefix: group.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Podcast-style group header
                PodcastStyleGroupHeader(group: group)
                
                // Regions grid
                LazyVGrid(
                    columns: PodcastLayoutHelper.regionGridColumns(for: screenSize),
                    spacing: 20
                ) {
                    ForEach(regions) { region in
                        PodcastStyleRegionCard(
                            region: region,
                            groupColor: group.swiftUIColor,
                            screenSize: screenSize,
                            onTap: {
                                selectionState.selectChannel(region.channel, showSheet: true)
                            },
                            serviceManager: serviceManager
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Master Panel Cards

struct MasterChannelGroupCard: View {
    let group: ChannelGroup
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Compact artwork
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [group.swiftUIColor.opacity(0.8), group.swiftUIColor.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: group.isRegional ? "location.fill" : "radio.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                    
                    Text(group.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(secondaryLabelColor)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if group.isRegional {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryLabelColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? group.swiftUIColor.opacity(0.1) : cardBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? group.swiftUIColor : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct MasterRegionCard: View {
    let region: ChannelRegion
    let groupColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Compact artwork
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [groupColor.opacity(0.8), groupColor.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                
                Text(region.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(labelColor)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? groupColor.opacity(0.1) : cardBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? groupColor : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}



struct SidebarListView: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    @ObservedObject var navigationState: ChannelNavigationState
    let screenSize: CGSize
    let sizeCategory: ScreenSizeCategory
    
    @State private var providers: [RadioStationProvider] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if serviceManager.isLoading {
                    PodcastStyleLoadingView()
                } else if let errorMessage = serviceManager.errorMessage {
                    PodcastStyleErrorView(
                        message: errorMessage,
                        onRetry: { serviceManager.loadChannels() }
                    )
                } else if providers.isEmpty {
                    PodcastStyleNoDataView()
                } else {
                    ForEach(providers) { provider in
                        VStack(alignment: .leading, spacing: 12) {
                    HStack {
                                Image(systemName: provider.logoSystemName)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(provider.swiftUIColor)
                                
                                Text(provider.name)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(labelColor)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Channel groups as a vertical list
                            LazyVStack(spacing: 8) {
                                ForEach(provider.channelGroups) { group in
                                    SidebarListCard(
                                        group: group,
                                        isSelected: selectionState.selectedGroup?.id == group.id,
                                        onTap: {
                                            selectionState.selectGroup(group)
                                            
                                            // For non-regional groups, also select the first channel
                                            if !group.isRegional, let channel = group.channels.first {
                                                selectionState.selectChannel(channel)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(backgroundColor)
        .onAppear {
            updateProviders()
            if serviceManager.appState.availableChannels.isEmpty && !serviceManager.isLoading {
                serviceManager.loadChannels()
            }
        }
        .onChange(of: serviceManager.appState.availableChannels) { _ in
            updateProviders()
        }
    }
    
    private func updateProviders() {
        providers = ChannelOrganizer.organizeProviders(serviceManager.appState.availableChannels)
    }
}

struct SidebarListCard: View {
    let group: ChannelGroup
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Group icon
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                            colors: [group.swiftUIColor.opacity(0.8), group.swiftUIColor.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay {
                        Image(systemName: group.isRegional ? "location.fill" : "radio.fill")
                            .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        
                VStack(alignment: .leading, spacing: 6) {
                            Text(group.name)
                        .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(labelColor)
                        .lineLimit(1)
                            
                            Text(group.description)
                        .font(.system(size: 15, weight: .regular))
                                .foregroundColor(secondaryLabelColor)
                        .lineLimit(2)
                    
                    if group.isRegional {
                        Text("\(group.channels.count) regions")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(group.swiftUIColor)
                    }
                        }
                        
                        Spacer()
                
                if group.isRegional {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(secondaryLabelColor)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(isSelected ? Color.blue.opacity(0.1) : cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail Views

struct DetailPlaceholderView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "radio")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(secondaryLabelColor)
            
            Text("Select a channel or group")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(secondaryLabelColor)
            
            Text("Choose from the list to see details here")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(secondaryLabelColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(secondaryBackgroundColor.opacity(0.3))
    }
}

struct GroupDetailView: View {
    let group: ChannelGroup
    @ObservedObject var serviceManager: DRServiceManager
    let sizeCategory: ScreenSizeCategory
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Group hero section
                VStack(spacing: 24) {
                    // Large artwork
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    group.swiftUIColor.opacity(0.9),
                                    group.swiftUIColor.opacity(0.7),
                                    group.swiftUIColor.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .shadow(color: group.swiftUIColor.opacity(0.4), radius: 20, x: 0, y: 10)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: group.isRegional ? "location.circle.fill" : "radio.fill")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundColor(.white)
                                
                                Text(group.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    
                    // Group info
                    VStack(spacing: 12) {
                        Text(group.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(labelColor)
                        
                        Text(group.description)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(secondaryLabelColor)
                            .multilineTextAlignment(.center)
                        
                        if group.isRegional {
                            Text("\(group.channels.count) regions")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(group.swiftUIColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(group.swiftUIColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                // Additional group stats/info
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    DetailInfoCard(
                        title: "Channels",
                        content: "\(group.channels.count)",
                        icon: "radio.fill",
                        color: group.swiftUIColor
                    )
                    
                    DetailInfoCard(
                        title: "Type",
                        content: group.isRegional ? "Regional" : "National",
                        icon: group.isRegional ? "location.fill" : "globe",
                        color: group.swiftUIColor
                    )
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
}

struct ChannelDetailView: View {
    let channel: DRChannel
    let region: ChannelRegion?
    @ObservedObject var serviceManager: DRServiceManager
    let sizeCategory: ScreenSizeCategory
    
    var currentProgram: DRLiveProgram? {
        return serviceManager.appState.allLivePrograms.first { $0.channel.id == channel.id }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                if let program = currentProgram {
                    // Channel with current program
                    DetailHeroView(
                        liveProgram: program,
                        region: region,
                        serviceManager: serviceManager,
                        sizeCategory: sizeCategory
                    )
                    
                    DetailProgramInfo(liveProgram: program)
                    
                    if sizeCategory == .large {
                        DetailStreamInfo(liveProgram: program)
                    }
                } else {
                    // Channel without program data
                    DetailChannelOnlyView(
                        channel: channel,
                        region: region,
                        serviceManager: serviceManager
                    )
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
}

struct ChannelDetailSheetView: View {
    let channel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    let onDismiss: () -> Void
    
    var currentProgram: DRLiveProgram? {
        return serviceManager.appState.allLivePrograms.first { $0.channel.id == channel.id }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let program = currentProgram {
                        PodcastStyleHeroView(
                            liveProgram: program,
                            screenSize: CGSize(width: 400, height: 600), // Assume compact
                            serviceManager: serviceManager
                        )
                        
                        PodcastStyleProgramDetails(liveProgram: program)
                    } else {
                        // Channel without program data
                        VStack(spacing: 20) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [channel.swiftUIColor.opacity(0.8), channel.swiftUIColor.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .overlay {
                                    VStack(spacing: 12) {
                                        Image(systemName: "radio.fill")
                                            .font(.system(size: 48, weight: .light))
                                            .foregroundColor(.white)
                                        
                                        Text(channel.displayName)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            
                            Text(channel.displayName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(labelColor)
                            
                            Text(channel.description)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(secondaryLabelColor)
                            
                            PodcastStyleLargePlayButton(
                                liveProgram: DRLiveProgram(
                                    id: "temp",
                                    type: "Live",
                                    learnId: "temp",
                                    durationMilliseconds: 3600000,
                                    categories: [],
                                    productionNumber: "temp",
                                    startTime: Date(),
                                    endTime: Date().addingTimeInterval(3600),
                                    presentationUrl: nil,
                                    order: 0,
                                    title: "Live Radio",
                                    description: nil,
                                    series: nil,
                                    channel: channel,
                                    audioAssets: [],
                                    imageAssets: [],
                                    isAvailableOnDemand: false,
                                    hasVideo: false,
                                    explicitContent: false,
                                    slug: "temp"
                                ),
                                serviceManager: serviceManager
                            )
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle(channel.displayName)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Region Selection Sheet

struct RegionSelectionSheetView: View {
    let group: ChannelGroup
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    let onDismiss: () -> Void
    
    @State private var selectedChannelForSheet: DRChannel?
    @State private var selectedRegionForSheet: ChannelRegion?
    @State private var showingNestedChannelSheet = false
    
    var regions: [ChannelRegion] {
        ChannelOrganizer.getRegionsForGroup(group.channels, groupPrefix: group.id)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Group header
                    VStack(spacing: 20) {
                        // Large artwork
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [group.swiftUIColor.opacity(0.9), group.swiftUIColor.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: group.swiftUIColor.opacity(0.4), radius: 12, x: 0, y: 6)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "location.circle.fill")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text(group.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        
                        VStack(spacing: 12) {
                            Text(group.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(labelColor)
                            
                            Text(group.description)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(secondaryLabelColor)
                                .multilineTextAlignment(.center)
                            
                            Text("\(group.channels.count) regions available")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(group.swiftUIColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(group.swiftUIColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    
                    // Regions list
                LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                    spacing: 16
                ) {
                    ForEach(regions) { region in
                                                         RegionSheetCard(
                            region: region,
                            groupColor: group.swiftUIColor,
                                 serviceManager: serviceManager,
                            onTap: {
                                     selectedChannelForSheet = region.channel
                                     selectedRegionForSheet = region
                                     showingNestedChannelSheet = true
                                     // Also update service manager for proper state management
                                     serviceManager.selectChannel(region.channel)
                                 }
                             )
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Select Region")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                                 ToolbarItem(placement: .primaryAction) {
                     Button("Close") {
                         onDismiss()
                     }
                 }
             }
             .sheet(isPresented: $showingNestedChannelSheet) {
                 if let channel = selectedChannelForSheet {
                     NestedChannelDetailSheetView(
                         channel: channel,
                         region: selectedRegionForSheet,
                         serviceManager: serviceManager,
                         onDismiss: {
                             showingNestedChannelSheet = false
                             selectedChannelForSheet = nil
                             selectedRegionForSheet = nil
                         }
                     )
                 }
             }
         }
     }
}

struct RegionSheetCard: View {
    let region: ChannelRegion
    let groupColor: Color
    @ObservedObject var serviceManager: DRServiceManager
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        #if os(tvOS)
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(.plain)
        #else
        cardContent
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { value in
                    isPressed = false
                    // Only trigger tap if drag distance is minimal (not a scroll)
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    if dragDistance < 10 {
                        onTap()
                    }
                }
        )
        #endif
    }
    
    private var cardContent: some View {
        VStack(spacing: 12) {
            // Region artwork
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [groupColor.opacity(0.8), groupColor.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: groupColor.opacity(0.2), radius: 8, x: 0, y: 4)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(region.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                }
            
            // Region name
            Text(region.displayName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(labelColor)
                .lineLimit(1)
        }
        .padding(12)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct NestedChannelDetailSheetView: View {
    let channel: DRChannel
    let region: ChannelRegion?
    @ObservedObject var serviceManager: DRServiceManager
    let onDismiss: () -> Void
    
    var currentProgram: DRLiveProgram? {
        return serviceManager.appState.allLivePrograms.first { $0.channel.id == channel.id }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let program = currentProgram {
                        PodcastStyleHeroView(
                            liveProgram: program,
                            screenSize: CGSize(width: 400, height: 600), // Assume compact
                            serviceManager: serviceManager
                        )
                        
                        PodcastStyleProgramDetails(liveProgram: program)
                    } else {
                        // Channel without program data
                        VStack(spacing: 20) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [channel.swiftUIColor.opacity(0.8), channel.swiftUIColor.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .overlay {
                                    VStack(spacing: 12) {
                                        Image(systemName: "radio.fill")
                                            .font(.system(size: 48, weight: .light))
                                            .foregroundColor(.white)
                                        
                                        VStack(spacing: 4) {
                                            Text(channel.displayName)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                            
                                            if let region = region {
                                                Text(region.displayName)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                        }
                                    }
                                }
                            
                            VStack(spacing: 12) {
                                Text(channel.displayName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(labelColor)
                                
                                if let region = region {
                                    Text(region.displayName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(channel.swiftUIColor)
                                }
                                
                                Text(channel.description)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(secondaryLabelColor)
                                    .multilineTextAlignment(.center)
                            }
                            
                            PodcastStyleLargePlayButton(
                                liveProgram: DRLiveProgram(
                                    id: "temp",
                                    type: "Live",
                                    learnId: "temp",
                                    durationMilliseconds: 3600000,
                                    categories: [],
                                    productionNumber: "temp",
                                    startTime: Date(),
                                    endTime: Date().addingTimeInterval(3600),
                                    presentationUrl: nil,
                                    order: 0,
                                    title: "Live Radio",
                                    description: nil,
                                    series: nil,
                                    channel: channel,
                                    audioAssets: [],
                                    imageAssets: [],
                                    isAvailableOnDemand: false,
                                    hasVideo: false,
                                    explicitContent: false,
                                    slug: "temp"
                                ),
                                serviceManager: serviceManager
                            )
                        }
                    }
                }
                .padding(24)
            }
                         .navigationTitle(region?.displayName ?? channel.displayName)
             #if os(iOS)
             .navigationBarTitleDisplayMode(.inline)
             #endif
             .toolbar {
                 ToolbarItem(placement: .primaryAction) {
                     Button("Done") {
                         onDismiss()
                     }
                 }
             }
             .onAppear {
                 // Ensure service manager is updated when nested sheet appears
                 serviceManager.selectChannel(channel)
             }
         }
     }
}

// MARK: - Detail Components

struct DetailHeroView: View {
    let liveProgram: DRLiveProgram
    let region: ChannelRegion?
    @ObservedObject var serviceManager: DRServiceManager
    let sizeCategory: ScreenSizeCategory
    
    var body: some View {
        VStack(spacing: 24) {
            // Large artwork
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            liveProgram.channel.swiftUIColor.opacity(0.9),
                            liveProgram.channel.swiftUIColor.opacity(0.7),
                            liveProgram.channel.swiftUIColor.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: sizeCategory == .large ? 280 : 220, height: sizeCategory == .large ? 280 : 220)
                .shadow(color: liveProgram.channel.swiftUIColor.opacity(0.5), radius: 30, x: 0, y: 15)
                .overlay {
                    VStack(spacing: 16) {
                        // Live indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.9))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        Image(systemName: "radio.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 4) {
                            Text(liveProgram.channel.displayName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let region = region {
                                Text(region.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(24)
                }
            
            // Program details
            VStack(spacing: 16) {
                Text(liveProgram.title)
                    .font(.system(size: sizeCategory == .large ? 28 : 24, weight: .bold))
                    .foregroundColor(labelColor)
                    .multilineTextAlignment(.center)
                
                if let series = liveProgram.series {
                    Text(series.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(liveProgram.channel.swiftUIColor)
                }
                
                if let description = liveProgram.description {
                    Text(description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(secondaryLabelColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                }
                
                // Time info
                HStack {
                    Text("\(liveProgram.startTime.timeString) - \(liveProgram.endTime.timeString)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(secondaryLabelColor)
                    
                    Spacer()
                    
                    Text(liveProgram.formattedDuration)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(secondaryLabelColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(fillColor)
                        .clipShape(Capsule())
                }
                
                // Large play button
                PodcastStyleLargePlayButton(
                    liveProgram: liveProgram,
                    serviceManager: serviceManager
                )
            }
        }
    }
}

struct DetailChannelOnlyView: View {
    let channel: DRChannel
    let region: ChannelRegion?
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Channel artwork
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [channel.swiftUIColor.opacity(0.8), channel.swiftUIColor.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 220, height: 220)
                .shadow(color: channel.swiftUIColor.opacity(0.4), radius: 20, x: 0, y: 10)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "radio.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 4) {
                            Text(channel.displayName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            if let region = region {
                                Text(region.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
            
            VStack(spacing: 16) {
                Text(channel.displayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(labelColor)
                
                Text(channel.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(secondaryLabelColor)
                    .multilineTextAlignment(.center)
                
                // Create a minimal program for the play button
                PodcastStyleLargePlayButton(
                    liveProgram: DRLiveProgram(
                        id: "temp",
                        type: "Live",
                        learnId: "temp",
                        durationMilliseconds: 3600000,
                        categories: [],
                        productionNumber: "temp",
                        startTime: Date(),
                        endTime: Date().addingTimeInterval(3600),
                        presentationUrl: nil,
                        order: 0,
                        title: "Live Radio",
                        description: nil,
                        series: nil,
                        channel: channel,
                        audioAssets: [],
                        imageAssets: [],
                        isAvailableOnDemand: false,
                        hasVideo: false,
                        explicitContent: false,
                        slug: "temp"
                    ),
                    serviceManager: serviceManager
                )
            }
        }
    }
}

struct DetailProgramInfo: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Program Information")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(labelColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if !liveProgram.categories.isEmpty {
                    DetailInfoCard(
                        title: "Categories",
                        content: liveProgram.categories.joined(separator: " • "),
                        icon: "tag.fill",
                        color: liveProgram.channel.swiftUIColor
                    )
                }
                
                DetailInfoCard(
                    title: "Duration",
                    content: liveProgram.formattedDuration,
                    icon: "clock.fill",
                    color: liveProgram.channel.swiftUIColor
                )
                
                if let series = liveProgram.series {
                    DetailInfoCard(
                        title: "Series",
                        content: series.title,
                        icon: "tv.fill",
                        color: liveProgram.channel.swiftUIColor
                    )
                }
                
                DetailInfoCard(
                    title: "Channel",
                    content: liveProgram.channel.displayName,
                    icon: "radio.fill",
                    color: liveProgram.channel.swiftUIColor
                )
            }
        }
    }
}

struct DetailStreamInfo: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Stream Information")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(labelColor)
            
            VStack(spacing: 16) {
                ForEach(liveProgram.audioAssets, id: \.url) { asset in
                    HStack(spacing: 16) {
                        Circle()
                            .fill(asset.isHLS ? .green : .orange)
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.isHLS ? "High Quality Stream" : "Standard Stream")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(labelColor)
                            
                            Text(asset.format + (asset.bitrate != nil ? " • \(asset.bitrate!)kbps" : ""))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryLabelColor)
                        }
                        
                        Spacer()
                        
                        if asset.isStreamLive {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 6, height: 6)
                                Text("Live")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.red.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if asset != liveProgram.audioAssets.last {
                        Divider()
                    }
                }
            }
            .padding(20)
            .background(cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
    }
}

struct DetailInfoCard: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(secondaryLabelColor)
                    .textCase(.uppercase)
                
                Spacer()
            }
            
            Text(content)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(labelColor)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Existing Views (Updated for compatibility)

// MARK: - Now Playing View

struct NowPlayingView: View {
    @ObservedObject var serviceManager: DRServiceManager
    let navigationState: ChannelNavigationState
    let screenSize: CGSize
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                if let currentLiveProgram = serviceManager.currentLiveProgram {
                    // Podcast-style hero section
                    PodcastStyleHeroView(
                        liveProgram: currentLiveProgram,
                        screenSize: screenSize,
                        serviceManager: serviceManager
                    )
                    
                    // Program details
                    PodcastStyleProgramDetails(liveProgram: currentLiveProgram)
                    
                    // Additional info for larger screens
                    if !PodcastLayoutHelper.shouldUseCompactLayout(for: screenSize) {
                        PodcastStyleExtendedInfo(liveProgram: currentLiveProgram)
                    }
                } else {
                    // No program data
                    PodcastStyleNoDataView()
                }
                
                // Error message
                if let errorMessage = serviceManager.errorMessage {
                    PodcastStyleErrorView(message: errorMessage) {
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
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 60)
        }
    }
}



// MARK: - Podcast-Style Channel Card

struct PodcastStyleChannelCard: View {
    let group: ChannelGroup
    let screenSize: CGSize
    let onTap: () -> Void
    @ObservedObject var serviceManager: DRServiceManager
    
    @State private var isPressed = false
    
    var body: some View {
        #if os(tvOS)
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: false)
        #else
        cardContent
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { value in
                    isPressed = false
                    // Only trigger tap if drag distance is minimal (not a scroll)
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    if dragDistance < 10 {
                        onTap()
                    }
                }
        )
        #endif
    }
    
    private var cardContent: some View {
        let isCompact = PodcastLayoutHelper.shouldUseCompactLayout(for: screenSize)
        
        return VStack(alignment: .leading, spacing: isCompact ? 8 : 16) {
            // Podcast artwork area
                ZStack {
                // Background artwork
                RoundedRectangle(cornerRadius: isCompact ? 12 : 20)
                        .fill(
                            LinearGradient(
                            colors: [
                                group.swiftUIColor.opacity(0.9),
                                group.swiftUIColor.opacity(0.6),
                                group.swiftUIColor.opacity(0.3)
                            ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: group.swiftUIColor.opacity(0.3), radius: isCompact ? 8 : 20, x: 0, y: isCompact ? 4 : 10)
                
                // Content overlay
                VStack(spacing: isCompact ? 6 : 12) {
                    // Icon
                    Image(systemName: group.isRegional ? "location.circle.fill" : "radio.fill")
                        .font(.system(size: isCompact ? 24 : 48, weight: .light))
                        .foregroundColor(.white)
                    
                    // Channel name
                                Text(group.name)
                        .font(.system(size: isCompact ? 14 : 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(isCompact ? 2 : nil)
                                
                    // Region indicator
                                if group.isRegional {
                                        Text("\(group.channels.count) regions")
                            .font(.system(size: isCompact ? 10 : 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, isCompact ? 6 : 12)
                            .padding(.vertical, isCompact ? 3 : 6)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                            }
                        }
                    
                // Play button overlay for single channels
                    if !group.isRegional, let channel = group.channels.first {
                        VStack {
                            HStack {
                                Spacer()
                            PodcastStylePlayButton(
                                channel: channel,
                                serviceManager: serviceManager,
                                size: isCompact ? .small : .medium
                            )
                            }
                            Spacer()
                        }
                    .padding(isCompact ? 8 : 20)
                    }
                }
                
            // Podcast info section
            if !isCompact {
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                    
                    Text(group.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(secondaryLabelColor)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                // Compact text section for iPhone
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                    
                    Text(group.description)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(secondaryLabelColor)
                        .lineLimit(2)
                }
            }
        }
    }
}

// MARK: - Podcast-Style Region Card

struct PodcastStyleRegionCard: View {
    let region: ChannelRegion
    let groupColor: Color
    let screenSize: CGSize
    let onTap: () -> Void
    @ObservedObject var serviceManager: DRServiceManager
    
    @State private var isPressed = false
    
    var body: some View {
        #if os(tvOS)
        Button(action: onTap) {
            regionCardContent
        }
        .buttonStyle(.plain)
        #else
        regionCardContent
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { value in
                    isPressed = false
                    // Only trigger tap if drag distance is minimal (not a scroll)
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    if dragDistance < 10 {
                        onTap()
                    }
                }
        )
        #endif
    }
    
    private var regionCardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Compact artwork
                ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [groupColor.opacity(0.8), groupColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: groupColor.opacity(0.2), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                                
                                Text(region.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                            }
                    
                // Play button overlay
                    VStack {
                        HStack {
                            Spacer()
                        PodcastStylePlayButton(
                            channel: region.channel,
                            serviceManager: serviceManager,
                            size: .small
                        )
                        }
                        Spacer()
                    }
                .padding(12)
                }
                
                // Region name
                Text(region.displayName)
                .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(labelColor)
                    .lineLimit(1)
            }
    }
}

// MARK: - Podcast-Style Play Button



// MARK: - Region Detail View

struct RegionDetailView: View {
    let group: ChannelGroup
    @ObservedObject var selectionState: SelectionState
    @ObservedObject var serviceManager: DRServiceManager
    let sizeCategory: ScreenSizeCategory
    
    var regions: [ChannelRegion] {
        ChannelOrganizer.getRegionsForGroup(group.channels, groupPrefix: group.id)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(regions) { region in
                    RegionDetailListItem(
                        region: region,
                        groupColor: group.swiftUIColor,
                        isSelected: selectionState.selectedChannel?.id == region.channel.id,
                        onTap: {
                            selectionState.openNestedNavigation(for: region.channel, in: region)
                        }
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RegionDetailCard: View {
    let region: ChannelRegion
    let groupColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Region artwork
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [groupColor.opacity(0.8), groupColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: groupColor.opacity(0.2), radius: 8, x: 0, y: 4)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(region.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                
                // Region name
                Text(region.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(labelColor)
                    .lineLimit(1)
            }
            .padding(16)
            .background(isSelected ? groupColor.opacity(0.1) : cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? groupColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RegionDetailListItem: View {
    let region: ChannelRegion
    let groupColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Region icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [groupColor.opacity(0.8), groupColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: groupColor.opacity(0.2), radius: 6, x: 0, y: 3)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(region.displayName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                    }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(region.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                    
                    Text("Listen to \(region.channel.displayName)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(secondaryLabelColor)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(groupColor)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(secondaryLabelColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(isSelected ? groupColor.opacity(0.1) : cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? groupColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Podcast-Style Group Header

struct PodcastStyleGroupHeader: View {
    let group: ChannelGroup
    
    var body: some View {
        HStack(spacing: 24) {
            // Group artwork
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [group.swiftUIColor.opacity(0.9), group.swiftUIColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: group.swiftUIColor.opacity(0.4), radius: 12, x: 0, y: 6)
                .overlay {
                    VStack(spacing: 4) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(group.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(group.name)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(labelColor)
                
                Text(group.description)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(secondaryLabelColor)
                
                Text("\(group.channels.count) regions available")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(group.swiftUIColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(group.swiftUIColor.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Podcast-Style Hero View

struct PodcastStyleHeroView: View {
    let liveProgram: DRLiveProgram
    let screenSize: CGSize
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
        let isCompact = PodcastLayoutHelper.shouldUseCompactLayout(for: screenSize)
        
        VStack(spacing: isCompact ? 24 : 32) {
            // Artwork section
            HStack {
                Spacer()
                
                ZStack {
                    // Main artwork
                    RoundedRectangle(cornerRadius: 24)
            .fill(
                LinearGradient(
                                colors: [
                                    liveProgram.channel.swiftUIColor.opacity(0.9),
                                    liveProgram.channel.swiftUIColor.opacity(0.7),
                                    liveProgram.channel.swiftUIColor.opacity(0.5)
                                ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
                        .frame(width: isCompact ? 280 : 320, height: isCompact ? 280 : 320)
                        .shadow(color: liveProgram.channel.swiftUIColor.opacity(0.5), radius: 30, x: 0, y: 15)
                    
                    // Content overlay
                    VStack(spacing: 16) {
                        // Live indicator
            HStack(spacing: 8) {
                Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                Text("LIVE")
                                .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
            }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.9))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        // Radio icon
                        Image(systemName: "radio.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.white)
                        
                        // Channel name
            Text(liveProgram.channel.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding(24)
                }
                
                Spacer()
            }
            
            // Program info section
            VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 12) {
                Text(liveProgram.title)
                        .font(.system(size: isCompact ? 24 : 28, weight: .bold))
                    .foregroundColor(labelColor)
                    .multilineTextAlignment(.leading)
            
            if let series = liveProgram.series {
                Text(series.title)
                            .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(liveProgram.channel.swiftUIColor)
            }
            
            if let description = liveProgram.description {
                Text(description)
                            .font(.system(size: 16, weight: .regular))
                    .foregroundColor(secondaryLabelColor)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    }
            }
            
                // Time and duration
            HStack {
                Text("\(liveProgram.startTime.timeString) - \(liveProgram.endTime.timeString)")
                        .font(.system(size: 14, weight: .medium))
                    .foregroundColor(secondaryLabelColor)
                
                Spacer()
                
                Text(liveProgram.formattedDuration)
                        .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(secondaryLabelColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(fillColor)
                        .clipShape(Capsule())
                }
                
                // Large play button
                PodcastStyleLargePlayButton(
                    liveProgram: liveProgram,
                    serviceManager: serviceManager
                )
            }
        }
    }
}

// MARK: - Podcast-Style Large Play Button

struct PodcastStyleLargePlayButton: View {
    let liveProgram: DRLiveProgram
    @ObservedObject var serviceManager: DRServiceManager
    
    var body: some View {
            Button(action: {
                serviceManager.togglePlayback(for: liveProgram.channel)
            }) {
            HStack(spacing: 16) {
                Image(systemName: playButtonIcon)
                    .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                
                Text(playButtonTitle)
                    .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            .frame(height: 56)
                .background(
                    LinearGradient(
                    colors: buttonGradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
    
    private var playButtonIcon: String {
        let state = serviceManager.getPlaybackState(for: liveProgram.channel)
        switch state {
        case .playing: return "pause.circle.fill"
        case .paused, .stopped, .error: return "play.circle.fill"
        case .loading: return "arrow.clockwise.circle.fill"
        }
    }
    
    private var playButtonTitle: String {
        let state = serviceManager.getPlaybackState(for: liveProgram.channel)
        switch state {
        case .playing: return "Pause"
        case .paused: return "Resume"
        case .stopped, .error: return "Play"
        case .loading: return "Loading..."
        }
    }
    
    private var buttonGradientColors: [Color] {
        let state = serviceManager.getPlaybackState(for: liveProgram.channel)
        switch state {
        case .playing: return [.red, .orange]
        case .paused, .stopped, .error: return [.green, .blue]
        case .loading: return [.gray, .gray.opacity(0.7)]
        }
    }
    
    private var isLoading: Bool {
        serviceManager.getPlaybackState(for: liveProgram.channel) == .loading
    }
}

// MARK: - Podcast-Style Program Details

struct PodcastStyleProgramDetails: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About This Program")
                .font(.system(size: 20, weight: .bold))
                    .foregroundColor(labelColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if !liveProgram.categories.isEmpty {
                    PodcastStyleInfoCard(
                        title: "Categories",
                        content: liveProgram.categories.joined(separator: " • "),
                        icon: "tag.fill",
                        color: liveProgram.channel.swiftUIColor
                    )
                }
                
                PodcastStyleInfoCard(
                    title: "Duration",
                    content: liveProgram.formattedDuration,
                    icon: "clock.fill",
                    color: liveProgram.channel.swiftUIColor
                )
                
                if let series = liveProgram.series {
                    PodcastStyleInfoCard(
                        title: "Series",
                        content: series.title,
                        icon: "tv.fill",
                        color: liveProgram.channel.swiftUIColor
                    )
                }
                
                PodcastStyleInfoCard(
                    title: "Channel",
                    content: liveProgram.channel.displayName,
                    icon: "radio.fill",
                    color: liveProgram.channel.swiftUIColor
                )
            }
        }
    }
}

// MARK: - Podcast-Style Info Card



// MARK: - Podcast-Style Mini Player

struct PodcastStyleMiniPlayer: View {
    let liveProgram: DRLiveProgram
    @ObservedObject var serviceManager: DRServiceManager
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main player bar
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // Artwork
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [liveProgram.channel.swiftUIColor.opacity(0.9), liveProgram.channel.swiftUIColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(systemName: "radio.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    
                    // Program info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(liveProgram.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(labelColor)
                            .lineLimit(1)
                        
                        Text(liveProgram.channel.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(secondaryLabelColor)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Play/pause button
                    PodcastStylePlayButton(
                        channel: liveProgram.channel,
                        serviceManager: serviceManager,
                        size: .medium
                    )
                    
                    // Expand indicator
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(secondaryLabelColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            
            // Volume control
            HStack(spacing: 16) {
                #if os(tvOS)
                // tvOS simplified volume control
                HStack(spacing: 12) {
                    Image(systemName: serviceManager.audioPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(secondaryLabelColor)
                    
                    Text("Volume: \(Int(serviceManager.audioPlayer.volume * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(secondaryLabelColor)
                }
                #else
                // iOS/macOS volume control with slider
                Image(systemName: serviceManager.audioPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(secondaryLabelColor)
                    .onTapGesture {
                        serviceManager.toggleMute()
                    }
                
                Slider(
                    value: Binding(
                        get: { serviceManager.audioPlayer.isMuted ? 0.0 : serviceManager.audioPlayer.volume },
                        set: { newValue in
                            serviceManager.setVolume(newValue)
                            if serviceManager.audioPlayer.isMuted && newValue > 0 {
                                serviceManager.toggleMute()
                            }
                        }
                    ),
                    in: 0...1
                )
                .accentColor(liveProgram.channel.swiftUIColor)
                .frame(height: 24)
                #endif
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
}

// MARK: - Support Views

struct PodcastStyleExtendedInfo: View {
    let liveProgram: DRLiveProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Stream Information")
                .font(.system(size: 20, weight: .bold))
                    .foregroundColor(labelColor)
            
            VStack(spacing: 16) {
                ForEach(liveProgram.audioAssets, id: \.url) { asset in
                    HStack(spacing: 16) {
                        Circle()
                            .fill(asset.isHLS ? .green : .orange)
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.isHLS ? "High Quality Stream" : "Standard Stream")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(labelColor)
                            
                            Text(asset.format + (asset.bitrate != nil ? " • \(asset.bitrate!)kbps" : ""))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryLabelColor)
                        }
                        
                        Spacer()
                        
                        if asset.isStreamLive {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 6, height: 6)
                                Text("Live")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.red.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if asset != liveProgram.audioAssets.last {
                        Divider()
                    }
                }
            }
            .padding(20)
            .background(cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
    }
}





// MARK: - Legacy Support Views (Unchanged)

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
