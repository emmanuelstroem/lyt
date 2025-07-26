import SwiftUI

// MARK: - macOS Layout

#if !os(tvOS)
struct MacOSLayout: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var navigationState: ChannelNavigationState
    @ObservedObject var selectionState: SelectionState
    let screenSize: CGSize
    
    var body: some View {
        if #available(macOS 13.0, *) {
            dynamicNavigationSplitView
        } else {
            // Fallback for older platforms
            fallbackMasterDetailLayout
        }
    }
    
    @ViewBuilder
    @available(macOS 13.0, *)
    private var dynamicNavigationSplitView: some View {
        // Two-column NavigationSplitView for macOS
        NavigationSplitView {
            sidebarContent
                .navigationTitle("Radio")
                .navigationSplitViewColumnWidth(
                    min: 280, 
                    ideal: 320, 
                    max: 400
                )
        } detail: {
            detailPanelContent
                .navigationTitle(detailNavigationTitle)
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    @ViewBuilder
    private var fallbackMasterDetailLayout: some View {
        HStack(spacing: 0) {
            // Sidebar panel
            VStack {
                NavigationView {
                    sidebarContent
                        .navigationTitle("Radio")
                }
                .navigationViewStyle(.automatic)
            }
            .frame(width: 350)
            
            // Divider
            Divider()
            
            // Detail panel
            detailPanelContent
                .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private var sidebarContent: some View {
        SidebarListView(
            serviceManager: serviceManager,
            selectionState: selectionState,
            navigationState: navigationState,
            screenSize: screenSize,
            sizeCategory: .large
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
                    sizeCategory: .large
                )
            }
        } else if let selectedChannel = selectionState.selectedChannel {
            ChannelDetailView(
                channel: selectedChannel,
                region: selectionState.selectedRegion,
                serviceManager: serviceManager,
                sizeCategory: .large
            )
        } else if let selectedGroup = selectionState.selectedGroup {
            if selectedGroup.isRegional {
                // For regional groups, show regions in the detail view
                RegionDetailView(
                    group: selectedGroup,
                    selectionState: selectionState,
                    serviceManager: serviceManager,
                    sizeCategory: .large
                )
            } else {
                GroupDetailView(
                    group: selectedGroup,
                    serviceManager: serviceManager,
                    sizeCategory: .large
                )
            }
        } else {
            DetailPlaceholderView()
        }
    }
    
    private var detailNavigationTitle: String {
        if let selectedChannel = selectionState.selectedChannel {
            return selectedChannel.displayName
        } else if let selectedGroup = selectionState.selectedGroup {
            return selectedGroup.name
        } else {
            return "Select a Channel"
        }
    }
}
#endif 