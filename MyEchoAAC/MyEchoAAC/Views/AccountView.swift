import SwiftUI

/// Parent-settings tab for the optional cloud account + sync. Coexists with the local Export/Import
/// backup in the Board tab.
struct AccountView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var sync: CloudSyncService

    @State private var showingAuthSheet = false
    @State private var showingSignOutConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                if !auth.isAvailable {
                    Section {
                        Label("Cloud backup isn't enabled in this build", systemImage: "icloud.slash")
                            .foregroundStyle(.secondary)
                    } footer: {
                        Text("Add the Firebase configuration to enable signing in and syncing your board across devices. The app works fully offline without an account.")
                    }
                } else if case let .signedIn(_, email) = auth.state {
                    signedInSections(email: email)
                } else {
                    signedOutSection
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAuthSheet) {
                AuthSheet().environmentObject(auth)
            }
            .confirmationDialog(
                "Use which board?",
                isPresented: $sync.pendingReconcile,
                titleVisibility: .visible
            ) {
                Button("Use cloud board (replace this device)") { sync.resolveReconcile(useCloud: true) }
                Button("Keep this device's board (replace cloud)") { sync.resolveReconcile(useCloud: false) }
            } message: {
                Text("This account already has a saved board, and this device also has its own. Choose which one to keep — the other will be replaced.")
            }
            .alert("Sign out?", isPresented: $showingSignOutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign out", role: .destructive) { try? auth.signOut() }
            } message: {
                Text("Your board stays on this device, and the cloud copy is kept. You can sign back in any time.")
            }
        }
    }

    private var signedOutSection: some View {
        Section {
            Button {
                showingAuthSheet = true
            } label: {
                Label("Sign in or create account", systemImage: "person.crop.circle.badge.plus")
            }
        } footer: {
            Text("Optional. Sign in to back up your board, photos, sign videos, and stats — and keep them in sync across your devices. The app works fully offline without an account.")
        }
    }

    @ViewBuilder
    private func signedInSections(email: String?) -> some View {
        Section("Signed in") {
            HStack {
                Image(systemName: "person.crop.circle.fill").foregroundStyle(.secondary)
                Text(email ?? "Apple account")
                Spacer()
            }
            syncStatusRow
        }

        Section {
            Button {
                sync.syncNow()
            } label: {
                Label("Sync now", systemImage: "arrow.triangle.2.circlepath")
            }
            Button {
                sync.restoreFromCloud()
            } label: {
                Label("Restore from cloud", systemImage: "icloud.and.arrow.down")
            }
        } footer: {
            Text("Changes sync automatically. Use these if you want to push or pull right now.")
        }

        Section {
            Button(role: .destructive) {
                showingSignOutConfirm = true
            } label: {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private var syncStatusRow: some View {
        HStack {
            Label("Sync", systemImage: statusIcon)
            Spacer()
            Text(statusText)
                .font(.footnote)
                .foregroundStyle(statusColor)
        }
    }

    private var statusText: String {
        switch sync.status {
        case .disabled: "Off"
        case .signedOut: "Signed out"
        case .idle: "Ready"
        case .syncing: "Syncing…"
        case .pending: "Pending…"
        case let .synced(date): "Synced \(date.formatted(date: .omitted, time: .shortened))"
        case let .error(message): message
        }
    }

    private var statusIcon: String {
        switch sync.status {
        case .syncing, .pending: "arrow.triangle.2.circlepath"
        case .synced: "checkmark.icloud"
        case .error: "exclamationmark.icloud"
        default: "icloud"
        }
    }

    private var statusColor: Color {
        switch sync.status {
        case .error: .red
        case .synced: .secondary
        default: .secondary
        }
    }
}
