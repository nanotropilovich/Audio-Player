import AVFoundation
import SwiftUI
import Combine
class AudioPlayer: NSObject, ObservableObject {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var isSeeking = false
    @Published var isPlaying = false
    @Published var duration: TimeInterval?
    private var atTime: TimeInterval = 0
    @Published var currentTime: TimeInterval?
    func playAudio(from url: URL, startTime: TimeInterval = 0) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.currentTime = startTime // устанавливаем время начала воспроизведения
            player?.play()
            duration = player?.duration

            // Set up timer to update current time
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
                guard let self = self, !self.isSeeking else { return }
                self.currentTime = self.player?.currentTime
            })

            isPlaying = true
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }

    func stopPlaying(at time: TimeInterval? = nil) {
        if let time = time {
            self.currentTime = time
            self.player?.currentTime = time
        }
        self.player?.stop()
        self.timer?.invalidate()
        self.timer = nil
        self.isPlaying = false
    }


    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }
    
    func resumePlaying() {
        playAudio(from: player!.url!, startTime: atTime)
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlaying()
    }
}
