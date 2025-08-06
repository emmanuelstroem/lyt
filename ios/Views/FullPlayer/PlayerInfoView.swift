//
//  PlayerInfoView.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI

struct PlayerInfoView: View {
    let title: String
    let subtitle: String
    let channel: DRChannel?
    let serviceManager: DRServiceManager?
    let onEllipsisTap: (() -> Void)?
    
    @State private var showingMenu = false
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    
    init(
        title: String,
        subtitle: String,
        channel: DRChannel? = nil,
        serviceManager: DRServiceManager? = nil,
        onEllipsisTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.channel = channel
        self.serviceManager = serviceManager
        self.onEllipsisTap = onEllipsisTap
    }
    
    private var deepLinkURL: URL? {
        guard let channel = channel else { return nil }
        // Create a deep link to the channel in the app
        let urlString = "lyt://channel/\(channel.id)"
        return URL(string: urlString)
    }
    
    private var currentProgram: DREpisode? {
        guard let channel = channel, let serviceManager = serviceManager else { return nil }
        return serviceManager.getCurrentProgram(for: channel)
    }
    
    private var channelArtworkURL: URL? {
        guard let currentProgram = currentProgram,
              let imageURL = currentProgram.primaryImageURL else { return nil }
        return URL(string: imageURL)
    }
    
    private var channelDisplayName: String {
        guard let channel = channel else { return "" }
        
        var displayName = channel.name
        if let district = channel.district {
            displayName += " \(district)"
        }
        return displayName
    }
    
    private var shareText: String {
        var text = "🎵 \(title)"
        if !subtitle.isEmpty {
            text += "\n📻 \(subtitle)"
        }
        if !channelDisplayName.isEmpty {
            text += "\n📡 \(channelDisplayName)"
        }
        if channel != nil {
            text += "\n\nListen on Lyt - DR Radio"
        }
        return text
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: geometry.size.height * 0.1) {
                HStack {
                    VStack(alignment: .leading, spacing: geometry.size.height * 0.03) {
                        Text(title)
                            .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.3, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        MarqueeText(
                            text: subtitle,
                            font: .system(size: min(geometry.size.width, geometry.size.height) * 0.3),
                            leftFade: geometry.size.width * 0.05,
                            rightFade: geometry.size.width * 0.05,
                            startDelay: 1.5
                        )
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    }
                    
                    Spacer()
                    
                    Menu {
                        if #available(iOS 26.0, *) {
                            Button {
                                loadShareImage()
                                showingShareSheet = true
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } else {
                            // Fallback on earlier versions
                            Button(action: {
                                loadShareImage()
                                showingShareSheet = true
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                        
                        // Button(action: {
                        //     // Add to favorites functionality
                        //     print("Add to favorites")
                        // }) {
                        //     Label("Add to Favorites", systemImage: "heart")
                        // }
                        
                        // Button(action: {
                        //     // Show more info functionality
                        //     print("Show more info")
                        // }) {
                        //     Label("Show More Info", systemImage: "info.circle")
                        // }
                        
                        // Divider()
                        
                        // Button(action: {
                        //     // Report issue functionality
                        //     print("Report issue")
                        // }) {
                        //     Label("Report Issue", systemImage: "exclamationmark.triangle")
                        // }
                    } label: {
                        ZStack {
                            // Icon
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.375, weight: .medium))
                                .foregroundColor(.white)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .onTapGesture {
                        // Call the original callback if provided
                        onEllipsisTap?()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, geometry.size.width * 0.05)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(
                activityItems: [shareText],
                deepLinkURL: deepLinkURL,
                shareImage: shareImage
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            loadShareImage()
        }
    }
    
    private func loadShareImage() {
        guard let artworkURL = channelArtworkURL else { return }
        
        URLSession.shared.dataTask(with: artworkURL) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.shareImage = image
                }
            }
        }.resume()
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let deepLinkURL: URL?
    let shareImage: UIImage?
    
    init(activityItems: [Any], deepLinkURL: URL? = nil, shareImage: UIImage? = nil) {
        var items = activityItems
        if let shareImage = shareImage {
            items.append(shareImage)
        }
        if let deepLinkURL = deepLinkURL {
            items.append(deepLinkURL)
        }
        self.activityItems = items
        self.deepLinkURL = deepLinkURL
        self.shareImage = shareImage
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Exclude some activity types that don't make sense for deep links
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks,
            .markupAsPDF
        ]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    PlayerInfoView(
        title: "DR P1 - Morning Show",
        subtitle: "Current track information with long text that should scroll",
        channel: DRChannel(
            id: "p1",
            title: "DR P1",
            slug: "p1",
            type: "Channel",
            presentationUrl: "https://www.dr.dk/radio/p1"
        )
    ) {
        print("Ellipsis tapped")
    }
} 
