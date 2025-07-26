import SwiftUI

// MARK: - Layout Helper

struct PodcastLayoutHelper {
    static func shouldUseCompactLayout(for screenSize: CGSize) -> Bool {
        return screenSize.width < 600 || screenSize.height < 800
    }
    
    static func gridColumns(for screenSize: CGSize) -> [GridItem] {
        let minItemWidth: CGFloat = shouldUseCompactLayout(for: screenSize) ? 300 : 350
        let spacing: CGFloat = 24
        let horizontalPadding: CGFloat = 48
        
        let availableWidth = screenSize.width - horizontalPadding
        let columnsCount = max(1, Int(availableWidth / (minItemWidth + spacing)))
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnsCount)
    }
    
    // New 3-column grid for sectioned channel groups
    static func threeColumnGrid(for screenSize: CGSize) -> [GridItem] {
        let isCompact = shouldUseCompactLayout(for: screenSize)
        let spacing: CGFloat = isCompact ? 8 : 16
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3)
    }
    
    static func regionGridColumns(for screenSize: CGSize) -> [GridItem] {
        let minItemWidth: CGFloat = shouldUseCompactLayout(for: screenSize) ? 150 : 180
        let spacing: CGFloat = 20
        let horizontalPadding: CGFloat = 48
        
        let availableWidth = screenSize.width - horizontalPadding
        let columnsCount = max(2, Int(availableWidth / (minItemWidth + spacing)))
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnsCount)
    }
    
    // New methods for master panel layouts
    static func masterGridColumns(for sizeCategory: ScreenSizeCategory) -> [GridItem] {
        switch sizeCategory {
        case .compact:
            return [GridItem(.flexible())]
        case .regular:
            return [GridItem(.flexible())]
        case .large:
            return [GridItem(.flexible())]
        }
    }
    
    static func masterRegionGridColumns(for sizeCategory: ScreenSizeCategory) -> [GridItem] {
        switch sizeCategory {
        case .compact:
            return [GridItem(.flexible())]
        case .regular:
            return [GridItem(.flexible())]
        case .large:
            return [GridItem(.flexible())]
        }
    }
} 