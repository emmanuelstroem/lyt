//
//  DRModels.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - iOS DR Models

// MARK: - API Configuration
struct DRAPIConfig {
    static let baseURL = "https://api.dr.dk/radio/v4"
    static let assetBaseURL = "https://asset.dr.dk/drlyd/images"
    
    // API Endpoints
    static let schedulesAllNow = "\(baseURL)/schedules/all/now"
    static let scheduleSnapshot = "\(baseURL)/schedules/snapshot"
    static let indexpointsLive = "\(baseURL)/indexpoints/live"
    
    static func imageURL(for imageAssetURN: String) -> String {
        return "\(assetBaseURL)/\(imageAssetURN)"
    }
}

// MARK: - Channel Models
struct DRChannel: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let slug: String
    let type: String
    let presentationUrl: String?
    
    var displayName: String { title }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DRChannel, rhs: DRChannel) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Series Models
struct DRSeries: Codable, Equatable {
    let id: String
    let title: String
    let slug: String
    let type: String
    let isAvailableOnDemand: Bool
    let presentationUrl: String?
    let learnId: String
}

// MARK: - Audio Asset Models
struct DRAudioAsset: Codable, Equatable {
    let type: String
    let target: String
    let isStreamLive: Bool?
    let format: String
    let bitrate: Int?
    let url: String
}

// MARK: - Image Asset Models
struct DRImageAsset: Codable, Equatable {
    let id: String
    let target: String
    let ratio: String
    let format: String
    let blurHash: String?
    
    var imageURL: String {
        return DRAPIConfig.imageURL(for: id)
    }
}

// MARK: - Role Models (for tracks)
struct DRRole: Codable, Equatable {
    let artistUrn: String
    let role: String
    let name: String
    let musicUrl: String
}

// MARK: - Track Models (for currently playing songs)
struct DRTrack: Identifiable, Codable, Equatable {
    let type: String
    let durationMilliseconds: Int
    let playedTime: String
    let musicUrl: String
    let trackUrn: String
    let classical: Bool
    let roles: [DRRole]?
    let title: String
    let description: String
    
    var id: String { trackUrn }
    
    var playedDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: playedTime)
    }
    
    var duration: TimeInterval {
        return TimeInterval(durationMilliseconds / 1000)
    }
    
    var isCurrentlyPlaying: Bool {
        guard let playedDate = playedDate else { return false }
        let now = Date()
        let endTime = playedDate.addingTimeInterval(duration)
        return now >= playedDate && now <= endTime
    }
    
    var artistName: String {
        return roles?.first(where: { $0.role == "Hovedkunstner" })?.name ?? description
    }
}

// MARK: - Episode/Program Models
struct DREpisode: Identifiable, Codable, Equatable {
    let type: String
    let learnId: String
    let durationMilliseconds: Int
    let categories: [String]?
    let productionNumber: String?
    let startTime: String
    let endTime: String
    let presentationUrl: String?
    let order: Int
    let previousId: String?
    let nextId: String?
    let series: DRSeries?
    let channel: DRChannel
    let audioAssets: [DRAudioAsset]? // Made optional to handle missing audio assets
    let isAvailableOnDemand: Bool
    let hasVideo: Bool?
    let explicitContent: Bool?
    let id: String
    let slug: String
    let title: String
    let description: String? // Made optional based on API analysis
    let imageAssets: [DRImageAsset]? // Made optional to handle missing image assets
    let episodeNumber: Int? // Made optional based on API analysis
    let seasonNumber: Int? // Made optional based on API analysis
    
    var startDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: startTime)
    }
    
    var endDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: endTime)
    }
    
    var duration: TimeInterval {
        return TimeInterval(durationMilliseconds / 1000)
    }
    
    var isLive: Bool {
        return type == "Live"
    }
    
    var isCurrentlyPlaying: Bool {
        guard let startDate = startDate, let endDate = endDate else { return false }
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    var squareImageURL: String? {
        return imageAssets?.first(where: { $0.target == "SquareImage" })?.imageURL
    }
    
    var streamURL: String? {
        guard let audioAssets = audioAssets, !audioAssets.isEmpty else {
            // If no audio assets, try to construct a stream URL from the channel
            return constructFallbackStreamURL()
        }
        
        // For live radio, we need to prioritize live streams
        // First try to find a live stream (isStreamLive: true)
        if let liveStream = audioAssets.first(where: { $0.isStreamLive == true }) {
            return liveStream.url
        }
        
        // If no live stream found, check if this is a live radio program
        if isLive {
            // For live programs, use the fallback stream URL instead of on-demand content
            return constructFallbackStreamURL()
        }
        
        // For on-demand content, try to find any stream with target "Stream"
        if let streamAsset = audioAssets.first(where: { $0.target == "Stream" }) {
            return streamAsset.url
        }
        
        // For on-demand content, try to find any stream with target "Progressive"
        if let progressiveAsset = audioAssets.first(where: { $0.target == "Progressive" }) {
            return progressiveAsset.url
        }
        
        // Fallback to first available audio asset
        return audioAssets.first?.url
    }
    
    private func constructFallbackStreamURL() -> String? {
        // Construct a fallback stream URL based on the channel slug
        // This is the standard pattern for DR radio live streams
        let channelSlug = channel.slug.lowercased()
        
        // Map channel slugs to their correct stream URLs
        let streamURLs: [String: String] = [
            "p1": "https://live-icy.gss.dr.dk/AACP1",
            "p2": "https://live-icy.gss.dr.dk/AACP2", 
            "p3": "https://live-icy.gss.dr.dk/AACP3",
            "p4kbh": "https://live-icy.gss.dr.dk/AACP4KBH",
            "p4fyn": "https://live-icy.gss.dr.dk/AACP4FYN",
            "p4sjaelland": "https://live-icy.gss.dr.dk/AACP4SJAEL",
            "p4bornholm": "https://live-icy.gss.dr.dk/AACP4BORNH",
            "p4trekanten": "https://live-icy.gss.dr.dk/AACP4TREK",
            "p4vest": "https://live-icy.gss.dr.dk/AACP4VEST",
            "p4syd": "https://live-icy.gss.dr.dk/AACP4SYD",
            "p4nord": "https://live-icy.gss.dr.dk/AACP4NORD",
            "p4aarhus": "https://live-icy.gss.dr.dk/AACP4AARHUS",
            "p5bornholm": "https://live-icy.gss.dr.dk/AACP5BORNHOLM",
            "p5esbjerg": "https://live-icy.gss.dr.dk/AACP5ESBJERG",
            "p5fyn": "https://live-icy.gss.dr.dk/AACP5FYN",
            "p5kbh": "https://live-icy.gss.dr.dk/AACP5KBH",
            "p5vest": "https://live-icy.gss.dr.dk/AACP5VEST",
            "p5nord": "https://live-icy.gss.dr.dk/AACP5NORD",
            "p5sjaelland": "https://live-icy.gss.dr.dk/AACP5SJAELLAND",
            "p5syd": "https://live-icy.gss.dr.dk/AACP5SYD",
            "p5trekanten": "https://live-icy.gss.dr.dk/AACP5TREKANTEN",
            "p5aarhus": "https://live-icy.gss.dr.dk/AACP5AARHUS",
            "p6beat": "https://live-icy.gss.dr.dk/AACP6BEAT",
            "p8jazz": "https://live-icy.gss.dr.dk/AACP8JAZZ"
        ]
        
        return streamURLs[channelSlug] ?? "https://live-icy.gss.dr.dk/AAC\(channel.slug.uppercased())"
    }
    
    var primaryImageURL: String? {
        guard let imageAssets = imageAssets, !imageAssets.isEmpty else { return nil }
        
        // Try to find a square or 1:1 ratio image first
        if let squareImage = imageAssets.first(where: { $0.ratio == "1:1" || $0.ratio == "square" }) {
            return squareImage.imageURL
        }
        // Fallback to first available image
        return imageAssets.first?.imageURL
    }
}

// MARK: - Schedule Response Models
struct DRScheduleResponse: Codable, Equatable {
    let type: String
    let channel: DRChannel
    let items: [DREpisode]
    let scheduleDate: String?
}

struct DRAllSchedulesResponse: Codable, Equatable {
    let schedules: [DREpisode]
}

// MARK: - Index Points Response Models
struct DRIndexPointsResponse: Codable, Equatable {
    let type: String
    let channel: DRChannel
    let totalSize: Int
    let items: [DRTrack]
    let id: String
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var availableChannels: [DRChannel] = []
    @Published var channelGroups: [ChannelGroup] = []
    @Published var isLoading = false
    @Published var error: String?
}

// MARK: - Channel Organization
struct ChannelGroup: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let channels: [DRChannel]
    let color: String?
    
    var isRegional: Bool {
        return channels.count > 1
    }
    
    var swiftUIColor: Color {
        if let colorString = color {
            return Color(hex: colorString) ?? .blue
        }
        return .blue
    }
}

struct ChannelRegion: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let channel: DRChannel
}

// MARK: - Service Manager
class DRServiceManager: ObservableObject {
    // Direct observable properties
    @Published var availableChannels: [DRChannel] = []
    @Published var channelGroups: [ChannelGroup] = []
    @Published var isLoading = false
    @Published var error: String?
    
    @Published var playingChannel: DRChannel?
    @Published var currentLiveProgram: DREpisode?
    @Published var currentTrack: DRTrack?
    @Published var isPlaying = false
    @Published var playbackError: String? // Separate error for playback issues
    
    let audioPlayer = AudioPlayerService()
    private let networkService = DRNetworkService()
    private var cancellables = Set<AnyCancellable>()
    
    // Caching properties
    private var cachedSchedules: [DREpisode] = []
    private var lastSchedulesUpdate: Date?
    private let cacheValidityDuration: TimeInterval = 10 * 60 // 10 minutes
    
    init() {
        setupBindings()
        loadChannels()
    }
    
    private func setupBindings() {
        audioPlayer.$isPlaying
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
        
        audioPlayer.$error
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    private func isCacheValid() -> Bool {
        guard let lastUpdate = lastSchedulesUpdate else { return false }
        return Date().timeIntervalSince(lastUpdate) < cacheValidityDuration
    }
    
    func loadChannels() {
        // Check if we have valid cached data
        if !cachedSchedules.isEmpty && isCacheValid() {
            let channels = Array(Set(cachedSchedules.map { $0.channel })).sorted { $0.title < $1.title }
            self.availableChannels = channels
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let schedules = try await networkService.fetchAllSchedules()
                let channels = Array(Set(schedules.map { $0.channel })).sorted { $0.title < $1.title }
                
                await MainActor.run {
                    self.cachedSchedules = schedules
                    self.lastSchedulesUpdate = Date()
                    self.availableChannels = channels
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func togglePlayback(for channel: DRChannel) {
        print("🎵 togglePlayback called for: \(channel.title)")
        print("🎵 Current playing channel: \(playingChannel?.title ?? "None")")
        print("🎵 Is currently playing: \(isPlaying)")
        
        if playingChannel?.id == channel.id {
            if isPlaying {
                print("🎵 Pausing current channel")
                audioPlayer.pause()
            } else {
                print("🎵 Resuming current channel")
                audioPlayer.resume()
            }
        } else {
            print("🎵 Starting new channel playback")
            playChannel(channel)
        }
    }
    
    func playChannel(_ channel: DRChannel) {
        Task {
            do {
                print("🎵 DRServiceManager: Starting playback for channel: \(channel.title)")
                
                // Get current program for the channel
                let schedule = try await networkService.fetchScheduleSnapshot(for: channel.slug)
                let currentProgram = schedule.items.first { $0.isCurrentlyPlaying }
                
                // Get current track
                let indexPoints = try await networkService.fetchIndexPoints(for: channel.slug)
                let currentTrack = indexPoints.items.first { $0.isCurrentlyPlaying }
                
                await MainActor.run {
                    self.currentLiveProgram = currentProgram
                    self.currentTrack = currentTrack
                }
                
                // Try to get stream URL from current program first
                var streamURL: String? = currentProgram?.streamURL
                
                // If no stream URL from current program, try to get from any program in the schedule
                if streamURL == nil {
                    streamURL = schedule.items.first?.streamURL
                }
                
                // If still no stream URL, construct a fallback URL
                if streamURL == nil {
                    streamURL = "https://live-icy.gss.dr.dk/AAC\(channel.slug.uppercased())"
                    print("🎵 DRServiceManager: Using fallback stream URL: \(streamURL ?? "None")")
                }
                
                // Debug: Log the stream URL selection process
                print("🎵 DRServiceManager: Stream URL selection:")
                print("   - Current program: \(currentProgram?.title ?? "None")")
                print("   - Current program type: \(currentProgram?.type ?? "None")")
                print("   - Current program isLive: \(currentProgram?.isLive ?? false)")
                print("   - Selected stream URL: \(streamURL ?? "None")")
                
                // Play the stream
                if let finalStreamURL = streamURL,
                   let url = URL(string: finalStreamURL) {
                    print("🔗 Found stream URL: \(finalStreamURL)")
                    await MainActor.run {
                        print("🎵 Setting playing channel and starting audio")
                        self.playingChannel = channel
                        self.audioPlayer.play(url: url)
                    }
                } else {
                    print("❌ No stream URL found for channel: \(channel.title)")
                    await MainActor.run {
                        self.playbackError = "No stream URL available for \(channel.title)"
                    }
                }
            } catch {
                print("❌ Error playing channel \(channel.title): \(error)")
                await MainActor.run {
                    self.playbackError = error.localizedDescription
                }
            }
        }
    }
    
    func getCurrentProgram(for channel: DRChannel) -> DREpisode? {
        let channelPrograms = cachedSchedules.filter { $0.channel.id == channel.id }
        return channelPrograms.first { $0.isCurrentlyPlaying } ?? channelPrograms.first
    }
    
    func clearPlaybackError() {
        playbackError = nil
    }
}

// MARK: - Selection State
class SelectionState: ObservableObject {
    @Published var selectedChannel: DRChannel?
    @Published var selectedRegion: ChannelRegion?
    
    func selectChannel(_ channel: DRChannel, showSheet: Bool = false) {
        selectedChannel = channel
        selectedRegion = nil
    }
    
    func openNestedNavigation(for channel: DRChannel, in region: ChannelRegion) {
        selectedChannel = channel
        selectedRegion = region
    }
}

// MARK: - Navigation State
class ChannelNavigationState: ObservableObject {
    @Published var navigationPath: [String] = []
    
    func navigateToChannel(_ channelId: String) {
        navigationPath.append(channelId)
    }
    
    func navigateBack() {
        _ = navigationPath.popLast()
    }
}

// MARK: - Channel Organizer
struct ChannelOrganizer {
    static func getRegionsForGroup(_ channels: [DRChannel], groupPrefix: String) -> [ChannelRegion] {
        return channels.map { channel in
            let regionName = channel.displayName.replacingOccurrences(of: groupPrefix, with: "").trimmingCharacters(in: .whitespaces)
            return ChannelRegion(id: channel.id, name: regionName, channel: channel)
        }
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
