import AuthenticationServices
import SwiftUI

/// Sign in / create account sheet. Email-password plus Sign in with Apple.
struct AuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthService

    private enum Mode: String, CaseIterable {
        case signIn = "Sign in"
        case signUp = "Create account"
    }

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var errorText: String?
    @State private var infoText: String?
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                } footer: {
                    if mode == .signUp {
                        Text("Use at least 6 characters.")
                    }
                }

                if let errorText {
                    Section { Text(errorText).font(.footnote).foregroundStyle(.red) }
                }
                if let infoText {
                    Section { Text(infoText).font(.footnote).foregroundStyle(.secondary) }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if busy { ProgressView() } else { Text(mode.rawValue).bold() }
                            Spacer()
                        }
                    }
                    .disabled(busy || !isValid)

                    if mode == .signIn {
                        Button("Forgot password?") {
                            Task { await resetPassword() }
                        }
                        .disabled(busy || email.isEmpty)
                    }
                }

                Section {
                    SignInWithAppleButton(.continue) { request in
                        auth.prepareAppleRequest(request)
                    } onCompletion: { result in
                        Task { await handleApple(result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 48)
                    .listRowInsets(EdgeInsets())
                } header: {
                    Text("Or")
                }
            }
            .navigationTitle("Cloud account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var isValid: Bool {
        email.contains("@") && password.count >= 6
    }

    private func submit() async {
        busy = true; errorText = nil; infoText = nil
        defer { busy = false }
        do {
            switch mode {
            case .signIn: try await auth.signIn(email: email, password: password)
            case .signUp: try await auth.signUp(email: email, password: password)
            }
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func resetPassword() async {
        busy = true; errorText = nil; infoText = nil
        defer { busy = false }
        do {
            try await auth.sendPasswordReset(email: email)
            infoText = "Password reset email sent to \(email)."
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        errorText = nil
        switch result {
        case let .success(authorization):
            do {
                try await auth.completeAppleSignIn(authorization)
                dismiss()
            } catch {
                errorText = error.localizedDescription
            }
        case let .failure(error):
            // User cancellation is not an error worth surfacing.
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorText = error.localizedDescription
            }
        }
    }
}
