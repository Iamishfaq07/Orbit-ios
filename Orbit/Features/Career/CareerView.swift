import SwiftUI

struct CareerView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let user = session.user {
                        LabeledContent("Email", value: user.email)
                    }
                    Button("Sign out", role: .destructive) { Task { await session.signOut() } }
                        .frame(minHeight: 44)
                }
                Section("Materials") {
                    NavigationLink("Resumes") { ResumesView() }.frame(minHeight: 44)
                    Text("Stories, LinkedIn, contacts and offers are coming next.").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("My Career")
        }
    }
}
