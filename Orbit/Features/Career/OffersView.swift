import SwiftUI

@MainActor @Observable
final class OffersViewModel {
    enum Phase: Equatable { case loading, loaded, failed(String) }
    private(set) var offers: [Offer] = []
    private(set) var phase: Phase = .loading

    func load() async {
        do {
            offers = try await APIClient.shared.get("/v1/offers")
            phase = .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

struct OffersView: View {
    @State private var model = OffersViewModel()

    var body: some View {
        Group {
            switch model.phase {
            case .loading: ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView("Couldn't load your offers", systemImage: "wifi.slash", description: Text(message))
            case .loaded where model.offers.isEmpty:
                ContentUnavailableView("No offers yet", systemImage: "doc.plaintext",
                                       description: Text("Add an offer on the web app to compare it here."))
            case .loaded:
                List(model.offers) { offer in
                    NavigationLink(value: offer) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(offer.company).font(Theme.title(18))
                            Text(offer.role).font(.subheadline).foregroundStyle(.secondary)
                            Text("\(Money.format(offer.yearly, currency: offer.currency)) a year · \(offer.status.title)")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6).frame(minHeight: 48, alignment: .leading)
                    }
                }
            }
        }
        .navigationTitle("Offers")
        .navigationDestination(for: Offer.self) { OfferDetailView(offer: $0) }
        .task { await model.load() }
        .refreshable { await model.load() }
    }
}

struct OfferDetailView: View {
    let offer: Offer

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.company).font(Theme.title(24))
                    Text([offer.role, offer.city].filter { !$0.isEmpty }.joined(separator: " · ")).foregroundStyle(.secondary)
                    Text(offer.status.title).font(.footnote).foregroundStyle(.secondary)
                    if let deadline = offer.deadline {
                        Text("Reply by \(deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.footnote).foregroundStyle(deadline < .now && offer.status == .considering ? Theme.pastDue : .secondary)
                    }
                }
            }

            Section("Pay") {
                row("Fixed", offer.fixed)
                if offer.variable > 0 { row("Variable", offer.variable) }
                if offer.equityPerYear > 0 { row("Equity per year", offer.equityPerYear) }
                if offer.other > 0 { row("Other", offer.other) }
                if offer.joiningBonus > 0 { row("Joining bonus (once)", offer.joiningBonus) }
                row("Each year", offer.yearly, bold: true)
                row("First year", offer.firstYear, bold: true)
            }

            if let takeHome = offer.takeHome {
                Section("Take-home (an estimate)") {
                    row("About per month", takeHome.monthly)
                    DisclosureGroup("What this assumes") {
                        ForEach(takeHome.assumptions, id: \.self) { Text($0).font(.footnote).foregroundStyle(.secondary) }
                    }
                    .frame(minHeight: 44)
                }
            }

            if let market = offer.market, let position = offer.position {
                Section("Against job posts") {
                    Text(positionText(position)).frame(minHeight: 44, alignment: .leading)
                    Text("Middle half of \(market.count) posts for \(market.scope): \(Money.format(market.p25, currency: offer.currency)) to \(Money.format(market.p75, currency: offer.currency)), middle \(Money.format(market.median, currency: offer.currency)).")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            if !offer.notes.isEmpty { Section("Notes") { Text(offer.notes) } }
            Section { Text("To edit this offer or plan your negotiation, open Orbit on the web.").font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: String, _ amount: Int, bold: Bool = false) -> some View {
        LabeledContent(title) { Text(Money.format(amount, currency: offer.currency)).fontWeight(bold ? .semibold : .regular) }
            .frame(minHeight: 44)
    }

    private func positionText(_ p: Offer.Position) -> String {
        switch p {
        case .below: "The fixed pay is below the middle half of similar posts."
        case .within: "The fixed pay is within the middle half of similar posts."
        case .above: "The fixed pay is above the middle half of similar posts."
        }
    }
}
