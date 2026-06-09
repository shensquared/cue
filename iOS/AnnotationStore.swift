import Foundation

final class AnnotationStore {
    private let fm = FileManager.default

    private var root: URL {
        let base = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Lectures", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func lectureDir(_ lectureID: String) -> URL {
        let dir = root.appendingPathComponent(lectureID, isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func annotationsURL(_ lectureID: String) -> URL {
        lectureDir(lectureID).appendingPathComponent("annotations.json")
    }

    func clipsDirectory(lectureID: String) -> URL {
        let dir = lectureDir(lectureID).appendingPathComponent("clips", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func load(lectureID: String) -> [Annotation] {
        let url = annotationsURL(lectureID)
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Annotation].self, from: data)) ?? []
    }

    func save(lectureID: String, annotations: [Annotation]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(annotations) else { return }
        try? data.write(to: annotationsURL(lectureID), options: .atomic)
    }

    func exportCSV(lectureID: String, annotations: [Annotation]) -> URL? {
        let url = lectureDir(lectureID).appendingPathComponent("annotations.csv")
        var lines = ["mm:ss,transcript"]
        for ann in annotations.sorted(by: { $0.masterTimestamp < $1.masterTimestamp }) {
            let s = Int(ann.masterTimestamp)
            let stamp = String(format: "%02d:%02d", s / 60, s % 60)
            let text = (ann.transcript ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            lines.append("\(stamp),\"\(text)\"")
        }
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
