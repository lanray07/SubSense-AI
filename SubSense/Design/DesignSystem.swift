import SwiftUI
import SubSenseCore

enum Theme {
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.80, green: 0.91, blue: 0.68, alpha: 1)
            : UIColor(red: 0.18, green: 0.38, blue: 0.30, alpha: 1)
    })
    static let action = Color(red: 0.18, green: 0.38, blue: 0.30)
    static let mint = Color(red: 0.80, green: 0.91, blue: 0.68)
    static let ink = Color(red: 0.10, green: 0.18, blue: 0.15)
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let warm = Color(red: 0.96, green: 0.86, blue: 0.69)
}
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { content.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(Theme.card, in: RoundedRectangle(cornerRadius: 24)) }
}
struct Eyebrow: View {
    var text: String
    var body: some View { Text(text.uppercased()).font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary) }
}
struct BrandMark: View {
    var size: CGFloat = 42
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3).fill(Theme.ink)
            Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: size * 0.50, weight: .medium)).foregroundStyle(Theme.mint)
            Image(systemName: "sparkle").font(.system(size: size * 0.2, weight: .bold)).foregroundStyle(.white).offset(x: size * 0.2, y: -size * 0.2)
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}
struct ProviderIcon: View {
    let subscription: Subscription
    var body: some View {
        Text(String(subscription.name.prefix(1))).font(.title3.bold())
            .foregroundStyle(Theme.accent).frame(width: 44, height: 44)
            .background(Theme.mint.opacity(0.35), in: RoundedRectangle(cornerRadius: 14)).accessibilityHidden(true)
    }
}
struct CurrencyTotals: View {
    var values: [String: Decimal]
    var suffix = ""
    var body: some View {
        ForEach(values.keys.sorted(), id: \.self) { code in
            Text(Money.format(values[code] ?? 0, currency: code) + suffix).monospacedDigit()
        }
    }
}
struct SectionHeading: View {
    var title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.title2.weight(.semibold)).tracking(-0.5)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct ScoreRing: View {
    var score: Int
    var body: some View {
        ZStack {
            Circle().stroke(Theme.mint.opacity(0.25), lineWidth: 8)
            Circle().trim(from: 0, to: CGFloat(score) / 100).stroke(Theme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
            Text("\(score)").font(.title2.bold()).monospacedDigit()
        }.frame(width: 74, height: 74).accessibilityElement(children: .ignore).accessibilityLabel("Score \(score) out of 100")
    }
}
struct SubscriptionRow: View {
    var subscription: Subscription
    var body: some View {
        HStack(spacing: 12) {
            ProviderIcon(subscription: subscription)
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name).font(.headline)
                Text("\(subscription.category) · \(subscription.usageFrequency.label)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 4) {
                Text(Money.format(subscription.price, currency: subscription.currency)).font(.subheadline.weight(.semibold)).monospacedDigit()
                Text(subscription.status == .active ? subscription.billingFrequency.label : subscription.status.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 6).accessibilityElement(children: .combine)
    }
}
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 17)
            .foregroundStyle(.white).background(Theme.action.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 18))
    }
}
struct SheetShell<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    var title: String
    @ViewBuilder var content: Content
    var body: some View {
        NavigationStack {
            content.navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }.tint(Theme.accent)
    }
}
