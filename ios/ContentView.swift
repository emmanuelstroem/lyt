//
//  ContentView.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var serviceManager = DRServiceManager()
    @StateObject private var selectionState = SelectionState()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main TabView
            TabView {
                // Home Tab
                HomeView(serviceManager: serviceManager, selectionState: selectionState)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                
                // Search Tab
                SearchView(serviceManager: serviceManager, selectionState: selectionState)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
            }
            .accentColor(.purple)
            
            // Floating MiniPlayer
            MiniPlayer.floating(serviceManager: serviceManager, selectionState: selectionState)
        }
    }
}

#Preview {
    ContentView()
}
