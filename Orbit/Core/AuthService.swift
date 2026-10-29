import Foundation

struct AuthService {
    var client: APIClient = .shared

    private struct LoginBody: Encodable { let email: String; let password: String }
    private struct TwoFactorBody: Encodable { let challenge: String; let code: String }

    private struct AppleBody: Encodable { let identityToken: String; let nonce: String; let name: String? }
    private struct GoogleBody: Encodable { let idToken: String; let nonce: String }

    /// `GET /v1/auth/config`: which sign-in buttons this server has switched on.
    func config() async -> AuthConfig {
        (try? await client.get("/v1/auth/config")) ?? AuthConfig(google: false, apple: false)
    }

    func login(email: String, password: String) async throws -> LoginResult {
        try await session("/v1/auth/login", body: LoginBody(email: email, password: password))
    }

    /// `rawNonce` is the random string; the provider was given its SHA-256 (see `Nonce`).
    func signInWithApple(identityToken: String, rawNonce: String, name: String?) async throws -> LoginResult {
        try await session("/v1/auth/apple", body: AppleBody(identityToken: identityToken, nonce: rawNonce, name: name))
    }

    func signInWithGoogle(idToken: String, rawNonce: String) async throws -> LoginResult {
        try await session("/v1/auth/google/native", body: GoogleBody(idToken: idToken, nonce: rawNonce))
    }

    /// These endpoints all answer with either a session (AuthOut) or, when 2FA is on, a challenge.
    private func session<B: Encodable>(_ path: String, body: B) async throws -> LoginResult {
        let raw: RawAuth = try await client.post(path, body: body)
        if let challenge = raw.challenge { return .twoFactor(challenge: challenge) }
        guard let user = raw.user else { throw APIError(status: 500, message: "Something went wrong. Please try again.") }
        return .signedIn(AuthResponse(user: user, accessToken: raw.accessToken))
    }

    func verifyTwoFactor(challenge: String, code: String) async throws -> AuthResponse {
        try await client.post("/v1/auth/login/2fa", body: TwoFactorBody(challenge: challenge, code: code))
    }

    func me() async throws -> User { try await client.get("/v1/auth/me") }

    func logout() async { try? await client.postVoid("/v1/auth/logout") }

    private struct RawAuth: Decodable {
        let user: User?
        let accessToken: String?
        let challenge: String?
    }
}
