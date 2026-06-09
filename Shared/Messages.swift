import Foundation

enum MessageKey {
    static let kind = "kind"
    static let timestamp = "timestamp"
    static let lectureID = "lectureID"
    static let annotationID = "annotationID"
    static let state = "state"
    static let error = "error"
}

enum MessageKind: String {
    case startComment
    case endComment
    case ack
    case resumed
    case play
    case pause
    case seek
    case error
}

enum FileMetaKey {
    static let kind = "kind"
    static let annotationID = "annotationID"
    static let lectureID = "lectureID"
}
