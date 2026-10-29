import Observation
import Foundation

@MainActor @Observable
final class DiscoverViewModel {
    enum Phase: Equatable { case loading, loaded, failed(String) }

    private(set) var jobs: [Job] = []
    private(set) var phase: Phase = .loading
    private(set) var hasMore = false
    private(set) var hasProfile = true
    var query = ""
    private var page = 1

    func reload() async {
        page = 1
        do {
            let feed = try await fetch(page: 1)
            jobs = feed.items; hasMore = feed.hasMore; hasProfile = feed.hasProfile
            phase = .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func loadMore(after job: Job) async {
        guard hasMore, job.id == jobs.last?.id else { return }
        do {
            let feed = try await fetch(page: page + 1)
            page += 1
            let seen = Set(jobs.map(\.id))
            jobs += feed.items.filter { !seen.contains($0.id) }
            hasMore = feed.hasMore
        } catch {
            // Keep what's on screen; the next scroll to the end tries again.
        }
    }

    /// Saves a job to the tracker (or moves it to `status`) and updates the row in place.
    func track(_ job: Job, as status: JobStatus = .saved) async throws {
        struct Body: Encodable { let listingId: String; let status: JobStatus }
        let entry: TrackedJob = try await APIClient.shared.post("/v1/jobs/tracker", body: Body(listingId: job.id, status: status))
        if let i = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[i].tracked = TrackedRef(id: entry.id, status: entry.status)
        }
    }

    private func fetch(page: Int) async throws -> FeedPage {
        var items = [URLQueryItem(name: "page", value: String(page))]
        let q = query.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty { items.append(URLQueryItem(name: "q", value: q)) }
        return try await APIClient.shared.get("/v1/jobs/feed", query: items)
    }
}
