import SwiftUI

/// Bulk sign assignment flow — shows all visible words without a sign video and lets parents
/// search + add signs one by one from this single screen, much faster than editing each word.
struct BulkSignView: View {
    @EnvironmentObject private var store: AACStore
    @Environment(\.dismiss) private var dismiss

    @State private var language: SignLanguage = .auslan
    @State private var states: [UUID: RowState] = [:]

    private enum RowState {
        case idle
        case searching
        case found([SignResult])
        case noResult
        case downloaded(filename: String)
        case error(String)
    }

    private var unsignedWords: [AACWord] {
        store.words
            .filter { $0.isVisible && $0.signVideoPath == nil }
            .sorted { $0.position < $1.position }
    }

    var body: some View {
        NavigationStack {
            Group {
                if unsignedWords.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.accentColor.opacity(0.6))
                        Text("All visible words already have a sign.")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(unsignedWords) { word in
                        wordRow(word)
                    }
                }
            }
            .navigationTitle("Add Signs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Language", selection: $language) {
                        ForEach(SignLanguage.allCases) { lang in
                            Text(lang.label).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    @ViewBuilder
    private func wordRow(_ word: AACWord) -> some View {
        let rowState = states[word.id] ?? .idle
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(word.symbol)
                    .font(.system(size: 28))
                Text(word.label)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                Spacer()
                rowAction(word: word, state: rowState)
            }

            switch rowState {
            case .found(let results):
                if let first = results.first {
                    SignVideoView(url: first.previewURL, videoGravity: .resizeAspect)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .onTapGesture {
                            Task { await downloadSign(first, for: word) }
                        }
                    Text("Tap video to use this sign")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .error(let msg):
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
            case .noResult:
                Text("No sign found. Try searching in Edit Word.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .downloaded:
                Label("Sign added", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            default:
                EmptyView()
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func rowAction(word: AACWord, state: RowState) -> some View {
        switch state {
        case .idle:
            Button("Search") {
                Task { await searchSign(for: word) }
            }
            .buttonStyle(.bordered)
            .font(.caption.weight(.semibold))
        case .searching:
            ProgressView()
        case .found:
            EmptyView()
        case .noResult, .error:
            Button("Retry") {
                Task { await searchSign(for: word) }
            }
            .buttonStyle(.bordered)
            .font(.caption.weight(.semibold))
        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    private func searchSign(for word: AACWord) async {
        states[word.id] = .searching
        let service = SignSearchService()
        do {
            let results = try await service.lookup(word.label, language: language)
            states[word.id] = results.isEmpty ? .noResult : .found(results)
        } catch {
            states[word.id] = .error(error.localizedDescription)
        }
    }

    private func downloadSign(_ result: SignResult, for word: AACWord) async {
        states[word.id] = .searching
        let downloader = SignDownloader()
        do {
            let filename = try await downloader.download(result.previewURL)
            var updated = word
            updated.signVideoPath = filename
            updated.signLanguage = result.language
            store.upsert(updated)
            states[word.id] = .downloaded(filename: filename)
        } catch {
            states[word.id] = .error("Download failed — check your connection")
        }
    }
}
