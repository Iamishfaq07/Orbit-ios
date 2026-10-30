import SwiftUI

@MainActor @Observable
final class ResumesViewModel {
    enum Phase: Equatable { case loading, loaded, failed(String) }
    private(set) var resumes: [ResumeSummary] = []
    private(set) var phase: Phase = .loading

    func load() async {
        do {
            resumes = try await APIClient.shared.get("/v1/resumes")
            phase = .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

struct ResumesView: View {
    @State private var model = ResumesViewModel()

    var body: some View {
        Group {
            switch model.phase {
            case .loading: ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView("Couldn't load your resumes", systemImage: "wifi.slash", description: Text(message))
            case .loaded where model.resumes.isEmpty:
                ContentUnavailableView("No resume yet", systemImage: "doc.text",
                                       description: Text("Build one on the web app and it shows up here."))
            case .loaded:
                List(model.resumes) { resume in
                    NavigationLink(value: resume) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(resume.title).font(Theme.title(18))
                            if !resume.headline.isEmpty { Text(resume.headline).font(.subheadline).foregroundStyle(.secondary) }
                            // A score of zero means "not scored yet", never a number to show.
                            Text(resume.score > 0 ? "ATS score \(resume.score) · updated \(resume.updatedAt.formatted(date: .abbreviated, time: .omitted))"
                                                  : "Updated \(resume.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6).frame(minHeight: 48, alignment: .leading)
                    }
                }
            }
        }
        .navigationTitle("Resumes")
        .navigationDestination(for: ResumeSummary.self) { ResumeDetailView(summary: $0) }
        .task { await model.load() }
        .refreshable { await model.load() }
    }
}

struct ResumeDetailView: View {
    let summary: ResumeSummary
    @State private var resume: Resume?
    @State private var error: String?

    var body: some View {
        ScrollView {
            if let resume {
                content(resume.data)
            } else if let error {
                ContentUnavailableView("Couldn't open this resume", systemImage: "wifi.slash", description: Text(error))
            } else {
                ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
            }
        }
        .navigationTitle(summary.title).navigationBarTitleDisplayMode(.inline)
        .task {
            do { resume = try await APIClient.shared.get("/v1/resumes/\(summary.id)") } catch { self.error = error.localizedDescription }
        }
    }

    @ViewBuilder private func content(_ d: ResumeContent) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 4) {
                Text(d.basics.name).font(Theme.title(26))
                if !d.basics.headline.isEmpty { Text(d.basics.headline).foregroundStyle(.secondary) }
                let contact = [d.basics.email, d.basics.phone, d.basics.location].filter { !$0.isEmpty }.joined(separator: " · ")
                if !contact.isEmpty { Text(contact).font(.footnote).foregroundStyle(.secondary) }
            }
            if !d.basics.summary.isEmpty { section("Summary") { Text(d.basics.summary) } }

            if d.shows("experience"), !d.experience.isEmpty {
                section("Experience") {
                    ForEach(d.experience) { role in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(role.title).font(.headline)
                            Text([role.company, role.dates].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.subheadline).foregroundStyle(.secondary)
                            bullets(role.bullets)
                        }
                    }
                }
            }
            if d.shows("education"), !d.education.isEmpty {
                section("Education") {
                    ForEach(d.education) { e in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.school).font(.headline)
                            Text([[e.degree, e.field].filter { !$0.isEmpty }.joined(separator: ", "), e.dates, e.grade]
                                .filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if d.shows("skills"), !d.skills.isEmpty {
                section("Skills") {
                    ForEach(d.skills) { g in
                        Text(g.name.isEmpty ? g.items.joined(separator: ", ") : "\(g.name): \(g.items.joined(separator: ", "))")
                    }
                }
            }
            if d.shows("projects"), !d.projects.isEmpty {
                section("Projects") {
                    ForEach(d.projects) { p in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.name).font(.headline)
                            if !p.description.isEmpty { Text(p.description).font(.subheadline) }
                            bullets(p.bullets)
                        }
                    }
                }
            }
            Text("To edit this resume, open Orbit on the web.").font(.footnote).foregroundStyle(.secondary)
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ body: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(Theme.accentStrong)
            body()
        }
    }

    @ViewBuilder private func bullets(_ items: [String]) -> some View {
        ForEach(items, id: \.self) { Text("• \($0)").font(.subheadline) }
    }
}
