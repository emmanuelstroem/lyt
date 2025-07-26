import SwiftUI

// MARK: - iPhone Layout

#if !os(tvOS)
struct iPhoneLayout: View {
    @ObservedObject var serviceManager: DRServiceManager
    @ObservedObject var navigationState: ChannelNavigationState
    @ObservedObject var selectionState: SelectionState
    let screenSize: CGSize
    
    var body: some View {
        NavigationView {
            mainContent
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
                                selectionState.clearSelection()
                            }
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch navigationState.currentLevel {
        case .channelGroups:
            CompactSectionedChannelGroupsView(
                serviceManager: serviceManager,
                navigationState: navigationState,
                selectionState: selectionState,
                screenSize: screenSize
            )
            
        case .regions(let group):
            CompactRegionsView(
                group: group,
                serviceManager: serviceManager,
                navigationState: navigationState,
                selectionState: selectionState,
                screenSize: screenSize
            )
            
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
#endif 