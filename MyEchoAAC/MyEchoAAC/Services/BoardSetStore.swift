import Foundation
import os

/// One saved board set in the index — the metadata shown in lists. The full board lives in its own
/// self-contained `.vaniboard` file (same format as export/import, photos embedded).
struct BoardSetMeta: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var savedAt: Date
    var wordCount: Int

    init(id: UUID = UUID(), name: String, savedAt: Date = Date(), wordCount: Int) {
        self.id = id
        self.name = name
        self.savedAt = savedAt
        self.wordCount = wordCount
    }
}

/// Named board sets (e.g. Home, School, Therapy): local snapshots of the whole board that a parent or
/// therapist can save and switch between. Loading a set replaces the live board; the live board is
/// what syncs to the cloud, so cloud semantics stay "the cloud board is the board on screen".
///
/// Storage: `Documents/board-sets/<uuid>.vaniboard` plus `index.json` for the list. Each set file is
/// fully self-contained (photos embedded), so deleting words or photos from the live board can never
/// corrupt a saved set.
@MainActor
final class BoardSetStore: ObservableObject {
    @Published private(set) var sets: [BoardSetMeta] = []

    private let directory: URL
    private let logger = Logger(subsystem: "com.pardeepdhingra.vani", category: "BoardSets")

    private var indexURL: URL { directory.appendingPathComponent("index.json") }

    nonisolated static var defaultDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("board-sets", isDirectory: true)
    }

    init(directory: URL = BoardSetStore.defaultDirectory) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        loadIndex()
    }

    // MARK: Operations

    /// Snapshot the live board into a new named set.
    @discardableResult
    func saveCurrentBoard(named name: String, store: AACStore) -> BoardSetMeta? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let payload = BoardBackup.makePayload(store: store)
        guard let data = BoardBackup.encode(payload) else { return nil }

        let meta = BoardSetMeta(name: trimmed, wordCount: payload.words.count)
        do {
            try data.write(to: fileURL(for: meta.id), options: .atomic)
        } catch {
            logger.error("Failed to write board set: \(error.localizedDescription, privacy: .public)")
            return nil
        }
        sets.append(meta)
        saveIndex()
        return meta
    }

    /// Overwrite an existing set with the live board.
    @discardableResult
    func updateSet(id: UUID, from store: AACStore) -> Bool {
        guard let index = sets.firstIndex(where: { $0.id == id }) else { return false }
        let payload = BoardBackup.makePayload(store: store)
        guard let data = BoardBackup.encode(payload) else { return false }
        do {
            try data.write(to: fileURL(for: id), options: .atomic)
        } catch {
            logger.error("Failed to update board set: \(error.localizedDescription, privacy: .public)")
            return false
        }
        sets[index].savedAt = Date()
        sets[index].wordCount = payload.words.count
        saveIndex()
        return true
    }

    /// Replace the live board with a saved set. The current board is NOT auto-saved first — callers
    /// must warn the user (or save a set) before loading.
    @discardableResult
    func load(id: UUID, into store: AACStore) -> Bool {
        guard let data = try? Data(contentsOf: fileURL(for: id)),
              let payload = BoardBackup.decodePayload(from: data) else {
            logger.error("Failed to read board set \(id, privacy: .public)")
            return false
        }
        BoardBackup.apply(payload, to: store)
        return true
    }

    func rename(id: UUID, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = sets.firstIndex(where: { $0.id == id }) else { return }
        sets[index].name = trimmed
        saveIndex()
    }

    func delete(id: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: id))
        sets.removeAll { $0.id == id }
        saveIndex()
    }

    // MARK: Persistence

    private func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).vaniboard")
    }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([BoardSetMeta].self, from: data) else { return }
        // Drop entries whose backing file vanished so the list never offers a set that can't load.
        sets = decoded.filter { FileManager.default.fileExists(atPath: fileURL(for: $0.id).path) }
    }

    private func saveIndex() {
        guard let data = try? JSONEncoder().encode(sets) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
