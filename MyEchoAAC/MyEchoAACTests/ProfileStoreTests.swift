import Testing
import Foundation
@testable import MyEchoAAC

@MainActor @Suite("ProfileStore")
struct ProfileStoreTests {

    // MARK: - Initialization

    @Test("ProfileStore starts with at least one profile")
    func startsWithDefaultProfile() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        #expect(store.profiles.count >= 1)
    }

    @Test("First profile is marked as default")
    func firstProfileIsDefault() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        #expect(store.profiles.first?.isDefault == true)
    }

    @Test("Active profile ID matches first profile on first run")
    func activeProfileMatchesFirstProfile() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        #expect(store.activeProfileId == store.profiles.first?.id)
    }

    // MARK: - Adding profiles

    @Test("addProfile appends a new profile")
    func addProfileAppends() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        let initial = store.profiles.count
        store.addProfile(name: "Aria", emoji: "🌟")
        #expect(store.profiles.count == initial + 1)
    }

    @Test("addProfile sets correct name and emoji")
    func addProfileSetsName() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        store.addProfile(name: "Aria", emoji: "🌟")
        let added = store.profiles.last!
        #expect(added.name == "Aria")
        #expect(added.emoji == "🌟")
    }

    @Test("new profile isDefault is false")
    func newProfileIsNotDefault() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        store.addProfile(name: "Leo", emoji: "🦁")
        #expect(store.profiles.last?.isDefault == false)
    }

    // MARK: - Switching profiles

    @Test("activate changes activeProfileId")
    func activateChangesId() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        store.addProfile(name: "Aria", emoji: "🌟")
        let newProfile = store.profiles.last!
        store.activate(newProfile)
        #expect(store.activeProfileId == newProfile.id)
    }

    @Test("activateDefaults returns standard defaults for default profile")
    func activeDefaultsForDefaultProfile() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        store.addProfile(name: "Second", emoji: "🐝")
        let second = store.profiles.last!
        let secondDefaults = store.userDefaults(for: second)
        #expect(secondDefaults != nil)
        #expect(secondDefaults !== defaults)
    }

    // MARK: - Deleting profiles

    @Test("deleteProfile removes it from the list")
    func deleteProfileRemoves() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        store.addProfile(name: "Temp", emoji: "🗑️")
        let toDelete = store.profiles.last!
        store.deleteProfile(toDelete)
        #expect(!store.profiles.contains(where: { $0.id == toDelete.id }))
    }

    @Test("cannot delete the default profile")
    func cannotDeleteDefaultProfile() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        let defaultProfile = store.profiles.first!
        store.deleteProfile(defaultProfile)
        #expect(store.profiles.contains(where: { $0.id == defaultProfile.id }))
    }

    @Test("deleting active profile falls back to default profile")
    func deletingActiveProfileFallsBack() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        store.addProfile(name: "Temp", emoji: "🗑️")
        let toDelete = store.profiles.last!
        store.activate(toDelete)
        store.deleteProfile(toDelete)
        #expect(store.activeProfileId == store.profiles.first?.id)
    }

    @Test("deleteProfile removes the profile's UserDefaults suite")
    func deleteProfileCleansUpSuite() {
        let defaults = makeIsolatedDefaults()
        let store = ProfileStore(defaults: defaults)
        store.addProfile(name: "Temp", emoji: "🗑️")
        let toDelete = store.profiles.last!

        let suiteName = "vani.profile.\(toDelete.id.uuidString)"
        let profileDefaults = UserDefaults(suiteName: suiteName)
        profileDefaults?.set("hello", forKey: "test-sentinel")
        profileDefaults?.synchronize()

        store.deleteProfile(toDelete)

        let afterDelete = UserDefaults(suiteName: suiteName)
        #expect(afterDelete?.string(forKey: "test-sentinel") == nil)
    }

    // MARK: - Persistence

    @Test("profiles persist across store instances")
    func profilesPersist() {
        let defaults = makeIsolatedDefaults()
        let store1 = ProfileStore(defaults: defaults)
        store1.addProfile(name: "Persistent", emoji: "💾")

        let store2 = ProfileStore(defaults: defaults)
        #expect(store2.profiles.contains(where: { $0.name == "Persistent" }))
    }

    // MARK: - AACStore reload

    @Test("AACStore.reload replaces words from new defaults")
    func aacStoreReloadReplacesWords() {
        let defaults1 = makeIsolatedDefaults()
        let defaults2 = makeIsolatedDefaults()

        let store1 = AACStore(defaults: defaults1)
        store1.words = [
            AACWord(label: "hello", phrase: "hello", symbol: "👋", category: "Core", colorName: .blue, position: 0)
        ]

        let store2 = AACStore(defaults: defaults2)
        store2.words = [
            AACWord(label: "world", phrase: "world", symbol: "🌍", category: "Core", colorName: .green, position: 0)
        ]

        store1.reload(from: defaults2)
        #expect(store1.words.first?.label == "world")
    }
}
