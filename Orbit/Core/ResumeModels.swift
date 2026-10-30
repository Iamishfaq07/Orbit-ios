import Foundation

/// `GET /v1/resumes` (ResumeSummary).
struct ResumeSummary: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let name: String
    let headline: String
    let template: String
    let score: Int
    let hasJob: Bool
    let updatedAt: Date
}

/// `GET /v1/resumes/{id}` (ResumeOut), only what the app shows.
struct Resume: Decodable, Identifiable {
    let id: String
    let title: String
    let data: ResumeContent
    let updatedAt: Date
}

struct ResumeContent: Decodable {
    let basics: Basics
    let experience: [Role]
    let education: [Education]
    let skills: [SkillGroup]
    let projects: [Project]
    /// Sections kept in the editor but left off the resume ("experience", "projects", …).
    let hidden: [String]

    struct Basics: Decodable {
        let name: String
        let headline: String
        let email: String
        let phone: String
        let location: String
        let summary: String
    }

    struct Role: Decodable, Identifiable {
        let id: String
        let title: String
        let company: String
        let location: String
        let start: String
        let end: String
        let current: Bool
        let bullets: [String]

        var dates: String { ResumeContent.range(start, end, current: current) }
    }

    struct Education: Decodable, Identifiable {
        let id: String
        let school: String
        let degree: String
        let field: String
        let start: String
        let end: String
        let grade: String

        var dates: String { ResumeContent.range(start, end, current: false) }
    }

    struct SkillGroup: Decodable, Identifiable {
        let id: String
        let name: String
        let items: [String]
    }

    struct Project: Decodable, Identifiable {
        let id: String
        let name: String
        let description: String
        let bullets: [String]
    }

    func shows(_ section: String) -> Bool { !hidden.contains(section) }

    static func range(_ start: String, _ end: String, current: Bool) -> String {
        let to = current ? "Present" : end
        switch (start.isEmpty, to.isEmpty) {
        case (true, true): return ""
        case (false, true): return start
        case (true, false): return to
        default: return "\(start) – \(to)"
        }
    }
}
