import SwiftUI

/// Route green, the web app's default accent (`packages/ui/src/design/design.ts`). Accent marks the route line,
/// the next stop and the one main action only; rose means past due; nothing else is coloured.
enum Theme {
    static let accent = Color(rgb: (24, 106, 90))          // route-600: white on it is 6.5:1
    static let accentStrong = Color(rgb: (19, 86, 73))     // route-700
    static let accentTint = Color(rgb: (225, 242, 236))    // route-100
    static let pastDue = Color(red: 190 / 255, green: 18 / 255, blue: 60 / 255) // rose-700

    /// Titles (greeting, next stop, job title) use a serif, like Source Serif 4 on the web.
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .semibold, design: .serif) }
}

extension Color {
    init(rgb: (Int, Int, Int)) {
        self.init(red: Double(rgb.0) / 255, green: Double(rgb.1) / 255, blue: Double(rgb.2) / 255)
    }
}
