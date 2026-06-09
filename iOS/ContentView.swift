import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var coordinator: PhoneCoordinator
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section("Lecture") {
                    if let id = coordinator.lectureID {
                        Text(id).font(.headline)
                        playbackControls
                    } else {
                        Button("Load lecture audio…") { showPicker = true }
                    }
                }
                Section("Annotations (\(coordinator.annotations.count))") {
                    if coordinator.annotations.isEmpty {
                        Text("No comments yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(coordinator.annotations.sorted(by: { $0.masterTimestamp < $1.masterTimestamp })) { ann in
                            AnnotationRow(annotation: ann) {
                                coordinator.audio.seek(to: ann.masterTimestamp)
                                coordinator.audio.play()
                                coordinator.isPlaying = true
                            }
                        }
                    }
                }
                if let err = coordinator.lastError {
                    Section("Error") { Text(err).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Commentator")
            .sheet(isPresented: $showPicker) {
                LecturePicker { id, url in
                    coordinator.loadLecture(id: id, url: url)
                    showPicker = false
                }
            }
        }
    }

    private var playbackControls: some View {
        HStack {
            Button {
                if coordinator.isPlaying {
                    coordinator.audio.pause()
                    coordinator.isPlaying = false
                } else {
                    coordinator.audio.play()
                    coordinator.isPlaying = true
                }
            } label: {
                Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            Spacer()
            Text(timeString(coordinator.audio.currentTime))
                .monospacedDigit()
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

private struct AnnotationRow: View {
    let annotation: Annotation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeString(annotation.masterTimestamp))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(annotation.transcript ?? "(no transcript yet)")
                    .foregroundStyle(annotation.transcript == nil ? .secondary : .primary)
            }
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

private struct LecturePicker: View {
    let onPicked: (String, URL) -> Void
    @State private var lectureID: String = "lecture-001"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Lecture ID", text: $lectureID)
                Text("File picker stub. Wire up UIDocumentPicker / .fileImporter next.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("New lecture")
        }
    }
}
