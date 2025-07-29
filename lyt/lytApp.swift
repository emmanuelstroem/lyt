//
//  lytApp.swift
//  lyt
//
//  Created by Emmanuel on 24/07/2025.
//

import SwiftUI

@main
struct lytApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("Lyt App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Views, Services, and Models have been removed")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
