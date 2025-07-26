import SwiftUI

// MARK: - TV Layout (Apple TV)

struct TVLayout: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var navigationState: ChannelNavigationState
    @ObservedObject var selectionState: SelectionState
    let screenSize: CGSize
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle(navigationTitle)
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
                                selectionState.clearSelection()
                            }
                        }
                    }
                }
        }
        .navigationViewStyle(.automatic)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch navigationState.currentLevel {
        case .channelGroups:
            TVChannelGroupsView(
                serviceManager: serviceManager,
                navigationState: navigationState,
                selectionState: selectionState,
                screenSize: screenSize
            )
            
        case .regions(let group):
            TVRegionsView(
                group: group,
                serviceManager: serviceManager,
                navigationState: navigationState,
                selectionState: selectionState,
                screenSize: screenSize
            )
            .onAppear {
                print("📺 TVLayout: Showing regions view for group '\(group.name)'")
            }
            
        case .playing(_):
            NowPlayingView(
                serviceManager: serviceManager,
                navigationState: navigationState,
                screenSize: screenSize
            )
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

// MARK: - TV-Specific Views

struct TVChannelGroupsView: View {
    @ObservedObject var serviceManager: DRServiceManager
    let navigationState: ChannelNavigationState
    @ObservedObject var selectionState: SelectionState
    let screenSize: CGSize
    
    @State private var providers: [RadioStationProvider] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                ForEach(providers) { provider in
                    VStack(alignment: .leading, spacing: 16) {
                        // Provider section header with description
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: provider.logoSystemName)
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(provider.swiftUIColor)
                                
                                Text(provider.name)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(labelColor)
                                
                                Spacer()
                            }
                            
                            Text(provider.description)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(secondaryLabelColor)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 24)
                        
                        // Channel groups grid - optimized for TV with better spacing
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 32),
                                GridItem(.flexible(), spacing: 32),
                                GridItem(.flexible(), spacing: 32),
                                GridItem(.flexible(), spacing: 32),
                                GridItem(.flexible(), spacing: 32)
                            ],
                            spacing: 32
                        ) {
                            ForEach(provider.channelGroups) { group in
                                TVChannelGroupCard(
                                    group: group,
                                    screenSize: screenSize,
                                    onTap: {
                                        if group.isRegional {
                                            // For TV, navigate to regions view instead of showing sheet
                                            navigationState.selectedGroup = group
                                            navigationState.currentLevel = .regions(group)
                                        } else if let channel = group.channels.first {
                                            selectionState.selectChannel(channel, showSheet: true)
                                        }
                                    },
                                    serviceManager: serviceManager
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 100)
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

struct TVRegionsView: View {
    let group: ChannelGroup
    @ObservedObject var serviceManager: DRServiceManager
    let navigationState: ChannelNavigationState
    @ObservedObject var selectionState: SelectionState
    let screenSize: CGSize
    
    var regions: [ChannelRegion] {
        let regions = ChannelOrganizer.getRegionsForGroup(group.channels, groupPrefix: group.id)
        print("📺 TVRegionsView: Found \(regions.count) regions for group '\(group.name)'")
        for region in regions {
            print("📺 Region: '\(region.displayName)' -> '\(region.channel.displayName)'")
        }
        return regions
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Regions grid - optimized for TV with better spacing
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 32),
                        GridItem(.flexible(), spacing: 32),
                        GridItem(.flexible(), spacing: 32),
                        GridItem(.flexible(), spacing: 32),
                        GridItem(.flexible(), spacing: 32)
                    ],
                    spacing: 32
                ) {
                    ForEach(regions) { region in
                        TVRegionCard(
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
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - TV-Specific Cards

struct TVChannelGroupCard: View {
    let group: ChannelGroup
    let screenSize: CGSize
    let onTap: () -> Void
    @ObservedObject var serviceManager: DRServiceManager
    
    @State private var cardSize: CGSize = .zero
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Compact artwork optimized for TV
                RoundedRectangle(cornerRadius: 16)
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
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: group.swiftUIColor.opacity(0.3), radius: 12, x: 0, y: 6)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: group.isRegional ? "location.circle.fill" : "radio.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(group.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            if group.isRegional {
                                Text("\(group.channels.count) regions")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                
                // Channel info
                VStack(spacing: 6) {
                    Text(group.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                    
                    Text(group.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(secondaryLabelColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(16)
            .background(cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .frame(height: 200) // Fixed height for consistency
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            cardSize = geometry.size
                            print("📱 Channel Group Card '\(group.name)': width=\(geometry.size.width), height=\(geometry.size.height)")
                        }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TVRegionCard: View {
    let region: ChannelRegion
    let groupColor: Color
    let screenSize: CGSize
    let onTap: () -> Void
    @ObservedObject var serviceManager: DRServiceManager
    
    @State private var cardSize: CGSize = .zero
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Compact region artwork - exactly same size as channel group cards
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                groupColor.opacity(0.9),
                                groupColor.opacity(0.7),
                                groupColor.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: groupColor.opacity(0.3), radius: 12, x: 0, y: 6)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(region.displayName)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                
                // Region info - exactly same styling as channel group cards
                VStack(spacing: 6) {
                    Text(region.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                    
                    Text("Region")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(secondaryLabelColor)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(12)
            .background(cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .frame(height: 180) // Compact height for region cards
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            cardSize = geometry.size
                            print("📺 Region Card '\(region.displayName)': width=\(geometry.size.width), height=\(geometry.size.height)")
                        }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TVGroupHeader: View {
    let group: ChannelGroup
    
    var body: some View {
        HStack(spacing: 32) {
            // Group artwork
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [group.swiftUIColor.opacity(0.9), group.swiftUIColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(color: group.swiftUIColor.opacity(0.4), radius: 16, x: 0, y: 8)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(group.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(group.name)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(labelColor)
                
                Text(group.description)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(secondaryLabelColor)
                
                Text("\(group.channels.count) regions available")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(group.swiftUIColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(group.swiftUIColor.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
} 