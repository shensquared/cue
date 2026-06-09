import Foundation
import Speech

enum TranscribeError: Error {
    case unauthorized
    case unavailable
    case empty
}

final class Transcriber {
    private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuth() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status)
            }
        }
    }

    func transcribe(fileURL: URL) async throws -> String {
        let status = await requestAuth()
        guard status == .authorized else { throw TranscribeError.unauthorized }
        guard let recognizer, recognizer.isAvailable else { throw TranscribeError.unavailable }

        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.shouldReportPartialResults = false
        if #available(iOS 16, *) { request.addsPunctuation = true }
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition

        let lock = NSLock()
        var resumed = false

        return try await withCheckedThrowingContinuation { cont in
            recognizer.recognitionTask(with: request) { result, error in
                lock.lock()
                defer { lock.unlock() }
                guard !resumed else { return }
                if let error {
                    resumed = true
                    cont.resume(throwing: error)
                    return
                }
                guard let result, result.isFinal else { return }
                let text = result.bestTranscription.formattedString
                resumed = true
                if text.isEmpty {
                    cont.resume(throwing: TranscribeError.empty)
                } else {
                    cont.resume(returning: text)
                }
            }
        }
    }
}
