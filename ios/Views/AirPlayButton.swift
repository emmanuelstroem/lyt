//
//  AirPlayButton.swift
//  ios
//
//  Created by Emmanuel on 28/07/2025.
//

import SwiftUI
import AVKit

// MARK: - SwiftUI Native AirPlay Button

struct AirPlayButton: UIViewRepresentable {
    let size: CGFloat
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        
        // Configure the view
        view.prioritizesVideoDevices = false
        view.activeTintColor = UIColor.systemBlue
        view.tintColor = UIColor.label
        view.backgroundColor = UIColor.clear
        
        // Set delegate
        view.delegate = context.coordinator
        
        // Ensure proper sizing and interaction
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        
        // Set minimum size for touch interaction
        let buttonSize = max(size, 44)
        view.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        

        
        return view
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // Update tint colors if needed
        uiView.activeTintColor = UIColor.systemBlue
        uiView.tintColor = UIColor.label
        
        // Ensure proper frame
        let buttonSize = max(size, 44)
        uiView.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, AVRoutePickerViewDelegate {
        var parent: AirPlayButton
        
        init(_ parent: AirPlayButton) {
            self.parent = parent
        }
        
        func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        }
        
        func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        }
    }
}

// MARK: - Simple AirPlay Button

struct SimpleAirPlayButton: View {
    let size: CGFloat
    @State private var showingAirPlayPicker = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            showingAirPlayPicker = true
        }) {
            Image(systemName: "airplayaudio")
                .font(.system(size: size * 0.6, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isPressed ? Color.blue.opacity(0.3) : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .sheet(isPresented: $showingAirPlayPicker) {
            AirPlayPickerSheet()
        }
    }
}

// MARK: - AirPlay Picker Sheet

struct AirPlayPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                AirPlayButton(size: 100)
                    .frame(width: 100, height: 100)
                    .padding()
                
                Text("AirPlay")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Select a device to stream audio")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("AirPlay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - AirPlay Button with Frame

struct AirPlayButtonView: View {
    let size: CGFloat
    
    var body: some View {
        AirPlayButton(size: size)
            .frame(width: size, height: size)
            .contentShape(Rectangle()) // Ensure the entire frame is tappable
            .accessibilityLabel("AirPlay")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AirPlayButtonView(size: 24)
        SimpleAirPlayButton(size: 24)
        AirPlayButtonView(size: 32)
    }
    .padding()
} 