import Foundation
import UIKit
import os

enum SignVideoStore {
    private static let directoryName = "sign-videos"
    private static let logger = Logger(subsystem: "com.pardeepdhingra.vani", category: "SignVideoStore")

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static func save(_ data: Data) -> String? {
        let filename = "\(UUID().uuidString).mp4"
        let url = directoryURL.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            logger.error("Failed to write sign video: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    static func fileURL(for filename: String) -> URL {
        directoryURL.appendingPathComponent(filename)
    }

    static func exists(_ filename: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: filename).path)
    }

    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: fileURL(for: filename))
        try? FileManager.default.removeItem(at: thumbnailFileURL(for: filename))
    }

    static func purgeAll() {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    // MARK: - Thumbnails

    private static func thumbnailFilename(for videoFilename: String) -> String {
        (videoFilename as NSString).deletingPathExtension + ".jpg"
    }

    static func thumbnailFileURL(for videoFilename: String) -> URL {
        directoryURL.appendingPathComponent(thumbnailFilename(for: videoFilename))
    }

    static func saveThumbnail(_ data: Data, for videoFilename: String) {
        let url = thumbnailFileURL(for: videoFilename)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            logger.error("Failed to write sign thumbnail: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func loadThumbnail(for videoFilename: String) -> UIImage? {
        UIImage(contentsOfFile: thumbnailFileURL(for: videoFilename).path)
    }

    static func thumbnailExists(for videoFilename: String) -> Bool {
        FileManager.default.fileExists(atPath: thumbnailFileURL(for: videoFilename).path)
    }
}
