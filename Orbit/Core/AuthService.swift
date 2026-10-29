import Foundation

struct AuthService {
    var client: APIClient = .shared

    private struct LoginBody: Encodable { let email: String; let password: String }
    private struct TwoFactorBody: Encodable { let challenge: String; let code: String }
    private struct Challenge: Decodable { let twoFactorRequired: Bool?; let challenge: String? }

    func login(email: String, password: String) async throws -> LoginResult {
        // Decode loosely first: the same endpoint returns AuthOut or TwoFactorChallenge.
        let raw: RawAuth = try await client.post("/v1/auth/login", body: LoginBody(email: email, password: password))
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
