import Foundation
import AVFoundation
import WatchKit

enum RecorderError: Error {
    case sessionFailed
    case startFailed
}

final class Recorder: NSObject, WKExtendedRuntimeSessionDelegate {
    private var recorder: AVAudioRecorder?
    private var currentURL: URL?
    private var runtimeSession: WKExtendedRuntimeSession?

    func start(annotationID: UUID) throws {
        startRuntimeSession()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .spokenAudio, options: [])
            try session.setActive(true, options: [])
        } catch {
            stopRuntimeSession()
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
        guard r.record() else {
            stopRuntimeSession()
            throw RecorderError.startFailed
        }
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
        stopRuntimeSession()
        return url
    }

    private func startRuntimeSession() {
        guard runtimeSession == nil else { return }
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        s.start()
        runtimeSession = s
    }

    private func stopRuntimeSession() {
        runtimeSession?.invalidate()
        runtimeSession = nil
    }

    // MARK: - WKExtendedRuntimeSessionDelegate

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        runtimeSession = nil
    }
}
