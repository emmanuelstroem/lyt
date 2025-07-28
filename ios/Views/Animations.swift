//
//  Animations.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI

// MARK: - Soundbar Animation Component
struct SoundbarAnimation: View {
    let isPlaying: Bool
    let color: Color
    @ObservedObject var audioPlayer: AudioPlayerService
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: 25 * CGFloat(audioPlayer.audioSpectrum[index]))
                    .animation(.easeInOut(duration: 0.1), value: audioPlayer.audioSpectrum[index])
            }
        }
        .frame(height: 25)
    }
} 