//
//  PlayerInfoView.swift
//  ios
//
//  Created by Emmanuel on 27/07/2025.
//

import SwiftUI

struct PlayerInfoView: View {
    let title: String
    let subtitle: String
    let onEllipsisTap: (() -> Void)?
    
    init(
        title: String,
        subtitle: String,
        onEllipsisTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onEllipsisTap = onEllipsisTap
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: geometry.size.height * 0.1) {
                HStack {
                    VStack(alignment: .leading, spacing: geometry.size.height * 0.03) {
                        Text(title)
                            .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.5, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        MarqueeText(
                            text: subtitle,
                            font: .system(size: min(geometry.size.width, geometry.size.height) * 0.5),
                            leftFade: geometry.size.width * 0.05,
                            rightFade: geometry.size.width * 0.05,
                            startDelay: 1.5
                        )
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    }
                    
                    Spacer()
                    
                    if let onEllipsisTap = onEllipsisTap {
                        Button(action: onEllipsisTap) {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.5, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, geometry.size.width * 0.05)
        }
    }
}

#Preview {
    PlayerInfoView(
        title: "DR P1 - Morning Show",
        subtitle: "Current track information with long text that should scroll"
    ) {
        print("Ellipsis tapped")
    }
} 
