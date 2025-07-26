import SwiftUI
import Foundation

// MARK: - Play Button Component

struct PodcastStylePlayButton: View {
    let channel: DRChannel
    @ObservedObject var serviceManager: DRServiceManager
    let size: ButtonSize
    
    enum ButtonSize {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 48
            case .large: return 64
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 28
            }
        }
    }
    
    var body: some View {
        Button(action: {
            serviceManager.togglePlayback(for: channel)
        }) {
            Image(systemName: playButtonIcon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size.dimension, height: size.dimension)
                .background(playButtonColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isLoading ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
    
    private var playButtonIcon: String {
        let state = serviceManager.getPlaybackState(for: channel)
        switch state {
        case .playing: return "pause.fill"
        case .paused, .stopped, .error: return "play.fill"
        case .loading: return "arrow.clockwise"
        }
    }
    
    private var playButtonColor: Color {
        let state = serviceManager.getPlaybackState(for: channel)
        switch state {
        case .playing: return .red
        case .paused, .stopped, .error: return .black.opacity(0.8)
        case .loading: return .orange
        }
    }
    
    private var isLoading: Bool {
        serviceManager.getPlaybackState(for: channel) == .loading
    }
}

// MARK: - Info Card Component

struct PodcastStyleInfoCard: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(secondaryLabelColor)
                    .textCase(.uppercase)
                
                Spacer()
            }
            
            Text(content)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(labelColor)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
} 