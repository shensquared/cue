import Foundation
import AVFoundation

final class AudioController {
    private var player: AVAudioPlayer?

    var isLoaded: Bool { player != nil }
    var currentTime: TimeInterval { player?.currentTime ?? 0 }
    var duration: TimeInterval { player?.duration ?? 0 }
    var isPlaying: Bool { player?.isPlaying ?? false }

    func load(url: URL) {
        configureSession()
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            player = p
        } catch {
            player = nil
        }
    }

    func play() { player?.play() }
    func pause() { player?.pause() }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        player.currentTime = max(0, min(time, player.duration))
    }

    private func configureSession() {
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetoothA2DP, .allowAirPlay])
        try? s.setActive(true)
    }
}
