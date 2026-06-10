import SwiftUI

/// Parent/therapist management of named board sets (e.g. Home, School, Therapy). Saving snapshots the
/// live board; loading replaces it (with a warning, since unsaved changes to the live board are lost).
struct BoardSetsView: View {
    @EnvironmentObject private var store: AACStore
    @StateObject private var boardSets = BoardSetStore()

    @State private var showingSavePrompt = false
    @State private var newSetName = ""
    @State private var setToLoad: BoardSetMeta?
    @State private var setToRename: BoardSetMeta?
    @State private var renameText = ""
    @State private var statusMessage: StatusMessage?

    private struct StatusMessage: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var body: some View {
        List {
            Section {
                Button {
                    newSetName = ""
                    showingSavePrompt = true
                } label: {
                    Label("Save current board as…", systemImage: "square.and.arrow.down.on.square")
                }
            } footer: {
                Text("A set is a full snapshot — every word, phrase, setting, and photo. Keep one per situation, like Home, School, or Therapy.")
            }

            if !boardSets.sets.isEmpty {
                Section("Saved sets") {
                    ForEach(boardSets.sets) { set in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(set.name)
                                .font(.body.weight(.semibold))
                            Text("\(set.wordCount) words · saved \(set.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                boardSets.delete(id: set.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                setToLoad = set
                            } label: {
                                Label("Load this set", systemImage: "arrow.down.circle")
                            }
                            Button {
                                if boardSets.updateSet(id: set.id, from: store) {
                                    Haptics.success()
                                    statusMessage = StatusMessage(title: "Updated", message: "“\(set.name)” now matches the current board.")
                                }
                            } label: {
                                Label("Overwrite with current board", systemImage: "square.and.arrow.down")
                            }
                            Button {
                                renameText = set.name
                                setToRename = set
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                boardSets.delete(id: set.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            setToLoad = set
                        }
                    }
                }
            }
        }
        .navigationTitle("Board sets")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Save current board", isPresented: $showingSavePrompt) {
            TextField("Name (e.g. School)", text: $newSetName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if boardSets.saveCurrentBoard(named: newSetName, store: store) != nil {
                    Haptics.success()
                } else {
                    statusMessage = StatusMessage(title: "Could not save", message: "Give the set a name and try again.")
                }
            }
        } message: {
            Text("Snapshots every word, phrase, setting, and photo into a named set.")
        }
        .alert("Load “\(setToLoad?.name ?? "")”?", isPresented: Binding(
            get: { setToLoad != nil },
            set: { if !$0 { setToLoad = nil } }
        )) {
            Button("Cancel", role: .cancel) { setToLoad = nil }
            Button("Load", role: .destructive) {
                if let set = setToLoad {
                    if boardSets.load(id: set.id, into: store) {
                        Haptics.success()
                        statusMessage = StatusMessage(title: "Loaded", message: "The board is now “\(set.name)”.")
                    } else {
                        statusMessage = StatusMessage(title: "Load failed", message: "Could not read that set's file.")
                    }
                }
                setToLoad = nil
            }
        } message: {
            Text("This replaces the current board. Save the current board as a set first if you want to keep it.")
        }
        .alert("Rename set", isPresented: Binding(
            get: { setToRename != nil },
            set: { if !$0 { setToRename = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { setToRename = nil }
            Button("Rename") {
                if let set = setToRename {
                    boardSets.rename(id: set.id, to: renameText)
                }
                setToRename = nil
            }
        }
        .alert(item: $statusMessage) { status in
            Alert(title: Text(status.title), message: Text(status.message), dismissButton: .default(Text("OK")))
        }
    }
}
