import Foundation
import Combine
import WatchKit

@MainActor
final class WatchCoordinator: ObservableObject {
    enum State { case idle, awaitingAck, recording, sending, error(String) }

    @Published var state: State = .idle
    @Published var pendingAnnotationID: UUID?
    @Published var pendingTimestamp: TimeInterval?

    let recorder = Recorder()
    private(set) lazy var wc: WCWatchSession = WCWatchSession(coordinator: self)

    func activate() {
        wc.activate()
    }

    func triggerPressed() {
        switch state {
        case .idle:
            startComment()
        case .recording:
            stopComment()
        case .awaitingAck, .sending:
            break
        case .error:
            state = .idle
        }
    }

    private func startComment() {
        state = .awaitingAck
        wc.sendStartComment { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let payload):
                    self.pendingAnnotationID = payload.annotationID
                    self.pendingTimestamp = payload.timestamp
                    do {
                        try self.recorder.start(annotationID: payload.annotationID)
                        self.state = .recording
                        WKInterfaceDevice.current().play(.start)
                    } catch {
                        self.state = .error("rec start: \(error.localizedDescription)")
                        WKInterfaceDevice.current().play(.failure)
                    }
                case .failure(let err):
                    self.state = .error(err.localizedDescription)
                    WKInterfaceDevice.current().play(.failure)
                }
            }
        }
    }

    private func stopComment() {
        state = .sending
        let url = recorder.stop()
        guard let id = pendingAnnotationID else {
            state = .idle
            return
        }
        wc.sendEndComment(annotationID: id, transcript: nil)
        if let url {
            wc.transferClip(annotationID: id, fileURL: url)
        }
        WKInterfaceDevice.current().play(.stop)
        pendingAnnotationID = nil
        pendingTimestamp = nil
        state = .idle
    }
}
