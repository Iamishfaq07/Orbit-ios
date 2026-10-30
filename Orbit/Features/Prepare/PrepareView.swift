import SwiftUI

@MainActor @Observable
final class PracticeQueueViewModel {
    enum Phase: Equatable { case loading, loaded, failed(String) }
    private(set) var queue: PracticeQueue?
    private(set) var phase: Phase = .loading

    func load() async {
        do {
            queue = try await APIClient.shared.get("/v1/practice/queue")
            phase = .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

struct PrepareView: View {
    @State private var model = PracticeQueueViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Practice queue") { queue }
                Section {
                    Text("Mock interviews, aptitude and coding practice run on the web and desktop apps for now.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Prepare")
            .task { await model.load() }
            .refreshable { await model.load() }
        }
    }

    @ViewBuilder private var queue: some View {
        switch model.phase {
        case .loading:
            ProgressView().frame(maxWidth: .infinity)
        case .failed(let message):
            Text(message).font(.footnote).foregroundStyle(Theme.pastDue)
        case .loaded:
            if let queue = model.queue, !queue.isEmpty {
                if queue.due.isEmpty {
                    Text(queue.nextDueAt.map { "Nothing due. The next question comes back \($0.formatted(.relative(presentation: .named)))." }
                         ?? "Nothing due. Every question you struggled with is learnt.")
                        .frame(minHeight: 44, alignment: .leading)
                } else {
                    Text("\(queue.due.count) question\(queue.due.count == 1 ? "" : "s") due for practice")
                        .font(.headline).frame(minHeight: 44, alignment: .leading)
                    ForEach(queue.due) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.question)
                            Text(detail(item)).font(.footnote).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    Text("Start a practice round from the web or desktop app.").font(.footnote).foregroundStyle(.secondary)
                }
                if queue.learnt > 0 { Text("\(queue.learnt) learnt so far.").font(.footnote).foregroundStyle(.secondary) }
            } else {
                Text("Questions you answer weakly in a mock interview review come back here on a schedule.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private func detail(_ item: PracticeQueue.Item) -> String {
        let tries = "\(item.attempts) \(item.attempts == 1 ? "try" : "tries")"
        // A score is only worth showing when there is one.
        guard let score = item.lastScore else { return tries }
        return "Last score \(score) · \(tries)"
    }
}
