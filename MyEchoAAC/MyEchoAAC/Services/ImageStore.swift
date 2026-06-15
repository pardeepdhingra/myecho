import Foundation
import UIKit
import os

/// Why saving an image to disk failed, with a parent-friendly message for the UI.
enum ImageStoreError: LocalizedError {
    case encodingFailed
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "That photo couldn't be processed. Try a different image."
        case .writeFailed(let error):
            return "Couldn't save the photo to this device: \(error.localizedDescription)"
        }
    }
}

enum ImageStore {
    private static let directoryName = "word-images"
    private static let logger = Logger(subsystem: "com.pardeepdhingra.vani", category: "ImageStore")

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    /// Save an image to disk and return its generated filename. Throws `ImageStoreError` when the image
    /// can't be encoded or written, so callers can surface the failure instead of silently dropping it.
    static func save(_ image: UIImage) throws -> String {
        let resized = resize(image, maxDimension: 800)
        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            logger.error("Failed to encode image as JPEG")
            throw ImageStoreError.encodingFailed
        }
        let filename = "\(UUID().uuidString).jpg"
        let url = directoryURL.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            logger.error("Failed to write image: \(error.localizedDescription, privacy: .public)")
            throw ImageStoreError.writeFailed(error)
        }
    }

    static func load(_ filename: String) -> UIImage? {
        let url = directoryURL.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    static func fileURL(for filename: String) -> URL {
        directoryURL.appendingPathComponent(filename)
    }

    static func exists(_ filename: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: filename).path)
    }

    /// Write raw JPEG bytes downloaded from the cloud under the given filename.
    static func writeData(_ data: Data, filename: String) {
        try? data.write(to: fileURL(for: filename), options: .atomic)
    }

    static func delete(_ filename: String) {
        let url = directoryURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    static func purgeAll() {
        let url = directoryURL
        try? FileManager.default.removeItem(at: url)
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
