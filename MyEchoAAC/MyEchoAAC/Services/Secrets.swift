import Foundation
import Security

enum Secrets {
    private static let service = "com.pardeepdhingra.vani.secrets"
    private static let elevenLabsAccount = "elevenlabs_api_key"

    static var elevenLabsAPIKey: String? {
        loadKeychainValue(account: elevenLabsAccount)
    }

    static func setElevenLabsAPIKey(_ key: String?) {
        if let key, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            saveKeychainValue(key.trimmingCharacters(in: .whitespacesAndNewlines), account: elevenLabsAccount)
        } else {
            deleteKeychainValue(account: elevenLabsAccount)
        }
    }

    private static func saveKeychainValue(_ value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = baseQuery
            addQuery.merge(attributes) { current, _ in current }
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private static func loadKeychainValue(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func deleteKeychainValue(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
