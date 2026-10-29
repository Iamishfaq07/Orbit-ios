import Observation

@MainActor @Observable
final class JobsViewModel {
    enum Phase { case loading, loaded, failed(String) }

    private(set) var jobs: [TrackedJob] = []
    private(set) var phase: Phase = .loading

    func load() async {
        do {
            jobs = try await APIClient.shared.get("/v1/jobs/tracker")
            phase = .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    var active: [TrackedJob] { jobs.filter { $0.status.routeIndex != nil } }
    var closed: [TrackedJob] { jobs.filter { $0.status.routeIndex == nil } }

    /// The nearest dated stop across active jobs, past due first (Today's "next stop").
    var nextStop: TrackedJob? {
        active.filter { $0.nextAt != nil }.min { $0.nextAt! < $1.nextAt! }
    }
}
