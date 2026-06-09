import Foundation
import AVFoundation

enum RecorderError: Error {
    case sessionFailed
    case startFailed
}

final class Recorder {
    private var recorder: AVAudioRecorder?
    private var currentURL: URL?

    func start(annotationID: UUID) throws {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .spokenAudio, options: [])
            try session.setActive(true, options: [])
        } catch {
            throw RecorderError.sessionFailed
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("comment-\(annotationID.uuidString).m4a")
        try? FileManager.default.removeItem(at: url)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        let r = try AVAudioRecorder(url: url, settings: settings)
        guard r.record() else { throw RecorderError.startFailed }
        recorder = r
        currentURL = url
    }

    @discardableResult
    func stop() -> URL? {
        recorder?.stop()
        let url = currentURL
        recorder = nil
        currentURL = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        return url
    }
}
