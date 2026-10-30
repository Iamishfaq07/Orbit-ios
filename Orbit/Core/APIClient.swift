import Foundation

struct APIError: LocalizedError, Equatable {
    let status: Int
    let message: String
    var errorDescription: String? { message }
    var isUnauthorized: Bool { status == 401 }
}

/// Thin client for the Orbit FastAPI backend (`apps/api` in iamishfaq07/ishai). Sends the keychain token as a Bearer
/// header; the server answers native callers with `access_token` on sign-in.
actor APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let urlSession: URLSession
    private var token: String?

    init(baseURL: URL = APIClient.configuredBaseURL(), urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    static func configuredBaseURL() -> URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "ORBIT_API_URL") as? String
        return URL(string: raw ?? "") ?? URL(string: "https://api.orbitanswer.com")!
    }

    func setToken(_ token: String?) { self.token = token }

    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        try await send(method: "GET", path: path, query: query, body: Optional<Empty>.none)
    }

    func post<T: Decodable, B: Encodable & Sendable>(_ path: String, body: B) async throws -> T {
        try await send(method: "POST", path: path, query: [], body: body)
    }

    func patch<T: Decodable, B: Encodable & Sendable>(_ path: String, body: B) async throws -> T {
        try await send(method: "PATCH", path: path, query: [], body: body)
    }

    /// A DELETE that carries a body and answers 204.
    func delete<B: Encodable & Sendable>(_ path: String, body: B) async throws {
        let _: Empty = try await send(method: "DELETE", path: path, query: [], body: body)
    }

    func postVoid(_ path: String) async throws {
        let _: Empty = try await send(method: "POST", path: path, query: [], body: Optional<Empty>.none)
    }

    struct Empty: Codable {}

    private func send<T: Decodable, B: Encodable & Sendable>(method: String, path: String, query: [URLQueryItem], body: B?) async throws -> T {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { comps.queryItems = query }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try Self.encoder.encode(body)
        }
        let (data, resp) = try await urlSession.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw APIError(status: status, message: Self.message(from: data, status: status))
        }
        if T.self == Empty.self || data.isEmpty { return Empty() as! T }
        return try Self.decoder.decode(T.self, from: data)
    }

    /// FastAPI errors are `{"detail": "text"}` or `{"detail": {...}}`; candidates never see server internals.
    static func message(from data: Data, status: Int) -> String {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let detail = obj["detail"] as? String {
            return detail
        }
        return status == 401 ? "Please sign in again." : "Something went wrong. Please try again."
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let s = try decoder.singleValueContainer().decode(String.self)
            if let date = ISO8601.fractional.date(from: s) ?? ISO8601.plain.date(from: s) ?? ISO8601.naive(s) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad date \(s)"))
        }
        return d
    }()
}

/// The API emits ISO-8601 with or without fractional seconds, and sometimes without a zone (treated as UTC).
enum ISO8601 {
    nonisolated(unsafe) static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f
    }()
    nonisolated(unsafe) static let plain = ISO8601DateFormatter()
    static func naive(_ s: String) -> Date? { plain.date(from: s + "Z") ?? fractional.date(from: s + "Z") }
}
