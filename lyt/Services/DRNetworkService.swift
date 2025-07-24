import Foundation
import Combine

/// Protocol defining the DR radio service interface
/// This will be implemented for both mock data (Phase 0) and real API calls (Phase 2)
protocol DRServiceProtocol {
    /// Fetch current now playing information for all channels
    func fetchNowPlaying() async throws -> DRNowResponse
    
    /// Get available channels
    func getChannels() -> [DRChannel]
    
    /// Get a specific channel by ID
    func getChannel(id: String) -> DRChannel?
    
    /// Get live program for a specific channel
    func getLiveProgram(for channelSlug: String) -> DRLiveProgram?
    
    /// Legacy method for backward compatibility
    func fetchSchedule(for channelId: String, date: Date) async throws -> DRScheduleResponse
}

/// Real DR network service (Phase 2 implementation)
class DRNetworkService: DRServiceProtocol {
    
    // MARK: - Configuration
    
    private let baseURL = "https://api.dr.dk/radio/v4"
    private let session: URLSession
    private var cachedChannels: [DRChannel] = []
    private var cachedLivePrograms: [DRLiveProgram] = []
    private var lastFetchTime: Date?
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Service Methods (Phase 2 Implementation)
    
    func fetchNowPlaying() async throws -> DRNowResponse {
        let endpoint = "schedules/all/now"
        
        do {
            let livePrograms: [DRLiveProgram] = try await makeRequest(
                endpoint: endpoint,
                responseType: [DRLiveProgram].self
            )
            
            // Cache the results
            cachedLivePrograms = livePrograms
            cachedChannels = Array(Set(livePrograms.map { $0.channel }))
            lastFetchTime = Date()
            
            return livePrograms
            
        } catch {
            print("Network fetch failed, falling back to mock data: \(error)")
            // Fallback to mock service for Phase 0
            let mockService = MockDRService()
            return try await mockService.fetchNowPlaying()
        }
    }
    
    func getChannels() -> [DRChannel] {
        // Return cached channels if available, otherwise use mock data
        if !cachedChannels.isEmpty {
            return cachedChannels
        } else {
            let mockService = MockDRService()
            return mockService.getChannels()
        }
    }
    
    func getChannel(id: String) -> DRChannel? {
        return getChannels().first { $0.id == id }
    }
    
    func getLiveProgram(for channelSlug: String) -> DRLiveProgram? {
        return cachedLivePrograms.first { $0.channel.slug == channelSlug }
    }
    
    func fetchSchedule(for channelId: String, date: Date = Date()) async throws -> DRScheduleResponse {
        // For now, convert from live programs - in Phase 2 we might add specific schedule endpoints
        let livePrograms = cachedLivePrograms.filter { $0.channel.id == channelId }
        let legacyPrograms = livePrograms.map { liveProgram in
            DRProgram(
                id: liveProgram.id,
                title: liveProgram.title,
                description: liveProgram.description,
                hosts: [], // Not available in current API
                imageURL: liveProgram.imageURL,
                startTime: liveProgram.startTime,
                endTime: liveProgram.endTime,
                channelId: liveProgram.channel.id,
                category: liveProgram.categories.first ?? "Unknown",
                isLive: liveProgram.isLive
            )
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return DRScheduleResponse(
            channelId: channelId,
            date: dateFormatter.string(from: date),
            programs: legacyPrograms
        )
    }
    
    // MARK: - Helper Methods
    
    private func makeRequest<T: Codable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Lyt/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        
        print("Fetching from DR API: \(url)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            print("DR API Response: \(httpResponse.statusCode)")
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            // DR API uses ISO 8601 dates with timezone
            decoder.dateDecodingStrategy = .iso8601
            
            // Debug: Print raw JSON for development
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON sample: \(String(jsonString.prefix(500)))...")
            }
            
            return try decoder.decode(T.self, from: data)
            
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw NetworkError.invalidData
        } catch let urlError as URLError {
            print("URL error: \(urlError)")
            throw NetworkError.connectionFailed
        } catch {
            print("General error: \(error)")
            throw error
        }
    }
    
    // MARK: - Cache Management
    
    /// Check if cached data is still fresh (less than 5 minutes old)
    private var isCacheFresh: Bool {
        guard let lastFetch = lastFetchTime else { return false }
        return Date().timeIntervalSince(lastFetch) < 300 // 5 minutes
    }
    
    /// Clear cached data
    func clearCache() {
        cachedChannels.removeAll()
        cachedLivePrograms.removeAll()
        lastFetchTime = nil
    }
}

// MARK: - Mock Service Conformance

extension MockDRService: DRServiceProtocol {
    // Already implemented in MockDRService.swift
}

// MARK: - Extended Network Errors

extension NetworkError {
    static let invalidURL = NetworkError.apiError("Invalid URL")
    static let invalidResponse = NetworkError.apiError("Invalid response")
    static let httpError = { (code: Int) in
        NetworkError.apiError("HTTP Error: \(code)")
    }
}

// MARK: - Service Factory

/// Factory for creating the appropriate service based on current phase
class DRServiceFactory {
    enum ServiceType {
        case mock       // Phase 0: Mock data
        case network    // Phase 2: Real API calls
        case auto       // Automatic: Try network, fallback to mock
    }
    
    static func createService(type: ServiceType = .auto) -> DRServiceProtocol {
        switch type {
        case .mock:
            return MockDRService()
        case .network:
            return DRNetworkService()
        case .auto:
            return DRNetworkService() // Will fallback to mock on error
        }
    }
}

// MARK: - Service Manager for App State

/// Central manager for DR radio service and app state
@MainActor
class DRServiceManager: ObservableObject {
    @Published var appState = DRAppState()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // CRITICAL FIX: Move key UI properties to top level for proper SwiftUI observation
    @Published var currentLiveProgram: DRLiveProgram?
    @Published var selectedChannel: DRChannel?
    
    private let service: DRServiceProtocol
    
    init(service: DRServiceProtocol? = nil) {
        self.service = service ?? DRServiceFactory.createService()
        loadChannels()
    }
    
    // MARK: - Public Methods
    
    func loadChannels() {
        appState.availableChannels = service.getChannels()
        if selectedChannel == nil, let firstChannel = appState.availableChannels.first {
            selectedChannel = firstChannel
        }
    }
    
    func refreshNowPlaying() async {
        print("🔄 DRServiceManager: refreshNowPlaying() called")
        print("   - Current selected channel: \(selectedChannel?.slug ?? "nil")")
        
        isLoading = true
        errorMessage = nil
        
        do {
            let livePrograms = try await service.fetchNowPlaying()
            print("   - Fetched \(livePrograms.count) live programs")
            print("   - Fetched channel slugs: \(livePrograms.map { $0.channel.slug })")
            
            // Update app state with fresh data
            appState.allLivePrograms = livePrograms
            
            // Update available channels
            let channels = livePrograms.map { $0.channel }
            let uniqueChannels = Array(Set(channels))
            appState.availableChannels = uniqueChannels
            
            // CRITICAL FIX: Update current live program for selected channel
            if let selectedCh = selectedChannel {
                print("   - Looking for program for selected channel: \(selectedCh.slug)")
                let foundProgram = livePrograms.first { liveProgram in
                    liveProgram.channel.id == selectedCh.id || liveProgram.channel.slug == selectedCh.slug
                }
                
                if let program = foundProgram {
                    print("   - ✅ Found program after refresh: \(program.title) for \(program.channel.slug)")
                    currentLiveProgram = program
                } else {
                    print("   - ❌ Still no program found for \(selectedCh.slug) after refresh")
                    print("   - Available slugs after refresh: \(livePrograms.map { $0.channel.slug })")
                    // Keep currentLiveProgram as nil to show proper "no data" state
                    currentLiveProgram = nil
                }
            } else {
                print("   - No selected channel to update")
            }
            
        } catch {
            print("   - ❌ Error in refreshNowPlaying: \(error)")
            errorMessage = error.localizedDescription
            appState.lastError = error.localizedDescription
            print("Error refreshing now playing: \(error)")
        }
        
        isLoading = false
        print("   - refreshNowPlaying completed, isLoading = false")
        print("   - Final currentLiveProgram: \(currentLiveProgram?.title ?? "nil")")
    }
    
    func selectChannel(_ channel: DRChannel) {
        print("🔄 DRServiceManager: selectChannel(\(channel.title)) slug: \(channel.slug)")
        print("   - Previous selected: \(selectedChannel?.title ?? "nil")")
        print("   - Total cached programs: \(appState.allLivePrograms.count)")
        print("   - Cached channel slugs: \(appState.allLivePrograms.map { $0.channel.slug })")
        
        // CRITICAL FIX: Always update selected channel first
        selectedChannel = channel
        
        // CRITICAL FIX: Clear current program immediately to prevent stale data
        currentLiveProgram = nil
        
        // Try to find the live program for the selected channel
        let foundProgram = appState.allLivePrograms.first { liveProgram in
            liveProgram.channel.id == channel.id || liveProgram.channel.slug == channel.slug
        }
        
        if let program = foundProgram {
            print("   - ✅ Found cached program: \(program.title) for \(program.channel.slug)")
            currentLiveProgram = program
        } else {
            print("   - ❌ No cached program found for \(channel.slug)")
            print("   - Available slugs: \(appState.allLivePrograms.map { $0.channel.slug })")
            
            // CRITICAL FIX: Set loading state and trigger immediate refresh
            isLoading = true
            errorMessage = nil
            
            print("   - 🔄 Setting loading state and triggering immediate refresh")
            Task {
                await refreshNowPlaying()
            }
        }
        
        print("   - Final currentLiveProgram: \(currentLiveProgram?.title ?? "nil")")
    }
    
    func getCurrentProgram() -> DRProgram? {
        guard let liveProgram = currentLiveProgram else { return nil }
        
        return DRProgram(
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
    
    func getNextProgram() -> DRProgram? {
        // Next program would require additional API call - not available in current endpoint
        return nil
    }
    
    func getCurrentTrack() -> DRTrackInfo? {
        // Track info not available in current DR API
        return nil
    }
    
    func getCurrentLiveProgram() -> DRLiveProgram? {
        return currentLiveProgram
    }
    
    func getStreamURL() -> String? {
        return currentLiveProgram?.streamURL
    }
} 
