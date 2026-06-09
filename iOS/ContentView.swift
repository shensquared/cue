import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var coordinator: PhoneCoordinator
    @State private var showImporter = false
    @State private var csvURL: URL?

    var body: some View {
        NavigationStack {
            List {
                lecturesSection
                if coordinator.lectureID != nil {
                    playbackSection
                    annotationsSection
                }
                if let err = coordinator.lastError {
                    Section("Error") {
                        Text(err).foregroundStyle(.red)
                        Button("Dismiss") { coordinator.lastError = nil }
                    }
                }
            }
            .navigationTitle("Cue")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if coordinator.lectureID != nil, let csvURL {
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: csvURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first { coordinator.importLecture(from: url) }
                case .failure(let error):
                    coordinator.lastError = "import canceled: \(error.localizedDescription)"
                }
            }
            .onChange(of: coordinator.lectureID) { _, _ in
                refreshCSV()
            }
            .onChange(of: coordinator.annotations.count) { _, _ in
                refreshCSV()
            }
            .onAppear { refreshCSV() }
        }
    }

    private func refreshCSV() {
        csvURL = coordinator.exportCSVURL()
    }

    private var lecturesSection: some View {
        Section("Lectures") {
            if coordinator.lectures.isEmpty {
                Text("No lectures yet — tap + to import.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(coordinator.lectures) { lecture in
                    Button {
                        coordinator.selectLecture(lecture)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(lecture.displayName)
                                Text(lecture.id).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if coordinator.lectureID == lecture.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            coordinator.deleteLecture(lecture)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var playbackSection: some View {
        Section("Playback") {
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
    }

    private var annotationsSection: some View {
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
