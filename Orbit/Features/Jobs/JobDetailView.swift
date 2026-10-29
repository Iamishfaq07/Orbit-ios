import SwiftUI

struct JobDetailView: View {
    let job: Job
    let model: DiscoverViewModel
    @State private var detail: JobDetail?
    @State private var error: String?
    @State private var busy = false
    @Environment(\.openURL) private var openURL

    private var current: Job { model.jobs.first { $0.id == job.id } ?? job }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(current.title).font(Theme.title(26))
                Text("\(current.company) · \(current.place)").foregroundStyle(.secondary)
                if let salary = current.salary { Text(salary).font(.subheadline) }
                if let status = current.tracked?.status { RouteLine(status: status) }

                if let match = current.match { matchSection(match) }

                Text(current.snippet).font(.body)

                if let checks = detail?.checks, !checks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("About this posting").font(.headline)
                        ForEach(checks) { Text("• \($0.text)").font(.subheadline).foregroundStyle(.secondary) }
                    }
                }
                if let error { Text(error).font(.footnote).foregroundStyle(Theme.pastDue) }
                actions
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { detail = try? await APIClient.shared.get("/v1/jobs/listings/\(job.id)") }
    }

    private func matchSection(_ match: JobMatch) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(match.score)% match").font(.headline)
            if !match.matched.isEmpty { Text("Your resume shows: " + match.matched.joined(separator: ", ")).font(.subheadline) }
            if !match.missing.isEmpty {
                Text("Asked for, not on your resume: " + match.missing.joined(separator: ", ")).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var actions: some View {
        VStack(spacing: 12) {
            if current.tracked == nil {
                Button { update(.saved) } label: { label("Save job") }.buttonStyle(.borderedProminent)
            } else if current.tracked?.status == .saved {
                Button { update(.applied) } label: { label("I applied") }.buttonStyle(.borderedProminent)
            }
            if let link = current.applyLink {
                Button { openURL(link) } label: { label("View posting") }.buttonStyle(.bordered)
            }
        }
        .disabled(busy)
    }

    private func label(_ text: String) -> some View { Text(text).frame(maxWidth: .infinity, minHeight: 44) }

    private func update(_ status: JobStatus) {
        busy = true; error = nil
        Task {
            defer { busy = false }
            do { try await model.track(current, as: status) } catch { self.error = error.localizedDescription }
        }
    }
}
