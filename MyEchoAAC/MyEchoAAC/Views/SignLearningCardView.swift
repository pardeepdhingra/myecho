import SwiftUI
import AVFoundation

/// Full-screen teaching card shown when a parent or child taps the sign badge on a word tile.
/// Displays the sign video large + the word label and lets the user hear the word spoken.
struct SignLearningCardView: View {
    let word: AACWord
    var onDismiss: () -> Void

    @EnvironmentObject private var store: AACStore
    @EnvironmentObject private var speech: SpeechService

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Word label
                Text(word.label)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                    .padding(.horizontal, 24)

                // Sign video
                signVideoArea
                    .padding(.vertical, 20)

                // Speak button
                Button {
                    speech.speak(word.phrase.isEmpty ? word.label : word.phrase,
                                 settings: store.settings)
                } label: {
                    Label("Hear word", systemImage: "speaker.wave.2.fill")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.15))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 12)

                // Attribution
                if let language = word.signLanguage {
                    Text(language.attribution)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer(minLength: 20)
            }

            // Dismiss button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var signVideoArea: some View {
        if let filename = word.signVideoPath, SignVideoStore.exists(filename) {
            SignVideoView(url: SignVideoStore.fileURL(for: filename), videoGravity: .resizeAspect)
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 24)
        } else {
            // Fallback: word symbol in a large box
            Text(word.symbol)
                .font(.system(size: 120))
                .frame(maxWidth: .infinity)
                .frame(height: 200)
        }
    }
}
