    //
    //  iosApp.swift
    //  ios
    //
    //  Created by Emmanuel on 27/07/2025.
    //

import SwiftUI

@main
struct iosApp: App {
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deepLinkHandler)
                .onOpenURL { url in
                    deepLinkHandler.handleDeepLink(url)
                }
        }
    }
}
