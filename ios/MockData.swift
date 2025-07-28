//
//  MockData.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import Foundation

// MARK: - Mock Data for DR API

struct MockData {
    
    // MARK: - Sample Channels
    static let sampleChannels: [DRChannel] = [
        DRChannel(
            id: "p1",
            title: "DR P1",
            slug: "p1",
            type: "Channel",
            presentationUrl: "https://www.dr.dk/radio/p1"
        ),
        DRChannel(
            id: "p2",
            title: "DR P2",
            slug: "p2",
            type: "Channel",
            presentationUrl: "https://www.dr.dk/radio/p2"
        ),
        DRChannel(
            id: "p3",
            title: "DR P3",
            slug: "p3",
            type: "Channel",
            presentationUrl: "https://www.dr.dk/radio/p3"
        ),
        DRChannel(
            id: "p4",
            title: "DR P4",
            slug: "p4",
            type: "Channel",
            presentationUrl: "https://www.dr.dk/radio/p4"
        ),
        DRChannel(
            id: "p5",
            title: "DR P5",
            slug: "p5",
            type: "Channel",
            presentationUrl: "https://www.dr.dk/radio/p5"
        ),
        DRChannel(
            id: "p6",
            title: "DR P6",
            slug: "p6",
            type: "Channel",
            presentationUrl: "https://www.dr.dk/radio/p6"
        ),
        DRChannel(
            id: "p7",
            title: "DR P7",
            slug: "p7",
            type: "Channel",
            presentationUrl: "https://www.dr.dk/radio/p7"
        ),
        DRChannel(
            id: "p8",
            title: "DR P8",
            slug: "p8",
            type: "Channel",
            presentationUrl: "https://www.dr.dk/radio/p8"
        )
    ]
    
    // MARK: - Sample Series
    static let sampleSeries: [DRSeries] = [
        DRSeries(
            id: "series-1",
            title: "Morgenhår på P1",
            slug: "morgenhar-p1",
            type: "Series",
            isAvailableOnDemand: true,
            presentationUrl: "https://www.dr.dk/radio/p1/morgenhar",
            learnId: "learn-1"
        ),
        DRSeries(
            id: "series-2",
            title: "Jazz på P2",
            slug: "jazz-p2",
            type: "Series",
            isAvailableOnDemand: true,
            presentationUrl: "https://www.dr.dk/radio/p2/jazz",
            learnId: "learn-2"
        ),
        DRSeries(
            id: "series-3",
            title: "Pop på P3",
            slug: "pop-p3",
            type: "Series",
            isAvailableOnDemand: true,
            presentationUrl: "https://www.dr.dk/radio/p3/pop",
            learnId: "learn-3"
        ),
        DRSeries(
            id: "series-4",
            title: "Klassisk på P2",
            slug: "klassisk-p2",
            type: "Series",
            isAvailableOnDemand: true,
            presentationUrl: "https://www.dr.dk/radio/p2/klassisk",
            learnId: "learn-4"
        ),
        DRSeries(
            id: "series-5",
            title: "Rock på P6",
            slug: "rock-p6",
            type: "Series",
            isAvailableOnDemand: true,
            presentationUrl: "https://www.dr.dk/radio/p6/rock",
            learnId: "learn-5"
        )
    ]
    
    // MARK: - Sample Audio Assets
    static let sampleAudioAssets: [DRAudioAsset] = [
        DRAudioAsset(
            type: "LiveStream",
            target: "p1",
            isStreamLive: true,
            format: "MP3",
            bitrate: 128,
            url: "https://live-icy.gss.dr.dk/A/A05H.mp3"
        ),
        DRAudioAsset(
            type: "LiveStream",
            target: "p2",
            isStreamLive: true,
            format: "MP3",
            bitrate: 128,
            url: "https://live-icy.gss.dr.dk/A/A05J.mp3"
        ),
        DRAudioAsset(
            type: "LiveStream",
            target: "p3",
            isStreamLive: true,
            format: "MP3",
            bitrate: 128,
            url: "https://live-icy.gss.dr.dk/A/A05K.mp3"
        ),
        DRAudioAsset(
            type: "LiveStream",
            target: "p4",
            isStreamLive: true,
            format: "MP3",
            bitrate: 128,
            url: "https://live-icy.gss.dr.dk/A/A05L.mp3"
        ),
        DRAudioAsset(
            type: "LiveStream",
            target: "p5",
            isStreamLive: true,
            format: "MP3",
            bitrate: 128,
            url: "https://live-icy.gss.dr.dk/A/A05M.mp3"
        )
    ]
    
    // MARK: - Sample Image Assets
    static let sampleImageAssets: [DRImageAsset] = [
        DRImageAsset(
            id: "urn:dr:radio:image:67e5144d8b2e4877edc3324f",
            target: "Default",
            ratio: "16:9",
            format: "JPEG",
            blurHash: "L6PZ0Si_.AyE_3t7t7R**0o#DgR4"
        ),
        DRImageAsset(
            id: "urn:dr:radio:image:67e5144d8b2e4877edc3324h",
            target: "SquareImage",
            ratio: "1:1",
            format: "JPEG",
            blurHash: "L6PZ0Si_.AyE_3t7t7R**0o#DgR4"
        ),
        DRImageAsset(
            id: "urn:dr:radio:image:67e5144d8b2e4877edc3324j",
            target: "Default",
            ratio: "16:9",
            format: "JPEG",
            blurHash: "L6PZ0Si_.AyE_3t7t7R**0o#DgR4"
        ),
        DRImageAsset(
            id: "urn:dr:radio:image:67e5144d8b2e4877edc3324l",
            target: "SquareImage",
            ratio: "1:1",
            format: "JPEG",
            blurHash: "L6PZ0Si_.AyE_3t7t7R**0o#DgR4"
        ),
        DRImageAsset(
            id: "urn:dr:radio:image:67e5144d8b2e4877edc3324n",
            target: "Default",
            ratio: "16:9",
            format: "JPEG",
            blurHash: "L6PZ0Si_.AyE_3t7t7R**0o#DgR4"
        )
    ]
    
    // MARK: - Sample Tracks
    static let sampleTracks: [DRTrack] = [
        DRTrack(
            type: "Track",
            durationMilliseconds: 180000,
            playedTime: "2024-01-15T10:30:00Z",
            musicUrl: "https://music.dr.dk/track1",
            trackUrn: "urn:dr:radio:track:67e5144d8b2e4877edc3324f",
            classical: false,
            roles: [
                DRRole(
                    artistUrn: "urn:dr:radio:artist:67e5144d8b2e4877edc3324g",
                    role: "Hovedkunstner",
                    name: "DR News Team",
                    musicUrl: "https://music.dr.dk/artist1"
                )
            ],
            title: "Morning News",
            description: "Dagens aktuelle nyheder"
        ),
        DRTrack(
            type: "Track",
            durationMilliseconds: 120000,
            playedTime: "2024-01-15T10:27:00Z",
            musicUrl: "https://music.dr.dk/track2",
            trackUrn: "urn:dr:radio:track:67e5144d8b2e4877edc3324h",
            classical: false,
            roles: [
                DRRole(
                    artistUrn: "urn:dr:radio:artist:67e5144d8b2e4877edc3324i",
                    role: "Hovedkunstner",
                    name: "DR Weather",
                    musicUrl: "https://music.dr.dk/artist2"
                )
            ],
            title: "Weather Report",
            description: "Dagens vejrudsigt"
        ),
        DRTrack(
            type: "Track",
            durationMilliseconds: 240000,
            playedTime: "2024-01-15T10:20:00Z",
            musicUrl: "https://music.dr.dk/track3",
            trackUrn: "urn:dr:radio:track:67e5144d8b2e4877edc3324j",
            classical: false,
            roles: [
                DRRole(
                    artistUrn: "urn:dr:radio:artist:67e5144d8b2e4877edc3324k",
                    role: "Hovedkunstner",
                    name: "Miles Davis",
                    musicUrl: "https://music.dr.dk/artist3"
                )
            ],
            title: "Jazz Improvisation",
            description: "Jazz fra Kind of Blue"
        ),
        DRTrack(
            type: "Track",
            durationMilliseconds: 195000,
            playedTime: "2024-01-15T10:15:00Z",
            musicUrl: "https://music.dr.dk/track4",
            trackUrn: "urn:dr:radio:track:67e5144d8b2e4877edc3324l",
            classical: false,
            roles: [
                DRRole(
                    artistUrn: "urn:dr:radio:artist:67e5144d8b2e4877edc3324m",
                    role: "Hovedkunstner",
                    name: "Dave Brubeck",
                    musicUrl: "https://music.dr.dk/artist4"
                )
            ],
            title: "Take Five",
            description: "Jazz klassiker"
        ),
        DRTrack(
            type: "Track",
            durationMilliseconds: 210000,
            playedTime: "2024-01-15T10:10:00Z",
            musicUrl: "https://music.dr.dk/track5",
            trackUrn: "urn:dr:radio:track:67e5144d8b2e4877edc3324n",
            classical: false,
            roles: [
                DRRole(
                    artistUrn: "urn:dr:radio:artist:67e5144d8b2e4877edc3324o",
                    role: "Hovedkunstner",
                    name: "Modern Artist",
                    musicUrl: "https://music.dr.dk/artist5"
                )
            ],
            title: "Pop Hit 2024",
            description: "Seneste pop hit"
        )
    ]
    
    // MARK: - Helper Methods
    
    /// Get a random channel from the sample data
    static func randomChannel() -> DRChannel {
        return sampleChannels.randomElement() ?? sampleChannels[0]
    }
    
    /// Get a random track from the sample data
    static func randomTrack() -> DRTrack {
        return sampleTracks.randomElement() ?? sampleTracks[0]
    }
    
    /// Get tracks for a specific channel
    static func tracksForChannel(_ channelId: String) -> [DRTrack] {
        return sampleTracks // Mock implementation - return all tracks
    }
    
    /// Get the current track for a channel
    static func currentTrackForChannel(_ channelId: String) -> DRTrack? {
        return sampleTracks.first { $0.isCurrentlyPlaying }
    }
    
    /// Get a mock episode for a channel
    static func mockEpisodeForChannel(_ channelId: String) -> DREpisode? {
        guard let channel = sampleChannels.first(where: { $0.id == channelId }),
              let series = sampleSeries.first else {
            return nil
        }
        
        return DREpisode(
            type: "Live",
            learnId: "learn-\(channelId)",
            durationMilliseconds: 3600000, // 1 hour
            categories: ["News", "Music"],
            productionNumber: "prod-\(channelId)",
            startTime: "2024-01-15T10:00:00Z",
            endTime: "2024-01-15T11:00:00Z",
            presentationUrl: channel.presentationUrl,
            order: 1,
            previousId: nil,
            nextId: nil,
            series: series,
            channel: channel,
            audioAssets: sampleAudioAssets.filter { $0.target == channelId },
            isAvailableOnDemand: true,
            hasVideo: false,
            explicitContent: false,
            id: "episode-\(channelId)",
            slug: "episode-\(channelId)",
            title: "Live på \(channel.title)",
            description: "Live program på \(channel.title)",
            imageAssets: sampleImageAssets,
            episodeNumber: 1,
            seasonNumber: 1
        )
    }
}

// MARK: - Mock Network Responses

extension MockData {
    
    /// Mock response for channels list
    static let mockChannelsResponse: [DRChannel] = sampleChannels
    
    /// Mock response for tracks for a channel
    static func mockTracksResponse(for channelId: String) -> [DRTrack] {
        return tracksForChannel(channelId)
    }
    
    /// Mock response for current track for a channel
    static func mockCurrentTrackResponse(for channelId: String) -> DRTrack? {
        return currentTrackForChannel(channelId)
    }
    
    /// Mock response for episode for a channel
    static func mockEpisodeResponse(for channelId: String) -> DREpisode? {
        return mockEpisodeForChannel(channelId)
    }
} 