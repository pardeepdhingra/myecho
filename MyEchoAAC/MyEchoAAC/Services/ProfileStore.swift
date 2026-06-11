import Foundation

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var profiles: [ChildProfile]
    @Published private(set) var activeProfileId: UUID

    private let profilesKey = "vani.profiles.v1"
    private let activeIdKey = "vani.activeProfileId.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let resolvedProfiles: [ChildProfile]
        if let data = defaults.data(forKey: "vani.profiles.v1"),
           let stored = try? JSONDecoder().decode([ChildProfile].self, from: data),
           !stored.isEmpty {
            resolvedProfiles = stored
        } else {
            resolvedProfiles = [ChildProfile(name: "My Child", emoji: "⭐️", isDefault: true)]
        }
        profiles = resolvedProfiles

        if let idString = defaults.string(forKey: "vani.activeProfileId.v1"),
           let uuid = UUID(uuidString: idString),
           resolvedProfiles.contains(where: { $0.id == uuid }) {
            activeProfileId = uuid
        } else {
            activeProfileId = resolvedProfiles.first!.id
        }
    }

    var activeProfile: ChildProfile? {
        profiles.first(where: { $0.id == activeProfileId })
    }

    func userDefaults(for profile: ChildProfile) -> UserDefaults? {
        if profile.isDefault { return defaults }
        let suiteName = "vani.profile.\(profile.id.uuidString)"
        return UserDefaults(suiteName: suiteName)
    }

    func addProfile(name: String, emoji: String) {
        let profile = ChildProfile(name: name, emoji: emoji, isDefault: false)
        profiles.append(profile)
        save()
    }

    func activate(_ profile: ChildProfile) {
        activeProfileId = profile.id
        defaults.set(profile.id.uuidString, forKey: activeIdKey)
    }

    func deleteProfile(_ profile: ChildProfile) {
        guard !profile.isDefault else { return }
        let suiteName = "vani.profile.\(profile.id.uuidString)"
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        profiles.removeAll { $0.id == profile.id }
        if activeProfileId == profile.id {
            activeProfileId = profiles.first!.id
            defaults.set(profiles.first!.id.uuidString, forKey: activeIdKey)
        }
        save()
    }

    func updateName(_ name: String, emoji: String, for profile: ChildProfile) {
        guard let i = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[i].name = name
        profiles[i].emoji = emoji
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: profilesKey)
        }
    }
}
