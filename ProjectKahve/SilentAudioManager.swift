import AVFoundation

class SilentAudioManager {
    static let shared = SilentAudioManager()
    private var audioPlayer: AVAudioPlayer?
    
    /// Call this before starting a background-sensitive process (e.g., TTS)
    func startPlaying() {
        guard let url = Bundle.main.url(forResource: "silence", withExtension: "mp3") else {
            print("Silent track `silence.mp3` not found in bundle!")
            return
        }
        
        do {
            // Configure audio session for background playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Initialize and prepare player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            audioPlayer?.volume = 1.0       // or 0.0 if you want absolute silence
            audioPlayer?.play()
            
            print("Silent audio started playing.")
        } catch {
            print("Failed to play silent audio: \(error.localizedDescription)")
        }
    }
    
    /// Stop the silent audio once your process finishes
    func stopPlaying() {
        audioPlayer?.stop()
        audioPlayer = nil
        print("Silent audio stopped.")
        
        do {
            // Optionally deactivate session if no other audio is needed
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}
