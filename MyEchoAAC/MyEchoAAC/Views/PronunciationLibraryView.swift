import SwiftUI

/// Parent-editable pronunciation library. Parents add word → spoken-form pairs that apply
/// app-wide whenever PronunciationService looks up a pronunciation (custom overrides take
/// precedence over the built-in dictionary).
struct PronunciationLibraryView: View {
    @EnvironmentObject private var store: AACStore
    @EnvironmentObject private var speech: SpeechService

    @State private var newWord = ""
    @State private var newSpoken = ""
    @FocusState private var focusedField: Field?

    private enum Field { case word, spoken }

    private var sortedOverrides: [(key: String, value: String)] {
        store.settings.pronunciationOverrides
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    TextField("Word (e.g. eat)", text: $newWord)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .word)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .spoken }

                    TextField("Spoken form (e.g. eet)", text: $newSpoken)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .spoken)
                        .submitLabel(.done)
                        .onSubmit { addEntry() }

                    Button(action: addEntry) {
                        Label("Add", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canAdd)
                }
            } header: {
                Text("Add override")
            } footer: {
                Text("Custom overrides take precedence over the built-in pronunciation dictionary.")
            }

            if !sortedOverrides.isEmpty {
                Section("Custom overrides") {
                    ForEach(sortedOverrides, id: \.key) { pair in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pair.key)
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                Text("→ \(pair.value)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                speech.speak(pair.value, settings: store.settings)
                            } label: {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Hear \(pair.key)")
                        }
                    }
                    .onDelete { offsets in
                        let keys = sortedOverrides.map(\.key)
                        for index in offsets {
                            store.settings.pronunciationOverrides.removeValue(forKey: keys[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Pronunciation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canAdd: Bool {
        !newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !newSpoken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addEntry() {
        let key = newWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let value = newSpoken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !value.isEmpty else { return }
        store.settings.pronunciationOverrides[key] = value
        newWord = ""
        newSpoken = ""
        focusedField = .word
    }
}
