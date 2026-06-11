import SwiftUI

struct SignPickerSelection: Equatable {
    let filename: String
    let language: SignLanguage
}

struct SignPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let initialWord: String
    let onSelect: (SignPickerSelection) -> Void

    @State private var query: String = ""
    @State private var language: SignLanguage = .auslan
    @State private var results: [SignResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var savingResultID: String?
    @State private var failedResultID: String?

    private let search = SignSearchService()
    private let downloader = SignDownloader()

    init(initialWord: String, onSelect: @escaping (SignPickerSelection) -> Void) {
        self.initialWord = initialWord
        self.onSelect = onSelect
        _query = State(initialValue: initialWord)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                searchControls
                resultsArea
            }
            .padding()
            .navigationTitle("Choose Sign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await runSearch()
                }
            }
        }
    }

    @ViewBuilder
    private var searchControls: some View {
        VStack(spacing: 10) {
            Picker("Language", selection: $language) {
                ForEach(SignLanguage.allCases) { lang in
                    Text(lang.label).tag(lang)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: language) { _, _ in
                results = []
                errorMessage = nil
                Task { await runSearch() }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Type a word…", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { Task { await runSearch() } }
                if !query.isEmpty {
                    Button {
                        query = ""
                        results = []
                        errorMessage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    Task { await runSearch() }
                } label: {
                    Text("Search")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.12))
            )

            Text(language.attribution)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var resultsArea: some View {
        if isSearching {
            ProgressView("Searching…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Button("Try again") {
                    Task { await runSearch() }
                }
                .buttonStyle(.bordered)
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if results.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "hand.wave")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Type a word and tap Search.\nPreviews stream from the dictionary;\n‘Use this sign’ saves it to the tile.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(results) { result in
                        resultCard(result)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    private func resultCard(_ result: SignResult) -> some View {
        VStack(spacing: 10) {
            SignVideoView(url: result.previewURL, videoGravity: .resizeAspect)
                .frame(height: 220)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08))
                )

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.word.capitalized)
                        .font(.headline)
                    Text(result.language.fullName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    failedResultID = nil
                    Task { await useResult(result) }
                } label: {
                    if savingResultID == result.id {
                        ProgressView()
                    } else if failedResultID == result.id {
                        Label("Retry", systemImage: "arrow.clockwise")
                    } else {
                        Text("Use this sign")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(failedResultID == result.id ? .orange : .accentColor)
                .disabled(savingResultID != nil)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        results = []
        defer { isSearching = false }
        do {
            let found = try await search.lookup(trimmed, language: language)
            results = found
        } catch let error as SignSearchError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func useResult(_ result: SignResult) async {
        savingResultID = result.id
        defer { savingResultID = nil }
        do {
            let filename = try await downloader.download(result.previewURL)
            onSelect(SignPickerSelection(filename: filename, language: result.language))
            dismiss()
        } catch let error as SignSearchError {
            failedResultID = result.id
            errorMessage = error.errorDescription
        } catch {
            failedResultID = result.id
            errorMessage = error.localizedDescription
        }
    }
}
