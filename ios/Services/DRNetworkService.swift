    //
    //  DRNetworkService.swift
    //  ios
    //
    //  Created by Emmanuel on 27/07/2025.
    //

import Foundation

    // MARK: - iOS DR Network Service

class DRNetworkService {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .useDefaultKeys
    }
    
        // MARK: - Fetch All Schedules
    func fetchAllSchedules() async throws -> [DREpisode] {
        let url = URL(string: DRAPIConfig.schedulesAllNow)!
        
        print("🌐 Fetching all schedules from: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw NetworkError.invalidResponse
        }
        
        do {
                // Decode as DRScheduleItem array first
            let scheduleItems = try decoder.decode([DRScheduleItem].self, from: data)
            print("✅ Successfully fetched \(scheduleItems.count) schedule items")
            
                // Convert to DREpisode objects
            let episodes = scheduleItems.map { $0.toEpisode() }
            print("✅ Converted to \(episodes.count) episodes")
            
            return episodes
        } catch {
            print("❌ Decoding error: \(error)")
            
                // Print the actual JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response (first 1000 chars):")
                print(String(jsonString.prefix(1000)))
            }
            
            throw NetworkError.decodingError
        }
    }
    
        // MARK: - Fetch Schedule Snapshot for Channel
    func fetchScheduleSnapshot(for channelSlug: String) async throws -> DRScheduleResponse {
        let url = URL(string: "\(DRAPIConfig.scheduleSnapshot)/\(channelSlug)")!
        
        print("🌐 Fetching schedule snapshot for \(channelSlug) from: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw NetworkError.invalidResponse
        }
        
            // Print the actual JSON response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Raw JSON response (first 2000 chars):")
            print(String(jsonString.prefix(2000)))
        }
        
        do {
            let schedule = try decoder.decode(DRScheduleResponse.self, from: data)
            print("✅ Successfully fetched schedule for \(channelSlug) with \(schedule.items.count) items")
            
                // Debug: Print details about the first item if available
            if let firstItem = schedule.items.first {
                print("📋 First item details:")
                print("   - Title: \(firstItem.title)")
                print("   - Type: \(firstItem.type)")
                print("   - Is Live: \(firstItem.isLive)")
                print("   - Audio assets count: \(firstItem.audioAssets?.count ?? 0)")
                print("   - Image assets count: \(firstItem.imageAssets?.count ?? 0)")
                print("   - Stream URL: \(firstItem.streamURL ?? "None")")
                
                    // Debug audio assets
                if let audioAssets = firstItem.audioAssets {
                    print("   - Audio assets details:")
                    for (index, asset) in audioAssets.enumerated() {
                        print("     \(index + 1). Type: \(asset.type), Target: \(asset.target), IsLive: \(asset.isStreamLive ?? false), URL: \(asset.url)")
                    }
                }
            }
            
            return schedule
        } catch {
            print("❌ Decoding error: \(error)")
            
                // Print detailed decoding error information
            if let decodingError = error as? DecodingError {
                switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ Missing key: \(key.stringValue) at path: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("❌ Type mismatch: expected \(type) at path: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("❌ Value not found: expected \(type) at path: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("❌ Data corrupted at path: \(context.codingPath)")
                    @unknown default:
                        print("❌ Unknown decoding error")
                }
            }
            
            throw NetworkError.decodingError
        }
    }
    
        // MARK: - Fetch Index Points (Currently Playing Tracks)
    func fetchIndexPoints(for channelSlug: String) async throws -> DRIndexPointsResponse {
        let url = URL(string: "\(DRAPIConfig.indexpointsLive)/\(channelSlug)")!
        
        print("🌐 Fetching index points for \(channelSlug) from: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw NetworkError.invalidResponse
        }
        
        do {
            let indexPoints = try decoder.decode(DRIndexPointsResponse.self, from: data)
            print("✅ Successfully fetched index points for \(channelSlug) with \(indexPoints.items.count) tracks")
            return indexPoints
        } catch {
            print("❌ Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
    
        // MARK: - Fetch Image Data
    func fetchImageData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        print("🌐 Fetching image from: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        print("✅ Successfully fetched image data (\(data.count) bytes)")
        return data
    }
}

    // MARK: - Network Error

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case invalidData
    case decodingError
    case invalidURL
    case noInternetConnection
    case serverError
    
    var errorDescription: String? {
        switch self {
            case .invalidResponse:
                return "Invalid response from server"
            case .invalidData:
                return "Invalid data received"
            case .decodingError:
                return "Failed to decode response"
            case .invalidURL:
                return "Invalid URL"
            case .noInternetConnection:
                return "No internet connection"
            case .serverError:
                return "Server error"
        }
    }
} 
