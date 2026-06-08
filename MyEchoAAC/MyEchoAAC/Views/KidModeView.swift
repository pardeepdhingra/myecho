import SwiftUI
import UIKit

struct KidModeView: View {
    @EnvironmentObject private var store: AACStore
    @EnvironmentObject private var speech: SpeechService
    @EnvironmentObject private var history: UsageHistory

    @State private var message: [AACWord] = []
    @State private var selectedCategory: String?
    @State private var showingParentGate = false
    @State private var showingParentMode = false
    @AppStorage("vani.welcomeSeen") private var welcomeSeen: Bool = false
    @State private var showingWelcome = false
    @State private var showingSentenceHistory = false
    @State private var showingAbout = false

    private var phrase: String {
        message.map(\.phrase).joined(separator: " ")
    }

    private var columns: [GridItem] {
        let maxAllowed = UIDevice.current.userInterfaceIdiom == .pad ? 8 : 6
        return Array(
            repeating: GridItem(.flexible(minimum: 68), spacing: 10),
            count: max(2, min(store.settings.gridColumns, maxAllowed))
        )
    }

    private static let recentCategoryToken = "__recent__"
    private static let favoritesCategoryToken = "__favorites__"

    private var categories: [String?] {
        var list: [String?] = [nil]
        if store.words.contains(where: { $0.isFavorite && $0.isVisible }) {
            list.append(Self.favoritesCategoryToken)
        }
        if store.settings.trackUsageHistory && !history.recentWordIds(limit: 1).isEmpty {
            list.append(Self.recentCategoryToken)
        }
        list.append(contentsOf: store.categories.map(Optional.some))
        return list
    }

    private func categoryLabel(_ category: String?) -> String {
        if category == Self.recentCategoryToken { return "Recent" }
        if category == Self.favoritesCategoryToken { return "★ Favorites" }
        return category ?? "All"
    }

    private func visibleWordsForSelectedCategory() -> [AACWord] {
        if selectedCategory == Self.recentCategoryToken {
            let recentIds = history.recentWordIds(limit: 12)
            let byId = Dictionary(uniqueKeysWithValues: store.words.filter { $0.isVisible }.map { ($0.id, $0) })
            return recentIds.compactMap { byId[$0] }
        }
        if selectedCategory == Self.favoritesCategoryToken {
            return store.favoritesOrdered.filter { $0.isVisible }
        }
        return store.visibleWords(in: selectedCategory)
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            regulationBar
            quickPhraseStrip
            messageBar
            categoryFilter
            wordGrid
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .background(appBackground.ignoresSafeArea())
        .preferredColorScheme(.light)
            .sheet(isPresented: $showingParentGate) {
                PINGateView {
                    showingParentMode = true
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingWelcome, onDismiss: {
                welcomeSeen = true
            }) {
                WelcomeView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showingSentenceHistory) {
                SentenceHistorySheet { sentence in
                    speech.speak(sentence, settings: store.settings)
                    Haptics.actionTap()
                }
                .environmentObject(history)
                .presentationDetents([.large])
            }
            .fullScreenCover(isPresented: $showingAbout) {
                NavigationStack {
                    AboutView()
                }
            }
            .task {
                if !welcomeSeen {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    showingWelcome = true
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .sheet(isPresented: $showingParentMode) {
                ParentModeView()
                    .environmentObject(store)
                    .environmentObject(speech)
                    .environmentObject(history)
                    .presentationDetents([.large])
            }
            .onChange(of: store.words) { _, _ in
                guard let selectedCategory, store.categories.contains(selectedCategory) else {
                    self.selectedCategory = nil
                    return
                }
            }
    }

    private var appBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.99, blue: 1.0),
                Color(red: 0.94, green: 0.99, blue: 0.97),
                Color(red: 1.0, green: 0.98, blue: 0.94)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 36)
                .accessibilityHidden(true)

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text("वाणी")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.85))
                Text("Vani")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.55))
            }

            Button {
                showingAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.75))
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(Color.black.opacity(0.08), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About Vani")

            Button {
                showingParentGate = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.75))
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(Color.black.opacity(0.08), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Parent settings")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func messageChip(for word: AACWord) -> some View {
        HStack(spacing: 8) {
            if store.settings.showSymbolsInMessageBar {
                chipSymbol(for: word)
            }
            Text(word.label)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(word.colorName.color.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(word.label)
    }

    @ViewBuilder
    private func chipSymbol(for word: AACWord) -> some View {
        if let filename = word.imagePath, let image = ImageStore.load(filename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            Text(word.symbol)
                .font(.system(size: 24))
        }
    }

    @ViewBuilder
    private var regulationBar: some View {
        if store.settings.showRegulationBar {
            let buttons = store.quickPhrases
                .filter { $0.mode == .regulation }
                .sorted { ($0.regulationKind?.rawValue ?? "") < ($1.regulationKind?.rawValue ?? "") }
            if !buttons.isEmpty {
                HStack(spacing: 8) {
                    ForEach(buttons) { phrase in
                        Button {
                            Haptics.actionTap()
                            speech.speak(phrase.text, settings: store.settings)
                            history.recordSentence(phrase.text, enabled: store.settings.trackUsageHistory)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: phrase.regulationKind?.systemImage ?? "exclamationmark.circle.fill")
                                    .font(.system(.title3, weight: .bold))
                                Text(phrase.text)
                                    .font(.system(.callout, design: .rounded, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(regulationColor(phrase.regulationKind))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(PressableTileStyle())
                        .accessibilityLabel(phrase.text)
                    }
                }
            }
        }
    }

    private func regulationColor(_ kind: RegulationKind?) -> Color {
        switch kind {
        case .calm: Color(red: 0.13, green: 0.66, blue: 0.55)
        case .help: Color(red: 0.95, green: 0.72, blue: 0.15)
        case .stop: Color(red: 0.85, green: 0.27, blue: 0.27)
        case nil: Color.accentColor
        }
    }

    @ViewBuilder
    private var quickPhraseStrip: some View {
        if store.settings.showQuickPhrases {
            let nonRegulation = store.quickPhrases
                .filter { $0.mode != .regulation }
                .sorted { $0.position < $1.position }
            if !nonRegulation.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(nonRegulation) { phrase in
                            Button {
                                handleQuickPhrase(phrase)
                            } label: {
                                HStack(spacing: 6) {
                                    if phrase.mode == .startSentence {
                                        Image(systemName: "text.bubble")
                                            .font(.caption.weight(.bold))
                                    }
                                    Text(phrase.text)
                                        .font(.system(.callout, design: .rounded, weight: .semibold))
                                }
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(phrase.mode == .speak ? Color.accentColor : Color.accentColor.opacity(0.78))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(PressableTileStyle())
                            .accessibilityLabel(phrase.text)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private var messageBar: some View {
        VStack(spacing: 10) {
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if message.isEmpty {
                            Text("Ready to talk")
                                .font(.system(.title3, design: .rounded, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.5))
                                .padding(.horizontal, 4)
                        } else {
                            ForEach(message) { word in
                                messageChip(for: word)
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
                .tint(Color.accentColor)
                .disabled(message.isEmpty)
            }

            HStack(spacing: 10) {
                Button {
                    removeLastWord()
                } label: {
                    Label("Delete", systemImage: "delete.left.fill")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor.opacity(0.85))
                .disabled(message.isEmpty)

                Button {
                    clearMessage()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(Color.accentColor)
                .disabled(message.isEmpty)

                Button {
                    showingSentenceHistory = true
                } label: {
                    Label("Recent", systemImage: "clock.arrow.circlepath")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(Color.accentColor)
                .disabled(history.spokenSentences.isEmpty)
            }
            .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .padding(12)
        .background(.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
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
                            Text(categoryLabel(category))
                                .font(.system(.callout, design: .rounded, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(selectedCategory == category ? Color.accentColor : Color.white.opacity(0.9))
                                .foregroundStyle(selectedCategory == category ? Color.white : Color.black.opacity(0.82))
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(.black.opacity(selectedCategory == category ? 0 : 0.08), lineWidth: 1)
                                }
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
                ForEach(visibleWordsForSelectedCategory()) { word in
                    WordTileView(word: word, action: {
                        addWord(word)
                    }, scale: store.settings.tileScale)
                    .contextMenu {
                        Button {
                            speech.speak(word.phrase, settings: store.settings)
                        } label: {
                            Label("Speak", systemImage: "speaker.wave.2")
                        }
                        Button {
                            store.toggleFavorite(for: word)
                            Haptics.success()
                        } label: {
                            Label(word.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                  systemImage: word.isFavorite ? "star.slash" : "star")
                        }
                        Button {
                            store.addQuickPhrase(word.phrase)
                            Haptics.success()
                        } label: {
                            Label("Add to Quick Phrases", systemImage: "quote.bubble")
                        }
                    }
                }
            }
            .padding(.bottom, 18)
        }
    }

    private func addWord(_ word: AACWord) {
        message.append(word)
        speech.speak(word.phrase, settings: store.settings)
        history.record(wordId: word.id, label: word.label, enabled: store.settings.trackUsageHistory)
    }

    private func handleQuickPhrase(_ phrase: QuickPhrase) {
        Haptics.actionTap()
        switch phrase.mode {
        case .speak, .regulation:
            speech.speak(phrase.text, settings: store.settings)
            history.recordSentence(phrase.text, enabled: store.settings.trackUsageHistory)
        case .startSentence:
            let starterWord = AACWord(
                label: phrase.text,
                phrase: phrase.text,
                symbol: "💬",
                category: "Phrase",
                colorName: .purple,
                position: 0
            )
            message.append(starterWord)
        }
    }

    private func speakMessage() {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Haptics.actionTap()
        let polished: String
        if let last = trimmed.last, ".?!".contains(last) {
            polished = trimmed
        } else {
            polished = trimmed + "."
        }
        speech.speak(polished, settings: store.settings)
        history.recordSentence(polished, enabled: store.settings.trackUsageHistory)
    }

    private func removeLastWord() {
        guard !message.isEmpty else { return }
        message.removeLast()
    }

    private func clearMessage() {
        message.removeAll()
    }
}
