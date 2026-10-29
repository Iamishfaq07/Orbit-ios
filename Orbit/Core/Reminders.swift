import Foundation
import UserNotifications

/// One reminder for a job's next stop.
struct StopReminder: Equatable {
    let id: String
    let fireAt: Date
    let title: String
    let body: String
}

/// On-device reminders an hour before each job's next stop. Local notifications need no push server or keys and work
/// offline; they are rebuilt from the tracker whenever it loads or changes.
enum Reminders {
    static let prefix = "orbit.stop."
    /// iOS keeps at most 64 pending local notifications per app.
    static let limit = 60
    static let lead: TimeInterval = 60 * 60

    /// Which reminders should exist for these jobs. Closed jobs and stops that are already inside the lead time get none.
    static func plan(jobs: [TrackedJob], now: Date = .now) -> [StopReminder] {
        jobs.compactMap { job -> StopReminder? in
            guard job.status.routeIndex != nil, let when = job.nextAt else { return nil }
            let fire = when.addingTimeInterval(-lead)
            guard fire > now else { return nil }
            return StopReminder(id: prefix + job.id, fireAt: fire,
                                title: "Next stop in an hour: \(job.company)",
                                body: job.title)
        }
        .sorted { $0.fireAt < $1.fireAt }
        .prefix(limit)
        .map { $0 }
    }

    /// Asks once; returns whether reminders are allowed. Call when the person sets a date, not at launch.
    @MainActor static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Replaces our pending reminders with the plan. Never prompts: without permission it does nothing.
    @MainActor static func sync(jobs: [TrackedJob]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        await clear()
        for item in plan(jobs: jobs) {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.fireAt)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: item.id, content: content, trigger: trigger))
        }
    }

    /// Removes our pending reminders (on sign-out the next person must not get them).
    @MainActor static func clear() async {
        let center = UNUserNotificationCenter.current()
        let ours = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)
    }
}
