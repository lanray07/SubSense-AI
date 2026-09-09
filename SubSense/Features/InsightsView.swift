import SwiftUI
import Charts
import SubSenseCore

struct InsightsView: View {
    @Environment(AppModel.self) private var model
    @State private var currency = ""
    private var code: String { currency.isEmpty ? model.data.user.currency : currency }
    private var scoped: [Subscription] { model.active.filter { $0.currency == code } }
    private var categories: [String: Decimal] { scoped.reduce(into: [:]) { $0[$1.category, default: 0] += $1.monthlyEquivalent } }
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                SectionHeading(title: "Less noise. More perspective.", subtitle: "Understand the commitments behind the numbers.")
                Picker("Currency", selection: $currency) { ForEach(model.currencies, id: \.self) { Text($0).tag($0) } }.pickerStyle(.segmented)
                Card {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeading(title: "Where it goes", subtitle: "Monthly equivalent · \(code)")
                        if categories.isEmpty { Text("Add a subscription to see your spending mix.").foregroundStyle(.secondary) }
                        else {
                            Chart(categories.keys.sorted(), id: \.self) { category in
                                BarMark(x: .value("Monthly cost", Money.number(categories[category] ?? 0)), y: .value("Category", category)).foregroundStyle(Theme.accent.gradient).cornerRadius(5)
                            }.frame(height: CGFloat(max(180, categories.count * 35)))
                            ForEach(categories.keys.sorted(), id: \.self) { key in LabeledContent(key, value: Money.format(categories[key]!, currency: code)).font(.caption) }
                        }
                    }
                }
                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(title: "30-day forecast", subtitle: "Cumulative expected charges · \(code)")
                        ForEach([7, 14, 30], id: \.self) { days in LabeledContent("Next \(days) days", value: Money.format(model.engine.forecast(scoped, from: Date(), days: days)[code] ?? 0, currency: code)) }
                        Text("Uses recorded renewal dates; variable bills and post-trial charges are estimates.").font(.caption).foregroundStyle(.secondary)
                        Button("Open renewal calendar") { model.sheet = .renewals }
                    }
                }
                if model.canUsePro {
                    Card {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeading(title: "Your savings, taking shape", subtitle: "Projected annual reductions from recorded actions")
                            let savings = model.data.savingsEvents.filter { $0.currency == code }.reduce(Decimal(0)) { $0 + $1.monthlySaving }
                            Text(Money.format(savings * 12, currency: code)).font(.system(.largeTitle, design: .rounded).weight(.semibold))
                            let goal = model.data.user.monthlySavingsGoal
                            if goal > 0 && code == model.data.user.currency {
                                ProgressView(value: min(Money.number(savings / goal), 1)).tint(Theme.accent)
                                Text("\(Money.format(savings, currency: code)) / \(Money.format(goal, currency: code)) monthly reduction goal").font(.caption)
                            }
                            ForEach(model.data.savingsEvents.filter { $0.currency == code }) { event in LabeledContent(event.name, value: "\(Money.format(event.monthlySaving, currency: code))/mo").font(.subheadline) }
                            Text("These are annualised reductions at the time of each action, not cash received or measured lifetime savings. Future price changes or resubscriptions can alter the result.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Button("Try a savings scenario") { model.sheet = .simulator }.buttonStyle(PrimaryButtonStyle())
                    NavigationLink { PortfolioGroupsView() } label: { Label("Household, business & AI Stack", systemImage: "person.2") }.buttonStyle(.bordered)
                    Card {
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeading(title: "Your portfolio, at a glance")
                            LabeledContent("Monthly plans", value: "\(scoped.filter { $0.billingFrequency == .monthly }.count)")
                            LabeledContent("Annual plans", value: "\(scoped.filter { $0.billingFrequency == .yearly }.count)")
                            LabeledContent("Recorded price increases", value: "\(scoped.filter { $0.priceIncrease != nil }.count)")
                            LabeledContent("Added this month", value: "\(model.subscriptions.filter { $0.currency == code && Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .month) }.count)")
                            LabeledContent("Cancelled records", value: "\(model.subscriptions.filter { $0.currency == code && $0.status == .cancelled }.count)")
                        }
                    }
                    if !model.data.audits.isEmpty {
                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeading(title: "Recorded audit history", subtitle: "Actual snapshots; no invented historical spending")
                                Chart(model.data.audits.sorted { $0.date < $1.date }) { audit in
                                    PointMark(x: .value("Audit date", audit.date), y: .value("Annual projection", Money.number(audit.totals[code] ?? 0))).foregroundStyle(Theme.accent)
                                }.frame(height: 160)
                                ForEach(model.data.audits) { audit in LabeledContent(audit.date.formatted(date: .abbreviated, time: .shortened), value: Money.format(audit.totals[code] ?? 0, currency: code)).font(.caption) }
                            }
                        }
                    }
                } else { Button("Explore advanced insights with Pro") { model.sheet = .paywall }.buttonStyle(PrimaryButtonStyle()) }
            }.padding(22).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.background(Theme.canvas).navigationTitle("Insights").onAppear { if currency.isEmpty { currency = model.data.user.currency } }
    }
}

struct SimulatorView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: Set<UUID> = []
    private var savings: [String: Decimal] { Money.grouped(model.active.filter { selected.contains($0.id) }) }
    var body: some View {
        SheetShell(title: "Savings Simulator") {
            List {
                Section {
                    Text("What could you make room for?").font(.system(.title, design: .serif))
                    Text("Select commitments to explore a future with fewer bills. Nothing is cancelled.").foregroundStyle(.secondary)
                }
                ForEach(savings.keys.sorted(), id: \.self) { code in
                    Section(code) {
                        LabeledContent("Monthly savings", value: Money.format(savings[code]!, currency: code))
                        LabeledContent("Annual savings", value: Money.format(savings[code]! * 12, currency: code))
                        LabeledContent("Five-year savings", value: Money.format(savings[code]! * 60, currency: code))
                        Chart([1, 2, 3, 4, 5], id: \.self) { year in
                            BarMark(x: .value("Year", year), y: .value("Cumulative savings", Money.number(savings[code]! * Decimal(year * 12)))).foregroundStyle(Theme.accent.gradient).cornerRadius(6)
                        }.frame(height: 140)
                    }
                }
                Section("Choose subscriptions") {
                    ForEach(model.active) { s in Toggle(isOn: Binding(get: { selected.contains(s.id) }, set: { if $0 { selected.insert(s.id) } else { selected.remove(s.id) } })) { SubscriptionRow(subscription: s) } }
                }
                Section { Text("Assumes immediate cancellation, unchanged prices, no fees and no replacement purchases. Annual payments may already be non-refundable. Savings begin when charges actually stop.").font(.caption).foregroundStyle(.secondary) }
            }
        }
    }
}

struct AuditView: View {
    @Environment(AppModel.self) private var model
    @State private var audit: SubscriptionAudit?
    @State private var running = false
    @State private var error: String?
    var body: some View {
        SheetShell(title: "Your Subscription Audit") {
            ScrollView {
                VStack(spacing: 22) {
                    Card { VStack(alignment: .leading, spacing: 12) { Label("Clarity, on your terms.", systemImage: "sparkles").font(.title2.weight(.semibold)); Text("Local analysis · Transparent rules\nUses only the costs, dates and usage you entered.").font(.subheadline).foregroundStyle(.secondary) } }
                    if running { Card { ProgressView("Reviewing your subscriptions…").frame(maxWidth: .infinity).padding(30) } }
                    if let audit {
                        Card { VStack(alignment: .leading, spacing: 15) { Eyebrow(text: "Estimated annual spend"); CurrencyTotals(values: audit.totals).font(.largeTitle); Eyebrow(text: "Possible annual savings"); CurrencyTotals(values: audit.savings).font(.title).foregroundStyle(Theme.accent); if audit.savings.isEmpty { Text("No low-use, non-essential commitments recorded.").foregroundStyle(.secondary) } } }
                        ForEach(audit.insights) { insight in InsightCard(insight: insight) }
                        Card {
                            VStack(alignment: .leading, spacing: 15) {
                                SectionHeading(title: "Your savings plan", subtitle: "Review these first. You stay in control.")
                                let priority = model.active.sorted { model.engine.cancelScore($0, portfolio: model.active).value > model.engine.cancelScore($1, portfolio: model.active).value }
                                ForEach(Array(priority.prefix(5))) { s in NavigationLink { CancellationView(id: s.id) } label: { SubscriptionRow(subscription: s) } }
                                Text("Savings count each rarely or never used, non-essential subscription once. Category overlaps and possible duplicates don't add unverified savings.").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeading(title: "Largest commitments", subtitle: "Ranked separately for each currency")
                                ForEach(model.currencies, id: \.self) { code in
                                    ForEach(Array(model.active.filter { $0.currency == code }.sorted { $0.annualEquivalent > $1.annualEquivalent }.prefix(3))) { s in
                                        LabeledContent(s.name, value: "\(Money.format(s.annualEquivalent, currency: code))/year").font(.subheadline)
                                    }
                                }
                                Divider()
                                SectionHeading(title: "Upcoming renewals", subtitle: "Your next 30 days")
                                ForEach(Array(model.engine.renewals(model.active, from: Date(), days: 30).prefix(10))) { renewal in
                                    LabeledContent(renewal.subscription.name, value: renewal.date.formatted(date: .abbreviated, time: .omitted)).font(.subheadline)
                                }
                            }
                        }
                    }
                    if let error { Text(error).foregroundStyle(.red) }
                    Button(audit == nil ? "Run My Subscription Audit" : "Run again") { Task { await run() } }.buttonStyle(PrimaryButtonStyle()).disabled(running)
                }.padding(22).frame(maxWidth: 800).frame(maxWidth: .infinity)
            }.background(Theme.canvas)
        }
    }
    private func run() async {
        running = true; error = nil; defer { running = false }
        do { let result = try await model.ai.analyseSubscriptionPortfolio(model.subscriptions); try Task.checkCancellation(); try model.saveAudit(result); audit = result }
        catch { self.error = error.localizedDescription }
    }
}

struct PortfolioGroupsView: View {
    @Environment(AppModel.self) private var model
    @State private var mode = "AI Stack"
    private var entries: [Subscription] {
        switch mode { case "AI Stack": return model.active.filter { $0.category == "AI Tools" }; case "Business": return model.active.filter { $0.scope != .personal }; default: return model.active }
    }
    var body: some View {
        List {
            Picker("View", selection: $mode) { ForEach(["AI Stack", "Household", "Business"], id: \.self) { Text($0).tag($0) } }.pickerStyle(.segmented)
            Section("Monthly spend · currencies kept separate") { CurrencyTotals(values: Money.grouped(entries)) }
            if mode == "Household" {
                ForEach(model.data.user.household.members, id: \.self) { member in
                    Section(member) { ForEach(entries.filter { $0.household == member }) { s in NavigationLink { SubscriptionDetailView(id: s.id) } label: { SubscriptionRow(subscription: s) } } }
                }
            } else {
                Section(mode == "AI Stack" ? "Your tools · most used first" : "Work & business commitments") {
                    ForEach(entries.sorted { ($0.usageFrequency.utilisation ?? -1) > ($1.usageFrequency.utilisation ?? -1) }) { s in
                        NavigationLink { SubscriptionDetailView(id: s.id) } label: {
                            VStack(alignment: .leading) { SubscriptionRow(subscription: s); if mode == "Business" { Text("\(Money.format(s.monthlyEquivalent / Decimal(s.seats), currency: s.currency))/licence/month · \(s.unusedSeats) unused").font(.caption).foregroundStyle(.secondary) } }
                        }
                    }
                }
            }
            Section("Possible overlap") {
                let insights = model.engine.insights(entries).filter { $0.id.hasPrefix("category-") || $0.id.hasSuffix("duplicate") || $0.id.hasSuffix("seats") }
                if insights.isEmpty { Text("No overlaps found in these entries.").foregroundStyle(.secondary) }
                ForEach(insights) { insight in VStack(alignment: .leading, spacing: 8) { Text(insight.title).font(.headline); Text(insight.explanation).font(.subheadline).foregroundStyle(.secondary) } }
            }
            Section { Text("Household profiles are local labels, not shared accounts. No cross-device sync is enabled. Cost per licence assumes the entered price covers all licences.").font(.caption).foregroundStyle(.secondary) }
        }.navigationTitle(mode)
    }
}

#Preview { NavigationStack { InsightsView() }.environment(AppModel.preview()) }
#Preview("Simulator") { SimulatorView().environment(AppModel.preview()) }
#Preview("Audit") { AuditView().environment(AppModel.preview()) }
#Preview("AI Stack") { NavigationStack { PortfolioGroupsView() }.environment(AppModel.preview()) }
