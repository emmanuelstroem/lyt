import Foundation
import SwiftUI
import Combine

// MARK: - Main API Response Models (Updated for DR API v4)

/// Direct array response from https://api.dr.dk/radio/v4/schedules/all/now
typealias DRNowResponse = [DRLiveProgram]

/// Represents a live program currently playing on a DR channel
struct DRLiveProgram: Identifiable, Codable {
    let id: String
    let type: String // "Live"
    let learnId: String
    let durationMilliseconds: Int
    let categories: [String]
    let productionNumber: String
    let startTime: Date
    let endTime: Date
    let presentationUrl: String?
    let order: Int
    let title: String
    let description: String?
    let series: DRSeries?
    let channel: DRChannel
    let audioAssets: [DRAudioAsset]
    let imageAssets: [DRImageAsset]
    let isAvailableOnDemand: Bool
    let hasVideo: Bool
    let explicitContent: Bool
    let slug: String
    
    // MARK: - Initializers
    
    /// Standard initializer for creating mock data
    init(
        id: String,
        type: String,
        learnId: String,
        durationMilliseconds: Int,
        categories: [String],
        productionNumber: String,
        startTime: Date,
        endTime: Date,
        presentationUrl: String?,
        order: Int,
        title: String,
        description: String?,
        series: DRSeries?,
        channel: DRChannel,
        audioAssets: [DRAudioAsset],
        imageAssets: [DRImageAsset],
        isAvailableOnDemand: Bool,
        hasVideo: Bool,
        explicitContent: Bool,
        slug: String
    ) {
        self.id = id
        self.type = type
        self.learnId = learnId
        self.durationMilliseconds = durationMilliseconds
        self.categories = categories
        self.productionNumber = productionNumber
        self.startTime = startTime
        self.endTime = endTime
        self.presentationUrl = presentationUrl
        self.order = order
        self.title = title
        self.description = description
        self.series = series
        self.channel = channel
        self.audioAssets = audioAssets
        self.imageAssets = imageAssets
        self.isAvailableOnDemand = isAvailableOnDemand
        self.hasVideo = hasVideo
        self.explicitContent = explicitContent
        self.slug = slug
    }
    
    // Computed properties for compatibility
    var isLive: Bool { type == "Live" }
    var duration: TimeInterval { Double(durationMilliseconds) / 1000.0 }
    var formattedDuration: String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type, learnId, durationMilliseconds, categories, productionNumber
        case startTime, endTime, presentationUrl, order, title, description
        case series, channel, audioAssets, imageAssets, isAvailableOnDemand
        case hasVideo, explicitContent, id, slug
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // The API doesn't include an "id" field, so we'll use learnId
        let learnId = try container.decode(String.self, forKey: .learnId)
        self.id = learnId
        self.learnId = learnId
        
        type = try container.decode(String.self, forKey: .type)
        durationMilliseconds = try container.decode(Int.self, forKey: .durationMilliseconds)
        categories = try container.decode([String].self, forKey: .categories)
        productionNumber = try container.decode(String.self, forKey: .productionNumber)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        presentationUrl = try container.decodeIfPresent(String.self, forKey: .presentationUrl)
        order = try container.decode(Int.self, forKey: .order)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        series = try container.decodeIfPresent(DRSeries.self, forKey: .series)
        channel = try container.decode(DRChannel.self, forKey: .channel)
        audioAssets = try container.decode([DRAudioAsset].self, forKey: .audioAssets)
        imageAssets = try container.decode([DRImageAsset].self, forKey: .imageAssets)
        isAvailableOnDemand = try container.decode(Bool.self, forKey: .isAvailableOnDemand)
        hasVideo = try container.decode(Bool.self, forKey: .hasVideo)
        explicitContent = try container.decode(Bool.self, forKey: .explicitContent)
        slug = try container.decode(String.self, forKey: .slug)
    }
}

// MARK: - Channel Model (Updated)

struct DRChannel: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let slug: String
    let type: String // "Channel"
    let presentationUrl: String
    
    // Computed properties for backward compatibility
    var name: String { slug.uppercased() }
    var displayName: String { title }
    var description: String { "DR \(title)" }
    var category: String {
        switch slug {
        case "p1": return "News"
        case "p2": return "Classical"
        case "p3": return "Music"
        case "p4kbh", "p4syd", "p4nord", "p4midt", "p4vest", "p4bornholm", "p4esbjerg", "p4fyn", "p4oestjylland": return "Regional"
        case "p5": return "Classical"
        case "p6beat": return "Rock"
        case "p7": return "Mix"
        case "p8jazz": return "Jazz"
        default: return "Music"
        }
    }
    
    var color: String {
        switch slug {
        case "p1": return "E60026"
        case "p2": return "9933CC"
        case "p3": return "FF6600"
        case "p4kbh", "p4syd", "p4nord", "p4midt", "p4vest", "p4bornholm", "p4esbjerg", "p4fyn", "p4oestjylland": return "0066CC"
        case "p5": return "663399"
        case "p6beat": return "000000"
        case "p7": return "FF3366"
        case "p8jazz": return "8B4513"
        default: return "999999"
        }
    }
    
    // SwiftUI Color from hex string
    var swiftUIColor: Color {
        Color(hex: color) ?? .accentColor
    }
}

// MARK: - Series Model

struct DRSeries: Codable, Hashable {
    let title: String
    let id: String
    let slug: String
    let type: String // "Series"
    let isAvailableOnDemand: Bool
    let presentationUrl: String?
    let learnId: String
}

// MARK: - Audio Asset Model

struct DRAudioAsset: Codable, Hashable {
    let type: String // "Audio"
    let target: String // "Stream"
    let isStreamLive: Bool
    let format: String // "HLS" or "ICY"
    let url: String
    let bitrate: Int? // Only for ICY streams
    
    var isHLS: Bool { format == "HLS" }
    var isICY: Bool { format == "ICY" }
}

// MARK: - Image Asset Model

struct DRImageAsset: Codable, Hashable {
    let id: String
    let target: String // "Default", "SquareImage", "Podcast"
    let ratio: String // "16:9", "1:1"
    let format: String // "image/jpeg", "image/png", "image/jpg"
    let blurHash: String?
    
    var isSquare: Bool { ratio == "1:1" }
    var isWidescreen: Bool { ratio == "16:9" }
    var isPodcastImage: Bool { target == "Podcast" }
}

// MARK: - Legacy Models for Backward Compatibility

/// Legacy program model for backward compatibility
struct DRProgram: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String?
    let hosts: [String]
    let imageURL: String?
    let startTime: Date
    let endTime: Date
    let channelId: String
    let category: String
    let isLive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, hosts, category
        case imageURL = "image_url"
        case startTime = "start_time"
        case endTime = "end_time"
        case channelId = "channel_id"
        case isLive = "is_live"
    }
    
    /// Duration of the program in seconds
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    /// Formatted duration string (e.g., "1h 30m")
    var formattedDuration: String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Legacy track info model for current music playing
struct DRTrackInfo: Codable, Hashable {
    let title: String?
    let artist: String?
    let album: String?
    let albumArt: String?
    let startTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case title, artist, album
        case albumArt = "album_art"
        case startTime = "start_time"
    }
}

/// Legacy now playing wrapper
struct DRNowPlaying: Identifiable, Codable {
    let id = UUID()
    let channel: DRChannel
    let currentProgram: DRProgram?
    let nextProgram: DRProgram?
    let trackInfo: DRTrackInfo?
    let isLive: Bool
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case channel
        case currentProgram = "current_program"
        case nextProgram = "next_program"
        case trackInfo = "track_info"
        case isLive = "is_live"
        case lastUpdated = "last_updated"
    }
}

// MARK: - App State Models

/// Playback state for the audio player
enum PlaybackState {
    case stopped
    case loading
    case playing
    case paused
    case error(String)
}

/// Current app state for radio playback
class DRAppState: ObservableObject {
    @Published var selectedChannel: DRChannel?
    @Published var currentLiveProgram: DRLiveProgram?
    @Published var playbackState: PlaybackState = .stopped
    @Published var volume: Double = 0.7
    @Published var isMuted: Bool = false
    @Published var availableChannels: [DRChannel] = []
    @Published var allLivePrograms: [DRLiveProgram] = []
    @Published var lastError: String?
    
    // Legacy compatibility
    var nowPlaying: DRNowPlaying? {
        guard let selectedChannel = selectedChannel,
              let currentProgram = currentLiveProgram else { return nil }
        
        let legacyProgram = DRProgram(
            id: currentProgram.id,
            title: currentProgram.title,
            description: currentProgram.description,
            hosts: [], // Not available in new API
            imageURL: currentProgram.imageAssets.first(where: { $0.target == "Default" })?.id,
            startTime: currentProgram.startTime,
            endTime: currentProgram.endTime,
            channelId: selectedChannel.id,
            category: currentProgram.categories.first ?? "Unknown",
            isLive: currentProgram.isLive
        )
        
        return DRNowPlaying(
            channel: selectedChannel,
            currentProgram: legacyProgram,
            nextProgram: nil, // Would need additional API call
            trackInfo: nil, // Not available in current API
            isLive: currentProgram.isLive,
            lastUpdated: Date()
        )
    }
}

// MARK: - Extensions

extension Color {
    /// Initialize Color from hex string
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

extension Date {
    /// Format time for UI display (e.g., "14:30")
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format date and time for UI display
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Stream URL Helpers

extension DRLiveProgram {
    /// Get the preferred HLS stream URL
    var hlsStreamURL: String? {
        return audioAssets.first { $0.isHLS }?.url
    }
    
    /// Get ICY stream URL with highest bitrate
    var icyStreamURL: String? {
        return audioAssets
            .filter { $0.isICY }
            .max { ($0.bitrate ?? 0) < ($1.bitrate ?? 0) }?.url
    }
    
    /// Get the best available stream URL (prefer HLS)
    var streamURL: String? {
        return hlsStreamURL ?? icyStreamURL
    }
    
    /// Get default image URL
    var imageURL: String? {
        // Try to get default 16:9 image first, fallback to square
        return imageAssets.first { $0.target == "Default" && $0.isWidescreen }?.id ??
               imageAssets.first { $0.target == "Default" }?.id
    }
    
    /// Get square image URL for compact displays
    var squareImageURL: String? {
        return imageAssets.first { $0.target == "SquareImage" }?.id
    }
} 