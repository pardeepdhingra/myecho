import SwiftUI

/// Type-to-speak keyboard sheet — lets literate children type words or phrases for AAC output.
/// Vocabulary type-ahead chips appear as the child types, matching existing board words by prefix.
struct KeyboardPageView: View {
    @EnvironmentObject private var store: AACStore
    @EnvironmentObject private var speech: SpeechService

    let onAddWord: (AACWord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !suggestions.isEmpty {
                    typeAheadStrip
                    Divider()
                }

                inputRow
                    .padding(14)

                speakTypedButton
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)

                Spacer()
            }
            .navigationTitle("Keyboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { isFocused = true }
        }
    }

    private var typeAheadStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.black.opacity(0.35))
                    .accessibilityHidden(true)
                ForEach(suggestions) { word in
                    Button {
                        onAddWord(word)
                        text = ""
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Text(word.symbol).font(.system(size: 18))
                            Text(word.label)
                                .font(.system(.callout, design: .rounded, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.82))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(store.tileColor(for: word).opacity(0.45))
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().stroke(store.tileColor(for: word).opacity(0.8), lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(PressableTileStyle())
                    .accessibilityLabel(word.phrase)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color.white.opacity(0.6))
    }

    private var inputRow: some View {
        HStack(spacing: 10) {
            TextField("Type a word or phrase…", text: $text)
                .font(.system(.title3, design: .rounded))
                .padding(12)
                .background(Color.gray.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { addTyped() }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityLabel("Type a word or phrase")

            Button(action: addTyped) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Add to message")
        }
    }

    private var speakTypedButton: some View {
        Button {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            speech.speak(trimmed, settings: store.settings)
        } label: {
            Label("Speak typed text", systemImage: "speaker.wave.2.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(Color.accentColor)
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var suggestions: [AACWord] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return Array(store.searchWords(matching: trimmed).prefix(6))
    }

    private func addTyped() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let word = AACWord(
            label: trimmed,
            phrase: trimmed,
            symbol: "💬",
            category: "Typed",
            colorName: .gray,
            position: 0
        )
        onAddWord(word)
        text = ""
        dismiss()
    }
}
