//
//  Animations.swift
//  ipados
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI

// MARK: - Soundbar Animation Component
struct SoundbarAnimation: View {
    let isPlaying: Bool
    let color: Color
    
    @State private var animationValues: [CGFloat] = Array(repeating: 0.2, count: 8)
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: 25 * animationValues[index])
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.08),
                        value: animationValues[index]
                    )
            }
        }
        .frame(height: 25)
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func startAnimation() {
        for i in 0..<8 {
            animationValues[i] = 1.0
        }
    }
    
    private func stopAnimation() {
        for i in 0..<8 {
            animationValues[i] = 0.2
        }
    }
} 