import SwiftUI

struct DiscoverView: View {
    @State private var model = DiscoverViewModel()

    var body: some View {
        Group {
            switch model.phase {
            case .loading: ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView("Couldn't load jobs", systemImage: "wifi.slash", description: Text(message))
            case .loaded:
                List {
                    if !model.hasProfile {
                        Text("Add a resume on the web app to see how well each job matches you.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(model.jobs) { job in
                        NavigationLink(value: job) { DiscoverRow(job: job) }
                            .task { await model.loadMore(after: job) }
                    }
                }
                .listStyle(.plain)
                .overlay { if model.jobs.isEmpty { ContentUnavailableView.search(text: model.query) } }
            }
        }
        .searchable(text: $model.query, prompt: "Role, city or skill")
        .onSubmit(of: .search) { Task { await model.reload() } }
        .navigationDestination(for: Job.self) { JobDetailView(job: $0, model: model) }
        .task { await model.reload() }
        .refreshable { await model.reload() }
    }
}

extension Job: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct DiscoverRow: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(job.title).font(Theme.title(18))
                Spacer(minLength: 8)
                if let score = job.match?.score { Text("\(score)%").font(.subheadline.monospacedDigit()).foregroundStyle(Theme.accentStrong) }
            }
            Text("\(job.company) · \(job.place)").font(.subheadline).foregroundStyle(.secondary)
            if let tracked = job.tracked { Text(tracked.status.title).font(.footnote).foregroundStyle(.secondary) }
        }
        .padding(.vertical, 6).frame(minHeight: 48, alignment: .leading)
    }
}
