import Foundation
import SwiftUI
import Combine

// MARK: - Radio Station Provider Models

/// Represents a radio station provider (e.g., DR, potentially others in the future)
struct RadioStationProvider: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let color: String
    let logoSystemName: String
    let channelGroups: [ChannelGroup]
    
    var swiftUIColor: Color {
        Color(hex: color) ?? .accentColor
    }
}

// MARK: - Channel Group Models

/// Represents a group of channels (e.g., P4 with different regions)
struct ChannelGroup: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let color: String
    let isRegional: Bool
    let channels: [DRChannel]
    
    var swiftUIColor: Color {
        Color(hex: color) ?? .accentColor
    }
    
    var displayChannels: [DRChannel] {
        channels.sorted { $0.title < $1.title }
    }
}

/// Represents a region for regional channels
struct ChannelRegion: Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let channel: DRChannel
}

// MARK: - Channel Organization Service

class ChannelOrganizer {
    
    static func organizeChannels(_ channels: [DRChannel]) -> [ChannelGroup] {
        print("🏗️ ChannelOrganizer: organizeChannels() called")
        print("   - Input channels: \(channels.map { $0.slug })")
        
        var groups: [ChannelGroup] = []
        var processedChannels = Set<String>()
        
        // Group P4 regional channels
        let p4Channels = channels.filter { $0.slug.hasPrefix("p4") }
        if !p4Channels.isEmpty {
            print("   - Found P4 channels: \(p4Channels.map { $0.slug })")
            groups.append(ChannelGroup(
                id: "p4",
                name: "P4",
                description: "Regional radio with local content",
                color: "0066CC",
                isRegional: true,
                channels: p4Channels
            ))
            p4Channels.forEach { processedChannels.insert($0.id) }
        }
        
        // Group P5 regional channels (NEWLY DISCOVERED FROM REAL API!)
        let p5Channels = channels.filter { $0.slug.hasPrefix("p5") }
        if !p5Channels.isEmpty {
            print("   - Found P5 channels: \(p5Channels.map { $0.slug })")
            groups.append(ChannelGroup(
                id: "p5",
                name: "P5",
                description: "Classical music with regional content",
                color: "663399",
                isRegional: true,
                channels: p5Channels
            ))
            p5Channels.forEach { processedChannels.insert($0.id) }
        }
        
        // Add single channels (non-regional: everything except P4 and P5)
        let singleChannels = channels.filter { channel in
            !processedChannels.contains(channel.id) && 
            !channel.slug.hasPrefix("p4") && 
            !channel.slug.hasPrefix("p5")
        }
        
        print("   - Single channels to process: \(singleChannels.map { $0.slug })")
        
        for channel in singleChannels.sorted(by: { $0.slug < $1.slug }) {
            let group = ChannelGroup(
                id: channel.slug,
                name: getChannelGroupName(for: channel.slug),
                description: getChannelDescription(for: channel.slug),
                color: channel.color,
                isRegional: false,
                channels: [channel]
            )
            print("   - Creating single group: \(group.name) (isRegional: \(group.isRegional))")
            groups.append(group)
        }
        
        let finalGroups = groups.sorted { $0.name < $1.name }
        print("   - Final groups: \(finalGroups.map { "\($0.name) (regional: \($0.isRegional))" })")
        return finalGroups
    }
    
    static func organizeProviders(_ channels: [DRChannel]) -> [RadioStationProvider] {
        print("🏢 ChannelOrganizer: organizeProviders() called")
        print("   - Input channels: \(channels.map { $0.slug })")
        
        // For now, all channels belong to DR (Danmarks Radio)
        // In the future, we can add other providers here
        let drChannelGroups = organizeChannels(channels)
        
        let drProvider = RadioStationProvider(
            id: "dr",
            name: "DR",
            description: "Danmarks Radio - Public service broadcasting",
            color: "E60026", // DR Red
            logoSystemName: "antenna.radiowaves.left.and.right",
            channelGroups: drChannelGroups
        )
        
        print("   - Created DR provider with \(drChannelGroups.count) channel groups")
        return [drProvider]
    }
    
    static func getRegionsForP4(_ channels: [DRChannel]) -> [ChannelRegion] {
        return channels
            .filter { $0.slug.hasPrefix("p4") }
            .compactMap { channel in
                guard let regionName = extractP4Region(from: channel.slug) else { return nil }
                return ChannelRegion(
                    id: channel.slug,
                    name: regionName,
                    displayName: getP4RegionDisplayName(regionName),
                    channel: channel
                )
            }
            .sorted { $0.displayName < $1.displayName }
    }
    
    static func getRegionsForGroup(_ channels: [DRChannel], groupPrefix: String) -> [ChannelRegion] {
        return channels
            .filter { $0.slug.hasPrefix(groupPrefix) }
            .compactMap { channel in
                guard let regionName = extractRegion(from: channel.slug, prefix: groupPrefix) else { return nil }
                return ChannelRegion(
                    id: channel.slug,
                    name: regionName,
                    displayName: getRegionDisplayName(regionName),
                    channel: channel
                )
            }
            .sorted { $0.displayName < $1.displayName }
    }
    
    private static func extractP4Region(from slug: String) -> String? {
        guard slug.hasPrefix("p4") else { return nil }
        let region = String(slug.dropFirst(2)) // Remove "p4" prefix
        return region.isEmpty ? nil : region
    }
    
    private static func extractRegion(from slug: String, prefix: String) -> String? {
        guard slug.hasPrefix(prefix) else { return nil }
        let region = String(slug.dropFirst(prefix.count)) // Remove prefix
        return region.isEmpty ? nil : region
    }
    
    private static func getP4RegionDisplayName(_ region: String) -> String {
        return getRegionDisplayName(region)
    }
    
    private static func getRegionDisplayName(_ region: String) -> String {
        switch region {
        case "kbh": return "København"
        case "syd": return "Syd"
        case "nord": return "Nord"
        case "midt": return "Midt"
        case "vest": return "Vest"
        case "bornholm": return "Bornholm"
        case "esbjerg": return "Esbjerg"
        case "fyn": return "Fyn"
        case "oestjylland", "østjylland": return "Østjylland"
        case "sjaelland": return "Sjælland"
        case "trekanten": return "Trekanten"
        case "aarhus": return "Aarhus"
        default: return region.capitalized
        }
    }
    
    private static func getChannelGroupName(for slug: String) -> String {
        switch slug {
        case "p1": return "P1"
        case "p2": return "P2"
        case "p3": return "P3"
        case "p5": return "P5"
        case "p6beat": return "P6 Beat"
        case "p7": return "P7"
        case "p8jazz": return "P8 Jazz"
        default: return slug.uppercased()
        }
    }
    
    private static func getChannelDescription(for slug: String) -> String {
        switch slug {
        case "p1": return "News and current affairs"
        case "p2": return "Classical music and culture"
        case "p3": return "Pop music for young adults"
        case "p5": return "Classical music"
        case "p6beat": return "Rock and alternative music"
        case "p7": return "Adult contemporary and mix"
        case "p8jazz": return "Jazz music 24/7"
        default: return "Radio channel"
        }
    }
}

// MARK: - Navigation State

enum NavigationLevel {
    case channelGroups
    case regions(ChannelGroup)
    case playing(DRChannel)
}

class ChannelNavigationState: ObservableObject {
    @Published var currentLevel: NavigationLevel = .channelGroups
    @Published var selectedGroup: ChannelGroup?
    @Published var selectedChannel: DRChannel?
    
    func selectGroup(_ group: ChannelGroup) {
        print("🧭 NavigationState: selectGroup(\(group.name))")
        print("   - Group isRegional: \(group.isRegional)")
        print("   - Previous selectedGroup: \(selectedGroup?.name ?? "nil")")
        print("   - Previous currentLevel: \(currentLevel)")
        
        // SAFEGUARD: Clear previous state when selecting a new group
        selectedChannel = nil
        
        selectedGroup = group
        if group.isRegional {
            currentLevel = .regions(group)
            print("   - New currentLevel: .regions(\(group.name))")
        } else {
            // Single channel group - select directly
            print("   - Single channel group detected")
            if let channel = group.channels.first {
                print("   - Single channel group, selecting channel: \(channel.title)")
                selectChannel(channel)
            } else {
                print("   - ERROR: Single channel group has no channels!")
                // Fallback: stay at channel groups level
                currentLevel = .channelGroups
                selectedGroup = nil
            }
        }
        
        print("   - FINAL STATE AFTER selectGroup:")
        print("     - Level: \(currentLevel)")
        print("     - Group: \(selectedGroup?.name ?? "nil")")
        print("     - Channel: \(selectedChannel?.title ?? "nil")")
    }
    
    func selectChannel(_ channel: DRChannel) {
        print("🧭 NavigationState: selectChannel(\(channel.title))")
        print("   - Previous currentLevel: \(currentLevel)")
        print("   - Current selectedGroup: \(selectedGroup?.name ?? "nil")")
        
        selectedChannel = channel
        currentLevel = .playing(channel)
        
        print("   - New currentLevel: .playing(\(channel.title))")
    }
    
    func navigateBack() {
        print("🧭 NavigationState: navigateBack()")
        print("   - Current level: \(currentLevel)")
        print("   - Selected group: \(selectedGroup?.name ?? "nil") (isRegional: \(selectedGroup?.isRegional ?? false))")
        print("   - Selected channel: \(selectedChannel?.title ?? "nil")")
        
        switch currentLevel {
        case .channelGroups:
            print("   - Already at root channel groups, no action")
            break // Already at root
        case .regions(_):
            print("   - From regions -> channelGroups")
            currentLevel = .channelGroups
            selectedGroup = nil
        case .playing(_):
            // BUG FIX: Check if we came from a regional view or directly from channel groups
            if let group = selectedGroup, group.isRegional {
                print("   - From playing (regional) -> regions(\(group.name))")
                currentLevel = .regions(group)
            } else {
                print("   - From playing (single channel) -> channelGroups")
                currentLevel = .channelGroups
                selectedGroup = nil // CRITICAL: Clear the selected group
            }
            selectedChannel = nil
        }
        
        print("   - Final level: \(currentLevel)")
        print("   - Final selectedGroup: \(selectedGroup?.name ?? "nil")")
        
        // ADDITIONAL FIX: Ensure we're always in a valid state
        switch currentLevel {
        case .channelGroups:
            // When at channel groups, there should be no selected group or channel
            if selectedGroup != nil {
                print("   - WARNING: selectedGroup not nil at channelGroups level, clearing it")
                selectedGroup = nil
            }
            if selectedChannel != nil {
                print("   - WARNING: selectedChannel not nil at channelGroups level, clearing it")
                selectedChannel = nil
            }
        case .regions(let group):
            // When at regions, selectedGroup should match the group, no selected channel
            if selectedGroup?.id != group.id {
                print("   - WARNING: selectedGroup mismatch at regions level, fixing it")
                selectedGroup = group
            }
            if selectedChannel != nil {
                print("   - WARNING: selectedChannel not nil at regions level, clearing it")
                selectedChannel = nil
            }
        case .playing(let channel):
            // When playing, selectedChannel should be set
            if selectedChannel?.id != channel.id {
                print("   - WARNING: selectedChannel mismatch at playing level, fixing it")
                selectedChannel = channel
            }
        }
        
        print("   - FINAL STATE AFTER VALIDATION:")
        print("     - Level: \(currentLevel)")
        print("     - Group: \(selectedGroup?.name ?? "nil")")
        print("     - Channel: \(selectedChannel?.title ?? "nil")")
    }
    
    func reset() {
        print("🧭 NavigationState: reset()")
        currentLevel = .channelGroups
        selectedGroup = nil
        selectedChannel = nil
    }
}

// MARK: - Layout Helpers

struct ChannelLayoutHelper {
    
    static func shouldUseCompactLayout(for screenSize: CGSize) -> Bool {
        // Use compact layout for iPhone-sized screens
        return screenSize.width < 600 || screenSize.height < 800
    }
    
    static func gridColumns(for screenSize: CGSize, isRegionalView: Bool = false) -> [GridItem] {
        let minItemWidth: CGFloat = isRegionalView ? 200 : 280
        let spacing: CGFloat = 20
        let horizontalPadding: CGFloat = 40
        
        let availableWidth = screenSize.width - horizontalPadding
        let columnsCount = max(1, Int(availableWidth / (minItemWidth + spacing)))
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnsCount)
    }
    
    static func cardHeight(for screenSize: CGSize, isRegionalView: Bool = false) -> CGFloat {
        if shouldUseCompactLayout(for: screenSize) {
            return isRegionalView ? 100 : 140
        } else {
            return isRegionalView ? 120 : 180
        }
    }
    
    static func heroHeight(for screenSize: CGSize) -> CGFloat {
        if shouldUseCompactLayout(for: screenSize) {
            return 200
        } else {
            return min(300, screenSize.height * 0.3)
        }
    }
} 