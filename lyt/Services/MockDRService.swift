import Foundation

/// Mock service providing realistic DR radio data for Phase 0 testing
/// Updated to match actual DR API v4 structure from https://api.dr.dk/radio/v4/schedules/all/now
class MockDRService {
    
    // MARK: - Static Mock Data (Updated for API v4)
    
    /// Generate mock live programs matching the real DR API v4 structure
    static func mockLivePrograms() -> [DRLiveProgram] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            // P1 - News Channel
            createMockLiveProgram(
                learnId: "urn:dr:ocs:audio:content:playable:11802510304",
                title: "P1 Orientering",
                description: "Få et originalt perspektiv på de begivenheder, der former verden og opdag de oversete historier, der kommer til at ændre verden.",
                channelSlug: "p1",
                channelTitle: "P1",
                seriesTitle: "P1 Orientering",
                categories: ["Nyheder"],
                startTime: calendar.date(byAdding: .minute, value: -30, to: now)!,
                durationMinutes: 120
            ),
            
            // P2 - Classical Music
            createMockLiveProgram(
                learnId: "urn:dr:ocs:audio:content:playable:12422583304",
                title: "Heise i hængekøjen",
                description: "Hvad rimer på skøn musik og god stemning? Det gør Heise i hængekøjen. Lotte Heise spiller sin yndlingsmusik.",
                channelSlug: "p2",
                channelTitle: "P2",
                seriesTitle: "Heise i hængekøjen",
                categories: ["Musik", "Klassisk"],
                startTime: calendar.date(byAdding: .minute, value: -15, to: now)!,
                durationMinutes: 120
            ),
            
            // P3 - Pop Music
            createMockLiveProgram(
                learnId: "urn:dr:ocs:audio:content:playable:13422583304",
                title: "Musikhjælpen",
                description: "De hotteste hits og popkultur for unge voksne.",
                channelSlug: "p3",
                channelTitle: "P3",
                seriesTitle: "Musikhjælpen",
                categories: ["Musik"],
                startTime: calendar.date(byAdding: .minute, value: -45, to: now)!,
                durationMinutes: 180
            ),
            
            // P4 København - Regional
            createMockLiveProgram(
                learnId: "urn:dr:ocs:audio:content:playable:14422583304",
                title: "Touren på P4",
                description: "Følg Tour de France med live kommentarer og analyse.",
                channelSlug: "p4kbh",
                channelTitle: "P4 København",
                seriesTitle: "Touren på P4",
                categories: ["Sport"],
                startTime: calendar.date(byAdding: .hour, value: -1, to: now)!,
                durationMinutes: 180
            ),
            
            // P6 Beat - Rock
            createMockLiveProgram(
                learnId: "urn:dr:ocs:audio:content:playable:16452511304",
                title: "P6 med Camilla Jane Lea",
                description: "Det bedste af dansk og international rock.",
                channelSlug: "p6beat",
                channelTitle: "P6",
                seriesTitle: "P6 med Camilla Jane Lea",
                categories: ["Musik"],
                startTime: calendar.date(byAdding: .minute, value: -60, to: now)!,
                durationMinutes: 120
            ),
            
            // P8 Jazz
            createMockLiveProgram(
                learnId: "urn:dr:ocs:audio:content:playable:18452583304",
                title: "P8 eftermiddag",
                description: "Jazz døgnet rundt med de bedste klassikere og nye opdagelser.",
                channelSlug: "p8jazz",
                channelTitle: "P8",
                seriesTitle: "P8 eftermiddag",
                categories: ["Musik", "Jazz"],
                startTime: calendar.date(byAdding: .minute, value: -90, to: now)!,
                durationMinutes: 120
            )
        ]
    }
    
    /// Helper function to create a mock live program
    private static func createMockLiveProgram(
        learnId: String,
        title: String,
        description: String,
        channelSlug: String,
        channelTitle: String,
        seriesTitle: String,
        categories: [String],
        startTime: Date,
        durationMinutes: Int
    ) -> DRLiveProgram {
        
        let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
        let durationMs = durationMinutes * 60 * 1000
        
        // Create channel
        let channel = DRChannel(
            id: "urn:dr:radio:channel:\(channelSlug)",
            title: channelTitle,
            slug: channelSlug,
            type: "Channel",
            presentationUrl: "https://www.dr.dk/lyd/\(channelSlug)"
        )
        
        // Create series
        let series = DRSeries(
            title: seriesTitle,
            id: "urn:dr:radio:series:\(UUID().uuidString)",
            slug: "\(seriesTitle.lowercased().replacingOccurrences(of: " ", with: "-"))-\(Int.random(in: 1000000000...9999999999))",
            type: "Series",
            isAvailableOnDemand: true,
            presentationUrl: "https://www.dr.dk/lyd/\(channelSlug)/\(seriesTitle.lowercased().replacingOccurrences(of: " ", with: "-"))",
            learnId: "urn:dr:ocs:audio:content:series:\(Int.random(in: 1000000000...9999999999))"
        )
        
        // Create audio assets
        let audioAssets = createMockAudioAssets(for: channelSlug)
        
        // Create image assets
        let imageAssets = createMockImageAssets()
        
        return DRLiveProgram(
            id: learnId,
            type: "Live",
            learnId: learnId,
            durationMilliseconds: durationMs,
            categories: categories,
            productionNumber: String(Int.random(in: 10000000000...99999999999)),
            startTime: startTime,
            endTime: endTime,
            presentationUrl: "https://www.dr.dk/lyd/\(channelSlug)/\(title.lowercased().replacingOccurrences(of: " ", with: "-"))",
            order: 0,
            title: title,
            description: description,
            series: series,
            channel: channel,
            audioAssets: audioAssets,
            imageAssets: imageAssets,
            isAvailableOnDemand: false,
            hasVideo: false,
            explicitContent: false,
            slug: "\(title.lowercased().replacingOccurrences(of: " ", with: "-"))-\(Int.random(in: 1000000000...9999999999))"
        )
    }
    
    /// Create mock audio assets for a channel
    private static func createMockAudioAssets(for channelSlug: String) -> [DRAudioAsset] {
        let baseURL = "https://drliveradio1.akamaized.net/hls/live/2097651/\(channelSlug)"
        let icyBaseURL = "https://live-icy.dr.dk/A"
        
        // Map channel slugs to ICY stream codes (based on real DR structure)
        let icyCode: String
        switch channelSlug {
        case "p1": icyCode = "A03"
        case "p2": icyCode = "A04"
        case "p3": icyCode = "A05"
        case "p4kbh": icyCode = "A08"
        case "p5": icyCode = "A21"
        case "p6beat": icyCode = "A29"
        case "p8jazz": icyCode = "A22"
        default: icyCode = "A03"
        }
        
        return [
            DRAudioAsset(
                type: "Audio",
                target: "Stream",
                isStreamLive: true,
                format: "HLS",
                url: "\(baseURL)/masterab.m3u8",
                bitrate: nil
            ),
            DRAudioAsset(
                type: "Audio",
                target: "Stream",
                isStreamLive: true,
                format: "ICY",
                url: "\(icyBaseURL)/\(icyCode)L.mp3",
                bitrate: 96
            ),
            DRAudioAsset(
                type: "Audio",
                target: "Stream",
                isStreamLive: true,
                format: "ICY",
                url: "\(icyBaseURL)/\(icyCode)H.mp3",
                bitrate: 192
            )
        ]
    }
    
    /// Create mock image assets
    private static func createMockImageAssets() -> [DRImageAsset] {
        let imageId = "urn:dr:radio:image:\(UUID().uuidString)"
        
        return [
            DRImageAsset(
                id: imageId,
                target: "Default",
                ratio: "16:9",
                format: "image/jpeg",
                blurHash: "NJR3D@t7?bt7wHt7_Mj[R5jsK5bHv}jtK5a}wIjZ"
            ),
            DRImageAsset(
                id: imageId,
                target: "SquareImage",
                ratio: "1:1",
                format: "image/jpeg",
                blurHash: "oLQl^4t7cYt7wvt7?^j[rDjsOEfR#7jsOsa}s9fQXnfRwIjtWWfQwvfQS4fQf+a}ogfQoffRnijZ"
            ),
            DRImageAsset(
                id: imageId,
                target: "Podcast",
                ratio: "1:1",
                format: "image/jpeg",
                blurHash: "oHQcSNrsX-s:wbxu_NVsq[enNxkCzpaKJ.aes9kCTKi{v}jFR,fkwbn%R-jZf+bHt8ofozj[nhay"
            )
        ]
    }
    
    // MARK: - Service Methods (Updated for API v4)
    
    /// Fetch current now playing information (returns array directly like real API)
    func fetchNowPlaying() async throws -> DRNowResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return Self.mockLivePrograms()
    }
    
    /// Get available channels from mock data
    func getChannels() -> [DRChannel] {
        return Self.mockLivePrograms().map { $0.channel }
    }
    
    /// Get a specific channel by ID
    func getChannel(id: String) -> DRChannel? {
        return getChannels().first { $0.id == id }
    }
    
    /// Get live program for a specific channel
    func getLiveProgram(for channelSlug: String) -> DRLiveProgram? {
        return Self.mockLivePrograms().first { $0.channel.slug == channelSlug }
    }
    
    // MARK: - Legacy Compatibility Methods
    
    /// Legacy fetch schedule method (for backward compatibility)
    func fetchSchedule(for channelId: String, date: Date = Date()) async throws -> DRScheduleResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Convert new format to legacy format
        let livePrograms = Self.mockLivePrograms().filter { $0.channel.id == channelId }
        let legacyPrograms = livePrograms.map { liveProgram in
            DRProgram(
                id: liveProgram.id,
                title: liveProgram.title,
                description: liveProgram.description,
                hosts: [], // Not available in new API
                imageURL: liveProgram.imageURL,
                startTime: liveProgram.startTime,
                endTime: liveProgram.endTime,
                channelId: liveProgram.channel.id,
                category: liveProgram.categories.first ?? "Unknown",
                isLive: liveProgram.isLive
            )
        }
        
        return DRScheduleResponse(
            channelId: channelId,
            date: dateFormatter.string(from: date),
            programs: legacyPrograms
        )
    }
}

// MARK: - Legacy Response Models (for backward compatibility)

struct DRScheduleResponse: Codable {
    let channelId: String
    let date: String
    let programs: [DRProgram]
    
    enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case date, programs
    }
}

// MARK: - Mock Data Validation

extension MockDRService {
    /// Validate that mock data structure matches expected API format
    static func validateMockData() -> [String] {
        var validationErrors: [String] = []
        
        let livePrograms = mockLivePrograms()
        
        // Validate live programs
        for program in livePrograms {
            if program.id.isEmpty {
                validationErrors.append("Program ID cannot be empty")
            }
            if program.learnId.isEmpty {
                validationErrors.append("Program learnId cannot be empty")
            }
            if program.title.isEmpty {
                validationErrors.append("Program \(program.id) has empty title")
            }
            if program.channel.id.isEmpty {
                validationErrors.append("Program \(program.id) has empty channel ID")
            }
            if program.audioAssets.isEmpty {
                validationErrors.append("Program \(program.id) has no audio assets")
            }
            if program.startTime >= program.endTime {
                validationErrors.append("Program \(program.id) has invalid time range")
            }
            
            // Validate audio assets
            let hasHLS = program.audioAssets.contains { $0.format == "HLS" }
            if !hasHLS {
                validationErrors.append("Program \(program.id) missing HLS stream")
            }
            
            // Validate channel color
            if !isValidHexColor(program.channel.color) {
                validationErrors.append("Channel \(program.channel.slug) has invalid color: \(program.channel.color)")
            }
        }
        
        return validationErrors
    }
    
    private static func isValidHexColor(_ hex: String) -> Bool {
        let hexPattern = "^[0-9A-Fa-f]{6}$"
        return hex.range(of: hexPattern, options: .regularExpression) != nil
    }
}

// MARK: - Error Simulation

extension MockDRService {
    /// Simulate network errors for testing error handling
    func simulateNetworkError() async throws -> DRNowResponse {
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        throw NetworkError.connectionFailed
    }
    
    /// Simulate API errors
    func simulateAPIError() async throws -> DRNowResponse {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        throw NetworkError.apiError("Mock API Error: Service temporarily unavailable")
    }
}

enum NetworkError: Error, LocalizedError {
    case connectionFailed
    case apiError(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Could not connect to DR servers"
        case .apiError(let message):
            return message
        case .invalidData:
            return "Invalid data received from server"
        }
    }
} 