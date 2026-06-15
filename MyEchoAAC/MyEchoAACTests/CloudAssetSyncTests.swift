import Foundation
import Testing
@testable import MyEchoAAC

/// Regression cover for the asset-sync error-handling fix: a failure to read the remote asset index
/// must abort the sync pass (propagate the error) rather than silently treating the cloud as empty,
/// which previously skipped media downloads and masked recoverable errors.
struct CloudAssetSyncTests {

    private struct IndexUnavailable: Error {}

    /// Backend whose asset-index read always fails. Tracks whether any storage side effects ran.
    private final class FailingIndexBackend: CloudBackend, @unchecked Sendable {
        private(set) var uploadCount = 0
        private(set) var downloadCount = 0
        private(set) var deleteAssetCount = 0

        func loadBoard(uid: String) async throws -> RemoteBoard? { nil }
        func writeBoard(uid: String, fields: BoardFields, updatedAtClient: Date, deviceId: String, schemaVersion: Int) async throws {}
        func listenBoard(uid: String, onChange: @escaping @Sendable (RemoteBoard?) -> Void) -> CloudListenerToken {
            CloudListenerToken(onRemove: {})
        }

        func loadAssetIndex(uid: String) async throws -> [CloudAsset] { throw IndexUnavailable() }
        func writeAssetMeta(uid: String, asset: CloudAsset) async throws {}
        func deleteAssetMeta(uid: String, filename: String) async throws {}

        func uploadAsset(localURL: URL, storagePath: String) async throws -> Int { uploadCount += 1; return 0 }
        func downloadAsset(storagePath: String, to localURL: URL) async throws { downloadCount += 1 }
        func deleteAsset(storagePath: String) async throws { deleteAssetCount += 1 }
    }

    @MainActor
    private func makeService(backend: CloudBackend) -> (CloudSyncService, AACStore) {
        let defaults = makeIsolatedDefaults()
        let store = AACStore(defaults: defaults)
        let history = UsageHistory(defaults: defaults)
        let auth = AuthService(backend: nil)
        let service = CloudSyncService(auth: auth, store: store, history: history, backend: backend)
        return (service, store)
    }

    @MainActor
    @Test("reconcileAssets propagates an asset-index failure without any storage side effects")
    func reconcileAbortsOnIndexFailure() async {
        let backend = FailingIndexBackend()
        let (service, store) = makeService(backend: backend)

        await #expect(throws: (any Error).self) {
            try await service.reconcileAssets(words: store.words, uid: "u1", backend: backend)
        }
        #expect(backend.uploadCount == 0)
        #expect(backend.deleteAssetCount == 0)
    }

    @MainActor
    @Test("downloadAssets propagates an asset-index failure instead of silently skipping media")
    func downloadAbortsOnIndexFailure() async {
        let backend = FailingIndexBackend()
        let (service, store) = makeService(backend: backend)

        await #expect(throws: (any Error).self) {
            try await service.downloadAssets(for: store.words, uid: "u1", backend: backend)
        }
        #expect(backend.downloadCount == 0)
    }
}
