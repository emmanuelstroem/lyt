//
//  lytTests.swift
//  lytTests
//
//  Created by Emmanuel on 24/07/2025.
//

import XCTest
@testable import lyt

final class lytTests: XCTestCase {

    // MARK: - Test Setup

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Data Model Tests

    func testDRChannelModel() throws {
        // Test DRChannel model creation and properties
        let channel = DRChannel(
            id: "p1",
            name: "P1",
            displayName: "DR P1",
            description: "Test description",
            imageURL: "https://example.com/image.png",
            streamURL: "https://example.com/stream.m3u8",
            color: "E60026",
            category: "News"
        )
        
        XCTAssertEqual(channel.id, "p1")
        XCTAssertEqual(channel.name, "P1")
        XCTAssertEqual(channel.displayName, "DR P1")
        XCTAssertEqual(channel.color, "E60026")
        XCTAssertEqual(channel.category, "News")
        
        // Test SwiftUI color conversion
        XCTAssertNotNil(channel.swiftUIColor)
    }

    func testDRProgramModel() throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600) // 1 hour later
        
        let program = DRProgram(
            id: "test_program",
            title: "Test Program",
            description: "A test program",
            hosts: ["Host One", "Host Two"],
            imageURL: "https://example.com/program.png",
            startTime: startTime,
            endTime: endTime,
            channelId: "p1",
            category: "News",
            isLive: true
        )
        
        XCTAssertEqual(program.id, "test_program")
        XCTAssertEqual(program.title, "Test Program")
        XCTAssertEqual(program.hosts.count, 2)
        XCTAssertEqual(program.channelId, "p1")
        XCTAssertTrue(program.isLive)
        
        // Test duration calculation
        XCTAssertEqual(program.duration, 3600)
        XCTAssertEqual(program.formattedDuration, "1h 0m")
    }

    func testFormattedDuration() throws {
        let startTime = Date()
        
        // Test 30 minutes
        let program30min = DRProgram(
            id: "test",
            title: "Test",
            description: nil,
            hosts: [],
            imageURL: nil,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(1800), // 30 minutes
            channelId: "p1",
            category: "Test",
            isLive: false
        )
        XCTAssertEqual(program30min.formattedDuration, "30m")
        
        // Test 1 hour 30 minutes
        let program90min = DRProgram(
            id: "test",
            title: "Test",
            description: nil,
            hosts: [],
            imageURL: nil,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(5400), // 90 minutes
            channelId: "p1",
            category: "Test",
            isLive: false
        )
        XCTAssertEqual(program90min.formattedDuration, "1h 30m")
    }

    func testDRTrackInfo() throws {
        let track = DRTrackInfo(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            albumArt: "https://example.com/art.jpg",
            startTime: Date()
        )
        
        XCTAssertEqual(track.title, "Test Song")
        XCTAssertEqual(track.artist, "Test Artist")
        XCTAssertEqual(track.album, "Test Album")
        XCTAssertNotNil(track.startTime)
    }

    // MARK: - Mock Service Tests

    func testMockChannelsData() throws {
        let channels = MockDRService.mockChannels
        
        // Verify we have the expected number of channels
        XCTAssertGreaterThan(channels.count, 0)
        
        // Check that essential channels exist
        let channelIds = channels.map { $0.id }
        XCTAssertTrue(channelIds.contains("p1"))
        XCTAssertTrue(channelIds.contains("p3"))
        
        // Validate each channel has required properties
        for channel in channels {
            XCTAssertFalse(channel.id.isEmpty)
            XCTAssertFalse(channel.name.isEmpty)
            XCTAssertFalse(channel.displayName.isEmpty)
            XCTAssertFalse(channel.streamURL.isEmpty)
            XCTAssertFalse(channel.color.isEmpty)
            XCTAssertFalse(channel.category.isEmpty)
        }
    }

    func testMockProgramsGeneration() throws {
        let p1Programs = MockDRService.mockPrograms(for: "p1")
        let p3Programs = MockDRService.mockPrograms(for: "p3")
        
        XCTAssertGreaterThan(p1Programs.count, 0)
        XCTAssertGreaterThan(p3Programs.count, 0)
        
        // Check that programs are properly associated with their channels
        for program in p1Programs {
            XCTAssertEqual(program.channelId, "p1")
        }
        
        for program in p3Programs {
            XCTAssertEqual(program.channelId, "p3")
        }
    }

    func testMockTrackInfo() throws {
        let p3Track = MockDRService.mockTrackInfo(for: "p3")
        let p6Track = MockDRService.mockTrackInfo(for: "p6")
        let p8Track = MockDRService.mockTrackInfo(for: "p8")
        
        // P3 should have track info (music channel)
        XCTAssertNotNil(p3Track)
        XCTAssertNotNil(p3Track?.title)
        XCTAssertNotNil(p3Track?.artist)
        
        // P6 should have track info (rock channel)
        XCTAssertNotNil(p6Track)
        XCTAssertNotNil(p6Track?.title)
        XCTAssertNotNil(p6Track?.artist)
        
        // P8 should have track info (jazz channel)
        XCTAssertNotNil(p8Track)
        XCTAssertNotNil(p8Track?.title)
        XCTAssertNotNil(p8Track?.artist)
        
        // P1 (news channel) should not have track info
        let p1Track = MockDRService.mockTrackInfo(for: "p1")
        XCTAssertNil(p1Track)
    }

    func testMockDataValidation() throws {
        let validationErrors = MockDRService.validateMockData()
        
        // There should be no validation errors in our mock data
        XCTAssertTrue(validationErrors.isEmpty, "Validation errors found: \(validationErrors)")
    }

    // MARK: - Async Service Tests

    func testMockServiceFetchNowPlaying() async throws {
        let service = MockDRService()
        
        let response = try await service.fetchNowPlaying()
        
        XCTAssertTrue(response.success)
        XCTAssertGreaterThan(response.channels.count, 0)
        
        // Check that each channel in the response has proper data
        for nowPlaying in response.channels {
            XCTAssertFalse(nowPlaying.channel.id.isEmpty)
            // Note: currentProgram might be nil depending on timing
            XCTAssertNotNil(nowPlaying.lastUpdated)
        }
    }

    func testMockServiceFetchSchedule() async throws {
        let service = MockDRService()
        
        let scheduleResponse = try await service.fetchSchedule(for: "p1")
        
        XCTAssertEqual(scheduleResponse.channelId, "p1")
        XCTAssertFalse(scheduleResponse.date.isEmpty)
        XCTAssertGreaterThan(scheduleResponse.programs.count, 0)
        
        // Verify all programs belong to the requested channel
        for program in scheduleResponse.programs {
            XCTAssertEqual(program.channelId, "p1")
        }
    }

    func testMockServiceGetChannels() throws {
        let service = MockDRService()
        let channels = service.getChannels()
        
        XCTAssertEqual(channels.count, MockDRService.mockChannels.count)
        XCTAssertEqual(channels.first?.id, MockDRService.mockChannels.first?.id)
    }

    func testMockServiceGetChannel() throws {
        let service = MockDRService()
        
        let p1Channel = service.getChannel(id: "p1")
        XCTAssertNotNil(p1Channel)
        XCTAssertEqual(p1Channel?.id, "p1")
        
        let nonExistentChannel = service.getChannel(id: "non_existent")
        XCTAssertNil(nonExistentChannel)
    }

    // MARK: - JSON Codable Tests

    func testChannelJSONCoding() throws {
        let originalChannel = DRChannel(
            id: "test",
            name: "Test",
            displayName: "Test Channel",
            description: "A test channel",
            imageURL: "https://example.com/image.png",
            streamURL: "https://example.com/stream.m3u8",
            color: "FF0000",
            category: "Test"
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalChannel)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedChannel = try decoder.decode(DRChannel.self, from: jsonData)
        
        // Verify the decoded channel matches the original
        XCTAssertEqual(originalChannel.id, decodedChannel.id)
        XCTAssertEqual(originalChannel.name, decodedChannel.name)
        XCTAssertEqual(originalChannel.displayName, decodedChannel.displayName)
        XCTAssertEqual(originalChannel.color, decodedChannel.color)
    }

    func testProgramJSONCoding() throws {
        let program = DRProgram(
            id: "test_program",
            title: "Test Program",
            description: "A test program",
            hosts: ["Host 1", "Host 2"],
            imageURL: "https://example.com/image.png",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            channelId: "test",
            category: "Test",
            isLive: true
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(program)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedProgram = try decoder.decode(DRProgram.self, from: jsonData)
        
        XCTAssertEqual(program.id, decodedProgram.id)
        XCTAssertEqual(program.title, decodedProgram.title)
        XCTAssertEqual(program.hosts, decodedProgram.hosts)
        XCTAssertEqual(program.isLive, decodedProgram.isLive)
    }

    // MARK: - Color Extension Tests

    func testColorFromHex() throws {
        // Test valid hex colors
        let redColor = Color(hex: "FF0000")
        XCTAssertNotNil(redColor)
        
        let blueColor = Color(hex: "0000FF")
        XCTAssertNotNil(blueColor)
        
        let shortRedColor = Color(hex: "F00")
        XCTAssertNotNil(shortRedColor)
        
        // Test invalid hex colors
        let invalidColor = Color(hex: "GGGGGG")
        XCTAssertNil(invalidColor)
        
        let tooShortColor = Color(hex: "FF")
        XCTAssertNil(tooShortColor)
    }

    // MARK: - Date Extension Tests

    func testDateFormatting() throws {
        let date = Date()
        
        let timeString = date.timeString
        XCTAssertFalse(timeString.isEmpty)
        
        let dateTimeString = date.dateTimeString
        XCTAssertFalse(dateTimeString.isEmpty)
        XCTAssertTrue(dateTimeString.contains(timeString))
    }

    // MARK: - Performance Tests

    func testMockServicePerformance() throws {
        let service = MockDRService()
        
        measure {
            // Test the performance of generating mock data
            for _ in 0..<100 {
                _ = service.getChannels()
                _ = MockDRService.mockPrograms(for: "p1")
                _ = MockDRService.mockTrackInfo(for: "p3")
            }
        }
    }

    func testAsyncServicePerformance() async throws {
        let service = MockDRService()
        
        // Test async operations performance
        let startTime = Date()
        
        for _ in 0..<5 {
            _ = try await service.fetchNowPlaying()
        }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        
        // Should complete reasonably quickly (less than 5 seconds for 5 calls)
        XCTAssertLessThan(totalTime, 5.0)
    }
}
