import SwiftUI

/// A tracked job: move it along the route, set when the next stop is, keep notes.
struct TrackedJobDetailView: View {
    let job: TrackedJob
    let model: JobsViewModel

    @State private var notes: String
    @State private var hasNext: Bool
    @State private var nextDate: Date
    @State private var busy = false
    @State private var error: String?
    @Environment(\.openURL) private var openURL

    init(job: TrackedJob, model: JobsViewModel) {
        self.job = job
        self.model = model
        _notes = State(initialValue: job.notes)
        _hasNext = State(initialValue: job.nextAt != nil)
        _nextDate = State(initialValue: job.nextAt ?? Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now)
    }

    /// The list's copy, so the screen follows what the server last said.
    private var current: TrackedJob { model.jobs.first { $0.id == job.id } ?? job }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(current.title).font(Theme.title(24))
                    Text(current.company + (current.location.isEmpty ? "" : " · \(current.location)")).foregroundStyle(.secondary)
                    RouteLine(status: current.status)
                }
                .padding(.vertical, 4)
            }

            Section("Stage") {
                Picker("Stage", selection: statusBinding) {
                    ForEach(JobStatus.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .frame(minHeight: 44)
            }

            Section("Next stop") {
                Toggle("Has a date", isOn: $hasNext.animation()).frame(minHeight: 44)
                if hasNext {
                    DatePicker("When", selection: $nextDate).frame(minHeight: 44)
                }
                Button("Save date") { save(hasNext ? TrackPatch(nextAt: nextDate) : TrackPatch(clearNext: true)) }
                    .frame(minHeight: 44)
                    .disabled(busy || !dateChanged)
            }

            Section("Notes") {
                TextEditor(text: $notes).frame(minHeight: 120)
                Button("Save notes") { save(TrackPatch(notes: notes)) }
                    .frame(minHeight: 44)
                    .disabled(busy || notes == current.notes)
            }

            if let link = postingLink {
                Section { Button("View posting") { openURL(link) }.frame(minHeight: 44) }
            }
            if let error { Section { Text(error).font(.footnote).foregroundStyle(Theme.pastDue) } }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusBinding: Binding<JobStatus> {
        Binding(get: { current.status }, set: { new in
            guard new != current.status else { return }
            save(TrackPatch(status: new))
        })
    }

    private var dateChanged: Bool {
        guard let saved = current.nextAt else { return hasNext }
        return !hasNext || abs(saved.timeIntervalSince(nextDate)) > 30
    }

    private var postingLink: URL? {
        guard let u = URL(string: current.url), ["http", "https"].contains(u.scheme?.lowercased()) else { return nil }
        return u
    }

    private func save(_ patch: TrackPatch) {
        busy = true; error = nil
        Task {
            defer { busy = false }
            do { try await model.update(current, with: patch) } catch { self.error = error.localizedDescription }
        }
    }
}
