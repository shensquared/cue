import Foundation

struct Annotation: Codable, Identifiable, Hashable {
    let id: UUID
    let lectureID: String
    let masterTimestamp: TimeInterval
    var commentAudioFile: String?
    var transcript: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        lectureID: String,
        masterTimestamp: TimeInterval,
        commentAudioFile: String? = nil,
        transcript: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.lectureID = lectureID
        self.masterTimestamp = masterTimestamp
        self.commentAudioFile = commentAudioFile
        self.transcript = transcript
        self.createdAt = createdAt
    }
}
