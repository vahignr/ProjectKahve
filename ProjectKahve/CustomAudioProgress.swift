import SwiftUI

struct CustomAudioProgress: View {
    @ObservedObject var audioManager: AudioPlayerManager
    @State private var isDragging: Bool = false
    @State private var dragValue: Float64 = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress Bar with Draggable Circle
            GeometryReader { geometry in
                // Main Container
                ZStack(alignment: .leading) {
                    // Track Container
                    ZStack(alignment: .leading) {
                        // Background Track
                        Rectangle()
                            .fill(ModernTheme.sage.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(4)
                        
                        // Progress Track
                        Rectangle()
                            .fill(ModernTheme.sage)
                            .frame(
                                width: max(0, min(geometry.size.width * (isDragging ? dragValue : Float64(audioManager.currentTime / audioManager.duration)), geometry.size.width)),
                                height: 4
                            )
                            .cornerRadius(4)
                    }
                    
                    // Draggable Circle (only if there's progress)
                    let progress = isDragging ? dragValue : Float64(audioManager.currentTime / audioManager.duration)
                    if progress > 0.001 || isDragging { // Small threshold to prevent initial display
                        Circle()
                            .fill(ModernTheme.surface)
                            .frame(width: 28, height: 28)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(ModernTheme.sage, lineWidth: 2)
                            )
                            .offset(x: max(0, min(geometry.size.width * progress - 14, geometry.size.width - 28)))
                    }
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            dragValue = Float64(max(0, min(value.location.x / geometry.size.width, 1.0)))
                        }
                        .onEnded { value in
                            isDragging = false
                            let percentage = Float64(max(0, min(value.location.x / geometry.size.width, 1.0)))
                            audioManager.seek(to: percentage)
                        }
                )
            }
            .frame(height: 28)
            .padding(.horizontal, 14) // Add padding to account for circle overflow
            
            // Time Labels
            HStack {
                Text(timeString(from: audioManager.currentTime))
                    .font(ModernTheme.Typography.caption)
                    .foregroundColor(ModernTheme.textSecondary)
                
                Spacer()
                
                Text(timeString(from: audioManager.duration))
                    .font(ModernTheme.Typography.caption)
                    .foregroundColor(ModernTheme.textSecondary)
            }
        }
        .padding(.horizontal)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    CustomAudioProgress(audioManager: AudioPlayerManager())
        .frame(height: 40)
        .padding()
}
