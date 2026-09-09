import Foundation
import Observation
import SubSenseCore

enum AppSheet: Identifiable {
    case add, edit(Subscription), scanner, paywall, health, audit, simulator, renewals, privacy, export
    var id: String {
        switch self {
        case .add: return "add"; case .edit(let s): return "edit-\(s.id)"; case .scanner: return "scanner"
        case .paywall: return "paywall"; case .health: return "health"; case .audit: return "audit"
        case .simulator: return "simulator"; case .renewals: return "renewals"; case .privacy: return "privacy"; case .export: return "export"
        }
    }
}

@MainActor @Observable
final class AppModel {
    private(set) var portfolio: Portfolio
    private(set) var demoPortfolio: Portfolio?
    let repository: any PortfolioRepository
    let ai: any AIService
    let store = StoreManager()
    let notifications = NotificationManager()
    var sheet: AppSheet?
    var error: String?
    var celebration: String?
    var engine = IntelligenceEngine()
    private var reminderTask: Task<Void, Never>?
    var data: Portfolio { demoPortfolio ?? portfolio }
    var isDemo: Bool { demoPortfolio != nil }
    var canUsePro: Bool { store.hasPro || isDemo }
    var subscriptions: [Subscription] { data.subscriptions }
    var active: [Subscription] { subscriptions.filter(\.isRecurring) }
    var currencies: [String] { Array(Set(active.map(\.currency) + [data.user.currency])).sorted() }
    init(repository: any PortfolioRepository, ai: any AIService = LocalAIService()) throws {
        self.repository = repository; self.ai = ai; self.portfolio = try repository.load()
    }
    static func preview() -> AppModel {
        let model = try! AppModel(repository: MemoryPortfolioRepository())
        model.startDemo(); return model
    }
    func startDemo() { demoPortfolio = DemoData.portfolio() }
    func endDemo() { demoPortfolio = nil }
    func requirePro(_ destination: AppSheet) { sheet = canUsePro ? destination : .paywall }
    private func commit(_ next: Portfolio) throws {
        if isDemo { demoPortfolio = next }
        else { try repository.save(next); portfolio = next }
        refreshReminders()
    }
    func refreshReminders() {
        guard !isDemo else { return }
        let previous = reminderTask
        previous?.cancel()
        let snapshot = portfolio
        reminderTask = Task {
            await previous?.value
            guard !Task.isCancelled else { return }
            do { try await notifications.schedule(snapshot) }
            catch is CancellationError {} catch { self.error = error.localizedDescription }
        }
    }
    func save(_ subscription: Subscription) throws {
        var next = data
        let s = try subscription.validated()
        if let index = next.subscriptions.firstIndex(where: { $0.id == s.id }) { next.subscriptions[index] = s }
        else {
            guard canUsePro || next.subscriptions.filter({ $0.status != .cancelled }).count < 5 else { throw DomainError.invalid("Free supports five subscriptions. Upgrade to Pro to add more.") }
            next.subscriptions.append(s)
        }
        try commit(next)
    }
    func delete(_ id: UUID) {
        var next = data; next.subscriptions.removeAll { $0.id == id }; next.cancellationPlans.removeAll { $0.subscriptionID == id }
        do { try commit(next) } catch { self.error = error.localizedDescription }
    }
    func keep(_ subscription: Subscription) {
        var s = subscription; s.favourite = true; s.lastReviewedAt = Date(); s.updatedAt = Date()
        do { try save(s) } catch { self.error = error.localizedDescription }
    }
    func savePlan(_ plan: CancellationPlan) throws {
        var next = data
        next.cancellationPlans.removeAll { $0.subscriptionID == plan.subscriptionID }
        next.cancellationPlans.append(plan)
        try commit(next)
    }
    func confirmCancellation(_ id: UUID) throws {
        var next = data
        guard let index = next.subscriptions.firstIndex(where: { $0.id == id }), next.subscriptions[index].isRecurring else { return }
        let s = next.subscriptions[index]
        next.savingsEvents.append(SavingsEvent(subscription: s, date: Date(), monthlySaving: s.monthlyEquivalent))
        next.subscriptions[index].status = .cancelled; next.subscriptions[index].cancelledAt = Date(); next.subscriptions[index].updatedAt = Date()
        if let p = next.cancellationPlans.firstIndex(where: { $0.subscriptionID == id }) { next.cancellationPlans[p].status = .cancelled }
        try commit(next)
        celebration = "\(Money.format(s.annualEquivalent, currency: s.currency))/year in projected savings. A little more breathing room."
    }
    func savePreferences(user: User, notifications: NotificationPreference) throws {
        var next = data; next.user = user; next.notifications = notifications; try commit(next)
    }
    func confirmDowngrade(_ id: UUID, newPrice: Decimal) throws {
        var next = data
        guard let index = next.subscriptions.firstIndex(where: { $0.id == id }), next.subscriptions[index].isRecurring else { return }
        let original = next.subscriptions[index]
        guard newPrice >= 0, newPrice < original.price else { throw DomainError.invalid("The new price must be lower than the current price.") }
        next.subscriptions[index].updatePrice(newPrice)
        let saving = original.monthlyEquivalent - next.subscriptions[index].monthlyEquivalent
        next.savingsEvents.append(SavingsEvent(subscription: original, date: Date(), monthlySaving: saving))
        if let p = next.cancellationPlans.firstIndex(where: { $0.subscriptionID == id }) { next.cancellationPlans[p].status = .downgraded }
        try commit(next)
        celebration = "Your confirmed downgrade reduces projected spending by \(Money.format(saving * 12, currency: original.currency))/year."
    }
    func saveAudit(_ audit: SubscriptionAudit) throws {
        var next = data; next.audits.insert(audit, at: 0); next.audits = Array(next.audits.prefix(24)); try commit(next)
    }
    func deleteAllData() throws {
        try repository.delete(); portfolio = Portfolio(); demoPortfolio = nil
        let previous = reminderTask
        previous?.cancel()
        reminderTask = Task { await previous?.value; notifications.removeAll() }
        notifications.removeAll()
    }
}
