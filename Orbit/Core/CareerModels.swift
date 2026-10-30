import Foundation

/// `GET /v1/stories` (StoryOut): one STAR story.
struct Story: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let situation: String
    let task: String
    let action: String
    let result: String
    let competencies: [String]
    let updatedAt: Date

    /// The STAR parts that have been written, in order.
    var parts: [(label: String, text: String)] {
        [("Situation", situation), ("Task", task), ("Action", action), ("Result", result)]
            .filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

/// `GET /v1/jobs/contacts` (ContactOut). The server lists follow-ups that are due first.
struct Contact: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let company: String
    let title: String
    let relation: String
    let linkedinUrl: String?
    let email: String?
    let phone: String?
    let notes: String
    let applicationLabel: String?
    let lastContactedAt: Date?
    let followUpAt: Date?

    var followUpIsDue: Bool { followUpAt.map { $0 <= .now } ?? false }

    /// "Engineer at Acme", whichever parts exist.
    var role: String {
        switch (title.isEmpty, company.isEmpty) {
        case (true, true): return ""
        case (false, true): return title
        case (true, false): return company
        default: return "\(title) at \(company)"
        }
    }

    /// Only http(s) links open; mail and phone links are built here, never taken from the server as-is.
    var linkedinLink: URL? {
        guard let raw = linkedinUrl, let u = URL(string: raw), ["http", "https"].contains(u.scheme?.lowercased()) else { return nil }
        return u
    }
    var mailLink: URL? { email.flatMap { $0.isEmpty ? nil : URL(string: "mailto:\($0)") } }
    var phoneLink: URL? {
        guard let phone else { return nil }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : URL(string: "tel:\(digits)")
    }
}
