import SwiftUI

struct KidModeView: View {
    @EnvironmentObject private var store: AACStore
    @EnvironmentObject private var speech: SpeechService

    @State private var message: [AACWord] = []
    @State private var selectedCategory: String?
    @State private var showingParentGate = false
    @State private var showingParentMode = false

    private var phrase: String {
        message.map(\.phrase).joined(separator: " ")
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 68), spacing: 10),
            count: max(2, min(store.settings.gridColumns, 6))
        )
    }

    private var categories: [String?] {
        [nil] + store.categories.map(Optional.some)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                messageBar
                categoryFilter
                wordGrid
            }
            .padding(14)
            .background(Color(red: 0.97, green: 0.98, blue: 1.0))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Echo")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingParentGate = true
                    } label: {
                        Label("Parent settings", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingParentGate) {
                parentGate
            }
            .sheet(isPresented: $showingParentMode) {
                ParentModeView()
                    .environmentObject(store)
                    .environmentObject(speech)
            }
            .onChange(of: store.words) { _, _ in
                guard let selectedCategory, store.categories.contains(selectedCategory) else {
                    self.selectedCategory = nil
                    return
                }
            }
        }
    }

    private var parentGate: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.indigo)

            Text("Parent Mode")
                .font(.system(.title2, design: .rounded, weight: .bold))

            Text("Press and hold to edit words, grid, and voice.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Hold to Open")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.indigo)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onLongPressGesture(minimumDuration: 1.2) {
                    showingParentGate = false
                    showingParentMode = true
                }

            Button("Cancel") {
                showingParentGate = false
            }
            .buttonStyle(.bordered)
        }
        .padding(28)
        .presentationDetents([.height(320)])
    }

    private var messageBar: some View {
        VStack(spacing: 10) {
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if message.isEmpty {
                            Text("Tap words to build a message")
                                .font(.system(.title3, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                        } else {
                            ForEach(message) { word in
                                Text(word.label)
                                    .font(.system(.title3, design: .rounded, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 58)

                Button {
                    speakMessage()
                } label: {
                    Label("Speak", systemImage: "speaker.wave.2.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .frame(width: 54, height: 54)
                }
                .buttonStyle(.borderedProminent)
                .disabled(message.isEmpty)
            }

            HStack(spacing: 10) {
                Button {
                    removeLastWord()
                } label: {
                    Label("Backspace", systemImage: "delete.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(message.isEmpty)

                Button {
                    clearMessage()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(message.isEmpty)
            }
            .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }

    @ViewBuilder
    private var categoryFilter: some View {
        if store.settings.showCategoryFilter {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category ?? "All")
                                .font(.system(.callout, design: .rounded, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(selectedCategory == category ? Color.indigo : Color.white)
                                .foregroundStyle(selectedCategory == category ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var wordGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.visibleWords(in: selectedCategory)) { word in
                    WordTileView(word: word) {
                        addWord(word)
                    }
                }
            }
            .padding(.bottom, 18)
        }
    }

    private func addWord(_ word: AACWord) {
        message.append(word)
        speech.speak(word.phrase, settings: store.settings)
    }

    private func speakMessage() {
        speech.speak(phrase, settings: store.settings)
    }

    private func removeLastWord() {
        guard !message.isEmpty else { return }
        message.removeLast()
    }

    private func clearMessage() {
        message.removeAll()
    }
}
