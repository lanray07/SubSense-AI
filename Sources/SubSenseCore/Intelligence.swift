import Foundation

public struct IntelligenceEngine: Sendable {
    public var calendar: Calendar
    public init(calendar: Calendar = .current) { self.calendar = calendar }

    /// Every occurrence is computed from the original anchor. Jan 31 → Feb 28 → Mar 31.
    public func renewals(_ subscriptions: [Subscription], from: Date, days: Int) -> [Renewal] {
        let beginning = calendar.startOfDay(for: from)
        guard let end = calendar.date(byAdding: .day, value: days, to: beginning) else { return [] }
        return subscriptions.filter(\.isRecurring).flatMap { s -> [Renewal] in
            guard let anchor = s.status == .trial ? s.trialEndDate : s.nextBillingDate else { return [] }
            let delta = max(0, calendar.dateComponents([.day], from: anchor, to: beginning).day ?? 0)
            // Start near the visible period, then use the anchor to preserve month-end semantics.
            let estimate: Int
            switch s.billingFrequency {
            case .weekly: estimate = delta / 7
            case .monthly: estimate = max(0, (calendar.dateComponents([.month], from: anchor, to: beginning).month ?? 0) - 1)
            case .quarterly: estimate = max(0, (calendar.dateComponents([.month], from: anchor, to: beginning).month ?? 0) / 3 - 1)
            case .yearly: estimate = max(0, (calendar.dateComponents([.year], from: anchor, to: beginning).year ?? 0) - 1)
            case .custom: estimate = delta / max(1, s.customDays)
            case .lifetime: return []
            }
            var result: [Renewal] = []
            for offset in estimate...(estimate + max(40, days + 5)) {
                guard let date = s.billingFrequency.date(from: anchor, occurrence: offset, customDays: s.customDays, calendar: calendar), date < end else { break }
                if date >= beginning { result.append(Renewal(subscription: s, date: date)) }
            }
            return result
        }.sorted { $0.date < $1.date }
    }
    public func forecast(_ subscriptions: [Subscription], from: Date, days: Int) -> [String: Decimal] {
        renewals(subscriptions, from: from, days: days).reduce(into: [:]) { $0[$1.subscription.currency, default: 0] += $1.subscription.price }
    }
    public func cancelScore(_ s: Subscription, portfolio: [Subscription], now: Date = Date()) -> Score {
        guard s.isRecurring else { return Score(value: 0, reasons: ["No active recurring commitment."]) }
        var score = 0
        var reasons: [String] = []
        if let usage = s.usageFrequency.utilisation {
            score += Int((1 - usage) * 65)
            reasons.append("Reported usage: \(s.usageFrequency.label.lowercased()) (up to 65 points).")
        } else { reasons.append("Usage unknown; no low-use penalty applied.") }
        let similar = portfolio.filter { $0.id != s.id && $0.isRecurring && $0.category == s.category }
        if !similar.isEmpty { score += 12; reasons.append("Another service in this category (+12); capabilities may differ.") }
        let peers = portfolio.filter { $0.isRecurring && $0.currency == s.currency }
        let average = peers.isEmpty ? Decimal(0) : peers.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent } / Decimal(peers.count)
        if s.monthlyEquivalent > average * 15 / 10 { score += 10; reasons.append("Above 1.5× your currency group's average cost (+10).") }
        if s.priceIncrease != nil { score += 8; reasons.append("Recorded price increase (+8).") }
        if let renewal = renewals([s], from: now, days: 8).first, renewal.date >= calendar.startOfDay(for: now) { score += 5; reasons.append("Renews within 7 days (+5).") }
        if s.favourite { score -= 25; reasons.append("Marked essential (−25).") }
        return Score(value: min(100, max(0, score)), reasons: reasons)
    }
    public func valueScore(_ s: Subscription, portfolio: [Subscription]) -> Score {
        guard let usage = s.usageFrequency.utilisation else { return Score(value: 50, reasons: ["Neutral estimate: add your usage rating for a meaningful score."]) }
        let peers = portfolio.filter { $0.isRecurring && $0.currency == s.currency && $0.category == s.category }
        let average = peers.isEmpty ? s.monthlyEquivalent : peers.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent } / Decimal(peers.count)
        let costBonus = s.monthlyEquivalent <= average ? 10 : 0
        return Score(value: min(100, Int(usage * 80) + costBonus + (s.favourite ? 10 : 0)), reasons: ["Reported usage contributes up to 80 points.", "Cost at or below your category average adds 10 points.", "Essential preference adds 10 points. No device usage is collected."])
    }
    public func health(_ subscriptions: [Subscription], income: Decimal? = nil, currency: String = "GBP", now: Date = Date()) -> Score {
        let active = subscriptions.filter(\.isRecurring)
        guard !active.isEmpty else { return Score(value: 100, reasons: ["No recurring commitments recorded. Add subscriptions to assess your portfolio."]) }
        let average = active.reduce(0) { $0 + cancelScore($1, portfolio: active, now: now).value } / active.count
        var penalty = 0
        if let income, income > 0, (Money.grouped(active)[currency] ?? 0) / income > Decimal(string: "0.1")! { penalty = 10 }
        return Score(value: max(0, 100 - average - penalty), reasons: ["100 minus the average Cancel Score across active subscriptions (\(average) points).", "Income adjustment: \(penalty) points. Applied only when recurring spend in your income currency exceeds 10% of optional monthly income.", "Scores use your entries and transparent rules; they are estimates, not financial advice. Unknown usage receives no waste penalty."])
    }
    public static func healthLabel(_ score: Int) -> String {
        switch score { case 90...100: return "Excellent"; case 75...89: return "Healthy"; case 60...74: return "Needs attention"; case 40...59: return "High waste"; default: return "Critical" }
    }
    public func insights(_ subscriptions: [Subscription], now: Date = Date()) -> [AIInsight] {
        var result: [AIInsight] = []
        for s in subscriptions.filter(\.isRecurring) {
            func add(_ kind: String, _ title: String, _ detail: String, _ saving: Decimal = 0, _ symbol: String = "sparkles") {
                result.append(.init(id: "\(s.id)-\(kind)", subscriptionID: s.id, title: title, explanation: detail, monthlySaving: saving, currency: s.currency, symbol: symbol))
            }
            if (s.usageFrequency == .rarely || s.usageFrequency == .never) && !s.favourite {
                add("waste", "A little less spend. A lot more room.", "You marked \(s.name) as \(s.usageFrequency.label.lowercased()) used. Review whether it still earns its place.", s.monthlyEquivalent, "leaf")
            }
            if let increase = s.priceIncrease {
                add("price", "A price worth revisiting", "\(s.name)'s recorded price increased by \(Int(Money.number(increase) * 100))%. Compare your plan and needs.", 0, "arrow.up.right")
            }
            if s.status == .trial, let end = s.trialEndDate, end >= calendar.startOfDay(for: now), end < calendar.date(byAdding: .day, value: 8, to: now)! {
                add("trial", "Your trial is nearly over", "\(s.name) ends on \(end.formatted(date: .abbreviated, time: .omitted)). Confirm its post-trial price before renewal.", 0, "hourglass")
            }
            let duplicates = subscriptions.filter { $0.id != s.id && $0.isRecurring && !$0.provider.isEmpty && $0.provider.localizedCaseInsensitiveCompare(s.provider) == .orderedSame }
            if !duplicates.isEmpty { add("duplicate", "Check a possible duplicate", "\(s.name) shares a provider with \(duplicates.map(\.name).joined(separator: ", ")). Profiles: \(Set(([s] + duplicates).map(\.household)).sorted().joined(separator: ", ")). These could be distinct plans.", 0, "square.on.square") }
            if s.unusedSeats > 0 { add("seats", "Unused licences", "\(s.name) has \(s.unusedSeats) of \(s.seats) licences marked unused. Review your contract before reducing seats.", 0, "person.2") }
            let reviewed = s.lastReviewedAt ?? s.createdAt
            if now.timeIntervalSince(reviewed) > 90 * 86400 { add("review", "Time for a quick check-in", "You haven't reviewed \(s.name) in over 90 days.", 0, "clock") }
        }
        let grouped = Dictionary(grouping: subscriptions.filter(\.isRecurring), by: \.category)
        for category in grouped.keys.sorted() {
            let group = grouped[category]!
            if group.count > 1 {
                result.append(.init(id: "category-\(category)", subscriptionID: group.first?.id, title: "Could your \(category.lowercased()) work together?", explanation: "\(group.map(\.name).joined(separator: ", ")) share a category. Check features and eligibility before consolidating; overlap is not proof of waste.", monthlySaving: 0, currency: group[0].currency, symbol: "square.stack.3d.up"))
            }
        }
        return result
    }
    /// Only low-use, non-essential commitments count. Each service contributes once.
    public func potentialSavings(_ subscriptions: [Subscription]) -> [String: Decimal] {
        Money.grouped(subscriptions.filter { !$0.favourite && ($0.usageFrequency == .rarely || $0.usageFrequency == .never) })
    }
    public func audit(_ subscriptions: [Subscription], now: Date = Date()) -> SubscriptionAudit {
        SubscriptionAudit(date: now, insights: insights(subscriptions, now: now), totals: Money.grouped(subscriptions, annual: true), savings: potentialSavings(subscriptions).mapValues { $0 * 12 })
    }
}
