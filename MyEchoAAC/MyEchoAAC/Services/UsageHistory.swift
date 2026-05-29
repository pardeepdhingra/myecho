import Foundation
import os

@MainActor
final class UsageHistory: ObservableObject {
    struct Entry: Codable, Identifiable {
        var id: UUID
        var wordId: UUID
        var label: String
        var timestamp: Date

        init(id: UUID = UUID(), wordId: UUID, label: String, timestamp: Date = Date()) {
            self.id = id
            self.wordId = wordId
            self.label = label
            self.timestamp = timestamp
        }
    }

    @Published private(set) var entries: [Entry] = []
    @Published private(set) var spokenSentences: [String] = []

    private let key = "vani.usage.v1"
    private let sentencesKey = "vani.sentences.v1"
    private let maxSentences = 25
    private let maxEntries = 2000
    private let logger = Logger(subsystem: "com.pardeepdhingra.vani", category: "UsageHistory")

    init() {
        load()
        loadSentences()
    }

    func record(wordId: UUID, label: String, enabled: Bool) {
        guard enabled else { return }
        entries.append(Entry(wordId: wordId, label: label))
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        save()
    }

    func clear() {
        entries = []
        save()
    }

    func recordSentence(_ text: String, enabled: Bool) {
        guard enabled else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        spokenSentences.removeAll { $0 == trimmed }
        spokenSentences.insert(trimmed, at: 0)
        if spokenSentences.count > maxSentences {
            spokenSentences = Array(spokenSentences.prefix(maxSentences))
        }
        saveSentences()
    }

    func clearSentences() {
        spokenSentences = []
        saveSentences()
    }

    func countsInLast(hours: Int) -> [(label: String, count: Int)] {
        let cutoff = Date().addingTimeInterval(-Double(hours) * 3600)
        let recent = entries.filter { $0.timestamp >= cutoff }
        let grouped = Dictionary(grouping: recent, by: \.label)
        return grouped
            .map { (label: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    func recentWordIds(limit: Int) -> [UUID] {
        var seen = Set<UUID>()
        var result: [UUID] = []
        for entry in entries.reversed() {
            guard !seen.contains(entry.wordId) else { continue }
            seen.insert(entry.wordId)
            result.append(entry.wordId)
            if result.count >= limit { break }
        }
        return result
    }

    var totalCount: Int { entries.count }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Entry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func loadSentences() {
        guard let data = UserDefaults.standard.data(forKey: sentencesKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else { return }
        spokenSentences = decoded
    }

    private func saveSentences() {
        guard let data = try? JSONEncoder().encode(spokenSentences) else { return }
        UserDefaults.standard.set(data, forKey: sentencesKey)
    }
}
