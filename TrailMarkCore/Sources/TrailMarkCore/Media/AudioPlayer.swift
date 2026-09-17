import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
public final class AudioPlayer: NSObject {
    public private(set) var isPlaying = false
    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }
    
    private var player: AVAudioPlayer?
    
    public override init() { super.init() }
    
    public func play(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let player = try AVAudioPlayer(contentsOf: url)
            
            player.delegate = self
            player.play()
            
            self.player = player
            self.isPlaying = true
            self.currentTime = 0
            self.duration = player.duration
        } catch {
            isPlaying = false
            currentTime = 0
            duration = 0
        }
    }
    
    public func stop() {
            player?.stop()
            player = nil
            isPlaying = false
            currentTime = 0
        }

    public func tick() {
        guard let player else { return }
        currentTime = player.currentTime
        duration = player.duration
    }
    }

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.currentTime = 0
            self.isPlaying = false
        }
    }
}
