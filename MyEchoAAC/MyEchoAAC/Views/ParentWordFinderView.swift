import SwiftUI

/// Parent-mode word finder — search any word across the board, see its exact location
/// (folder + rank), and jump straight to editing it. Complements the existing Words tab
/// flat list by surfacing the word's spatial context for therapist planning.
struct ParentWordFinderView: View {
    @EnvironmentObject private var store: AACStore
    @Environment(\.dismiss) private var dismiss

    let onEdit: (AACWord) -> Void

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var results: [AACWord] {
        store.searchWords(matching: query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                Divider()
                content
            }
            .navigationTitle("Find a Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .onAppear { searchFocused = true }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
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
            Text("Search to find any word and see exactly where it lives on the board.")
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
        let info = store.locationInfo(for: word)
        let badge = locationBadge(info: info, word: word)

        return HStack(spacing: 14) {
            WordArtworkView(word: word, size: 54, cornerRadius: 10)
                .background(store.tileColor(for: word))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(word.label)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.88))
                    if !word.isVisible {
                        Image(systemName: "eye.slash")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if word.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                Text(badge)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                onEdit(word)
                dismiss()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(.callout, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color.accentColor)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(word.label)")
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(word.label), \(badge)")
        .accessibilityHint("Tap Edit to modify this word")
    }

    private func locationBadge(info: AACStore.WordLocationInfo, word: AACWord) -> String {
        if info.category == AACWord.coreCategory {
            return "⭐️ Core · \(info.rank) of \(info.total)"
        }
        return "📁 \(info.category) · \(info.rank) of \(info.total)"
    }
}
