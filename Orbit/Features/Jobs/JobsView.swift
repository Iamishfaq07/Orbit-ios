import SwiftUI

struct JobsView: View {
    @State private var model = JobsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch model.phase {
                case .loading: ProgressView()
                case .failed(let message): ContentUnavailableView("Couldn't load your jobs", systemImage: "wifi.slash", description: Text(message))
                case .loaded where model.jobs.isEmpty:
                    ContentUnavailableView("No jobs yet", systemImage: "briefcase", description: Text("Jobs you save show up here with their route."))
                case .loaded:
                    List {
                        Section { ForEach(model.active) { JobRow(job: $0) } }
                        if !model.closed.isEmpty {
                            Section("Closed (\(model.closed.count))") { ForEach(model.closed) { JobRow(job: $0) } }
                        }
                    }
                }
            }
            .navigationTitle("Jobs")
            .task { await model.load() }
            .refreshable { await model.load() }
        }
    }
}

struct JobRow: View {
    let job: TrackedJob

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(job.title).font(Theme.title(18))
            Text(job.company + (job.location.isEmpty ? "" : " · \(job.location)")).font(.subheadline).foregroundStyle(.secondary)
            RouteLine(status: job.status)
        }
        .padding(.vertical, 6)
        .frame(minHeight: 48, alignment: .leading)
    }
}
