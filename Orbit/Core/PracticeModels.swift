import Foundation

/// `GET /v1/practice/queue` (PracticeQueueOut): questions answered weakly in a review, coming back on a spaced
/// schedule (the next day, then 3, 7 and 21 days) until answered well.
struct PracticeQueue: Decodable {
    let due: [Item]
    /// Coming back later: how many, and when the next one is due.
    let upcoming: Int
    let nextDueAt: Date?
    let learnt: Int

    struct Item: Decodable, Identifiable, Hashable {
        let question: String
        let lastScore: Int?
        let attempts: Int
        let lastPractisedAt: Date
        let dueAt: Date
        let sessionId: String

        var id: String { sessionId + "|" + question }
    }

    /// Nothing at all to show yet: no weak answers have been reviewed.
    var isEmpty: Bool { due.isEmpty && upcoming == 0 && learnt == 0 }
}
