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
    @SceneStorage("selectedTab") private var selectedTabIndex = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main TabView with TabBarMinimizeBehavior
            if #available(iOS 26.0, *) {
                TabView(selection: $selectedTabIndex) {
                    Tab("Home", systemImage: "house", value: 0) {
                        HomeView(serviceManager: serviceManager, selectionState: selectionState)
                        // List(0...100, id: \.self) { id in
                        //     Text(id.description)
                        // }
                    }
                    Tab("Radio", systemImage: "antenna.radiowaves.left.and.right", value: 2) {
                        RadioView(serviceManager: serviceManager, selectionState: selectionState)
                    }
                    Tab("Search", systemImage: "magnifyingglass", value: 1, role: .search) {
                        SearchView(serviceManager: serviceManager, selectionState: selectionState)
                    }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
                .accentColor(.purple)
                .tabViewBottomAccessory {
                    MiniPlayer()
                        .environmentObject(serviceManager)
                        .environmentObject(selectionState)
                }
            } else {
                // Fallback on earlier versions
                TabView {
                    // Home Tab
                    HomeView(serviceManager: serviceManager, selectionState: selectionState)
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }
                    
                    SearchView(serviceManager: serviceManager, selectionState: selectionState)
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                }
                .accentColor(.purple)
                
                // MiniPlayer positioned above TabView
                MiniPlayer()
                    .environmentObject(serviceManager)
                    .environmentObject(selectionState)
                    .frame(alignment: .bottom)
            }
        }
    }
    
    private var content: some View {
        List(0...100, id: \.self) { id in
            Text(id.description)
        }
    }
}

#Preview {
    ContentView()
}
