import SwiftUI

struct ParentModeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AACStore
    @EnvironmentObject private var speech: SpeechService

    @State private var editedWord: AACWord?
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            TabView {
                boardSettings
                    .tabItem {
                        Label("Board", systemImage: "square.grid.3x3")
                    }

                wordList
                    .tabItem {
                        Label("Words", systemImage: "text.badge.plus")
                    }

                voiceSettings
                    .tabItem {
                        Label("Voice", systemImage: "speaker.wave.2")
                    }
            }
            .navigationTitle("Parent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editedWord = store.addBlankWord()
                    } label: {
                        Label("Add word", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editedWord) { word in
                EditWordView(word: word)
                    .environmentObject(store)
            }
            .alert("Reset starter board?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetStarterBoard()
                }
            } message: {
                Text("This replaces your custom words and voice settings with the starter board.")
            }
        }
    }

    private var boardSettings: some View {
        Form {
            Section("Grid") {
                Picker("Columns", selection: $store.settings.gridColumns) {
                    Text("3").tag(3)
                    Text("4").tag(4)
                    Text("5").tag(5)
                    Text("6").tag(6)
                }
                .pickerStyle(.segmented)

                Toggle("Show categories on kid screen", isOn: $store.settings.showCategoryFilter)
            }

            Section("Learning") {
                Text("Keep familiar words in the same position. Hide words while learning, then reveal more without rearranging the board.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Reset starter board", role: .destructive) {
                    showingResetAlert = true
                }
            }
        }
    }

    private var wordList: some View {
        List {
            ForEach(store.words.sorted { $0.position < $1.position }) { word in
                HStack(spacing: 12) {
                    Text(word.symbol)
                        .font(.largeTitle)
                        .frame(width: 46, height: 46)
                        .background(word.colorName.color)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(word.label)
                            .font(.headline)
                        Text(word.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        store.toggleVisibility(for: word)
                    } label: {
                        Image(systemName: word.isVisible ? "eye" : "eye.slash")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(word.isVisible ? "Hide word" : "Show word")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editedWord = word
                }
            }
            .onDelete { offsets in
                let sorted = store.words.sorted { $0.position < $1.position }
                offsets.map { sorted[$0] }.forEach(store.delete)
            }
        }
    }

    private var voiceSettings: some View {
        Form {
            Section("Voice") {
                Picker("Voice", selection: $store.settings.voiceIdentifier) {
                    Text("Default friendly voice").tag(String?.none)
                    ForEach(speech.voiceOptions) { voice in
                        Text(voice.displayName).tag(Optional(voice.id))
                    }
                }

                Button {
                    speech.previewVoice(settings: store.settings)
                } label: {
                    Label("Preview voice", systemImage: "play.circle")
                }
            }

            Section("Sound") {
                VStack(alignment: .leading) {
                    Text("Speed")
                    Slider(value: $store.settings.speechRate, in: 0.32...0.58)
                }

                VStack(alignment: .leading) {
                    Text("Pitch")
                    Slider(value: $store.settings.pitchMultiplier, in: 0.85...1.25)
                }
            }

            Section("ElevenLabs") {
                Text("For a future online voice option, the API key should live on a small backend, not inside the iOS app. The app can call that backend to receive generated audio while keeping the key private.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
