import SwiftUI
import Foundation

// MARK: - Support Views

struct PodcastStyleLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Loading...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(48)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

struct PodcastStyleErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(labelColor)
            
            Text(message)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(secondaryLabelColor)
                .multilineTextAlignment(.center)
                .lineLimit(4)
            
            Button("Try Again", action: onRetry)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.blue)
                .clipShape(Capsule())
        }
        .padding(32)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
}

struct PodcastStyleNoDataView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "radio")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(secondaryLabelColor)
            
            Text("No program information available")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(secondaryLabelColor)
            
            Text("Pull down to refresh")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(secondaryLabelColor)
        }
        .padding(48)
    }
} 