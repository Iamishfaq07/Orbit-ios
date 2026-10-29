import SwiftUI

struct TrackerView: View {
    @State private var model = JobsViewModel()

    var body: some View {
        Group {
            switch model.phase {
            case .loading: ProgressView()
            case .failed(let message): ContentUnavailableView("Couldn't load your jobs", systemImage: "wifi.slash", description: Text(message))
            case .loaded where model.jobs.isEmpty:
                ContentUnavailableView("No jobs yet", systemImage: "briefcase", description: Text("Jobs you save show up here with their route."))
            case .loaded:
                List {
                    Section {
                        ForEach(model.active) { job in NavigationLink(value: job) { JobRow(job: job) } }
                    }
                    if !model.closed.isEmpty {
                        Section("Closed (\(model.closed.count))") {
                            ForEach(model.closed) { job in NavigationLink(value: job) { JobRow(job: job) } }
                        }
                    }
                }
                .navigationDestination(for: TrackedJob.self) { TrackedJobDetailView(job: $0, model: model) }
            }
            }
        .task { await model.load() }
        .refreshable { await model.load() }
    }
}

struct JobsView: View {
    enum Tab: String, CaseIterable { case discover = "Discover", tracker = "Tracker" }
    @State private var tab: Tab = .discover

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Jobs", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).padding(.horizontal, 16).padding(.vertical, 8)
                switch tab {
                case .discover: DiscoverView()
                case .tracker: TrackerView()
                }
            }
            .navigationTitle("Jobs").navigationBarTitleDisplayMode(.inline)
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
