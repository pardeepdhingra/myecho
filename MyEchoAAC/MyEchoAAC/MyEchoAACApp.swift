import SwiftUI

@main
struct MyEchoAACApp: App {
    @StateObject private var store = AACStore()
    @StateObject private var speech = SpeechService()
    @StateObject private var history = UsageHistory()

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
