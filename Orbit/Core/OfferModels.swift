import Foundation

/// `GET /v1/offers` (OfferOut), only what the app shows.
struct Offer: Decodable, Identifiable, Hashable {
    let id: String
    let company: String
    let role: String
    let city: String
    let currency: String
    let fixed: Int
    let variable: Int
    let joiningBonus: Int
    let equityPerYear: Int
    let other: Int
    let firstYear: Int
    let yearly: Int
    let status: Status
    let deadline: Date?
    let notes: String
    /// India only.
    let takeHome: TakeHome?
    let market: Market?
    let position: Position?

    enum Status: String, Decodable { case considering, accepted, declined
        var title: String {
            switch self {
            case .considering: "Considering"
            case .accepted: "Accepted"
            case .declined: "Declined"
            }
        }
    }

    enum Position: String, Decodable { case below, within, above }

    struct TakeHome: Decodable, Hashable {
        let monthly: Int
        let assumptions: [String]
    }

    struct Market: Decodable, Hashable {
        let count: Int
        let p25: Double
        let median: Double
        let p75: Double
        let scope: String
    }
}

enum Money {
    /// Whole units in the offer's currency; rupees group in lakhs and crores the way people write them.
    static func format(_ amount: Double, currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currency
        f.maximumFractionDigits = 0
        if currency == "INR" { f.locale = Locale(identifier: "en_IN") }
        return f.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }

    static func format(_ amount: Int, currency: String) -> String { format(Double(amount), currency: currency) }
}
