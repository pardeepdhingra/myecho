import SwiftUI

@main
struct MyEchoAACApp: App {
    @StateObject private var store = AACStore()
    @StateObject private var speech = SpeechService()

    var body: some Scene {
        WindowGroup {
            KidModeView()
                .environmentObject(store)
                .environmentObject(speech)
                .tint(.indigo)
        }
    }
}
