import Foundation
import Testing
@testable import MyEchoAAC

@Suite("AARASAACService")
struct AARASAACServiceTests {

    @Test func searchURLEncoded() throws {
        let url = AARASAACService.searchURL(for: "my turn")
        #expect(url.absoluteString.contains("my%20turn") || url.absoluteString.contains("my+turn"))
    }

    @Test func searchURLSchemeAndHost() throws {
        let url = AARASAACService.searchURL(for: "apple")
        #expect(url.scheme == "https")
        #expect(url.host == "api.arasaac.org")
    }

    @Test func imageURLContainsID() {
        let url = AARASAACService.imageURL(for: 3763)
        #expect(url.absoluteString.contains("3763"))
        #expect(url.absoluteString.contains("arasaac"))
    }

    @Test func parseSearchResponseExtractsResults() throws {
        let json = """
        [
            {"_id": 100, "keywords": [{"keyword": "apple", "type": 1, "plural": "apples", "meaning": ""}]},
            {"_id": 200, "keywords": [{"keyword": "banana", "type": 1, "plural": "bananas", "meaning": ""}]}
        ]
        """
        let data = Data(json.utf8)
        let results = try AARASAACService.parseSearchResponse(data)
        #expect(results.count == 2)
        #expect(results[0].id == 100)
        #expect(results[0].keyword == "apple")
        #expect(results[1].id == 200)
        #expect(results[1].keyword == "banana")
    }

    @Test func parseSearchResponseIgnoresEmptyKeywords() throws {
        let json = """
        [{"_id": 999, "keywords": []}]
        """
        let data = Data(json.utf8)
        let results = try AARASAACService.parseSearchResponse(data)
        #expect(results.isEmpty)
    }

    @Test func parseSearchResponseEmpty() throws {
        let json = "[]"
        let data = Data(json.utf8)
        let results = try AARASAACService.parseSearchResponse(data)
        #expect(results.isEmpty)
    }
}
