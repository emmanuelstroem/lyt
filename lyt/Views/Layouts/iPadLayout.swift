import SwiftUI

// MARK: - iPad Layout

#if !os(tvOS)
struct iPadLayout: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var navigationState: ChannelNavigationState
    @ObservedObject var selectionState: SelectionState
    let screenSize: CGSize
    
    var body: some View {
        if #available(iOS 16.0, *) {
            dynamicNavigationSplitView
        } else {
            // Fallback for older platforms
            fallbackMasterDetailLayout
        }
    }
    
    @ViewBuilder
    @available(iOS 16.0, *)
    private var dynamicNavigationSplitView: some View {
        // Two-column NavigationSplitView for iPad
        NavigationSplitView {
            sidebarContent
                .navigationTitle("Radio")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                #endif
                .navigationSplitViewColumnWidth(
                    min: 280, 
                    ideal: 320, 
                    max: 400
                )
        } detail: {
            detailPanelContent
                .navigationTitle(detailNavigationTitle)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                #endif
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
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.large)
                        #endif
                }
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
            sizeCategory: .regular
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
                    sizeCategory: .regular
                )
            }
        } else if let selectedChannel = selectionState.selectedChannel {
            ChannelDetailView(
                channel: selectedChannel,
                region: selectionState.selectedRegion,
                serviceManager: serviceManager,
                sizeCategory: .regular
            )
        } else if let selectedGroup = selectionState.selectedGroup {
            if selectedGroup.isRegional {
                // For regional groups, show regions in the detail view
                RegionDetailView(
                    group: selectedGroup,
                    selectionState: selectionState,
                    serviceManager: serviceManager,
                    sizeCategory: .regular
                )
            } else {
                GroupDetailView(
                    group: selectedGroup,
                    serviceManager: serviceManager,
                    sizeCategory: .regular
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