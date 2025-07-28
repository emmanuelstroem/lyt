//
//  ContentView.swift
//  tvos
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI
import Combine

// MARK: - tvOS Main Content View

struct ContentView: View {
    @StateObject private var serviceManager = DRServiceManager()
    @StateObject private var selectionState = SelectionState()

    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(
                serviceManager: serviceManager,
                selectionState: selectionState
            )
        } detail: {
            // Detail view
            if let selectedChannel = selectionState.selectedChannel {
                DetailView(
                    channel: selectedChannel,
                    region: selectionState.selectedRegion,
                    serviceManager: serviceManager,
                    selectionState: selectionState
                )
            } else {
                // Placeholder when no channel is selected
                VStack(spacing: 40) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 120))
                        .foregroundColor(.secondary)
                    
                    Text("Select a Channel")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    Text("Choose a channel from the sidebar to view details and start listening.")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 80)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            // Initialize services when app launches
            Task {
                await serviceManager.refreshNowPlaying()
            }
        }
    }
}

#Preview {
    ContentView()
}
