import SwiftUI

struct SignInView: View {
    @Environment(SessionStore.self) private var session
    @State private var email = ""
    @State private var password = ""
    @State private var challenge: String?
    @State private var code = ""
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("Orbit").font(Theme.title(40))
            Text("One coach for the whole job search.").foregroundStyle(.secondary)

            if challenge == nil {
                TextField("Email", text: $email)
                    .textContentType(.username).keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder).frame(minHeight: 44)
                SecureField("Password", text: $password)
                    .textContentType(.password).textFieldStyle(.roundedBorder).frame(minHeight: 44)
            } else {
                Text("Enter the code from your authenticator app.").font(.subheadline)
                TextField("6-digit code", text: $code)
                    .textContentType(.oneTimeCode).keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder).frame(minHeight: 44)
            }

            if let error { Text(error).font(.footnote).foregroundStyle(Theme.pastDue) }

            Button(action: submit) {
                Group { if busy { ProgressView() } else { Text(challenge == nil ? "Sign in" : "Verify") } }
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent).disabled(busy || !canSubmit)
            Spacer()
        }
        .padding(24)
    }

    private var canSubmit: Bool {
        challenge == nil ? !email.isEmpty && !password.isEmpty : code.count >= 6
    }

    private func submit() {
        busy = true; error = nil
        Task {
            defer { busy = false }
            do {
                let svc = AuthService()
                if let challenge {
                    await session.complete(try await svc.verifyTwoFactor(challenge: challenge, code: code))
                } else {
                    switch try await svc.login(email: email.trimmingCharacters(in: .whitespaces), password: password) {
                    case .signedIn(let r): await session.complete(r)
                    case .twoFactor(let c): challenge = c
                    }
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
