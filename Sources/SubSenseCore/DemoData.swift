import Foundation

public enum DemoData {
    public static func portfolio(now: Date = Date()) -> Portfolio {
        var result = Portfolio()
        result.user.currency = "GBP"
        let rows: [(String, String, String, String, UsageRating, Int)] = [
            ("ChatGPT Plus", "OpenAI", "AI Tools", "20.00", .daily, 2),
            ("Netflix", "Netflix", "Streaming", "17.99", .weekly, 4),
            ("Spotify", "Spotify", "Music", "11.99", .daily, 6),
            ("Creative Cloud", "Adobe", "Design", "24.99", .rarely, 9),
            ("Canva Pro", "Canva", "Design", "119.99", .weekly, 23),
            ("Dropbox Plus", "Dropbox", "Cloud Storage", "9.99", .never, 3),
            ("Microsoft 365", "Microsoft", "Productivity", "8.49", .weekly, 12),
            ("iCloud+", "Apple", "Cloud Storage", "2.99", .daily, 15),
            ("Notion Plus", "Notion", "Productivity", "9.50", .rarely, 19),
            ("GitHub Copilot", "GitHub", "AI Tools", "10.00", .daily, 7),
            ("Gym membership", "Studio North", "Fitness", "39.00", .weekly, 11),
            ("Amazon Prime", "Amazon", "Streaming", "8.99", .monthly, 26)
        ]
        result.subscriptions = rows.enumerated().map { index, row in
            let start = Calendar.current.date(byAdding: .month, value: -6, to: now)!
            var s = Subscription(name: row.0, provider: row.1, category: row.2, price: Decimal(string: row.3)!, currency: "GBP", billingFrequency: index == 4 ? .yearly : .monthly, startDate: start, nextBillingDate: Calendar.current.date(byAdding: .day, value: row.5, to: now))
            s.usageFrequency = row.4; s.isDemo = true; s.updatedAt = now
            s.favourite = index == 0; s.scope = [0, 3, 4, 8, 9].contains(index) ? .work : .personal
            s.notes = "Illustrative demo entry. This is not a current provider price."
            if index == 3 { s.priceHistory = [.init(date: start, price: Decimal(string: "19.99")!, currency: "GBP", frequency: .monthly)] }
            return s
        }
        return result
    }
}
