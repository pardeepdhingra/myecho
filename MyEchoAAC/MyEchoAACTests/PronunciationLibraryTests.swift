import Foundation
import Testing
@testable import MyEchoAAC

@MainActor
@Suite("PronunciationLibrary")
struct PronunciationLibraryTests {

    private func makeStore() -> AACStore {
        AACStore(defaults: makeIsolatedDefaults())
    }

    @Test func pronunciationOverridesEmptyByDefault() {
        let store = makeStore()
        #expect(store.settings.pronunciationOverrides.isEmpty)
    }

    @Test func addingOverridePersists() {
        let store = makeStore()
        store.settings.pronunciationOverrides["eat"] = "eet"
        #expect(store.settings.pronunciationOverrides["eat"] == "eet")
    }

    @Test func removingOverrideDisappears() {
        let store = makeStore()
        store.settings.pronunciationOverrides["drink"] = "drinkk"
        store.settings.pronunciationOverrides.removeValue(forKey: "drink")
        #expect(store.settings.pronunciationOverrides["drink"] == nil)
    }

    @Test func customOverrideLookupReturnsValue() {
        let overrides = ["mum": "mumm", "toilet": "toy let"]
        let result = PronunciationService.suggestion(for: "mum", customOverrides: overrides)
        #expect(result == "mumm")
    }

    @Test func customOverrideTakesPrecedenceOverBuiltIn() {
        // Built-in has "toilet" → "toy lit"; parent overrides with "toy let"
        let customOverrides = ["toilet": "toy let"]
        let result = PronunciationService.suggestion(for: "toilet", customOverrides: customOverrides)
        #expect(result == "toy let")
    }

    @Test func fallsBackToBuiltInWhenNoCustomOverride() {
        let result = PronunciationService.suggestion(for: "toilet", customOverrides: [:])
        #expect(result == "toy lit")
    }

    @Test func settingsRoundTripsWithOverrides() {
        let sharedDefaults = makeIsolatedDefaults()
        let store1 = AACStore(defaults: sharedDefaults)
        store1.settings.pronunciationOverrides["book"] = "buk"
        // didSet fires → saveSettings() writes to sharedDefaults

        let store2 = AACStore(defaults: sharedDefaults)
        #expect(store2.settings.pronunciationOverrides["book"] == "buk")
    }
}
