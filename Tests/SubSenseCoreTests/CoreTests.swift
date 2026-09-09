import Foundation
import Testing
@testable import SubSenseCore

struct CoreTests {
    var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    func date(_ year: Int, _ month: Int, _ day: Int) -> Date { calendar.date(from: DateComponents(year: year, month: month, day: day))! }
    func subscription(_ price: Decimal = 12, frequency: BillingFrequency = .monthly) -> Subscription {
        Subscription(name: "Test", price: price, billingFrequency: frequency, startDate: date(2024, 1, 1), nextBillingDate: date(2024, 1, 31))
    }
    @Test func equivalents() {
        #expect(BillingFrequency.monthly.monthlyEquivalent(12) == 12)
        #expect(BillingFrequency.yearly.monthlyEquivalent(120) == 10)
        #expect(BillingFrequency.weekly.monthlyEquivalent(3) == 13)
        #expect(BillingFrequency.quarterly.monthlyEquivalent(90) == 30)
        #expect(BillingFrequency.custom.monthlyEquivalent(12, customDays: 365) == 1)
        #expect(BillingFrequency.lifetime.monthlyEquivalent(999) == 0)
        #expect(subscription().annualEquivalent == 144)
    }
    @Test func inactiveDoesNotRecur() {
        for status in [SubscriptionStatus.cancelled, .paused] {
            var s = subscription(); s.status = status
            #expect(s.monthlyEquivalent == 0)
            #expect(IntelligenceEngine().renewals([s], from: date(2024, 1, 1), days: 365).isEmpty)
        }
    }
    @Test func monthEndPreservesAnchor() {
        let engine = IntelligenceEngine(calendar: calendar)
        let dates = engine.renewals([subscription()], from: date(2024, 1, 1), days: 100).map(\.date)
        #expect(dates == [date(2024, 1, 31), date(2024, 2, 29), date(2024, 3, 31)])
    }
    @Test func leapYearAnnual() {
        var s = subscription(frequency: .yearly); s.nextBillingDate = date(2024, 2, 29)
        #expect(IntelligenceEngine(calendar: calendar).renewals([s], from: date(2025, 1, 1), days: 365).first?.date == date(2025, 2, 28))
    }
    @Test func oldAnchorAndWeeklyForecast() {
        var s = subscription(5, frequency: .weekly); s.nextBillingDate = date(2000, 1, 1)
        let renewals = IntelligenceEngine(calendar: calendar).renewals([s], from: date(2026, 9, 9), days: 30)
        #expect(renewals.count == 4)
        #expect(renewals.allSatisfy { $0.date >= date(2026, 9, 9) && $0.date < date(2026, 10, 9) })
    }
    @Test func trialUsesEndAndMissingDateDoesNotInvent() {
        var s = subscription(); s.status = .trial; s.trialEndDate = date(2024, 1, 12)
        let engine = IntelligenceEngine(calendar: calendar)
        #expect(engine.renewals([s], from: date(2024, 1, 1), days: 30).first?.date == s.trialEndDate)
        s.status = .active; s.nextBillingDate = nil
        #expect(engine.renewals([s], from: date(2024, 1, 1), days: 365).isEmpty)
    }
    @Test func currenciesNeverCombined() {
        var usd = subscription(100); usd.currency = "USD"
        #expect(Money.grouped([subscription(10), usd]) == ["GBP": Decimal(10), "USD": Decimal(100)])
    }
    @Test func scoresRespectUnknownAndEssential() {
        let engine = IntelligenceEngine(calendar: calendar)
        var s = subscription(); s.usageFrequency = .unknown
        #expect(engine.cancelScore(s, portfolio: [s], now: date(2024, 1, 1)).value == 0)
        #expect(engine.valueScore(s, portfolio: [s]).value == 50)
        s.usageFrequency = .never
        let before = engine.cancelScore(s, portfolio: [s]).value
        s.favourite = true
        #expect(engine.cancelScore(s, portfolio: [s]).value == before - 25)
        #expect(engine.potentialSavings([s]).isEmpty)
    }
    @Test func savingsNotDoubleCounted() {
        var s = subscription(); s.usageFrequency = .never; s.updatePrice(20)
        #expect(IntelligenceEngine().potentialSavings([s])["GBP"] == 20)
        #expect(s.priceHistory.count == 1)
        s.updatePrice(20)
        #expect(s.priceHistory.count == 1)
    }
    @Test func priceHistoryComparisonRequiresSameBasis() {
        var s = subscription(10); s.updatePrice(15)
        #expect(s.priceIncrease == Decimal(string: "0.5"))
        s.billingFrequency = .yearly
        #expect(s.priceIncrease == nil)
    }
    @Test func validationRejectsInvalidData() {
        var s = subscription(-1)
        #expect(throws: DomainError.self) { try s.validated() }
        s.price = 1; s.currency = "XXXINVALID"
        #expect(throws: DomainError.self) { try s.validated() }
        s.currency = "GBP"; s.status = .trial
        #expect(throws: DomainError.self) { try s.validated() }
    }
    @Test func portfolioRoundTrip() throws {
        let p = DemoData.portfolio()
        let decoded = try JSONDecoder().decode(Portfolio.self, from: JSONEncoder().encode(p))
        #expect(decoded.subscriptions == p.subscriptions)
        #expect(decoded.subscriptions.count == 12)
    }
    @Test func receiptIsOnlyADraft() async throws {
        let draft = try await LocalAIService().extractSubscriptionFromReceipt("Example\nUSD 19.99\nBilled yearly")
        #expect(draft.subscription.price == Decimal(string: "19.99"))
        #expect(draft.subscription.billingFrequency == .yearly)
        #expect(draft.subscription.nextBillingDate == nil)
        #expect(!draft.uncertainties.isEmpty)
    }
    @Test func chatDoesNotInventUnknownUsage() async throws {
        let reply = try await LocalAIService().answerSubscriptionQuestion("Where can I save?", subscriptions: [subscription()])
        #expect(reply.contains("no non-essential"))
    }
    @Test func moneyInputIsStrictAndLocalised() {
        let english = Locale(identifier: "en_GB")
        let german = Locale(identifier: "de_DE")
        #expect(Money.parseInput("12.50", locale: english) == Decimal(string: "12.5"))
        #expect(Money.parseInput("12,50", locale: german) == Decimal(string: "12.5"))
        #expect(Money.parseInput("12oops", locale: english) == nil)
        #expect(Money.parseInput("-2", locale: english) == nil)
        #expect(Money.parseInput("NaN", locale: english) == nil)
        #expect(Money.parseInput("1e9", locale: english) == nil)
        #expect(Money.parseInput("", locale: english) == nil)
        #expect(Money.input(Decimal(string: "12.5")!, locale: german) == "12,5")
    }
    @Test func forecastWindowExcludesEndBoundary() {
        var s = subscription(); s.nextBillingDate = date(2024, 1, 8)
        let engine = IntelligenceEngine(calendar: calendar)
        #expect(engine.forecast([s], from: date(2024, 1, 1), days: 7).isEmpty)
        #expect(engine.forecast([s], from: date(2024, 1, 1), days: 8)["GBP"] == 12)
    }
    @Test func customDailyBillsAllOccurrences() {
        var s = subscription(2, frequency: .custom); s.customDays = 1; s.nextBillingDate = date(2024, 1, 1)
        let engine = IntelligenceEngine(calendar: calendar)
        #expect(engine.renewals([s], from: date(2024, 1, 1), days: 30).count == 30)
        #expect(engine.forecast([s], from: date(2024, 1, 1), days: 30)["GBP"] == 60)
    }
    @Test func healthIncomeOnlyMatchesCurrency() {
        let engine = IntelligenceEngine(calendar: calendar)
        var s = subscription(200); s.currency = "USD"
        #expect(engine.health([s], income: 100, currency: "GBP", now: date(2024, 1, 1)).value == 100)
        #expect(engine.health([s], income: 100, currency: "USD", now: date(2024, 1, 1)).value == 90)
    }
    @Test func scoresAlwaysStayInRange() {
        let engine = IntelligenceEngine()
        for usage in UsageRating.allCases {
            var s = subscription(1_000_000); s.usageFrequency = usage; s.favourite = true
            #expect((0...100).contains(engine.cancelScore(s, portfolio: [s]).value))
            #expect((0...100).contains(engine.valueScore(s, portfolio: [s]).value))
            #expect((0...100).contains(engine.health([s]).value))
        }
    }
    @Test func receiptAmbiguousCurrencyIsDisclosed() async throws {
        let draft = try await LocalAIService().extractSubscriptionFromReceipt("Service\n$9.99 monthly\n$12.99 total")
        #expect(draft.uncertainties.contains { $0.contains("ambiguous") })
        #expect(draft.uncertainties.contains { $0.contains("Multiple amounts") })
    }
}
