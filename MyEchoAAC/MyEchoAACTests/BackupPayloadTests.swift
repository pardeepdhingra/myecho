import Foundation
import Testing
import UIKit
@testable import MyEchoAAC

@Suite("Backup payload coding")
struct BackupPayloadTests {
    @Test("A full payload survives an encode/decode round trip")
    func roundTrip() throws {
        let word = AACWord(
            label: "swing",
            symbol: "🛝",
            category: "Play",
            colorName: .pink,
            position: 4,
            isFavorite: true,
            favoritePosition: 1,
            partOfSpeech: .noun
        )
        let phrase = QuickPhrase(text: "I need a break", position: 1, mode: .regulation, regulationKind: .calm)
        let payload = BackupPayload(
            version: 1,
            exportedAt: Date(timeIntervalSince1970: 1_750_000_000),
            words: [word],
            quickPhrases: [phrase],
            settings: .default,
            images: ["photo.jpg": "aGVsbG8="]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(BackupPayload.self, from: encoder.encode(payload))
        #expect(decoded.words == [word])
        #expect(decoded.quickPhrases == [phrase])
        #expect(decoded.images == payload.images)
        #expect(decoded.version == 1)
    }

    @Test("Word with signThumbnailPath survives backup round-trip")
    func signThumbnailPathRoundTrip() throws {
        var word = AACWord(
            label: "hello",
            symbol: "👋",
            category: AACWord.coreCategory,
            colorName: .blue,
            position: 0
        )
        word.signVideoPath = "videos/hello.mp4"
        word.signThumbnailPath = "abc123.jpg"

        let payload = BackupPayload(
            version: 1,
            exportedAt: Date(timeIntervalSince1970: 1_750_000_000),
            words: [word],
            quickPhrases: [],
            settings: .default,
            images: ["abc123.jpg": "aGVsbG8="]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(BackupPayload.self, from: encoder.encode(payload))
        #expect(decoded.words.first?.signThumbnailPath == "abc123.jpg")
        #expect(decoded.images["abc123.jpg"] == "aGVsbG8=")
    }

    @Test("Words from older boards decode with sensible defaults for missing keys")
    func lenientWordDecoding() throws {
        // The minimal shape an old/cross-platform board might export — no favorites,
        // no part of speech, no sign or symbol metadata.
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "label": "more",
            "phrase": "more",
            "symbol": "➕",
            "category": "Core",
            "colorName": "green",
            "position": 1,
            "isVisible": true
        }
        """
        let word = try JSONDecoder().decode(AACWord.self, from: Data(json.utf8))
        #expect(word.label == "more")
        #expect(word.isFavorite == false)
        #expect(word.partOfSpeech == nil)
        #expect(word.colorOverride == nil)
        #expect(word.signVideoPath == nil)
    }

    @Test("Quick phrases without a mode decode as speak-immediately")
    func lenientPhraseDecoding() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000002",
            "text": "I love you",
            "position": 3
        }
        """
        let phrase = try JSONDecoder().decode(QuickPhrase.self, from: Data(json.utf8))
        #expect(phrase.mode == .speak)
        #expect(phrase.regulationKind == nil)
    }

    @Test("apply() does not delete images that are not referenced by any word")
    @MainActor
    func applyDoesNotDeleteUnreferencedImages() throws {
        // Simulate a "scene image" that lives in ImageStore but isn't in any word
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        let img = renderer.image { ctx in ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4)) }
        let scenePath = try ImageStore.save(img)
        #expect(ImageStore.exists(scenePath))

        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        // The store has default words (no custom image paths), so apply should leave scenePath alone
        let payload = BackupPayload(
            version: 1,
            exportedAt: Date(timeIntervalSince1970: 1_750_000_000),
            words: store.words,
            quickPhrases: store.quickPhrases,
            settings: store.settings,
            images: [:]
        )
        BoardBackup.apply(payload, to: store)

        // The scene image must still exist — apply() only removes word-referenced images
        #expect(ImageStore.exists(scenePath))

        // Cleanup
        ImageStore.delete(scenePath)
    }
}
