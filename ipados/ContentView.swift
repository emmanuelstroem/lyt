//
//  ContentView.swift
//  ipados
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI
import Combine

// MARK: - iPadOS Main Content View

struct ContentView: View {
    @StateObject private var serviceManager = DRServiceManager()
    @StateObject private var selectionState = SelectionState()

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
                VStack(spacing: 24) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 80))
                        .foregroundColor(.secondary)
                    
                    Text("Select a Channel")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    Text("Choose a channel from the sidebar to view details and start listening.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
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
