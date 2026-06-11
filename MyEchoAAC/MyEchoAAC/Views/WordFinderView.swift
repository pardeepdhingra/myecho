import SwiftUI

struct WordFinderView: View {
    @EnvironmentObject private var store: AACStore

    let onAdd: (AACWord) -> Void
    let onNavigate: (AACWord) -> Void

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var results: [AACWord] {
        store.searchWords(matching: query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                Divider()
                content
            }
            .navigationTitle("Find a Word")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        }
        .onAppear { searchFocused = true }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search words…", text: $query)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(.body, design: .rounded))
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.white)
    }

    // MARK: - Content states

    @ViewBuilder
    private var content: some View {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emptyPrompt
        } else if results.isEmpty {
            noResults
        } else {
            resultList
        }
    }

    private var emptyPrompt: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Type to find any word on the board")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResults: some View {
        VStack(spacing: 14) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No words found for \"\(query)\"")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(results) { word in
                    resultCard(word)
                }
            }
            .padding(14)
        }
    }

    // MARK: - Result card

    private func resultCard(_ word: AACWord) -> some View {
        HStack(spacing: 14) {
            tileSymbol(word)
                .frame(width: 54, height: 54)
                .background(store.tileColor(for: word))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(word.label)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.88))
                    .lineLimit(1)
                Text(pathBadge(word))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                onNavigate(word)
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(.callout, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color.accentColor)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Locate \(word.label) on board")
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture { onAdd(word) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(word.label), \(pathBadge(word))")
        .accessibilityHint("Tap to add to message bar")
    }

    private func pathBadge(_ word: AACWord) -> String {
        let path = AACStore.pathLabel(for: word)
        return path == "Core" ? "⭐️ Core (always visible)" : "📁 \(path)"
    }

    @ViewBuilder
    private func tileSymbol(_ word: AACWord) -> some View {
        if let filename = word.imagePath, let image = ImageStore.load(filename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else if let symbolName = word.symbolName, SymbolLibrary.exists(symbolName) {
            Image(symbolName)
                .resizable()
                .scaledToFit()
                .padding(8)
        } else {
            Text(word.symbol)
                .font(.system(size: 28))
        }
    }
}
