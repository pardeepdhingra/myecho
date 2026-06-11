import SwiftUI

@main
struct MyEchoAACApp: App {
    @StateObject private var store: AACStore
    @StateObject private var speech = SpeechService()
    @StateObject private var history: UsageHistory
    @StateObject private var predictions = PredictionService()
    @StateObject private var auth: AuthService
    @StateObject private var sync: CloudSyncService

    init() {
        // UI-test hook: start from a known state (no first-run welcome sheet, fresh starter board).
        if ProcessInfo.processInfo.arguments.contains("--uitest") {
            UserDefaults.standard.set(true, forKey: "vani.welcomeSeen")
            UserDefaults.standard.removeObject(forKey: "vani.words.v1")
            UserDefaults.standard.removeObject(forKey: "vani.settings.v1")
            UserDefaults.standard.removeObject(forKey: "vani.phrases.v1")
        }

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
                .environmentObject(predictions)
                .environmentObject(auth)
                .environmentObject(sync)
                .tint(.indigo)
                .task { sync.start() }
        }
    }
}
