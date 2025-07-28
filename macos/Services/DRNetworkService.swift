//
//  DRNetworkService.swift
//  macos
//
//  Created by Emmanuel on 27/07/2025.
//

import Foundation

// MARK: - macOS DR Network Service

class DRNetworkService {
    private let session = URLSession.shared
    
    // MARK: - Fetch All Schedules
    func fetchAllSchedules() async throws -> [DREpisode] {
        let url = URL(string: DRAPIConfig.schedulesAllNow)!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let schedules = try JSONDecoder().decode([DREpisode].self, from: data)
        return schedules
    }
    
    // MARK: - Fetch Schedule Snapshot for Channel
    func fetchScheduleSnapshot(for channelSlug: String) async throws -> DRScheduleResponse {
        let url = URL(string: "\(DRAPIConfig.scheduleSnapshot)/\(channelSlug)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let schedule = try JSONDecoder().decode(DRScheduleResponse.self, from: data)
        return schedule
    }
    
    // MARK: - Fetch Index Points (Currently Playing Tracks)
    func fetchIndexPoints(for channelSlug: String) async throws -> DRIndexPointsResponse {
        let url = URL(string: "\(DRAPIConfig.indexpointsLive)/\(channelSlug)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let indexPoints = try JSONDecoder().decode(DRIndexPointsResponse.self, from: data)
        return indexPoints
    }
    
    // MARK: - Fetch Image Data
    func fetchImageData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return data
    }
}

// MARK: - Network Error

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case invalidData
    case decodingError
    case invalidURL
    
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
        }
    }
} 