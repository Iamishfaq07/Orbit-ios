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
            await Reminders.sync(jobs: jobs)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// Applies a change on the server and swaps the answer into the list.
    func update(_ job: TrackedJob, with patch: TrackPatch) async throws {
        let updated: TrackedJob = try await APIClient.shared.patch("/v1/jobs/tracker/\(job.id)", body: patch)
        if let i = jobs.firstIndex(where: { $0.id == job.id }) { jobs[i] = updated }
        // Setting a date is the moment to ask; any other change just keeps existing reminders in step.
        if patch.nextAt != nil { _ = await Reminders.requestPermission() }
        await Reminders.sync(jobs: jobs)
    }

    var active: [TrackedJob] { jobs.filter { $0.status.routeIndex != nil } }
    var closed: [TrackedJob] { jobs.filter { $0.status.routeIndex == nil } }

    /// The nearest dated stop across active jobs, past due first (Today's "next stop").
    var nextStop: TrackedJob? {
        active.filter { $0.nextAt != nil }.min { $0.nextAt! < $1.nextAt! }
    }
}
