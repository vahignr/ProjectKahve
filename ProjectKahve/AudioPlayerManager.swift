import Foundation
import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject {
   // Audio player instance
   private var audioPlayer: AVAudioPlayer?
   
   // Published properties for UI updates
   @Published var isPlaying: Bool = false
   @Published var currentTime: TimeInterval = 0
   @Published var duration: TimeInterval = 0
   
   // Timer for tracking progress
   private var progressTimer: Timer?
   
   override init() {
       super.init()
       setupAudioSession()
   }
   
   private func setupAudioSession() {
       do {
           try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
           try AVAudioSession.sharedInstance().setActive(true)
       } catch {
           print("Failed to setup audio session:", error.localizedDescription)
       }
   }
   
   func loadAudio(from url: URL, autoplay: Bool = true) {
       do {
           let audioData = try Data(contentsOf: url)
           audioPlayer = try AVAudioPlayer(data: audioData)
           audioPlayer?.delegate = self
           audioPlayer?.prepareToPlay()
           duration = audioPlayer?.duration ?? 0
           
           // Only start playing if autoplay is true
           if autoplay {
               play()
           }
           
       } catch {
           print("Failed to load audio:", error.localizedDescription)
       }
   }
   
   func play() {
       audioPlayer?.play()
       isPlaying = true
       startProgressTimer()
   }
   
   func pause() {
       audioPlayer?.pause()
       isPlaying = false
       stopProgressTimer()
   }
   
   func stop() {
       audioPlayer?.stop()
       audioPlayer?.currentTime = 0
       isPlaying = false
       currentTime = 0
       stopProgressTimer()
   }
   
   func seek(to percentage: Float64) {
       guard let player = audioPlayer else { return }
       let time = percentage * player.duration
       player.currentTime = time
       currentTime = time
       
       // If it was playing, continue playing after seek
       if isPlaying {
           player.play()
       }
   }
   
   private func startProgressTimer() {
       progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
           guard let self = self else { return }
           self.currentTime = self.audioPlayer?.currentTime ?? 0
       }
   }
   
   private func stopProgressTimer() {
       progressTimer?.invalidate()
       progressTimer = nil
   }
   
   deinit {
       stopProgressTimer()
       audioPlayer?.stop()
   }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerManager: AVAudioPlayerDelegate {
   func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
       isPlaying = false
       stopProgressTimer()
       // Removed resetting currentTime to prevent auto-replay
   }
}
