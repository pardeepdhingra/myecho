import SwiftUI

struct ProfileSwitcherView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var store: AACStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddSheet = false
    @State private var editingProfile: ChildProfile?
    @State private var newName = ""
    @State private var newEmoji = "🧒"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(profileStore.profiles) { profile in
                        profileRow(profile)
                    }
                } header: {
                    Text("Profiles")
                } footer: {
                    Text("Each profile has its own board, words, and settings.")
                        .font(.footnote)
                }

                Section {
                    Button {
                        newName = ""
                        newEmoji = "🧒"
                        showingAddSheet = true
                    } label: {
                        Label("Add Profile", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Child Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addSheet
            }
            .sheet(item: $editingProfile) { profile in
                editSheet(for: profile)
            }
        }
    }

    // MARK: - Profile row

    private func profileRow(_ profile: ChildProfile) -> some View {
        HStack(spacing: 14) {
            Text(profile.emoji)
                .font(.system(size: 30))
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                if profile.isDefault {
                    Text("Default board")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if profile.id == profileStore.activeProfileId {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.title3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard profile.id != profileStore.activeProfileId else { return }
            switchTo(profile)
        }
        .swipeActions(edge: .trailing) {
            if !profile.isDefault {
                Button(role: .destructive) {
                    if profile.id == profileStore.activeProfileId {
                        if let defaultProfile = profileStore.profiles.first(where: \.isDefault) {
                            switchTo(defaultProfile)
                        }
                    }
                    profileStore.deleteProfile(profile)
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    newName = profile.name
                    newEmoji = profile.emoji
                    editingProfile = profile
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.orange)
            }
        }
    }

    // MARK: - Add sheet

    private var addSheet: some View {
        NavigationStack {
            profileForm(title: "New Profile")
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingAddSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        profileStore.addProfile(name: name, emoji: newEmoji)
                        showingAddSheet = false
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Edit sheet

    private func editSheet(for profile: ChildProfile) -> some View {
        NavigationStack {
            profileForm(title: "Edit Profile")
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { editingProfile = nil }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        profileStore.updateName(name, emoji: newEmoji, for: profile)
                        editingProfile = nil
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func profileForm(title: String) -> some View {
        Form {
            Section("Name") {
                TextField("Child's name", text: $newName)
                    .autocorrectionDisabled()
            }
            Section("Avatar Emoji") {
                TextField("Emoji", text: $newEmoji)
                    .font(.system(size: 28))
                    .frame(height: 44)
            }
        }
    }

    // MARK: - Switch helper

    private func switchTo(_ profile: ChildProfile) {
        profileStore.activate(profile)
        if let newDefaults = profileStore.userDefaults(for: profile) {
            store.reload(from: newDefaults)
        }
        dismiss()
    }
}
