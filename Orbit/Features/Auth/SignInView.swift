import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Environment(SessionStore.self) private var session
    @State private var email = ""
    @State private var password = ""
    @State private var challenge: String?
    @State private var code = ""
    @State private var busy = false
    @State private var error: String?
    @State private var config = AuthConfig()
    @State private var appleNonce = Nonce()

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

            if challenge == nil { socialButtons }
            Spacer()
        }
        .padding(24)
        .task { config = await AuthService().config() }
    }

    @ViewBuilder private var socialButtons: some View {
        if config.apple || (config.google && GoogleSignInHelper.isConfigured) {
            Text("or").font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity)
        }
        if config.apple {
            SignInWithAppleButton(.signIn) { request in
                appleNonce = Nonce()
                request.requestedScopes = [.fullName, .email]
                request.nonce = appleNonce.hashed
            } onCompletion: { result in
                handleApple(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)
            .disabled(busy)
        }
        if config.google && GoogleSignInHelper.isConfigured {
            Button(action: google) {
                Text("Continue with Google").frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered).disabled(busy)
        }
    }

    private var canSubmit: Bool {
        challenge == nil ? !email.isEmpty && !password.isEmpty : code.count >= 6
    }

    private func submit() {
        run {
            let svc = AuthService()
            if let challenge {
                await session.complete(try await svc.verifyTwoFactor(challenge: challenge, code: code))
            } else {
                try await finish(svc.login(email: email.trimmingCharacters(in: .whitespaces), password: password))
            }
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        run {
            switch result {
            case .failure(let failure):
                // Backing out of Apple's sheet isn't an error worth showing.
                if (failure as? ASAuthorizationError)?.code == .canceled { return }
                throw failure
            case .success(let auth):
                guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                      let data = credential.identityToken, let token = String(data: data, encoding: .utf8) else {
                    throw APIError(status: 0, message: "Apple didn't return a sign-in token.")
                }
                // Apple sends the name only the first time, and only to the app.
                let name = credential.fullName.flatMap { PersonNameComponentsFormatter().string(from: $0) }
                try await finish(AuthService().signInWithApple(identityToken: token, rawNonce: appleNonce.raw,
                                                               name: name?.isEmpty == false ? name : nil))
            }
        }
    }

    private func google() {
        run {
            let nonce = Nonce()
            do {
                let token = try await GoogleSignInHelper.idToken(nonce: nonce)
                try await finish(AuthService().signInWithGoogle(idToken: token, rawNonce: nonce.raw))
            } catch where GoogleSignInHelper.isCancel(error) {
                return
            }
        }
    }

    private func finish(_ result: LoginResult) async {
        switch result {
        case .signedIn(let response): await session.complete(response)
        case .twoFactor(let c): challenge = c
        }
    }

    private func run(_ work: @escaping () async throws -> Void) {
        busy = true; error = nil
        Task {
            defer { busy = false }
            do { try await work() } catch { self.error = error.localizedDescription }
        }
    }
}
