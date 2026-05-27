import SwiftUI

struct EditWordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AACStore

    @State private var draft: AACWord

    init(word: AACWord) {
        _draft = State(initialValue: word)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Word") {
                    TextField("Label", text: $draft.label)
                    TextField("Spoken phrase", text: $draft.phrase)
                    TextField("Symbol or emoji", text: $draft.symbol)
                    TextField("Category", text: $draft.category)
                }

                Section("Board") {
                    Picker("Color", selection: $draft.colorName) {
                        ForEach(TileColorName.allCases) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 16, height: 16)
                                Text(color.label)
                            }
                            .tag(color)
                        }
                    }

                    Stepper("Position \(draft.position)", value: $draft.position, in: 1...400)
                    Toggle("Visible on kid screen", isOn: $draft.isVisible)
                }

                Section("Preview") {
                    WordTileView(word: draft) {}
                        .frame(maxWidth: 220)
                        .disabled(true)
                }
            }
            .navigationTitle("Edit Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(draft.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        draft.label = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.phrase = draft.phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.symbol = draft.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.category = draft.category.trimmingCharacters(in: .whitespacesAndNewlines)

        if draft.phrase.isEmpty {
            draft.phrase = draft.label
        }

        if draft.symbol.isEmpty {
            draft.symbol = "💬"
        }

        if draft.category.isEmpty {
            draft.category = "Home"
        }

        store.upsert(draft)
        dismiss()
    }
}
