import Foundation
import WatchConnectivity

struct StartCommentAck {
    let annotationID: UUID
    let timestamp: TimeInterval
}

enum WCWatchError: LocalizedError {
    case notReachable
    case badAck
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notReachable: return "iPhone not reachable"
        case .badAck: return "bad ack"
        case .server(let s): return s
        }
    }
}

final class WCWatchSession: NSObject, WCSessionDelegate {
    private weak var coordinator: WatchCoordinator?
    private let session = WCSession.default

    init(coordinator: WatchCoordinator) {
        self.coordinator = coordinator
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    func sendStartComment(completion: @escaping (Result<StartCommentAck, Error>) -> Void) {
        guard session.isReachable else {
            completion(.failure(WCWatchError.notReachable))
            return
        }
        let msg: [String: Any] = [MessageKey.kind: MessageKind.startComment.rawValue]
        session.sendMessage(msg, replyHandler: { reply in
            if let err = reply[MessageKey.error] as? String {
                completion(.failure(WCWatchError.server(err)))
                return
            }
            guard let idString = reply[MessageKey.annotationID] as? String,
                  let id = UUID(uuidString: idString),
                  let t = reply[MessageKey.timestamp] as? TimeInterval else {
                completion(.failure(WCWatchError.badAck))
                return
            }
            completion(.success(StartCommentAck(annotationID: id, timestamp: t)))
        }, errorHandler: { error in
            completion(.failure(error))
        })
    }

    func sendEndComment(annotationID: UUID, transcript: String?) {
        var msg: [String: Any] = [
            MessageKey.kind: MessageKind.endComment.rawValue,
            MessageKey.annotationID: annotationID.uuidString
        ]
        if let transcript { msg[MessageKey.transcript] = transcript }
        if session.isReachable {
            session.sendMessage(msg, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(msg)
        }
    }

    func transferClip(annotationID: UUID, fileURL: URL) {
        let meta: [String: Any] = [
            FileMetaKey.kind: "commentClip",
            FileMetaKey.annotationID: annotationID.uuidString
        ]
        session.transferFile(fileURL, metadata: meta)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
