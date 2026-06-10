import Foundation

/// A fresh, isolated UserDefaults suite per test so tests never touch the app's real data
/// and never see each other's state.
func makeIsolatedDefaults() -> UserDefaults {
    let suiteName = "vani.tests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        fatalError("Could not create test UserDefaults suite")
    }
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}
