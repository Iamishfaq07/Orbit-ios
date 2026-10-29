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
