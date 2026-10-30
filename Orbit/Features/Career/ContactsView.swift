import SwiftUI

@MainActor @Observable
final class ContactsViewModel {
    enum Phase: Equatable { case loading, loaded, failed(String) }
    private(set) var contacts: [Contact] = []
    private(set) var phase: Phase = .loading

    func load() async {
        do {
            contacts = try await APIClient.shared.get("/v1/jobs/contacts")
            phase = .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

struct ContactsView: View {
    @State private var model = ContactsViewModel()

    var body: some View {
        Group {
            switch model.phase {
            case .loading: ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView("Couldn't load your contacts", systemImage: "wifi.slash", description: Text(message))
            case .loaded where model.contacts.isEmpty:
                ContentUnavailableView("No contacts yet", systemImage: "person.2",
                                       description: Text("People who can refer or advise you show up here once you add them on the web app."))
            case .loaded:
                List(model.contacts) { contact in
                    NavigationLink(value: contact) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name).font(Theme.title(18))
                            if !contact.role.isEmpty { Text(contact.role).font(.subheadline).foregroundStyle(.secondary) }
                            if let due = contact.followUpAt {
                                Text("Follow up \(due.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.footnote).foregroundStyle(contact.followUpIsDue ? Theme.pastDue : .secondary)
                            }
                        }
                        .padding(.vertical, 6).frame(minHeight: 48, alignment: .leading)
                    }
                }
            }
        }
        .navigationTitle("Contacts")
        .navigationDestination(for: Contact.self) { ContactDetailView(contact: $0) }
        .task { await model.load() }
        .refreshable { await model.load() }
    }
}

struct ContactDetailView: View {
    let contact: Contact
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name).font(Theme.title(24))
                    if !contact.role.isEmpty { Text(contact.role).foregroundStyle(.secondary) }
                    Text(contact.relation.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let label = contact.applicationLabel {
                Section("Linked job") { Text(label) }
            }
            Section("Follow-up") {
                if let due = contact.followUpAt {
                    Text(due.formatted(date: .complete, time: .omitted))
                        .foregroundStyle(contact.followUpIsDue ? Theme.pastDue : .primary)
                }
                if let last = contact.lastContactedAt {
                    Text("Last contacted \(last.formatted(date: .abbreviated, time: .omitted))").foregroundStyle(.secondary)
                } else if contact.followUpAt == nil {
                    Text("Nothing planned").foregroundStyle(.secondary)
                }
            }
            if contact.mailLink != nil || contact.phoneLink != nil || contact.linkedinLink != nil {
                Section("Reach them") {
                    if let mail = contact.mailLink { Button(contact.email ?? "Email") { openURL(mail) }.frame(minHeight: 44) }
                    if let tel = contact.phoneLink { Button(contact.phone ?? "Call") { openURL(tel) }.frame(minHeight: 44) }
                    if let link = contact.linkedinLink { Button("LinkedIn") { openURL(link) }.frame(minHeight: 44) }
                }
            }
            if !contact.notes.isEmpty { Section("Notes") { Text(contact.notes) } }
            Section { Text("To edit this contact or draft a message, open Orbit on the web.").font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
