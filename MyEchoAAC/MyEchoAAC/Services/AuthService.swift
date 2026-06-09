import AuthenticationServices
import CryptoKit
import Foundation

/// Optional account layer. Wraps an `AuthBackend` (Firebase when available). When no backend is
/// present the service simply stays `.signedOut` and `isAvailable` is false, so the app runs offline
/// exactly as before.
@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var state: AuthState

    private let backend: AuthBackend?
    private var currentAppleRawNonce: String?

    var isAvailable: Bool { backend != nil }

    init(backend: AuthBackend?) {
        self.backend = backend
        if let backend, let uid = backend.currentUID() {
            state = .signedIn(uid: uid, email: backend.currentEmail())
        } else {
            state = .signedOut
        }
        backend?.addStateListener { [weak self] uid, email in
            Task { @MainActor in
                guard let self else { return }
                self.state = uid.map { .signedIn(uid: $0, email: email) } ?? .signedOut
            }
        }
    }

    // MARK: Email / password

    func signUp(email: String, password: String) async throws {
        guard let backend else { throw CloudError.notConfigured }
        state = .signingIn
        do {
            let uid = try await backend.signUp(email: email, password: password)
            state = .signedIn(uid: uid, email: email)
        } catch {
            state = .signedOut
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        guard let backend else { throw CloudError.notConfigured }
        state = .signingIn
        do {
            let uid = try await backend.signIn(email: email, password: password)
            state = .signedIn(uid: uid, email: email)
        } catch {
            state = .signedOut
            throw error
        }
    }

    func sendPasswordReset(email: String) async throws {
        guard let backend else { throw CloudError.notConfigured }
        try await backend.sendPasswordReset(email: email)
    }

    // MARK: Sign in with Apple

    /// Configure the Apple request (call from `SignInWithAppleButton`'s `onRequest`).
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let raw = Self.randomNonceString()
        currentAppleRawNonce = raw
        request.requestedScopes = [.email]
        request.nonce = Self.sha256(raw)
    }

    /// Complete Apple sign-in (call from the button's `onCompletion` success case).
    func completeAppleSignIn(_ authorization: ASAuthorization) async throws {
        guard let backend else { throw CloudError.notConfigured }
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8),
            let rawNonce = currentAppleRawNonce
        else {
            throw NSError(domain: "Vani.Auth", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Apple sign-in returned no token."])
        }
        state = .signingIn
        do {
            let uid = try await backend.signInWithApple(idToken: idToken, rawNonce: rawNonce)
            let email = credential.email
            state = .signedIn(uid: uid, email: email)
            currentAppleRawNonce = nil
        } catch {
            state = .signedOut
            currentAppleRawNonce = nil
            throw error
        }
    }

    // MARK: Sign out

    func signOut() throws {
        try backend?.signOut()
        state = .signedOut
    }

    // MARK: Nonce helpers

    private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
