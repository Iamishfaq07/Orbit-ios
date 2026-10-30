import SwiftUI

struct CareerView: View {
    @Environment(SessionStore.self) private var session
    @State private var deleting = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let user = session.user {
                        LabeledContent("Email", value: user.email)
                    }
                    Button("Sign out", role: .destructive) { Task { await session.signOut() } }
                        .frame(minHeight: 44)
                    Button("Delete account", role: .destructive) { deleting = true }
                        .frame(minHeight: 44)
                }
                Section("Materials") {
                    NavigationLink("Resumes") { ResumesView() }.frame(minHeight: 44)
                    NavigationLink("Offers") { OffersView() }.frame(minHeight: 44)
                    NavigationLink("Stories") { StoriesView() }.frame(minHeight: 44)
                    NavigationLink("Contacts") { ContactsView() }.frame(minHeight: 44)
                    Text("LinkedIn is coming next.").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("My Career")
            .sheet(isPresented: $deleting) { DeleteAccountView() }
        }
    }
}
