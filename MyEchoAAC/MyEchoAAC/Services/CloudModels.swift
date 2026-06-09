import CryptoKit
import Foundation

// MARK: - Contract constants (Part A of CLOUD_SYNC_PLAN.md)

enum CloudSchema {
    static let version = 1
    static let usersCollection = "users"
    static let boardCollection = "board"
    static let boardDoc = "current"
    static let assetsCollection = "assets"
}

// MARK: - Auth & sync UI state (always available, regardless of Firebase)

enum AuthState: Equatable, Sendable {
    case signedOut
    case signingIn
    case signedIn(uid: String, email: String?)

    var uid: String? {
        if case let .signedIn(uid, _) = self { return uid }
        return nil
    }

    var isSignedIn: Bool { uid != nil }
}

enum SyncStatus: Equatable, Sendable {
    case disabled          // Firebase not compiled/configured in this build
    case signedOut
    case idle
    case syncing
    case synced(Date)
    case pending
    case error(String)
}

enum CloudError: LocalizedError {
    case notConfigured
    case notSignedIn
    case schemaTooNew

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Cloud sync isn't set up in this build."
        case .notSignedIn: "You need to sign in first."
        case .schemaTooNew: "This board was saved by a newer version of the app. Please update."
        }
    }
}

// MARK: - Assets

enum AssetKind: String, Sendable, Codable {
    case image
    case signVideo
    case signThumb

    /// Documents subfolder that mirrors the Storage subfolder.
    var localSubfolder: String {
        switch self {
        case .image: "word-images"
        case .signVideo, .signThumb: "sign-videos"
        }
    }
}

struct CloudAsset: Sendable, Equatable {
    var filename: String
    var kind: AssetKind
    var storagePath: String
    var updatedAtClient: Date
    var deviceId: String
    var sizeBytes: Int
}

// MARK: - Board over-the-wire shapes

/// The five JSON-string fields that make up `/users/{uid}/board/current`.
struct BoardFields: Sendable, Equatable {
    var wordsJSON: String
    var quickPhrasesJSON: String
    var settingsJSON: String
    var usageEntriesJSON: String
    var spokenSentencesJSON: String
}

/// A board read back from the cloud, with metadata for last-write-wins + echo suppression.
struct RemoteBoard: Sendable {
    var fields: BoardFields
    var updatedAtClient: Date
    var deviceId: String
    var schemaVersion: Int
    var hasPendingWrites: Bool

    var contentHash: String { BoardCodec.contentHash(fields) }
}

/// A fully decoded local snapshot, ready to apply into the stores.
struct BoardSnapshot: Sendable {
    var words: [AACWord]
    var quickPhrases: [QuickPhrase]
    var settings: AACSettings
    var usageEntries: [UsageHistory.Entry]
    var spokenSentences: [String]
}

// MARK: - Codec

enum BoardCodec {
    /// Shared encoder/decoder using ISO-8601 dates (RFC 3339) so `UsageEntry.timestamp` matches the
    /// cross-platform contract in Part A.
    static func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    static func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    /// Build the five JSON-string fields. `voiceIdentifier` is nulled out (it is device-specific and
    /// excluded from sync per Part A — each device keeps its own local voice choice).
    static func fields(
        words: [AACWord],
        quickPhrases: [QuickPhrase],
        settings: AACSettings,
        usageEntries: [UsageHistory.Entry],
        spokenSentences: [String]
    ) -> BoardFields {
        let encoder = makeEncoder()
        var settingsForCloud = settings
        settingsForCloud.voiceIdentifier = nil

        func encode<T: Encodable>(_ value: T) -> String {
            guard let data = try? encoder.encode(value) else { return "" }
            return String(data: data, encoding: .utf8) ?? ""
        }

        return BoardFields(
            wordsJSON: encode(words),
            quickPhrasesJSON: encode(quickPhrases),
            settingsJSON: encode(settingsForCloud),
            usageEntriesJSON: encode(usageEntries),
            spokenSentencesJSON: encode(spokenSentences)
        )
    }

    /// Decode fields into a snapshot. `localVoiceIdentifier` is preserved into the decoded settings so a
    /// pulled board never clobbers the device's own voice choice.
    static func snapshot(from fields: BoardFields, preservingVoiceIdentifier localVoiceIdentifier: String?) -> BoardSnapshot? {
        let decoder = makeDecoder()

        func decode<T: Decodable>(_ type: T.Type, _ json: String) -> T? {
            guard let data = json.data(using: .utf8) else { return nil }
            return try? decoder.decode(type, from: data)
        }

        guard
            let words = decode([AACWord].self, fields.wordsJSON),
            let quickPhrases = decode([QuickPhrase].self, fields.quickPhrasesJSON),
            var settings = decode(AACSettings.self, fields.settingsJSON),
            let usageEntries = decode([UsageHistory.Entry].self, fields.usageEntriesJSON),
            let spokenSentences = decode([String].self, fields.spokenSentencesJSON)
        else { return nil }

        settings.voiceIdentifier = localVoiceIdentifier

        return BoardSnapshot(
            words: words,
            quickPhrases: quickPhrases,
            settings: settings,
            usageEntries: usageEntries,
            spokenSentences: spokenSentences
        )
    }

    /// Stable hash over content only (excludes updatedAt/deviceId) — used to break restore→re-upload loops.
    static func contentHash(_ fields: BoardFields) -> String {
        let joined = [
            fields.wordsJSON,
            fields.quickPhrasesJSON,
            fields.settingsJSON,
            fields.usageEntriesJSON,
            fields.spokenSentencesJSON
        ].joined(separator: "\u{1F}")
        let digest = SHA256.hash(data: Data(joined.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: Storage paths (keyed by the existing local filenames — no path rewriting on restore)

    static func storagePath(uid: String, kind: AssetKind, filename: String) -> String {
        "\(CloudSchema.usersCollection)/\(uid)/\(kind.localSubfolder)/\(filename)"
    }
}
