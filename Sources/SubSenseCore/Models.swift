import Foundation

public enum BillingFrequency: String, Codable, CaseIterable, Sendable {
    case weekly, monthly, quarterly, yearly, custom, lifetime
    public var label: String { rawValue.capitalized }
    public func monthlyEquivalent(_ price: Decimal, customDays: Int = 30) -> Decimal {
        switch self {
        case .weekly: return price * 52 / 12
        case .monthly: return price
        case .quarterly: return price / 3
        case .yearly: return price / 12
        case .custom: return price * 365 / Decimal(max(1, customDays)) / 12
        case .lifetime: return 0
        }
    }
    public func date(from anchor: Date, occurrence: Int, customDays: Int, calendar: Calendar) -> Date? {
        switch self {
        case .weekly: return calendar.date(byAdding: .day, value: 7 * occurrence, to: anchor)
        case .monthly: return calendar.date(byAdding: .month, value: occurrence, to: anchor)
        case .quarterly: return calendar.date(byAdding: .month, value: 3 * occurrence, to: anchor)
        case .yearly: return calendar.date(byAdding: .year, value: occurrence, to: anchor)
        case .custom: return calendar.date(byAdding: .day, value: max(1, customDays) * occurrence, to: anchor)
        case .lifetime: return nil
        }
    }
}

public enum UsageRating: String, CaseIterable, Codable, Sendable {
    case daily, weekly, monthly, rarely, never, unknown
    public var label: String { rawValue.capitalized }
    public var utilisation: Double? {
        switch self {
        case .daily: return 1
        case .weekly: return 0.75
        case .monthly: return 0.45
        case .rarely: return 0.15
        case .never: return 0
        case .unknown: return nil
        }
    }
}
public enum SubscriptionStatus: String, CaseIterable, Codable, Sendable {
    case active, trial, paused, cancelled
}
public enum SubscriptionScope: String, CaseIterable, Codable, Sendable { case personal, work, business }
public enum PlanStatus: String, CaseIterable, Codable, Sendable { case planning, cancelled, keeping, downgraded }

public enum SubscriptionCategory {
    public static let all = ["AI Tools", "Productivity", "Streaming", "Music", "Cloud Storage", "Finance", "Fitness", "Education", "Gaming", "Business", "Design", "Developer Tools", "News", "Membership", "Utilities", "Other"]
}

public struct SubscriptionPriceHistory: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public var date: Date
    public var price: Decimal
    public var currency: String
    public var frequency: BillingFrequency
    public var customDays: Int
    public init(date: Date, price: Decimal, currency: String, frequency: BillingFrequency, customDays: Int = 30) {
        self.date = date; self.price = price; self.currency = currency; self.frequency = frequency; self.customDays = customDays
    }
}

public struct Subscription: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public var name: String
    public var provider: String
    public var category: String
    public var price: Decimal
    public var currency: String
    public var billingFrequency: BillingFrequency
    public var customDays = 30
    public var startDate: Date
    public var nextBillingDate: Date?
    public var trialEndDate: Date?
    public var status: SubscriptionStatus = .active
    public var usageFrequency: UsageRating = .unknown
    public var notes = ""
    public var paymentNickname = ""
    public var household = "Me"
    public var scope: SubscriptionScope = .personal
    public var seats = 1
    public var unusedSeats = 0
    public var favourite = false
    public var variablePrice = false
    public var lastReviewedAt: Date?
    public var cancelledAt: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var priceHistory: [SubscriptionPriceHistory] = []
    public var isDemo = false

    public init(name: String = "", provider: String = "", category: String = "Other", price: Decimal = 0, currency: String = "GBP", billingFrequency: BillingFrequency = .monthly, startDate: Date = Date(), nextBillingDate: Date? = nil) {
        self.name = name; self.provider = provider; self.category = category; self.price = price
        self.currency = currency; self.billingFrequency = billingFrequency; self.startDate = startDate
        self.nextBillingDate = nextBillingDate; self.createdAt = startDate; self.updatedAt = startDate
    }
    public var isRecurring: Bool { (status == .active || status == .trial) && billingFrequency != .lifetime }
    /// Trials are projected at their entered post-trial price, not represented as paid charges.
    public var monthlyEquivalent: Decimal { isRecurring ? billingFrequency.monthlyEquivalent(price, customDays: customDays) : 0 }
    public var annualEquivalent: Decimal { monthlyEquivalent * 12 }
    public var priceIncrease: Decimal? {
        guard let old = priceHistory.last, old.currency == currency, old.price > 0,
              old.frequency == billingFrequency, old.customDays == customDays, price > old.price else { return nil }
        return (price - old.price) / old.price
    }
    public mutating func updatePrice(_ newPrice: Decimal, now: Date = Date()) {
        guard newPrice != price else { return }
        priceHistory.append(.init(date: updatedAt, price: price, currency: currency, frequency: billingFrequency, customDays: customDays))
        price = newPrice; updatedAt = now
    }
    public func validated() throws -> Subscription {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw DomainError.invalid("Enter a subscription name.") }
        guard price >= 0, !price.isNaN, price <= 1_000_000_000 else { throw DomainError.invalid("Enter a valid, non-negative price.") }
        guard Locale.commonISOCurrencyCodes.contains(currency) else { throw DomainError.invalid("Select a supported currency code.") }
        guard (1...3650).contains(customDays) else { throw DomainError.invalid("Custom billing intervals must be 1–3,650 days.") }
        guard seats > 0, unusedSeats >= 0, unusedSeats <= seats else { throw DomainError.invalid("Unused licences cannot exceed the number of licences.") }
        guard status != .trial || trialEndDate != nil else { throw DomainError.invalid("Add the trial end date.") }
        guard trialEndDate == nil || trialEndDate! >= startDate else { throw DomainError.invalid("The trial must end after its start date.") }
        guard nextBillingDate == nil || nextBillingDate! >= startDate else { throw DomainError.invalid("The renewal must be on or after the start date.") }
        return self
    }
}

public enum DomainError: LocalizedError {
    case invalid(String)
    public var errorDescription: String? { switch self { case .invalid(let message): return message } }
}

public struct Renewal: Identifiable, Sendable {
    public var id: String { "\(subscription.id)-\(date.timeIntervalSince1970)" }
    public var subscription: Subscription
    public var date: Date
}
public struct Score: Sendable {
    public var value: Int
    public var reasons: [String]
}
public struct AIInsight: Identifiable, Codable, Sendable {
    public var id: String
    public var subscriptionID: UUID?
    public var title: String
    public var explanation: String
    public var monthlySaving: Decimal
    public var currency: String
    public var symbol: String
}
public typealias SavingRecommendation = AIInsight
public struct SubscriptionAudit: Identifiable, Codable, Sendable {
    public var id = UUID()
    public var date = Date()
    public var insights: [AIInsight]
    public var totals: [String: Decimal]
    public var savings: [String: Decimal]
}
public struct CancellationPlan: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public var subscriptionID: UUID
    public var status: PlanStatus = .planning
    public var intendedDate: Date
    public var notes = ""
    public var completedSteps: Set<Int> = []
    public init(subscriptionID: UUID, intendedDate: Date) { self.subscriptionID = subscriptionID; self.intendedDate = intendedDate }
}
public struct SavingsEvent: Identifiable, Codable, Sendable {
    public var id = UUID()
    public var subscriptionID: UUID
    public var name: String
    public var date: Date
    public var monthlySaving: Decimal
    public var currency: String
    public init(subscription: Subscription, date: Date, monthlySaving: Decimal) {
        self.subscriptionID = subscription.id; self.name = subscription.name
        self.date = date; self.monthlySaving = monthlySaving; self.currency = subscription.currency
    }
}
public struct NotificationPreference: Codable, Sendable {
    public var enabled = false
    public var daysBefore = 3
    public var privateContent = true
    public init() {}
}
public struct Household: Identifiable, Codable, Sendable {
    public var id = UUID()
    public var name: String
    public var members: [String]
    public init(name: String = "My household", members: [String] = ["Me", "Partner", "Family", "Business", "Shared"]) { self.name = name; self.members = members }
}
public struct User: Codable, Sendable {
    public var name = ""
    public var currency = Locale.current.currency?.identifier ?? "GBP"
    public var monthlyIncome: Decimal?
    public var monthlySavingsGoal: Decimal = 50
    public var household = Household()
    public init() {}
}
public struct Portfolio: Codable, Sendable {
    public var schemaVersion = 1
    public var subscriptions: [Subscription] = []
    public var cancellationPlans: [CancellationPlan] = []
    public var savingsEvents: [SavingsEvent] = []
    public var audits: [SubscriptionAudit] = []
    public var user = User()
    public var notifications = NotificationPreference()
    public init() {}
}

public enum Money {
    /// User input accepts a decimal separator, never partial parses, exponents or grouping.
    public static func parseInput(_ text: String, locale: Locale = .current) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let separator = locale.decimalSeparator ?? "."
        let escaped = NSRegularExpression.escapedPattern(for: separator)
        guard trimmed.range(of: "^[0-9]+(?:\(escaped)[0-9]{1,4})?$", options: .regularExpression) != nil else { return nil }
        return Decimal(string: trimmed.replacingOccurrences(of: separator, with: "."), locale: Locale(identifier: "en_US_POSIX"))
    }
    public static func input(_ amount: Decimal, locale: Locale = .current) -> String {
        NSDecimalNumber(decimal: amount).stringValue.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
    }
    public static func format(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency; formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(currency) \(amount)"
    }
    public static func number(_ amount: Decimal) -> Double { NSDecimalNumber(decimal: amount).doubleValue }
    public static func grouped(_ subscriptions: [Subscription], annual: Bool = false) -> [String: Decimal] {
        subscriptions.filter(\.isRecurring).reduce(into: [:]) { result, s in
            result[s.currency, default: 0] += annual ? s.annualEquivalent : s.monthlyEquivalent
        }
    }
}
