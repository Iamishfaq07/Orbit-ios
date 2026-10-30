import SwiftUI

/// In-app account deletion (App Store guideline 5.1.1(v) requires it for apps that can create accounts).
/// `DELETE /v1/auth/me` asks for the password again, or the account's email when it never had one (Apple/Google).
struct DeleteAccountView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var confirmation = ""
    @State private var busy = false
    @State private var error: String?

    private var needsPassword: Bool { session.user?.hasPassword ?? true }

    private struct Body: Encodable, Sendable { let password: String }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("This permanently deletes your Orbit account and everything in it: your resumes, jobs, stories, contacts, offers and practice history, on every device and on the web. This can't be undone.")
                    Text("Payment and credit records are kept without your personal details.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section(needsPassword ? "Enter your password to confirm" : "Type your email to confirm") {
                    if needsPassword {
                        SecureField("Password", text: $confirmation).textContentType(.password).frame(minHeight: 44)
                    } else {
                        TextField(session.user?.email ?? "Email", text: $confirmation)
                            .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                            .frame(minHeight: 44)
                    }
                }
                if let error { Section { Text(error).font(.footnote).foregroundStyle(Theme.pastDue) } }
                Section {
                    Button("Delete my account", role: .destructive, action: delete)
                        .frame(minHeight: 44)
                        .disabled(busy || confirmation.isEmpty)
                }
            }
            .navigationTitle("Delete account").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func delete() {
        busy = true; error = nil
        Task {
            defer { busy = false }
            do {
                try await APIClient.shared.delete("/v1/auth/me", body: Body(password: confirmation))
                // The account is gone: clear the Keychain token and reminders and return to sign-in.
                await session.signOut()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
