import Foundation
import UIKit
import os

struct BackupPayload: Codable {
    var version: Int
    var exportedAt: Date
    var words: [AACWord]
    var quickPhrases: [QuickPhrase]
    var settings: AACSettings
    var images: [String: String]
}

@MainActor
enum BoardBackup {
    private static let logger = Logger(subsystem: "com.pardeepdhingra.vani", category: "BoardBackup")
    private static let currentVersion = 1

    /// Snapshot the whole board — words, phrases, settings, and every referenced photo (embedded as
    /// base64 JPEG) — into one self-contained payload. Shared by file export and saved board sets.
    static func makePayload(store: AACStore) -> BackupPayload {
        var images: [String: String] = [:]
        for word in store.words {
            for filename in [word.imagePath, word.signThumbnailPath].compactMap({ $0 }) {
                guard let image = ImageStore.load(filename),
                      let data = image.jpegData(compressionQuality: 0.85) else { continue }
                images[filename] = data.base64EncodedString()
            }
        }

        return BackupPayload(
            version: currentVersion,
            exportedAt: Date(),
            words: store.words,
            quickPhrases: store.quickPhrases,
            settings: store.settings,
            images: images
        )
    }

    static func encode(_ payload: BackupPayload) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(payload) else {
            logger.error("Failed to encode backup")
            return nil
        }
        return data
    }

    static func decodePayload(from data: Data) -> BackupPayload? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(BackupPayload.self, from: data) else {
            logger.error("Failed to decode backup")
            return nil
        }
        return payload
    }

    /// Replace the live board with a payload: photos on disk are replaced with the payload's embedded
    /// images, then the store contents swap in one shot.
    static func apply(_ payload: BackupPayload, to store: AACStore) {
        ImageStore.purgeAll()
        for (filename, base64) in payload.images {
            guard let imageData = Data(base64Encoded: base64),
                  let image = UIImage(data: imageData),
                  let savedData = image.jpegData(compressionQuality: 0.85) else { continue }
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationDir = documentsURL.appendingPathComponent("word-images", isDirectory: true)
            try? FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            let destination = destinationDir.appendingPathComponent(filename)
            try? savedData.write(to: destination, options: .atomic)
        }

        store.replaceAll(words: payload.words, quickPhrases: payload.quickPhrases, settings: payload.settings)
    }

    static func exportToTempFile(store: AACStore) -> URL? {
        guard let data = encode(makePayload(store: store)) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let filename = "vani-board-\(formatter.string(from: Date())).vaniboard"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            logger.error("Failed to write backup: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    @discardableResult
    static func importFromFile(_ url: URL, into store: AACStore) -> Bool {
        let needsRelease = url.startAccessingSecurityScopedResource()
        defer { if needsRelease { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            logger.error("Failed to read backup file")
            return false
        }

        guard let payload = decodePayload(from: data) else { return false }
        apply(payload, to: store)
        return true
    }
}
