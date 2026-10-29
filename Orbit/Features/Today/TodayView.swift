import SwiftUI

/// Today answers "what should I do now?" first: the next dated stop, then one row per active route.
struct TodayView: View {
    @Environment(SessionStore.self) private var session
    @State private var model = JobsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(greeting).font(Theme.title(30))
                    nextStop
                    if !model.active.isEmpty {
                        Text("Your routes").font(.headline)
                        ForEach(model.active) { JobRow(job: $0); Divider() }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Today").navigationBarTitleDisplayMode(.inline)
            .task { await model.load() }
            .refreshable { await model.load() }
        }
    }

    private var greeting: String {
        let name = session.user?.name?.split(separator: " ").first.map(String.init)
        return name.map { "Hello, \($0)" } ?? "Hello"
    }

    @ViewBuilder private var nextStop: some View {
        if let job = model.nextStop, let when = job.nextAt {
            VStack(alignment: .leading, spacing: 8) {
                Text(when, format: .dateTime.weekday().day().month().hour().minute())
                    .font(.subheadline).foregroundStyle(when < .now ? Theme.pastDue : Theme.accentStrong)
                Text(job.title).font(Theme.title(22))
                Text(job.company).foregroundStyle(.secondary)
                RouteLine(status: job.status)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.accentTint.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        } else if case .loaded = model.phase {
            Text("Nothing is due. Save a job to start a route.").foregroundStyle(.secondary)
        }
    }
}
