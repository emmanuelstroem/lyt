# AGENT.md

## App Name
Lyt — A Professional Client for DR (Danmerks Radio) Audio Streams

## Description
This app is a cross-platform (iOS/macOS/iPadOS/tvOS) audio player for listening to live and scheduled programming from Danmarks Radio (DR), using public data from [https://www.dr.dk/lyd](https://www.dr.dk/lyd).

The app uses JSON endpoints found via the DR Lyd website to display current programming (`now`), fetch metadata, and stream audio (typically HLS `.m3u8` streams). Playback is handled via AVFoundation.

This is a multiplatform app. The same code should be compatible with iOS, macOS, tvOS and iPadOS.

I am using Xcode-beta to build the code because my system is running on MacOS Tahoe beta. 

Agent must NOT make changes to `*.xcodeproj` files. Instead, let me know what changes to make. Since these changes easily break the build. 
Agent must NOT make changes to this file. Instead, use the README.md or create an ISSUES.md, etc

Note:

- There are different color specifications for iOS, macOS and tvOS. Here is the comprehensive list: https://mar.codes/apple-colors
---

## Agent Role

The agent may assist with:
- Fetching and parsing DR audio program metadata (live and scheduled)
- Managing media playback via AVPlayer
- Mapping UI elements to DR channels or program data
- Performing periodic updates (e.g., polling for new programs)
- Helping with error handling, fallbacks, and graceful UX
- Ensuring compliance with public data use policies
- Ensure there are no memory issues withe application
- Efficiently handle audio playback, handoff to airplay or bluetooth, and graceful handover to other applications like phone, music, spotify, alarm, etc
- Handle gracefully termination when the application is quite 
- Ability to resume playback when Audio interface is freed up again 
- Optional: Generating audio program summaries or recommendations

---

## Main Endpoints (Discovered)

> ⚠️ Subject to change; verify endpoint structure via network inspector

- `https://api.dr.dk/radio/v4/schedules/all/now`  
  Provides live information about what's currently playing (title, channel, start time, stream URL).
  
- Example stream (P3):  
  `https://live-radio.dr.dk/p3/live.m3u8`

- Program guide (optional):  
  `https://www.dr.dk/api/radio/programs/{channelId}`

- Show metadata (optional):  
  `https://www.dr.dk/api/radio/shows/{showId}`

---

## Playback Constraints

- Use HLS (.m3u8) URLs only with `AVPlayer`
- Do not transcode or redistribute streams
- Use background audio capabilities on mobile platforms
- Display current program metadata accurately and in sync

---

## UI/UX Guidelines

- Show current station (e.g., P1, P3) and program name
- Allow easy channel switching
- Show album cover photos of shows 
- Show host(s) and description of the shows and any time/duration related 
- Optional: Program schedule viewer
- Optional: Favorite or "bookmark" features for programs

---

## Ethical & Legal Considerations

- Respect DR’s terms of use (no caching or redistribution without permission)
- Do not modify or alter content metadata
- Attribution to DR should be present if data is shown directly from DR endpoints

---

## Agent Tools

The agent may have access to:
- `fetchJSON(url)`: Downloads and parses a JSON endpoint
- `parseNowPlaying(json)`: Extracts currently playing title, description, stream URL
- `playStream(url)`: Uses `AVPlayer` to start or stop playback
- `updateUI(nowPlaying)`: Refreshes UI labels and images
- `handleError(error)`: Logs or displays audio/network issues

---

## Environment & Platforms

- **Language**: Swift (using SwiftUI for interface developement)
- **Platforms**: iOS, macOS, iPadOS, tvOS (via SwiftUI universal codebase)
- **Audio**: with background playback where supported

---

## Goals for Agents

- Maintain accurate, real-time playback with minimal latency
- Keep metadata in sync with current stream
- Offer reliable, accessible audio streaming experience
- Handle error states and stream changes gracefully
- Avoid unnecessary battery/network usage
- Do NOT make changes to `*.xcodeproj`

---

## Non-Goals

- No offline downloads or caching
- No editing or remapping of stream content
- No access to private DR APIs or non-public data

---

## Phases

### Phase 0: Prototyping

- Hit the API endpoint and use the response structure in now.json to construct some dummy data for local testing.
- Build the data model for the API and validate that the response fits model structure

### Phase 1: Local Testing
- Assume that the web requests are working
- Build the user interface for loading the data 
- Test validate that the test data can load on it

### Phase 2: URL testing
- Check network connection 
- Ensure that the web requests succeeed
- Fetch the program schedule, build urls and metadata from the API
- Use this data to populate the interface. 

---

## Builds 

- Code MUST build successfully
- Swift compilation MUST also succeed and 
- Executables MUST be created


### iOS ✅ VALIDATED
```bash
# Debug (for development)
xcodebuild -project lyt.xcodeproj -scheme lyt -destination 'platform=iOS Simulator,name=iPhone 16' build

# Release (recommended - cleaner, no debug artifacts)
xcodebuild -project lyt.xcodeproj -scheme lyt -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Release build
```

### macOS ✅ VALIDATED  
```bash
# Debug (may have dyld Team ID issues)
xcodebuild -project lyt.xcodeproj -scheme lyt -destination 'platform=macOS' build CODE_SIGN_IDENTITY="-"

# Release (recommended - avoids Team ID mismatch)
xcodebuild -project lyt.xcodeproj -scheme lyt -destination 'platform=macOS' -configuration Release build CODE_SIGN_IDENTITY="-"
```

### Additional Platforms (Should work but not tested)
For iPadOS and tvOS, use these variations:
```bash
# iPadOS Release
xcodebuild -project lyt.xcodeproj -scheme lyt -destination 'platform=iOS Simulator,name=iPad Air 11-inch (M3)' -configuration Release build

# tvOS Release
xcodebuild -project lyt.xcodeproj -scheme lyt -destination 'platform=tvOS Simulator,name=Apple TV' -configuration Release build
```

**💡 Recommendation**: Use **Release builds** for testing and running the app to avoid code signing and dynamic library issues that occur in Debug builds.

### Troubleshooting: Xcode Launch Error (SOLVED ✅)

**Issue**: `Could not launch "lyt" - bundle doesn't contain an executable` 

**Root Cause**: Swift compilation errors due to macOS/iOS color compatibility issues prevented the executable from being created, even though the build appeared to "succeed."

**Solution**: Use platform-specific colors in SwiftUI:
```swift
// Platform-specific background colors
private var backgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlBackgroundColor)
    #else
    Color(.systemBackground)
    #endif
}
```

**Key Learning**: When the app bundle exists but has no executable, check for Swift compilation errors by looking for actual compile output, not just the final "BUILD SUCCEEDED" message.

---

### Troubleshooting: dyld Team ID Mismatch Error (SOLVED ✅)

**Issue**: `no such file, not in dyld cache` and `mapping process and mapped file (non-platform) have different Team IDs`

**Root Cause**: Debug builds create a `lyt.debug.dylib` with different Team ID than the main executable:
- Main executable: `TeamIdentifier=A9Q5VPE9WX` (Apple Developer signing)  
- Debug dylib: `TeamIdentifier=not set` (adhoc signing)

**Solution**: Build in Release mode to avoid debug dylibs:
```bash
# For macOS (avoids debug dylib entirely)
xcodebuild -project lyt.xcodeproj -scheme lyt -destination 'platform=macOS' -configuration Release build CODE_SIGN_IDENTITY="-"
```

**Alternative Solution**: Use `DRServiceFactory.createService(.mock)` in Debug builds to avoid network-related debug symbols.

**Key Learning**: Release builds are cleaner and avoid many development-time signing/debugging artifacts that can cause runtime issues.

---

### Platform-Specific Color System ✅ IMPLEMENTED

**Implementation**: Comprehensive platform-specific color system based on [Apple Colors guide](https://mar.codes/apple-colors)

**Features**:
- **iOS**: Uses full iOS system color palette (`systemBackground`, `systemGray6`, `label`, etc.)
- **macOS**: Uses macOS-specific colors (`controlBackgroundColor`, `controlColor`, `labelColor`, etc.) 
- **tvOS**: Uses tvOS-appropriate colors with fallbacks (`systemGray`, black/white basics)

**Key Color Mappings**:
```swift
// Background colors properly mapped per platform
private var backgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlBackgroundColor)
    #elseif os(tvOS)
    Color.black // tvOS dark theme
    #else // iOS
    Color(.systemBackground)
    #endif
}
```

**Benefits**:
- ✅ No more color compatibility errors across platforms
- ✅ Native look and feel on each platform
- ✅ Proper dark mode support per platform conventions
- ✅ Accessibility compliance per platform guidelines

**Reference**: Complete color compatibility matrix at https://mar.codes/apple-colors

---

### Apple Music-Style Design System ✅ IMPLEMENTED

**Overview**: Complete UI/UX redesign to match Apple Music's modern, polished look and feel

**Key Design Elements**:
- **Hero Section**: Large album art with gradient backgrounds and prominent typography
- **Card-Based Layout**: Modern cards with shadows, rounded corners, and proper spacing  
- **Grid Interface**: Channel selection in 2-column grid layout (like album browsing)
- **Now Playing Bar**: Persistent bottom player bar with mini album art and controls
- **Visual Hierarchy**: Bold titles, weighted fonts, and proper information hierarchy
- **Blur Effects**: Ultra-thin material backgrounds for modern iOS/macOS aesthetic

**Major UI Components**:

1. **NowPlayingHeroView**: Apple Music-style hero section
   - Large 120x120 album art with channel color gradients
   - Live indicator with animated red dot
   - Prominent program title and description
   - Series information with channel color accent

2. **ChannelGridView**: Album-style channel browser
   - 2-column responsive grid layout
   - Gradient "album art" for each channel
   - Hover/selection animations with scale effects
   - Category badges and channel information

3. **NowPlayingBar**: Persistent bottom player
   - Mini album art (50x50) with gradient
   - Program title and channel name
   - Play/pause button (ready for Phase 1 audio implementation)
   - Ultra-thin material background with blur

4. **StreamDetailsView**: Technical information display
   - Quality indicators (HLS vs ICY)
   - Bitrate information and live status
   - Clean dividers and proper spacing

**Typography System**:
- **Headlines**: `.title2.weight(.bold)` for main titles
- **Subheadings**: `.title3.weight(.semibold)` for section headers  
- **Body**: `.subheadline.weight(.medium)` for primary content
- **Captions**: `.caption.weight(.bold)` for badges and labels

**Visual Polish**:
- **Shadows**: Subtle `.black.opacity(0.08)` with 8pt radius
- **Gradients**: Channel-specific color gradients for visual identity
- **Animations**: Scale effects on selection (1.02x scale)
- **Spacing**: 20pt horizontal padding, 16-20pt vertical spacing
- **Corner Radius**: 12-16pt for cards, 6-8pt for smaller elements

**Platform Adaptations**:
- **iOS**: Large navigation titles, full gesture support
- **macOS**: Automatic navigation style, proper window integration
- **Cross-Platform**: Consistent look while respecting platform conventions

**Benefits**:
- ✅ Professional, modern appearance matching Apple's design language
- ✅ Intuitive user experience familiar to Apple Music users
- ✅ Improved visual hierarchy and content discoverability
- ✅ Ready for Phase 1 audio controls integration
- ✅ Scalable design system for future features

---

## Version

- AGENT.md v1.0  
- Last updated: 2025-07-24

---

## Author / Contact

Built by [Your Name or Team]  
Contact: [your email]  
GitHub: [link if open source]  