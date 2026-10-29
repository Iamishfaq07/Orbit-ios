import SwiftUI

/// Saved → Applied → Interviews → Offer. Reached stops are filled, the next stop is ringed, the rest hollow.
/// Labels carry the stage, so nothing depends on colour. A closed job shows its stage as text instead.
struct RouteLine: View {
    let status: JobStatus
    private static let stops = ["Saved", "Applied", "Interviews", "Offer"]

    var body: some View {
        if let current = status.routeIndex {
            HStack(spacing: 0) {
                ForEach(Self.stops.indices, id: \.self) { i in
                    VStack(spacing: 4) {
                        stop(i, current: current)
                        Text(Self.stops[i]).font(.caption2).foregroundStyle(i <= current ? .primary : .secondary)
                    }
                    if i < Self.stops.count - 1 {
                        Rectangle().fill(i < current ? Theme.accent : Color.secondary.opacity(0.3))
                            .frame(height: 2).padding(.bottom, 16)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Route: \(status.title)")
        } else {
            Text(status.title).font(.footnote).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private func stop(_ i: Int, current: Int) -> some View {
        if i < current {
            Circle().fill(Theme.accent).frame(width: 12, height: 12)
        } else if i == current {
            Circle().strokeBorder(Theme.accent, lineWidth: 3).frame(width: 14, height: 14)
        } else {
            Circle().strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1.5).frame(width: 12, height: 12)
        }
    }
}
