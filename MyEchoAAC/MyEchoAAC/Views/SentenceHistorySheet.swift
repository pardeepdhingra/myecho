import SwiftUI

struct SentenceHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var history: UsageHistory

    let onSpeak: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                if history.spokenSentences.isEmpty {
                    Text("No recent sentences yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(history.spokenSentences, id: \.self) { sentence in
                        Button {
                            onSpeak(sentence)
                            dismiss()
                        } label: {
                            HStack {
                                Text(sentence)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recent Sentences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
