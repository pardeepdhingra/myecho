import Foundation

/// Boots the cloud layer and builds the Firebase-backed implementations. Everything Firebase-specific
/// is behind `#if canImport(...)`, so the project compiles with cloud `Disabled` until the Firebase SPM
/// packages are added. `configure()` is also a no-op when `GoogleService-Info.plist` is missing, so the
/// app never crashes from an unconfigured Firebase.
enum CloudBootstrap {
    #if canImport(FirebaseCore) && canImport(FirebaseAuth) && canImport(FirebaseFirestore) && canImport(FirebaseStorage)
    static func configure() {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    static func makeBackends() -> CloudBackends? {
        guard FirebaseApp.app() != nil else { return nil }
        return CloudBackends(auth: FirebaseAuthBackend(), cloud: FirebaseCloudBackend())
    }
    #else
    static func configure() {}
    static func makeBackends() -> CloudBackends? { nil }
    #endif
}

#if canImport(FirebaseCore) && canImport(FirebaseAuth) && canImport(FirebaseFirestore) && canImport(FirebaseStorage)
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

struct FirebaseAuthBackend: AuthBackend {
    func currentUID() -> String? { Auth.auth().currentUser?.uid }
    func currentEmail() -> String? { Auth.auth().currentUser?.email }

    func addStateListener(_ onChange: @escaping @Sendable (String?, String?) -> Void) {
        Auth.auth().addStateDidChangeListener { _, user in
            onChange(user?.uid, user?.email)
        }
    }

    func signUp(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func signInWithApple(idToken: String, rawNonce: String) async throws -> String {
        let credential = OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: rawNonce, fullName: nil)
        let result = try await Auth.auth().signIn(with: credential)
        return result.user.uid
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

struct FirebaseCloudBackend: CloudBackend {
    private var db: Firestore { Firestore.firestore() }
    private var storage: StorageReference { Storage.storage().reference() }

    private func boardRef(_ uid: String) -> DocumentReference {
        db.collection(CloudSchema.usersCollection).document(uid)
            .collection(CloudSchema.boardCollection).document(CloudSchema.boardDoc)
    }

    private func assetsRef(_ uid: String) -> CollectionReference {
        db.collection(CloudSchema.usersCollection).document(uid)
            .collection(CloudSchema.assetsCollection)
    }

    // MARK: Board

    func loadBoard(uid: String) async throws -> RemoteBoard? {
        let snap = try await boardRef(uid).getDocument()
        return Self.remoteBoard(from: snap)
    }

    func writeBoard(uid: String, fields: BoardFields, updatedAtClient: Date, deviceId: String, schemaVersion: Int) async throws {
        let data: [String: Any] = [
            "schemaVersion": schemaVersion,
            "updatedAt": FieldValue.serverTimestamp(),
            "updatedAtClient": Timestamp(date: updatedAtClient),
            "deviceId": deviceId,
            "wordsJSON": fields.wordsJSON,
            "quickPhrasesJSON": fields.quickPhrasesJSON,
            "settingsJSON": fields.settingsJSON,
            "usageEntriesJSON": fields.usageEntriesJSON,
            "spokenSentencesJSON": fields.spokenSentencesJSON
        ]
        try await boardRef(uid).setData(data, merge: true)
        try? await db.collection(CloudSchema.usersCollection).document(uid).setData([
            "lastDeviceId": deviceId,
            "schemaVersion": schemaVersion
        ], merge: true)
    }

    func listenBoard(uid: String, onChange: @escaping @Sendable (RemoteBoard?) -> Void) -> CloudListenerToken {
        let registration = boardRef(uid).addSnapshotListener { snap, _ in
            onChange(snap.flatMap(Self.remoteBoard(from:)))
        }
        return CloudListenerToken { registration.remove() }
    }

    private static func remoteBoard(from snap: DocumentSnapshot) -> RemoteBoard? {
        guard let data = snap.data() else { return nil }
        let fields = BoardFields(
            wordsJSON: data["wordsJSON"] as? String ?? "",
            quickPhrasesJSON: data["quickPhrasesJSON"] as? String ?? "",
            settingsJSON: data["settingsJSON"] as? String ?? "",
            usageEntriesJSON: data["usageEntriesJSON"] as? String ?? "",
            spokenSentencesJSON: data["spokenSentencesJSON"] as? String ?? ""
        )
        let updatedAtClient = (data["updatedAtClient"] as? Timestamp)?.dateValue() ?? .distantPast
        let deviceId = data["deviceId"] as? String ?? ""
        let schemaVersion = data["schemaVersion"] as? Int ?? CloudSchema.version
        return RemoteBoard(
            fields: fields,
            updatedAtClient: updatedAtClient,
            deviceId: deviceId,
            schemaVersion: schemaVersion,
            hasPendingWrites: snap.metadata.hasPendingWrites
        )
    }

    // MARK: Asset index

    func loadAssetIndex(uid: String) async throws -> [CloudAsset] {
        let snap = try await assetsRef(uid).getDocuments()
        return snap.documents.compactMap { doc in
            let data = doc.data()
            guard
                let filename = data["filename"] as? String,
                let kindRaw = data["kind"] as? String,
                let kind = AssetKind(rawValue: kindRaw),
                let storagePath = data["storagePath"] as? String
            else { return nil }
            return CloudAsset(
                filename: filename,
                kind: kind,
                storagePath: storagePath,
                updatedAtClient: (data["updatedAtClient"] as? Timestamp)?.dateValue() ?? .distantPast,
                deviceId: data["deviceId"] as? String ?? "",
                sizeBytes: data["sizeBytes"] as? Int ?? 0
            )
        }
    }

    func writeAssetMeta(uid: String, asset: CloudAsset) async throws {
        try await assetsRef(uid).document(asset.filename).setData([
            "filename": asset.filename,
            "kind": asset.kind.rawValue,
            "storagePath": asset.storagePath,
            "updatedAtClient": Timestamp(date: asset.updatedAtClient),
            "deviceId": asset.deviceId,
            "sizeBytes": asset.sizeBytes
        ], merge: true)
    }

    func deleteAssetMeta(uid: String, filename: String) async throws {
        try await assetsRef(uid).document(filename).delete()
    }

    // MARK: Storage

    func uploadAsset(localURL: URL, storagePath: String) async throws -> Int {
        let metadata = try await storage.child(storagePath).putFileAsync(from: localURL)
        return Int(metadata.size)
    }

    func downloadAsset(storagePath: String, to localURL: URL) async throws {
        try? FileManager.default.removeItem(at: localURL)
        _ = try await storage.child(storagePath).writeAsync(toFile: localURL)
    }

    func deleteAsset(storagePath: String) async throws {
        try await storage.child(storagePath).delete()
    }
}
#endif
