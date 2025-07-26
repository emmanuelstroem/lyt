import SwiftUI

#if os(macOS)
import AppKit
#endif

// MARK: - Platform-Specific Colors
// Based on https://mar.codes/apple-colors for proper cross-platform compatibility

var backgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlBackgroundColor)
    #elseif os(tvOS)
    Color.black // tvOS typically uses black backgrounds
    #else // iOS
    Color(.systemBackground)
    #endif
}

var secondaryBackgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlColor)
    #elseif os(tvOS)
    Color(.systemGray) // tvOS has systemGray but not systemGray6
    #else // iOS
    Color(.systemGray6)
    #endif
}

var tertiaryBackgroundColor: Color {
    #if os(macOS)
    Color(NSColor.separatorColor)
    #elseif os(tvOS)
    Color(.systemGray) // tvOS has limited color options
    #else // iOS
    Color(.systemGray4)
    #endif
}

var separatorColor: Color {
    #if os(macOS)
    Color(NSColor.separatorColor)
    #elseif os(tvOS)
    Color(.systemGray) // tvOS fallback
    #else // iOS
    Color(.separator)
    #endif
}

var labelColor: Color {
    #if os(macOS)
    Color(NSColor.labelColor)
    #elseif os(tvOS)
    Color.white // tvOS typically uses white text
    #else // iOS
    Color(.label)
    #endif
}

var secondaryLabelColor: Color {
    #if os(macOS)
    Color(NSColor.secondaryLabelColor)
    #elseif os(tvOS)
    Color.gray // tvOS fallback
    #else // iOS
    Color(.secondaryLabel)
    #endif
}

var cardBackgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlBackgroundColor)
    #elseif os(tvOS)
    Color.black.opacity(0.3) // Basic black with opacity for tvOS
    #else // iOS
    Color(.systemBackground)
    #endif
}

var fillColor: Color {
    #if os(macOS)
    Color(NSColor.controlColor)
    #elseif os(tvOS)
    Color(.systemGray).opacity(0.5)
    #else // iOS
    Color(.systemFill)
    #endif
} 