import SwiftUI
import Foundation
import Combine

// MARK: - Selection State

class SelectionState: ObservableObject {
    @Published var selectedGroup: ChannelGroup?
    @Published var selectedChannel: DRChannel?
    @Published var selectedRegion: ChannelRegion?
    @Published var showingChannelSheet = false
    @Published var showingRegionSheet = false
    @Published var showingNestedNavigation = false
    
    func selectGroup(_ group: ChannelGroup, showSheet: Bool = false) {
        selectedGroup = group
        selectedChannel = nil
        selectedRegion = nil
        showingChannelSheet = false
        if showSheet {
            showingRegionSheet = true
        }
    }
    
    func selectChannel(_ channel: DRChannel, inRegion region: ChannelRegion? = nil, showSheet: Bool = false) {
        selectedChannel = channel
        selectedRegion = region
        showingRegionSheet = false
        if showSheet {
            showingChannelSheet = true
        }
    }
    
    func clearSelection() {
        selectedGroup = nil
        selectedChannel = nil
        selectedRegion = nil
        showingChannelSheet = false
        showingRegionSheet = false
        showingNestedNavigation = false
    }
    
    func openNestedNavigation(for channel: DRChannel, in region: ChannelRegion) {
        selectedChannel = channel
        selectedRegion = region
        showingNestedNavigation = true
    }
    
    func dismissNestedNavigation() {
        showingNestedNavigation = false
        selectedChannel = nil
        selectedRegion = nil
    }
} 