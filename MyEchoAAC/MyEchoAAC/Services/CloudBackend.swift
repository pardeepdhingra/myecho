import Foundation

/// Abstraction over the auth provider so the rest of the app never imports Firebase directly. The real
/// implementation lives behind `#if canImport(FirebaseAuth)` in FirebaseBackend.swift; when the SDK is
/// absent there is no implementation and the cloud layer reports `.disabled`.
protocol AuthBackend: Sendable {
    func currentUID() -> String?
    func currentEmail() -> String?
    /// Calls back with (uid, email); uid is nil when signed out. Fired on the listener thread.
    func addStateListener(_ onChange: @escaping @Sendable (String?, String?) -> Void)

    func signUp(email: String, password: String) async throws -> String
    func signIn(email: String, password: String) async throws -> String
    func sendPasswordReset(email: String) async throws
    /// Apple sign-in completes a Firebase OAuth credential from an Apple identity token + raw nonce.
    func signInWithApple(idToken: String, rawNonce: String) async throws -> String
    func signOut() throws
}

/// Token returned by a board listener so the caller can detach it.
final class CloudListenerToken: @unchecked Sendable {
    private let onRemove: () -> Void
    init(onRemove: @escaping () -> Void) { self.onRemove = onRemove }
    func remove() { onRemove() }
}

/// Abstraction over Firestore + Storage. Implemented behind `#if canImport(FirebaseFirestore)`.
protocol CloudBackend: Sendable {
    // Board document
    func loadBoard(uid: String) async throws -> RemoteBoard?
    func writeBoard(uid: String, fields: BoardFields, updatedAtClient: Date, deviceId: String, schemaVersion: Int) async throws
    func listenBoard(uid: String, onChange: @escaping @Sendable (RemoteBoard?) -> Void) -> CloudListenerToken

    // Asset index (one doc per binary, for reconciliation + GC)
    func loadAssetIndex(uid: String) async throws -> [CloudAsset]
    func writeAssetMeta(uid: String, asset: CloudAsset) async throws
    func deleteAssetMeta(uid: String, filename: String) async throws

    // Storage objects
    func uploadAsset(localURL: URL, storagePath: String) async throws -> Int
    func downloadAsset(storagePath: String, to localURL: URL) async throws
    func deleteAsset(storagePath: String) async throws
}

/// Bundle of backends for one app session. `nil` when Firebase isn't available/configured.
struct CloudBackends {
    let auth: AuthBackend
    let cloud: CloudBackend
}
