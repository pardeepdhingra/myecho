import SwiftUI

@main
struct MyEchoAACApp: App {
    @StateObject private var store: AACStore
    @StateObject private var speech = SpeechService()
    @StateObject private var history: UsageHistory
    @StateObject private var auth: AuthService
    @StateObject private var sync: CloudSyncService

    init() {
        CloudBootstrap.configure()
        _ = DeviceID.current

        let s = AACStore()
        s.ensureRegulationDefaults()
        let h = UsageHistory()
        let backends = CloudBootstrap.makeBackends()
        let a = AuthService(backend: backends?.auth)
        let cs = CloudSyncService(auth: a, store: s, history: h, backend: backends?.cloud)

        _store = StateObject(wrappedValue: s)
        _history = StateObject(wrappedValue: h)
        _auth = StateObject(wrappedValue: a)
        _sync = StateObject(wrappedValue: cs)
    }

    var body: some Scene {
        WindowGroup {
            KidModeView()
                .environmentObject(store)
                .environmentObject(speech)
                .environmentObject(history)
                .environmentObject(auth)
                .environmentObject(sync)
                .tint(.indigo)
                .task { sync.start() }
        }
    }
}
