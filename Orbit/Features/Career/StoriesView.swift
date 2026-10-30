import SwiftUI

@MainActor @Observable
final class StoriesViewModel {
    enum Phase: Equatable { case loading, loaded, failed(String) }
    private(set) var stories: [Story] = []
    private(set) var phase: Phase = .loading

    func load() async {
        do {
            stories = try await APIClient.shared.get("/v1/stories")
            phase = .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

struct StoriesView: View {
    @State private var model = StoriesViewModel()

    var body: some View {
        Group {
            switch model.phase {
            case .loading: ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView("Couldn't load your stories", systemImage: "wifi.slash", description: Text(message))
            case .loaded where model.stories.isEmpty:
                ContentUnavailableView("No stories yet", systemImage: "text.book.closed",
                                       description: Text("Write a few STAR stories on the web app for interviews, and read them here."))
            case .loaded:
                List(model.stories) { story in
                    NavigationLink(value: story) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(story.title).font(Theme.title(18))
                            if !story.competencies.isEmpty {
                                Text(story.competencies.map(\.capitalized).joined(separator: " · "))
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6).frame(minHeight: 48, alignment: .leading)
                    }
                }
            }
        }
        .navigationTitle("Stories")
        .navigationDestination(for: Story.self) { StoryDetailView(story: $0) }
        .task { await model.load() }
        .refreshable { await model.load() }
    }
}

struct StoryDetailView: View {
    let story: Story

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(story.title).font(Theme.title(24))
                ForEach(story.parts, id: \.label) { part in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(part.label).font(.headline).foregroundStyle(Theme.accentStrong)
                        Text(part.text)
                    }
                }
                Text("To edit this story or practise it out loud, open Orbit on the web.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
