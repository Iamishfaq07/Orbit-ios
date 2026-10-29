import Foundation

struct User: Codable, Equatable {
    let id: String
    let email: String
    let name: String?
    let emailVerified: Bool
    let country: String?
}

struct AuthResponse: Decodable {
    let user: User
    let accessToken: String?
}

/// `POST /v1/auth/login` answers with either a session or, when 2FA is on, a challenge.
enum LoginResult {
    case signedIn(AuthResponse)
    case twoFactor(challenge: String)
}

enum JobStatus: String, Codable, CaseIterable {
    case saved, applied, interviewing, offer, hired, rejected, withdrawn

    var title: String {
        switch self {
        case .saved: "Saved"
        case .applied: "Applied"
        case .interviewing: "Interviewing"
        case .offer: "Offer"
        case .hired: "Hired"
        case .rejected: "Not this time"
        case .withdrawn: "Withdrawn"
        }
    }

    /// Position on the route (Saved → Applied → Interviews → Offer); closed jobs have none.
    var routeIndex: Int? {
        switch self {
        case .saved: 0
        case .applied: 1
        case .interviewing: 2
        case .offer, .hired: 3
        case .rejected, .withdrawn: nil
        }
    }
}

/// `GET /v1/jobs/tracker` entry (TrackerOut).
struct TrackedJob: Codable, Identifiable, Equatable {
    let id: String
    let listingId: String
    let company: String
    let title: String
    let location: String
    let url: String
    let status: JobStatus
    let notes: String
    let appliedAt: Date?
    let nextAt: Date?
    let statusAt: Date
    let live: Bool
}

// MARK: - Discover (`GET /v1/jobs/feed`, `GET /v1/jobs/listings/{id}`)

struct JobMatch: Codable, Equatable {
    let score: Int
    let matched: [String]
    let missing: [String]
}

struct TrackedRef: Codable, Equatable {
    let id: String
    let status: JobStatus
}

/// JobOut: one post in the feed. Only the fields the app shows are decoded.
struct Job: Codable, Identifiable, Equatable {
    let id: String
    let sourceLabel: String
    let direct: Bool
    let company: String
    let title: String
    let place: String
    let experience: String?
    let postedAt: Date
    let url: String
    let applyUrl: String
    let snippet: String
    let salary: String?
    let match: JobMatch?
    var tracked: TrackedRef?
}

struct FeedPage: Decodable {
    let items: [Job]
    let total: Int
    let page: Int
    let hasMore: Bool
    let hasProfile: Bool
}

struct PostingCheck: Decodable, Equatable, Identifiable {
    let kind: String
    let tone: String
    let text: String
    var id: String { kind + text }
}

struct JobDetail: Decodable {
    let job: Job
    let fullText: Bool
    let checks: [PostingCheck]
}

extension Job {
    /// Apply only opens http(s) links; anything else from a feed is ignored.
    var applyLink: URL? {
        guard let u = URL(string: applyUrl.isEmpty ? url : applyUrl), ["http", "https"].contains(u.scheme?.lowercased()) else { return nil }
        return u
    }
}
