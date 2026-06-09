import Foundation

struct Lecture: Codable, Identifiable, Hashable {
    let id: String
    var displayName: String
    var bookmark: Data
    var addedAt: Date
}

final class LectureStore {
    private let fm = FileManager.default

    private var root: URL {
        let base = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Lectures", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var indexURL: URL {
        root.appendingPathComponent("lectures.json")
    }

    func load() -> [Lecture] {
        guard let data = try? Data(contentsOf: indexURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Lecture].self, from: data)) ?? []
    }

    func save(_ lectures: [Lecture]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(lectures) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }

    func makeBookmark(from url: URL) throws -> Data {
        try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    func resolveBookmark(_ data: Data) -> URL? {
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale) else {
            return nil
        }
        return url
    }
}
