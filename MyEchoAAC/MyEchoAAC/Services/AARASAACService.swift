import Foundation
import UIKit
import os.log

/// ARASAAC pictogram search and download.
///
/// ARASAAC (arasaac.org) is an open AAC symbol set created by the Government of Aragón (Spain),
/// licensed CC BY-NC-SA. Over 12,000 pictograms are available free for non-commercial use.
/// Attribution: Sergio Palao / ARASAAC (arasaac.org).
struct AARASAACResult: Identifiable {
    let id: Int
    let keyword: String
}

enum AARASAACService {
    private static let logger = Logger(subsystem: "com.myecho.aac", category: "AARASAACService")

    // MARK: - URL helpers (testable without networking)

    static func searchURL(for query: String) -> URL {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
        return URL(string: "https://api.arasaac.org/api/pictograms/en/search/\(encoded)")!
    }

    static func imageURL(for id: Int) -> URL {
        URL(string: "https://static.arasaac.org/pictograms/\(id)/\(id)_300.png")!
    }

    // MARK: - Parsing (testable without networking)

    static func parseSearchResponse(_ data: Data) throws -> [AARASAACResult] {
        struct Entry: Decodable {
            let _id: Int
            let keywords: [Keyword]
            struct Keyword: Decodable {
                let keyword: String
            }
        }
        let entries = try JSONDecoder().decode([Entry].self, from: data)
        return entries.compactMap { entry in
            guard let kw = entry.keywords.first else { return nil }
            return AARASAACResult(id: entry._id, keyword: kw.keyword)
        }
    }

    // MARK: - Network

    /// Search ARASAAC for pictograms matching `query`. Returns up to 30 results.
    static func search(_ query: String) async throws -> [AARASAACResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let url = searchURL(for: trimmed)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let results = try parseSearchResponse(data)
        return Array(results.prefix(30))
    }

    /// Download a pictogram image and save it to `ImageStore`. Returns the stored filename.
    /// Throws on network error or if the image can't be decoded.
    static func downloadImage(id: Int) async throws -> String {
        let url = imageURL(for: id)
        var lastError: Error = URLError(.unknown)
        for attempt in 1...3 {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                guard let uiImage = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                guard let filename = ImageStore.save(uiImage) else {
                    throw URLError(.cannotCreateFile)
                }
                return filename
            } catch {
                lastError = error
                if attempt < 3 {
                    logger.warning("ARASAAC download attempt \(attempt) failed: \(error.localizedDescription)")
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                }
            }
        }
        throw lastError
    }
}
