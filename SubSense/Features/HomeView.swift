import SwiftUI
import Charts
import SubSenseCore

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var currency = ""
    private var code: String { currency.isEmpty ? model.data.user.currency : currency }
    private var scoped: [Subscription] { model.active.filter { $0.currency == code } }
    private var monthly: Decimal { Money.grouped(scoped)[code] ?? 0 }
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) { Eyebrow(text: "A little more clarity"); Text("Your money,\nwith more meaning.").font(.system(.largeTitle, design: .serif).weight(.medium)).tracking(-1) }
                    Spacer(); BrandMark(size: 48)
                }
                if model.active.isEmpty {
                    ContentUnavailableView {
                        Label("Find out where your money goes every month.", systemImage: "square.stack.3d.up")
                    } description: { Text("Start with one subscription. Your insights grow from there.") } actions: {
                        Button("Add My First Subscription") { model.sheet = .add }.buttonStyle(PrimaryButtonStyle())
                        Button("Import Subscription") { model.sheet = .scanner }
                        Button("Preview a sample dashboard") { model.startDemo() }
                    }
                } else {
                    if model.currencies.count > 1 { Picker("Currency", selection: $currency) { ForEach(model.currencies, id: \.self) { Text($0).tag($0) } }.pickerStyle(.segmented) }
                    spendCard
                    kpis
                    Button { model.requirePro(.audit) } label: {
                        HStack(spacing: 14) { Image(systemName: "sparkles").font(.title2); VStack(alignment: .leading, spacing: 4) { Text("Make room for more.").font(.headline); Text("Run your subscription audit").font(.subheadline) }; Spacer(); Image(systemName: "arrow.up.right") }
                            .padding(22).foregroundStyle(Theme.ink).background(Theme.mint, in: RoundedRectangle(cornerRadius: 22))
                    }.buttonStyle(.plain)
                    HStack { SectionHeading(title: "Worth a closer look", subtitle: "Small changes. Meaningful savings."); Spacer(); Image(systemName: "sparkles").foregroundStyle(Theme.accent) }
                    let insights = model.engine.insights(scoped)
                    if insights.isEmpty { Card { Label("Nothing urgent. Your subscriptions look settled.", systemImage: "checkmark.seal") } }
                    ForEach(Array(insights.prefix(3))) { insight in InsightCard(insight: insight) }
                    HStack { SectionHeading(title: "Coming up next"); Button("View all") { model.sheet = .renewals }.font(.subheadline) }
                    Card {
                        let renewals = model.engine.renewals(scoped, from: Date(), days: 30)
                        if renewals.isEmpty { Text("No recorded renewals in the next 30 days.").foregroundStyle(.secondary) }
                        ForEach(Array(renewals.prefix(3))) { renewal in
                            NavigationLink { SubscriptionDetailView(id: renewal.subscription.id) } label: {
                                VStack(alignment: .leading, spacing: 3) { Text(renewal.date, format: .dateTime.month(.abbreviated).day()).font(.caption).foregroundStyle(.secondary); SubscriptionRow(subscription: renewal.subscription) }
                            }.buttonStyle(.plain)
                        }
                    }
                    Text("Based on your entries. Trials use their entered post-trial price. Variable prices are estimates. Currencies are never combined.").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                }
            }.padding(22).frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
        }.background(Theme.canvas).toolbar {
            ToolbarItem(placement: .topBarLeading) { Text("subsense").font(.headline).tracking(-0.7) }
            ToolbarItem(placement: .topBarTrailing) { Button { model.sheet = .add } label: { Image(systemName: "plus") }.accessibilityLabel("Add subscription") }
        }.onAppear { if currency.isEmpty { currency = model.data.user.currency } }
    }
    private var spendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Text("MONTHLY SUBSCRIPTION SPEND").font(.caption.weight(.medium)).tracking(1.6); Spacer(); Text(code).font(.caption) }.foregroundStyle(.white.opacity(0.65))
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 5) { Text(Money.format(monthly, currency: code)).font(.system(size: 48, weight: .medium, design: .rounded)).tracking(-2); Text("/ month").font(.subheadline).foregroundStyle(.white.opacity(0.6)) }
                Text(Money.format(monthly, currency: code)).font(.largeTitle).minimumScaleFactor(0.7)
            }.foregroundStyle(.white)
            HStack { Text("\(Money.format(monthly * 12, currency: code)) projected / year"); Spacer(); Image(systemName: "arrow.up.right") }.font(.subheadline).foregroundStyle(Theme.mint)
            Rectangle().fill(.white.opacity(0.15)).frame(height: 1)
            if let previous = model.data.audits.first, let annual = previous.totals[code], annual > 0 {
                let change = (monthly * 12 - annual) / annual * 100
                HStack(spacing: 7) {
                    Image(systemName: change > 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(Int(Money.number(change)))% vs your last saved audit")
                }.font(.caption).foregroundStyle(.white.opacity(0.8))
            } else {
                HStack(spacing: 7) { Image(systemName: "leaf"); Text("Clarity is the first step to saving.") }.font(.caption).foregroundStyle(.white.opacity(0.8))
            }
        }.padding(25).background(Theme.ink.gradient, in: RoundedRectangle(cornerRadius: 28))
    }
    private var kpis: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metric("Active subscriptions", value: "\(scoped.count)", symbol: "square.stack", footnote: "in \(code)")
            Button { model.sheet = .renewals } label: { metric("Upcoming charges", value: Money.format(model.engine.forecast(scoped, from: Date(), days: 7)[code] ?? 0, currency: code), symbol: "calendar", footnote: "next 7 days") }.buttonStyle(.plain)
            Button { model.requirePro(.simulator) } label: { metric("Potential savings", value: Money.format(model.engine.potentialSavings(scoped)[code] ?? 0, currency: code), symbol: "leaf", footnote: "per month · review first") }.buttonStyle(.plain)
            Button { model.sheet = .health } label: {
                let score = model.engine.health(model.active, income: model.data.user.monthlyIncome, currency: model.data.user.currency)
                metric("Subscription health", value: "\(score.value) / 100", symbol: "waveform.path.ecg", footnote: IntelligenceEngine.healthLabel(score.value))
            }.buttonStyle(.plain)
        }
    }
    private func metric(_ title: String, value: String, symbol: String, footnote: String) -> some View {
        Card { VStack(alignment: .leading, spacing: 10) { Image(systemName: symbol).foregroundStyle(Theme.accent); Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title2.weight(.semibold)).minimumScaleFactor(0.6).lineLimit(1); Text(footnote).font(.caption2).foregroundStyle(.secondary) } }.frame(maxHeight: .infinity)
    }
}

struct InsightCard: View {
    @Environment(AppModel.self) private var model
    var insight: AIInsight
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Label(insight.title, systemImage: insight.symbol).font(.headline)
                Text(insight.explanation).font(.subheadline).foregroundStyle(.secondary).lineSpacing(3)
                if insight.monthlySaving > 0 { Text("\(Money.format(insight.monthlySaving * 12, currency: insight.currency)) / year to reconsider").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent) }
                if let id = insight.subscriptionID, let s = model.subscriptions.first(where: { $0.id == id }) {
                    HStack {
                        NavigationLink("Review") { SubscriptionDetailView(id: id) }.buttonStyle(.bordered)
                        Button("Keep") { model.keep(s) }.buttonStyle(.bordered)
                        Spacer()
                        NavigationLink { CancellationView(id: id) } label: { Image(systemName: "arrow.up.right") }.accessibilityLabel("Create cancellation plan for \(s.name)")
                    }.font(.caption.weight(.semibold))
                }
            }
        }
    }
}

struct HealthView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        SheetShell(title: "Subscription Health Score") {
            let score = model.engine.health(model.active, income: model.data.user.monthlyIncome, currency: model.data.user.currency)
            List {
                Section { HStack(spacing: 22) { ScoreRing(score: score.value); Text(IntelligenceEngine.healthLabel(score.value)).font(.title2.weight(.semibold)) }.padding(.vertical) }
                Section("How it's calculated") { ForEach(score.reasons, id: \.self) { Text($0) } }
                Section("Score bands") { Text("90–100 · Excellent\n75–89 · Healthy\n60–74 · Needs attention\n40–59 · High waste\n0–39 · Critical").lineSpacing(10) }
            }
        }
    }
}

#Preview { NavigationStack { HomeView() }.environment(AppModel.preview()) }
#Preview("Health") { HealthView().environment(AppModel.preview()) }
