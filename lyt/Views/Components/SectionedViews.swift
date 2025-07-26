import SwiftUI
import Foundation

// MARK: - Sectioned Views

struct MasterSectionedChannelGroupsView: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var selectionState: SelectionState
    let navigationState: ChannelNavigationState
    let screenSize: CGSize
    let sizeCategory: ScreenSizeCategory
    
    @State private var providers: [RadioStationProvider] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                ForEach(providers) { provider in
                    VStack(alignment: .leading, spacing: 16) {
                        // Provider section header
                        HStack {
                            Image(systemName: provider.logoSystemName)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(provider.swiftUIColor)
                            
                            Text(provider.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(labelColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal, PodcastLayoutHelper.shouldUseCompactLayout(for: screenSize) ? 16 : 20)
                        
                        // Channel groups grid
                        LazyVGrid(
                            columns: PodcastLayoutHelper.threeColumnGrid(for: screenSize),
                            spacing: PodcastLayoutHelper.shouldUseCompactLayout(for: screenSize) ? 8 : 16
                        ) {
                            ForEach(provider.channelGroups) { group in
                                MasterChannelGroupCard(
                                    group: group,
                                    isSelected: selectionState.selectedGroup?.id == group.id,
                                    onTap: {
                                        selectionState.selectGroup(group)
                                        
                                        // Don't navigate for regional groups in master-detail layout
                                        // The middle column will handle region selection
                                        if !group.isRegional, let channel = group.channels.first {
                                            // For single channel groups, select the channel for detail view
                                            selectionState.selectChannel(channel)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, PodcastLayoutHelper.shouldUseCompactLayout(for: screenSize) ? 12 : 20)
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .onAppear {
            updateProviders()
        }
        .onChange(of: serviceManager.appState.availableChannels) { _ in
            updateProviders()
        }
    }
    
    private func updateProviders() {
        providers = ChannelOrganizer.organizeProviders(serviceManager.appState.availableChannels)
    }
}

struct CompactSectionedChannelGroupsView: View {
    @ObservedObject var serviceManager: DRServiceManager
    let navigationState: ChannelNavigationState
    @ObservedObject var selectionState: SelectionState
    let screenSize: CGSize
    
    @State private var providers: [RadioStationProvider] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 40) {
                ForEach(providers) { provider in
                    VStack(alignment: .leading, spacing: 20) {
                        // Provider section header with description
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: provider.logoSystemName)
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(provider.swiftUIColor)
                                
                                Text(provider.name)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(labelColor)
                                
                                Spacer()
                            }
                            
                            Text(provider.description)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(secondaryLabelColor)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, PodcastLayoutHelper.shouldUseCompactLayout(for: screenSize) ? 16 : 24)
                        
                        // Channel groups grid
                        LazyVGrid(
                            columns: PodcastLayoutHelper.threeColumnGrid(for: screenSize),
                            spacing: PodcastLayoutHelper.shouldUseCompactLayout(for: screenSize) ? 8 : 16
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
                        .padding(.horizontal, PodcastLayoutHelper.shouldUseCompactLayout(for: screenSize) ? 12 : 24)
                    }
                }
            }
            .padding(.vertical, 32)
        }
        .onAppear {
            updateProviders()
        }
        .onChange(of: serviceManager.appState.availableChannels) { _ in
            updateProviders()
        }
    }
    
    private func updateProviders() {
        providers = ChannelOrganizer.organizeProviders(serviceManager.appState.availableChannels)
    }
} 