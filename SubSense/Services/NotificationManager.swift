import Foundation
import UserNotifications
import SubSenseCore

@MainActor
final class NotificationManager {
    private let center = UNUserNotificationCenter.current()
    func requestPermission() async throws -> Bool { try await center.requestAuthorization(options: [.alert, .sound, .badge]) }
    func removeAll() { center.removeAllPendingNotificationRequests(); center.removeAllDeliveredNotifications() }
    func schedule(_ portfolio: Portfolio) async throws {
        try Task.checkCancellation()
        center.removeAllPendingNotificationRequests()
        guard portfolio.notifications.enabled else { return }
        let settings = await center.notificationSettings()
        try Task.checkCancellation()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { throw DomainError.invalid("Notifications are disabled in iOS Settings. Enable them to receive renewal reminders.") }
        let preference = portfolio.notifications
        var requests: [(Date, String, UNMutableNotificationContent)] = []
        let engine = IntelligenceEngine()
        for renewal in engine.renewals(portfolio.subscriptions.filter { !$0.isDemo }, from: Date(), days: 400) {
            guard let date = Calendar.current.date(byAdding: .day, value: -preference.daysBefore, to: renewal.date), date > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = renewal.subscription.status == .trial ? "A trial needs your attention" : "A renewal is coming up"
            content.body = preference.privateContent ? "Open SubSense to review your upcoming commitment." : "\(renewal.subscription.name) renews on \(renewal.date.formatted(date: .abbreviated, time: .omitted)) for \(Money.format(renewal.subscription.price, currency: renewal.subscription.currency))."
            content.sound = .default
            requests.append((date, renewal.id, content))
        }
        for plan in portfolio.cancellationPlans where plan.status == .planning {
            guard plan.intendedDate > Date(), let s = portfolio.subscriptions.first(where: { $0.id == plan.subscriptionID }), !s.isDemo else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Review your cancellation plan"
            content.body = preference.privateContent ? "You have a subscription to review in SubSense." : "Review \(s.name) before its next renewal."
            content.sound = .default
            requests.append((plan.intendedDate, "plan-\(plan.id)", content))
        }
        // iOS caps pending requests. Refill the nearest 60 whenever the app becomes active.
        for (date, id, content) in requests.sorted(by: { $0.0 < $1.0 }).prefix(60) {
            try Task.checkCancellation()
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)))
        }
    }
}
