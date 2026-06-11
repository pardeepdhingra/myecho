import AVFoundation
import CoreMedia
import Foundation
import UIKit
import os

struct SignResult: Identifiable, Equatable, Sendable {
    let id: String
    let word: String
    let language: SignLanguage
    let previewURL: URL
    let pageURL: URL
}

enum SignSearchError: Error, LocalizedError {
    case invalidWord
    case notFound(language: SignLanguage)
    case network(String)
    case unsupported

    var errorDescription: String? {
        switch self {
        case .invalidWord: "Please type a word to look up."
        case .notFound(let language): "No \(language.label) sign found for that word."
        case .network(let message): message
        case .unsupported: "This sign language is not supported yet."
        }
    }
}

struct SignSearchService: Sendable {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.pardeepdhingra.vani", category: "SignSearch")

    init(session: URLSession = .shared) {
        self.session = session
    }

    func lookup(_ rawWord: String, language: SignLanguage) async throws -> [SignResult] {
        let word = rawWord
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !word.isEmpty else { throw SignSearchError.invalidWord }

        switch language {
        case .auslan: return try await lookupAuslan(word: word)
        case .asl: return try await lookupASL(word: word)
        }
    }

    // MARK: - Auslan

    private func lookupAuslan(word: String) async throws -> [SignResult] {
        let slugs = candidateAuslanSlugs(for: word)
        var seen = Set<String>()
        var results: [SignResult] = []
        for slug in slugs {
            guard let pageURL = URL(string: "https://www.auslan.org.au/dictionary/words/\(slug).html") else { continue }
            do {
                let (data, response) = try await session.data(from: pageURL)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }
                let html = String(decoding: data, as: UTF8.self)
                let videoURLs = extractMP4URLs(from: html)
                for videoString in videoURLs {
                    guard let videoURL = URL(string: videoString) else { continue }
                    if seen.insert(videoString).inserted {
                        results.append(SignResult(
                            id: "auslan|\(videoString)",
                            word: word,
                            language: .auslan,
                            previewURL: videoURL,
                            pageURL: pageURL
                        ))
                    }
                    if results.count >= 4 { break }
                }
                if !results.isEmpty { break }
            } catch {
                logger.warning("Auslan lookup error for \(slug, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
        if results.isEmpty { throw SignSearchError.notFound(language: .auslan) }
        return results
    }

    private func candidateAuslanSlugs(for word: String) -> [String] {
        let base = word
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
        var slugs: [String] = []
        for variant in [base, "\(base)1"] {
            for n in 1...3 {
                slugs.append("\(variant)-\(n)")
            }
            slugs.append(variant)
        }
        return slugs
    }

    // MARK: - ASL

    private func lookupASL(word: String) async throws -> [SignResult] {
        let slug = word
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
        guard let pageURL = URL(string: "https://www.signasl.org/sign/\(slug)") else {
            throw SignSearchError.invalidWord
        }
        do {
            let (data, response) = try await session.data(from: pageURL)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw SignSearchError.notFound(language: .asl)
            }
            let html = String(decoding: data, as: UTF8.self)
            let videoURLs = extractMP4URLs(from: html)
                .filter { $0.contains("media.signbsl.com") || $0.contains("signasl.org") }
            var seen = Set<String>()
            var results: [SignResult] = []
            for videoString in videoURLs {
                guard let videoURL = URL(string: videoString) else { continue }
                if seen.insert(videoString).inserted {
                    results.append(SignResult(
                        id: "asl|\(videoString)",
                        word: word,
                        language: .asl,
                        previewURL: videoURL,
                        pageURL: pageURL
                    ))
                }
                if results.count >= 4 { break }
            }
            if results.isEmpty { throw SignSearchError.notFound(language: .asl) }
            return results
        } catch let error as SignSearchError {
            throw error
        } catch {
            throw SignSearchError.network(error.localizedDescription)
        }
    }

    // MARK: - HTML extraction

    private func extractMP4URLs(from html: String) -> [String] {
        let pattern = #"https?://[^\s"'<>]+\.mp4"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        var ordered: [String] = []
        var seen = Set<String>()
        for match in matches {
            guard let r = Range(match.range, in: html) else { continue }
            let urlString = String(html[r])
            if seen.insert(urlString).inserted {
                ordered.append(urlString)
            }
        }
        return ordered
    }
}

actor SignDownloader {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.pardeepdhingra.vani", category: "SignDownloader")

    init(session: URLSession = .shared) {
        self.session = session
    }

    func download(_ url: URL) async throws -> String {
        var lastError: Error = SignSearchError.network("Download failed.")
        for attempt in 1...3 {
            do {
                return try await attemptDownload(url)
            } catch {
                lastError = error
                if attempt < 3 {
                    logger.warning("Download attempt \(attempt) failed, retrying: \(error.localizedDescription, privacy: .public)")
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            }
        }
        throw lastError
    }

    private func attemptDownload(_ url: URL) async throws -> String {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw SignSearchError.network("Could not download sign video.")
        }
        guard !data.isEmpty else {
            throw SignSearchError.network("Empty video file.")
        }
        guard let filename = SignVideoStore.save(data) else {
            throw SignSearchError.network("Failed to save sign video.")
        }
        logger.info("Saved sign video \(filename, privacy: .public) (\(data.count) bytes)")
        await generateThumbnail(for: filename)
        return filename
    }

    private func generateThumbnail(for filename: String) async {
        let videoURL = SignVideoStore.fileURL(for: filename)
        if let data = await SignThumbnailGenerator.makeFinalFrameJPEG(from: videoURL) {
            SignVideoStore.saveThumbnail(data, for: filename)
        } else {
            logger.warning("Failed to generate thumbnail for \(filename, privacy: .public)")
        }
    }
}

enum SignThumbnailGenerator {
    static func makeFinalFrameJPEG(from videoURL: URL) async -> Data? {
        let asset = AVURLAsset(url: videoURL)
        do {
            let duration = try await asset.load(.duration)
            let totalSeconds = CMTimeGetSeconds(duration)
            let targetSeconds = max(0, totalSeconds - 0.2)
            let target = CMTime(seconds: targetSeconds, preferredTimescale: 600)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
            generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)
            let (cgImage, _) = try await generator.image(at: target)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: 0.85)
        } catch {
            return nil
        }
    }
}
