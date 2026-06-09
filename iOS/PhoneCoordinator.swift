import Foundation
import Combine

@MainActor
final class PhoneCoordinator: ObservableObject {
    @Published var lectureID: String?
    @Published var isPlaying = false
    @Published var pendingCommentTimestamp: TimeInterval?
    @Published var annotations: [Annotation] = []
    @Published var lastError: String?

    let audio = AudioController()
    let store = AnnotationStore()
    let transcriber = Transcriber()
    private(set) lazy var wc: WCPhoneSession = WCPhoneSession(coordinator: self)

    static let resumeBackoff: TimeInterval = 3.0

    func activate() {
        wc.activate()
    }

    func loadLecture(id: String, url: URL) {
        lectureID = id
        audio.load(url: url)
        annotations = store.load(lectureID: id)
    }

    func handleStartComment() -> TimeInterval? {
        guard audio.isLoaded else { return nil }
        audio.pause()
        isPlaying = false
        let t = audio.currentTime
        pendingCommentTimestamp = t
        return t
    }

    func handleEndComment(annotationID: UUID, transcript: String?) {
        guard let lectureID, let t = pendingCommentTimestamp else { return }
        let ann = Annotation(
            id: annotationID,
            lectureID: lectureID,
            masterTimestamp: t,
            commentAudioFile: nil,
            transcript: transcript
        )
        annotations.append(ann)
        store.save(lectureID: lectureID, annotations: annotations)
        pendingCommentTimestamp = nil
        resumeAfterComment(from: t)
    }

    func handleClipFileReceived(annotationID: UUID, at fileURL: URL) {
        guard let lectureID else { return }
        guard let idx = annotations.firstIndex(where: { $0.id == annotationID }) else { return }
        let dest = store.clipsDirectory(lectureID: lectureID)
            .appendingPathComponent("\(annotationID.uuidString).m4a")
        try? FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: fileURL, to: dest)
            annotations[idx].commentAudioFile = dest.lastPathComponent
            store.save(lectureID: lectureID, annotations: annotations)
            Task { await autoTranscribe(annotationID: annotationID, fileURL: dest) }
        } catch {
            lastError = "clip move failed: \(error.localizedDescription)"
        }
    }

    private func autoTranscribe(annotationID: UUID, fileURL: URL) async {
        do {
            let text = try await transcriber.transcribe(fileURL: fileURL)
            guard let idx = annotations.firstIndex(where: { $0.id == annotationID }) else { return }
            if (annotations[idx].transcript ?? "").isEmpty {
                annotations[idx].transcript = text
                if let lectureID {
                    store.save(lectureID: lectureID, annotations: annotations)
                }
            }
        } catch {
            lastError = "transcribe failed: \(error.localizedDescription)"
        }
    }

    private func resumeAfterComment(from t: TimeInterval) {
        let target = max(0, t - Self.resumeBackoff)
        audio.seek(to: target)
        audio.play()
        isPlaying = true
    }
}
