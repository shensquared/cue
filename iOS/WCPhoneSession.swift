import Foundation
import WatchConnectivity

final class WCPhoneSession: NSObject, WCSessionDelegate {
    private weak var coordinator: PhoneCoordinator?
    private let session = WCSession.default
    private var pendingAnnotationID: UUID?

    init(coordinator: PhoneCoordinator) {
        self.coordinator = coordinator
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let kindRaw = message[MessageKey.kind] as? String,
              let kind = MessageKind(rawValue: kindRaw) else {
            replyHandler([MessageKey.error: "unknown kind"])
            return
        }

        Task { @MainActor in
            switch kind {
            case .startComment:
                let id = UUID()
                pendingAnnotationID = id
                if let t = coordinator?.handleStartComment() {
                    replyHandler([
                        MessageKey.kind: MessageKind.ack.rawValue,
                        MessageKey.annotationID: id.uuidString,
                        MessageKey.timestamp: t
                    ])
                } else {
                    replyHandler([MessageKey.error: "no lecture loaded"])
                }

            case .endComment:
                let transcript = message["transcript"] as? String
                let idString = message[MessageKey.annotationID] as? String
                let id = idString.flatMap(UUID.init(uuidString:)) ?? pendingAnnotationID ?? UUID()
                coordinator?.handleEndComment(annotationID: id, transcript: transcript)
                pendingAnnotationID = nil
                replyHandler([MessageKey.kind: MessageKind.resumed.rawValue])

            default:
                replyHandler([MessageKey.error: "unsupported kind"])
            }
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let meta = file.metadata ?? [:]
        guard let idString = meta[FileMetaKey.annotationID] as? String,
              let id = UUID(uuidString: idString) else { return }
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("incoming-\(id.uuidString).m4a")
        try? FileManager.default.removeItem(at: tmp)
        try? FileManager.default.copyItem(at: file.fileURL, to: tmp)
        Task { @MainActor in
            coordinator?.handleClipFileReceived(annotationID: id, at: tmp)
        }
    }
}
