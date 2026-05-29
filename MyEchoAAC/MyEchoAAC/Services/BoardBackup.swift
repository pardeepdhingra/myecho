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

    static func exportToTempFile(store: AACStore) -> URL? {
        var images: [String: String] = [:]
        for word in store.words {
            guard let filename = word.imagePath,
                  let image = ImageStore.load(filename),
                  let data = image.jpegData(compressionQuality: 0.85) else { continue }
            images[filename] = data.base64EncodedString()
        }

        let payload = BackupPayload(
            version: currentVersion,
            exportedAt: Date(),
            words: store.words,
            quickPhrases: store.quickPhrases,
            settings: store.settings,
            images: images
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(payload) else {
            logger.error("Failed to encode backup")
            return nil
        }

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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let payload = try? decoder.decode(BackupPayload.self, from: data) else {
            logger.error("Failed to decode backup")
            return false
        }

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

        store.words = payload.words
        store.quickPhrases = payload.quickPhrases
        store.settings = payload.settings
        return true
    }
}
