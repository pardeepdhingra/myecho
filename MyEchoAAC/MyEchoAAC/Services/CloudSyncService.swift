import Combine
import Foundation
import os

/// Orchestrates board + asset sync (Part B of CLOUD_SYNC_PLAN.md). The engine is fully implemented
/// here against the `CloudBackend` protocol; Firebase only supplies the backend, so this logic builds
/// and can be unit-tested with a fake backend even when the SDK is absent (`backend == nil` →
/// `.disabled`, the app stays offline).
@MainActor
final class CloudSyncService: ObservableObject {
    @Published private(set) var status: SyncStatus
    /// Set when a first sign-in finds BOTH a remote board and non-default local data — the UI must ask
    /// the user whether to keep this device's board or use the cloud board.
    @Published var pendingReconcile = false

    private let auth: AuthService
    private let store: AACStore
    private let history: UsageHistory
    private let backend: CloudBackend?
    private let logger = Logger(subsystem: "com.pardeepdhingra.vani", category: "CloudSync")

    private var cancellables = Set<AnyCancellable>()
    private var pushTask: Task<Void, Never>?
    private var boardListener: CloudListenerToken?
    private var isApplyingRemote = false
    private var activeUID: String?

    private var lastContentHash: String?
    private var lastUpdatedAtClient: Date = .distantPast
    private var pendingRemote: RemoteBoard?

    private let debounceNanos: UInt64 = 3_000_000_000

    var isAvailable: Bool { backend != nil }

    init(auth: AuthService, store: AACStore, history: UsageHistory, backend: CloudBackend?) {
        self.auth = auth
        self.store = store
        self.history = history
        self.backend = backend
        status = backend == nil ? .disabled : .signedOut
    }

    // MARK: Lifecycle

    func start() {
        guard backend != nil else { return }

        auth.$state
            .sink { [weak self] state in
                Task { @MainActor in self?.handleAuthChange(state) }
            }
            .store(in: &cancellables)

        // Any local change to the synced stores schedules a debounced upload.
        store.$words.dropFirst().sink { [weak self] _ in
            Task { @MainActor in self?.scheduleDebouncedPush() }
        }.store(in: &cancellables)
        store.$settings.dropFirst().sink { [weak self] _ in
            Task { @MainActor in self?.scheduleDebouncedPush() }
        }.store(in: &cancellables)
        store.$quickPhrases.dropFirst().sink { [weak self] _ in
            Task { @MainActor in self?.scheduleDebouncedPush() }
        }.store(in: &cancellables)
        history.$entries.dropFirst().sink { [weak self] _ in
            Task { @MainActor in self?.scheduleDebouncedPush() }
        }.store(in: &cancellables)
        history.$spokenSentences.dropFirst().sink { [weak self] _ in
            Task { @MainActor in self?.scheduleDebouncedPush() }
        }.store(in: &cancellables)

        handleAuthChange(auth.state)
    }

    private func handleAuthChange(_ state: AuthState) {
        guard backend != nil else { return }
        switch state {
        case .signedOut, .signingIn:
            teardownSession()
            status = .signedOut
        case let .signedIn(uid, _):
            guard uid != activeUID else { return }
            activeUID = uid
            Task { await onSignedIn(uid: uid) }
        }
    }

    private func teardownSession() {
        boardListener?.remove()
        boardListener = nil
        pushTask?.cancel()
        pushTask = nil
        activeUID = nil
        pendingRemote = nil
        pendingReconcile = false
        lastContentHash = nil
        lastUpdatedAtClient = .distantPast
    }

    // MARK: First sign-in reconcile

    private func onSignedIn(uid: String) async {
        guard let backend else { return }
        status = .syncing
        loadHighWaterMark(uid: uid)
        do {
            if let remote = try await backend.loadBoard(uid: uid) {
                if isLocalBoardPristine() {
                    try await applyRemote(remote, uid: uid)
                } else if remote.contentHash == currentLocalContentHash() {
                    adopt(remote, uid: uid)
                } else {
                    pendingRemote = remote
                    pendingReconcile = true
                    status = .pending
                }
            } else {
                try await pushNow(uid: uid)
            }
            startBoardListener(uid: uid)
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    /// User's answer to the first-sign-in conflict prompt.
    func resolveReconcile(useCloud: Bool) {
        guard let uid = auth.state.uid else { return }
        let remote = pendingRemote
        pendingRemote = nil
        pendingReconcile = false
        Task {
            do {
                if useCloud, let remote {
                    try await applyRemote(remote, uid: uid)
                } else {
                    try await pushNow(uid: uid)
                }
                startBoardListener(uid: uid)
            } catch {
                status = .error(error.localizedDescription)
            }
        }
    }

    // MARK: Manual controls (Phase 1 buttons)

    func syncNow() {
        guard let uid = auth.state.uid else { return }
        Task {
            do { try await pushNow(uid: uid) }
            catch { status = .error(error.localizedDescription) }
        }
    }

    func restoreFromCloud() {
        guard let uid = auth.state.uid, let backend else { return }
        Task {
            do {
                status = .syncing
                if let remote = try await backend.loadBoard(uid: uid) {
                    try await applyRemote(remote, uid: uid)
                } else {
                    status = .synced(Date())
                }
            } catch {
                status = .error(error.localizedDescription)
            }
        }
    }

    // MARK: Push

    private func scheduleDebouncedPush() {
        guard backend != nil, auth.state.isSignedIn, !isApplyingRemote else { return }
        pushTask?.cancel()
        status = .pending
        pushTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.debounceNanos ?? 3_000_000_000)
            guard !Task.isCancelled, let self, let uid = self.auth.state.uid else { return }
            do { try await self.pushNow(uid: uid) }
            catch { self.status = .error(error.localizedDescription) }
        }
    }

    private func pushNow(uid: String) async throws {
        guard let backend else { throw CloudError.notConfigured }
        let fields = currentFields()
        let hash = BoardCodec.contentHash(fields)
        if hash == lastContentHash {
            status = .synced(Date())
            return
        }
        status = .syncing
        let stamp = max(Date(), lastUpdatedAtClient.addingTimeInterval(0.001))
        try await backend.writeBoard(uid: uid, fields: fields, updatedAtClient: stamp,
                                     deviceId: DeviceID.current, schemaVersion: CloudSchema.version)
        try await reconcileAssets(words: store.words, uid: uid, backend: backend)
        lastContentHash = hash
        lastUpdatedAtClient = stamp
        saveHighWaterMark(uid: uid)
        status = .synced(Date())
    }

    // MARK: Pull / apply

    private func startBoardListener(uid: String) {
        guard let backend, boardListener == nil else { return }
        boardListener = backend.listenBoard(uid: uid) { [weak self] remote in
            Task { @MainActor in self?.handleRemote(remote) }
        }
    }

    private func handleRemote(_ remote: RemoteBoard?) {
        guard let remote, let uid = auth.state.uid else { return }
        if remote.hasPendingWrites { return }                 // our own write echoing from cache
        if remote.deviceId == DeviceID.current { return }
        if remote.contentHash == lastContentHash { return }
        if remote.updatedAtClient <= lastUpdatedAtClient { return }
        Task {
            do { try await applyRemote(remote, uid: uid) }
            catch { status = .error(error.localizedDescription) }
        }
    }

    private func applyRemote(_ remote: RemoteBoard, uid: String) async throws {
        guard let backend else { return }
        if remote.schemaVersion > CloudSchema.version {
            status = .error(CloudError.schemaTooNew.localizedDescription)
            return
        }
        status = .syncing
        guard let snapshot = BoardCodec.snapshot(from: remote.fields,
                                                 preservingVoiceIdentifier: store.settings.voiceIdentifier) else {
            throw NSError(domain: "Vani.Cloud", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Could not read the cloud board."])
        }
        try await downloadAssets(for: snapshot.words, uid: uid, backend: backend)

        isApplyingRemote = true
        store.replaceAll(words: snapshot.words, quickPhrases: snapshot.quickPhrases, settings: snapshot.settings)
        history.importAll(entries: snapshot.usageEntries, spokenSentences: snapshot.spokenSentences)
        isApplyingRemote = false

        lastContentHash = remote.contentHash
        lastUpdatedAtClient = remote.updatedAtClient
        saveHighWaterMark(uid: uid)
        status = .synced(Date())
    }

    private func adopt(_ remote: RemoteBoard, uid: String) {
        lastContentHash = remote.contentHash
        lastUpdatedAtClient = remote.updatedAtClient
        saveHighWaterMark(uid: uid)
        status = .synced(Date())
    }

    // MARK: Assets

    private struct LocalAsset {
        let filename: String
        let kind: AssetKind
        let localURL: URL
    }

    private func referencedLocalAssets(_ words: [AACWord]) -> [LocalAsset] {
        var out: [LocalAsset] = []
        for word in words {
            if let img = word.imagePath, ImageStore.exists(img) {
                out.append(LocalAsset(filename: img, kind: .image, localURL: ImageStore.fileURL(for: img)))
            }
            if let vid = word.signVideoPath, SignVideoStore.exists(vid) {
                out.append(LocalAsset(filename: vid, kind: .signVideo, localURL: SignVideoStore.fileURL(for: vid)))
                if SignVideoStore.thumbnailExists(for: vid) {
                    let thumb = (vid as NSString).deletingPathExtension + ".jpg"
                    out.append(LocalAsset(filename: thumb, kind: .signThumb,
                                          localURL: SignVideoStore.thumbnailFileURL(for: vid)))
                }
            }
        }
        return out
    }

    private func reconcileAssets(words: [AACWord], uid: String, backend: CloudBackend) async throws {
        let local = referencedLocalAssets(words)
        let localNames = Set(local.map(\.filename))
        let remote = (try? await backend.loadAssetIndex(uid: uid)) ?? []
        let remoteNames = Set(remote.map(\.filename))

        for asset in local where !remoteNames.contains(asset.filename) {
            let path = BoardCodec.storagePath(uid: uid, kind: asset.kind, filename: asset.filename)
            let size = try await backend.uploadAsset(localURL: asset.localURL, storagePath: path)
            try await backend.writeAssetMeta(uid: uid, asset: CloudAsset(
                filename: asset.filename, kind: asset.kind, storagePath: path,
                updatedAtClient: Date(), deviceId: DeviceID.current, sizeBytes: size))
        }

        for asset in remote where !localNames.contains(asset.filename) {
            try? await backend.deleteAsset(storagePath: asset.storagePath)
            try? await backend.deleteAssetMeta(uid: uid, filename: asset.filename)
        }
    }

    private func downloadAssets(for words: [AACWord], uid: String, backend: CloudBackend) async throws {
        let remote = (try? await backend.loadAssetIndex(uid: uid)) ?? []
        var remoteByName: [String: CloudAsset] = [:]
        for asset in remote { remoteByName[asset.filename] = asset }

        for word in words {
            if let img = word.imagePath, !ImageStore.exists(img), let meta = remoteByName[img] {
                try await backend.downloadAsset(storagePath: meta.storagePath, to: ImageStore.fileURL(for: img))
            }
            if let vid = word.signVideoPath {
                if !SignVideoStore.exists(vid), let meta = remoteByName[vid] {
                    try await backend.downloadAsset(storagePath: meta.storagePath, to: SignVideoStore.fileURL(for: vid))
                }
                let thumb = (vid as NSString).deletingPathExtension + ".jpg"
                if !SignVideoStore.thumbnailExists(for: vid), let meta = remoteByName[thumb] {
                    try await backend.downloadAsset(storagePath: meta.storagePath,
                                                    to: SignVideoStore.thumbnailFileURL(for: vid))
                }
            }
        }
    }

    // MARK: Helpers

    private func currentFields() -> BoardFields {
        BoardCodec.fields(
            words: store.words,
            quickPhrases: store.quickPhrases,
            settings: store.settings,
            usageEntries: history.entries,
            spokenSentences: history.spokenSentences
        )
    }

    private func currentLocalContentHash() -> String {
        BoardCodec.contentHash(currentFields())
    }

    private func isLocalBoardPristine() -> Bool {
        let defaultLabels = Set(AACStore.defaultWords.map(\.label))
        let localLabels = Set(store.words.map(\.label))
        let noMedia = store.words.allSatisfy { $0.imagePath == nil && $0.signVideoPath == nil }
        return store.words.count <= AACStore.defaultWords.count
            && localLabels.isSubset(of: defaultLabels)
            && noMedia
            && history.entries.isEmpty
    }

    private func hwmKey(_ uid: String) -> String { "vani.sync.hwm.\(uid)" }
    private func hashKey(_ uid: String) -> String { "vani.sync.hash.\(uid)" }

    private func loadHighWaterMark(uid: String) {
        let d = UserDefaults.standard
        lastUpdatedAtClient = (d.object(forKey: hwmKey(uid)) as? Date) ?? .distantPast
        lastContentHash = d.string(forKey: hashKey(uid))
    }

    private func saveHighWaterMark(uid: String) {
        let d = UserDefaults.standard
        d.set(lastUpdatedAtClient, forKey: hwmKey(uid))
        if let lastContentHash { d.set(lastContentHash, forKey: hashKey(uid)) }
    }
}
