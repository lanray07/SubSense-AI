import Foundation

public struct ReceiptDraft: Sendable {
    public var subscription: Subscription
    public var uncertainties: [String]
}
public struct SuggestedAlternative: Identifiable, Sendable {
    public var id: String { name }
    public var name: String
    public var features: String
    public var limitations: String
    public var difficulty: String
    public var estimatedMonthlyPrice: Decimal?
    public var pricingNote: String
}
public protocol AIService: Sendable {
    func analyseSubscriptionPortfolio(_ subscriptions: [Subscription]) async throws -> SubscriptionAudit
    func calculateWasteSignals(_ subscriptions: [Subscription]) async throws -> [AIInsight]
    func generateSavingsRecommendations(_ subscriptions: [Subscription]) async throws -> [SavingRecommendation]
    func compareSubscriptionValue(_ subscription: Subscription, portfolio: [Subscription]) async throws -> Score
    func generateCancellationPlan(_ subscription: Subscription) async throws -> CancellationPlan
    func answerSubscriptionQuestion(_ question: String, subscriptions: [Subscription]) async throws -> String
    func extractSubscriptionFromReceipt(_ text: String) async throws -> ReceiptDraft
}

/// Offline, deterministic provider. Deliberately identifies its limits instead of impersonating an LLM.
public struct LocalAIService: AIService {
    public init() {}
    public func analyseSubscriptionPortfolio(_ subscriptions: [Subscription]) async throws -> SubscriptionAudit { IntelligenceEngine().audit(subscriptions) }
    public func calculateWasteSignals(_ subscriptions: [Subscription]) async throws -> [AIInsight] { IntelligenceEngine().insights(subscriptions) }
    public func generateSavingsRecommendations(_ subscriptions: [Subscription]) async throws -> [SavingRecommendation] { IntelligenceEngine().insights(subscriptions).filter { $0.monthlySaving > 0 } }
    public func compareSubscriptionValue(_ subscription: Subscription, portfolio: [Subscription]) async throws -> Score { IntelligenceEngine().valueScore(subscription, portfolio: portfolio) }
    public func generateCancellationPlan(_ subscription: Subscription) async throws -> CancellationPlan {
        let date = IntelligenceEngine().renewals([subscription], from: Date(), days: 400).first?.date ?? Date()
        return CancellationPlan(subscriptionID: subscription.id, intendedDate: Calendar.current.date(byAdding: .day, value: -7, to: date).map { max(Date(), $0) } ?? Date())
    }
    public func answerSubscriptionQuestion(_ question: String, subscriptions: [Subscription]) async throws -> String {
        let active = subscriptions.filter(\.isRecurring)
        guard !active.isEmpty else { return "Add your subscriptions first. I use only your recorded costs, dates and usage ratings." }
        let q = question.lowercased()
        let engine = IntelligenceEngine()
        func amounts(_ values: [String: Decimal]) -> String { values.keys.sorted().map { Money.format(values[$0]!, currency: $0) }.joined(separator: " + ") }
        if q.contains("five") || q.contains("5 most") {
            let groups = Dictionary(grouping: active, by: \.currency)
            return groups.keys.sorted().map { currency in
                let selected = Array(groups[currency]!.sorted { $0.annualEquivalent > $1.annualEquivalent }.prefix(5))
                return "\(currency): Removing \(selected.map(\.name).joined(separator: ", ")) would reduce projected spending by \(amounts(Money.grouped(selected)))/month, or \(amounts(Money.grouped(selected, annual: true)))/year."
            }.joined(separator: "\n\n") + "\n\nCurrencies are ranked separately. This assumes unchanged prices and immediate cancellation without fees; nothing has been cancelled."
        }
        if q.contains("overlap") || q.contains("duplicate") {
            let groups = Dictionary(grouping: active, by: \.category).filter { $0.value.count > 1 }
            return groups.isEmpty ? "No category overlaps appear in your entries." : groups.keys.sorted().map { "\($0): \(groups[$0]!.map(\.name).joined(separator: ", "))." }.joined(separator: "\n") + "\n\nShared categories may serve different needs. Compare features before switching."
        }
        if q.contains("renew") {
            let days = Calendar.current.range(of: .day, in: .month, for: Date())!.count - Calendar.current.component(.day, from: Date()) + 1
            let renewals = engine.renewals(active, from: Date(), days: days)
            return renewals.isEmpty ? "No recorded renewals remain this month. Add missing dates to improve your forecast." : renewals.map { "\($0.date.formatted(date: .abbreviated, time: .omitted)): \($0.subscription.name), \(Money.format($0.subscription.price, currency: $0.subscription.currency))." }.joined(separator: "\n") + "\n\nBased on entered renewal dates and prices."
        }
        if q.contains("most") || q.contains("expensive") {
            return Dictionary(grouping: active, by: \.currency).keys.sorted().compactMap { currency in
                active.filter { $0.currency == currency }.max { $0.annualEquivalent < $1.annualEquivalent }.map { "\($0.name) is your largest annual commitment in \(currency): \(Money.format($0.annualEquivalent, currency: currency))/year." }
            }.joined(separator: "\n")
        }
        if ["save", "saving", "cancel", "rarely", "unused"].contains(where: q.contains) {
            let low = active.filter { !$0.favourite && ($0.usageFrequency == .rarely || $0.usageFrequency == .never) }.sorted { engine.cancelScore($0, portfolio: active).value > engine.cancelScore($1, portfolio: active).value }
            return low.isEmpty ? "You have no non-essential services marked rarely or never used. Add usage ratings to reveal possible savings; I can't observe your app activity." : "Start by reviewing \(low.map(\.name).joined(separator: ", ")). You marked these as rarely or never used.\n\nPotential reduction: \(amounts(Money.grouped(low)))/month, or \(amounts(Money.grouped(low, annual: true)))/year. These are projections, not confirmed savings. Check contracts and cancellation terms first."
        }
        return "I'm running locally with a limited set of portfolio questions. Ask about savings, low usage, category overlap, upcoming renewals, your most expensive subscription, or cancelling your five most expensive services. No data is sent to an AI provider."
    }
    public func extractSubscriptionFromReceipt(_ text: String) async throws -> ReceiptDraft {
        guard text.count <= 100_000, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw DomainError.invalid("Paste receipt text up to 100,000 characters.") }
        var subscription = Subscription(currency: Locale.current.currency?.identifier ?? "GBP")
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        subscription.name = String((lines.first ?? "").prefix(80)); subscription.provider = subscription.name
        let pattern = #"(GBP|USD|EUR|CAD|AUD|NGN|£|\$|€)\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)"#
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var uncertainties = ["Provider/name are taken from the first line; confirm them.", "Usage, category and renewal date need your confirmation."]
        if let match = matches.first, let cr = Range(match.range(at: 1), in: text), let pr = Range(match.range(at: 2), in: text) {
            let code = String(text[cr]).uppercased()
            subscription.currency = ["£": "GBP", "$": "USD", "€": "EUR"][code] ?? code
            subscription.price = Decimal(string: String(text[pr]).replacingOccurrences(of: ",", with: "")) ?? 0
            if code == "$" { uncertainties.append("Dollar symbol is ambiguous. Confirm the currency; USD is only a draft.") }
            if matches.count > 1 { uncertainties.append("Multiple amounts found. The first may be tax or a subtotal; verify the recurring charge.") }
        } else { uncertainties.append("No supported amount found. Enter the price manually.") }
        let lower = text.lowercased()
        if lower.contains("annual") || lower.contains("yearly") { subscription.billingFrequency = .yearly }
        else if lower.contains("quarter") { subscription.billingFrequency = .quarterly }
        else if lower.contains("weekly") { subscription.billingFrequency = .weekly }
        else if !lower.contains("month") { uncertainties.append("Billing frequency is unknown. Monthly is only a draft.") }
        return ReceiptDraft(subscription: subscription, uncertainties: uncertainties)
    }
    public static func alternatives(for subscription: Subscription) -> [SuggestedAlternative] {
        [SuggestedAlternative(name: "Review your provider's free tier", features: "Keep only the features you need; check whether a free plan exists.", limitations: "A free tier may not exist. Storage, exports, commercial use or collaboration may be limited.", difficulty: "Usually low; verify data retention before downgrading.", estimatedMonthlyPrice: nil, pricingNote: "No current pricing source connected. Verify availability, price and eligibility on the provider's website."),
         SuggestedAlternative(name: "Consolidate with a service you already own", features: "Compare your existing \(subscription.category.lowercased()) tools before adding another bill.", limitations: "Similar categories do not guarantee equivalent features or household licensing.", difficulty: "Depends on data migration and contract terms.", estimatedMonthlyPrice: nil, pricingNote: "Potential savings are not quantified until you confirm the replacement cost.")]
    }
}

/// Future discovery implementations return drafts. Persisting requires an explicit confirmation.
public protocol SubscriptionDiscoverySource: Sendable {
    func discover(from data: Data) async throws -> [Subscription]
}
public protocol PortfolioSyncService: Sendable {
    func sync(_ portfolio: Portfolio) async throws -> Portfolio
}
