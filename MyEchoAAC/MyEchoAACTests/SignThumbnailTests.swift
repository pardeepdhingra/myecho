import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("SignThumbnail")
struct SignThumbnailTests {

    // MARK: - AACWord Codable round-trip

    @Test("signThumbnailPath encodes and decodes")
    func signThumbnailPathEncodesAndDecodes() throws {
        var word = AACWord(
            label: "hello",
            symbol: "👋",
            category: AACWord.coreCategory,
            colorName: .blue,
            position: 0
        )
        word.signThumbnailPath = "sign-thumbs/hello.jpg"

        let data = try JSONEncoder().encode(word)
        let decoded = try JSONDecoder().decode(AACWord.self, from: data)

        #expect(decoded.signThumbnailPath == "sign-thumbs/hello.jpg")
    }

    @Test("signThumbnailPath defaults to nil on fresh word")
    func signThumbnailPathDefaultsToNil() {
        let word = AACWord(
            label: "hello",
            symbol: "👋",
            category: AACWord.coreCategory,
            colorName: .blue,
            position: 0
        )
        #expect(word.signThumbnailPath == nil)
    }

    @Test("signThumbnailPath is nil when key missing in JSON (backward compat)")
    func signThumbnailPathMissingKeyDecodesToNil() throws {
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "label": "hello",
          "phrase": "hello",
          "symbol": "👋",
          "category": "Core",
          "colorName": "blue",
          "position": 0,
          "isVisible": true,
          "isFavorite": false,
          "wordForms": []
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AACWord.self, from: data)
        #expect(decoded.signThumbnailPath == nil)
    }

    // MARK: - AACStore persistence

    @Test("AACStore round-trips signThumbnailPath")
    func aacStoreRoundTripsSignThumbnailPath() {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)

        guard var word = store.words.first else {
            Issue.record("No words in store")
            return
        }
        word.signThumbnailPath = "sign-thumbs/test.jpg"
        store.upsert(word)

        let store2 = AACStore(defaults: defaults)
        let loaded = store2.words.first(where: { $0.id == word.id })
        #expect(loaded?.signThumbnailPath == "sign-thumbs/test.jpg")
    }

    @Test("signThumbnailPath is independent of signVideoPath")
    func thumbnailAndVideoAreIndependent() throws {
        var word = AACWord(
            label: "run",
            symbol: "🏃",
            category: AACWord.coreCategory,
            colorName: .green,
            position: 0
        )
        word.signVideoPath = "videos/run.mp4"
        word.signThumbnailPath = "sign-thumbs/run.jpg"

        let data = try JSONEncoder().encode(word)
        let decoded = try JSONDecoder().decode(AACWord.self, from: data)

        #expect(decoded.signVideoPath == "videos/run.mp4")
        #expect(decoded.signThumbnailPath == "sign-thumbs/run.jpg")
    }
}
