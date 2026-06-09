import Foundation

/// Stable per-install identifier used to attribute cloud writes (last-write-wins authority is
/// `(updatedAtClient, deviceId)`). Stored in UserDefaults so it survives launches but NOT reinstalls
/// (a fresh install should look like a new device for sync purposes).
enum DeviceID {
    private static let key = "vani.deviceId.v1"

    static let current: String = {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let new = UUID().uuidString
        defaults.set(new, forKey: key)
        return new
    }()
}
