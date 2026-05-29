import SwiftUI

@main
struct MyEchoAACApp: App {
    @StateObject private var store: AACStore
    @StateObject private var speech = SpeechService()
    @StateObject private var history = UsageHistory()

    init() {
        let s = AACStore()
        s.ensureRegulationDefaults()
        _store = StateObject(wrappedValue: s)
    }

    var body: some Scene {
        WindowGroup {
            KidModeView()
                .environmentObject(store)
                .environmentObject(speech)
                .environmentObject(history)
                .tint(.indigo)
        }
    }
}
