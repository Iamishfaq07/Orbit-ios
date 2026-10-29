import SwiftUI

@main
struct OrbitApp: App {
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .tint(Theme.accent)
                .task { await session.restore() }
        }
    }
}

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        switch session.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .signedOut:
            SignInView()
        case .signedIn:
            MainTabs()
        }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            TodayView().tabItem { Label("Today", systemImage: "sun.max") }
            JobsView().tabItem { Label("Jobs", systemImage: "briefcase") }
            PrepareView().tabItem { Label("Prepare", systemImage: "text.bubble") }
            CareerView().tabItem { Label("My Career", systemImage: "person.text.rectangle") }
        }
    }
}
