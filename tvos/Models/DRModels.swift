//
//  DRModels.swift
//  tvos
//
//  Created by Emmanuel on 27/07/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - tvOS DR Models

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
    let presentationUrl: String
    
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
    let presentationUrl: String
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
struct DRTrackRole: Codable, Equatable {
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
    let roles: [DRTrackRole]?
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
    
    var displayText: String {
        return "\(artistName): \(title)"
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
    let audioAssets: [DRAudioAsset]
    let isAvailableOnDemand: Bool
    let hasVideo: Bool?
    let explicitContent: Bool?
    let id: String
    let slug: String
    let title: String
    let description: String? // Made optional based on API analysis
    let imageAssets: [DRImageAsset]
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
    
    /// Returns the program title with channel name removed to avoid duplication
    /// This is useful when displaying program titles alongside channel names
    func cleanTitle() -> String {
        return title.replacingOccurrences(of: channel.title, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var primaryImageURL: String? {
        return imageAssets.first(where: { $0.target == "Default" })?.imageURL
    }
    
    var squareImageURL: String? {
        return imageAssets.first(where: { $0.target == "SquareImage" })?.imageURL
    }
    
    var streamURL: String? {
        return audioAssets.first(where: { $0.isStreamLive == true })?.url
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
    
    private let audioPlayer = AudioPlayerService()
    private let networkService = DRNetworkService()
    private var cancellables = Set<AnyCancellable>()
    
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
    
    func loadChannels() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let schedules = try await networkService.fetchAllSchedules()
                let channels = Array(Set(schedules.map { $0.channel })).sorted { $0.title < $1.title }
                
                await MainActor.run {
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
        if playingChannel?.id == channel.id {
            if isPlaying {
                audioPlayer.pause()
            } else {
                audioPlayer.resume()
            }
        } else {
            playChannel(channel)
        }
    }
    
    func playChannel(_ channel: DRChannel) {
        Task {
            do {
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
                
                // Play the stream
                if let streamURL = currentProgram?.streamURL ?? schedule.items.first?.streamURL,
                   let url = URL(string: streamURL) {
                    await MainActor.run {
                        self.playingChannel = channel
                        self.audioPlayer.play(url: url)
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    @MainActor
    func refreshNowPlaying() async {
        guard let channel = playingChannel else { return }
        
        do {
            let schedule = try await networkService.fetchScheduleSnapshot(for: channel.slug)
            let currentProgram = schedule.items.first { $0.isCurrentlyPlaying }
            
            let indexPoints = try await networkService.fetchIndexPoints(for: channel.slug)
            let currentTrack = indexPoints.items.first { $0.isCurrentlyPlaying }
            
            self.currentLiveProgram = currentProgram
            self.currentTrack = currentTrack
        } catch {
            self.error = error.localizedDescription
        }
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