import SwiftUI
import UIKit
import Charts
import SubSenseCore

struct SubscriptionDetailView: View {
    @Environment(AppModel.self) private var model
    var id: UUID
    var body: some View {
        if let s = model.subscriptions.first(where: { $0.id == id }) {
            ScrollView {
                VStack(spacing: 22) {
                    Card {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack { ProviderIcon(subscription: s); Spacer(); Text(s.status.rawValue.capitalized).font(.caption.weight(.semibold)).padding(8).background(Theme.mint.opacity(0.4), in: Capsule()) }
                            Text(s.name).font(.system(.largeTitle, design: .serif))
                            Text("\(Money.format(s.price, currency: s.currency)) / \(s.billingFrequency.label.lowercased())").font(.title2.weight(.semibold))
                            Text("\(Money.format(s.annualEquivalent, currency: s.currency)) projected per year").foregroundStyle(.secondary)
                            if let next = model.engine.renewals([s], from: Date(), days: 400).first { Label("Next: \(next.date.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar").font(.subheadline) }
                        }
                    }
                    if model.canUsePro {
                        scoreCard("Value Score", score: model.engine.valueScore(s, portfolio: model.subscriptions), subtitle: s.usageFrequency == .unknown ? "Add usage to improve this estimate" : "Based on your reported usage")
                        scoreCard("Cancel Score", score: model.engine.cancelScore(s, portfolio: model.subscriptions), subtitle: "Higher means worth reviewing sooner")
                    } else { Button("Unlock Value & Cancel Scores") { model.sheet = .paywall }.buttonStyle(PrimaryButtonStyle()) }
                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            LabeledContent("Category", value: s.category)
                            LabeledContent("Usage", value: s.usageFrequency.label)
                            LabeledContent("Profile", value: s.household)
                            LabeledContent("Purpose", value: s.scope.rawValue.capitalized)
                            if !s.paymentNickname.isEmpty { LabeledContent("Payment", value: s.paymentNickname) }
                            if s.scope != .personal { LabeledContent("Licences", value: "\(s.seats) · \(s.unusedSeats) unused") }
                            if !s.notes.isEmpty { Text(s.notes).font(.subheadline).foregroundStyle(.secondary) }
                        }
                    }
                    if !s.priceHistory.isEmpty && model.canUsePro {
                        Card {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeading(title: "Price history", subtitle: "Recorded prices per billing period")
                                let history = s.priceHistory.filter { $0.currency == s.currency && $0.frequency == s.billingFrequency && $0.customDays == s.customDays }
                                Chart {
                                    ForEach(history) { item in
                                        LineMark(x: .value("Date", item.date), y: .value("Price", Money.number(item.price))).foregroundStyle(Theme.accent)
                                        PointMark(x: .value("Date", item.date), y: .value("Price", Money.number(item.price))).foregroundStyle(Theme.accent)
                                    }
                                    LineMark(x: .value("Date", s.updatedAt), y: .value("Price", Money.number(s.price))).foregroundStyle(Theme.accent)
                                    PointMark(x: .value("Date", s.updatedAt), y: .value("Price", Money.number(s.price))).foregroundStyle(Theme.accent)
                                }.frame(height: 160).accessibilityLabel("Price history in \(s.currency)")
                                ForEach(s.priceHistory) { item in Text("\(item.date.formatted(date: .abbreviated, time: .omitted)): \(Money.format(item.price, currency: item.currency)), \(item.frequency.label.lowercased())").font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                    }
                    NavigationLink { AlternativesView(subscription: s) } label: { Label("Find alternatives", systemImage: "arrow.triangle.branch") }.buttonStyle(.bordered)
                    if s.isRecurring { NavigationLink { CancellationView(id: s.id) } label: { Text("Build a cancellation plan") }.buttonStyle(PrimaryButtonStyle()) }
                }.padding(22).frame(maxWidth: 800).frame(maxWidth: .infinity)
            }.background(Theme.canvas).navigationTitle("Subscription").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Edit") { model.sheet = .edit(s) } }
        } else { ContentUnavailableView("Subscription not found", systemImage: "square.stack") }
    }
    private func scoreCard(_ title: String, score: Score, subtitle: String) -> some View {
        Card { VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 20) { ScoreRing(score: score.value); VStack(alignment: .leading, spacing: 5) { Text(title).font(.headline); Text(subtitle).font(.caption).foregroundStyle(.secondary) } }
            DisclosureGroup("How we worked this out") { VStack(alignment: .leading, spacing: 10) { ForEach(score.reasons, id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) }; Text("An optimisation suggestion, not an automatic decision or financial advice.").font(.caption) } }
        } }
    }
}

struct CancellationView: View {
    @Environment(AppModel.self) private var model
    var id: UUID
    @State private var plan: CancellationPlan?
    @State private var confirmed = false
    @State private var message: String?
    private let steps = ["Check your provider's billing portal and cancellation terms.", "Export files and transfer shared access if needed.", "Cancel with the provider; check the effective date and any fees.", "Save the provider's confirmation and check for future charges."]
    var body: some View {
        Form {
            if let s = model.subscriptions.first(where: { $0.id == id }), let current = plan {
                Section { SubscriptionRow(subscription: s); Text("\(Money.format(s.annualEquivalent, currency: s.currency))/year in projected savings if you stop this commitment.").font(.subheadline) }
                Section { Text("SubSense cannot cancel this service for you. Complete cancellation with the provider before marking it cancelled here.").foregroundStyle(.secondary) }
                Section("Your checklist") {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        Toggle(step, isOn: Binding(get: { plan?.completedSteps.contains(index) ?? false }, set: { value in if value { plan?.completedSteps.insert(index) } else { plan?.completedSteps.remove(index) } }))
                    }
                }
                Section("Remind me to review") {
                    DatePicker("Planned date", selection: Binding(get: { plan?.intendedDate ?? Date() }, set: { plan?.intendedDate = $0 }), in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    Button("7 days before next renewal") {
                        if let renewal = model.engine.renewals([s], from: Date(), days: 400).first?.date { plan?.intendedDate = max(Date().addingTimeInterval(60), Calendar.current.date(byAdding: .day, value: -7, to: renewal) ?? Date()) }
                    }
                    TextField("Plan notes", text: Binding(get: { plan?.notes ?? "" }, set: { plan?.notes = $0 }), axis: .vertical)
                    Button("Save plan & reminder") { Task { await saveReminder() } }
                    Button("Keep this subscription") {
                        model.keep(s); plan?.status = .keeping
                        do { if let plan { try model.savePlan(plan) }; message = "Marked as keeping." } catch { message = error.localizedDescription }
                    }
                    NavigationLink("Record a downgrade") { DowngradeView(id: id) }
                }
                Section {
                    Button("I've cancelled with the provider", role: .destructive) { confirmed = true }.disabled(!s.isRecurring)
                    Text("Plan status: \(current.status.rawValue.capitalized)").font(.caption)
                    if let message { Text(message).font(.subheadline).foregroundStyle(.secondary) }
                }
            } else { ProgressView("Preparing your plan…") }
        }.navigationTitle("Cancellation Assistant").navigationBarTitleDisplayMode(.inline)
            .task {
                if plan == nil, let s = model.subscriptions.first(where: { $0.id == id }) {
                    do {
                        if let existing = model.data.cancellationPlans.first(where: { $0.subscriptionID == id }) { plan = existing }
                        else { plan = try await model.ai.generateCancellationPlan(s) }
                    }
                    catch { model.error = error.localizedDescription }
                }
            }
            .confirmationDialog("Have you completed cancellation with the provider?", isPresented: $confirmed, titleVisibility: .visible) {
                Button("Confirm cancellation", role: .destructive) {
                    do { try model.confirmCancellation(id); plan?.status = .cancelled; UIImpactFeedbackGenerator(style: .soft).impactOccurred() } catch { model.error = error.localizedDescription }
                }
            } message: { Text("This updates your local record and projected savings. It does not contact the provider or refund past payments.") }
    }
    private func saveReminder() async {
        guard let plan else { return }
        do {
            try model.savePlan(plan)
            if model.isDemo { message = "Demo plan saved. No notification scheduled."; return }
            guard try await model.notifications.requestPermission() else { message = "Plan saved. Notifications weren't allowed; enable them in iOS Settings."; return }
            var preferences = model.data.notifications; preferences.enabled = true
            try model.savePreferences(user: model.data.user, notifications: preferences)
            message = "Plan saved. Reminders use the nearest 60 scheduled events and refresh when you open SubSense."
        } catch { message = error.localizedDescription }
    }
}

struct DowngradeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var id: UUID
    @State private var price = ""
    @State private var error: String?
    var body: some View {
        Form {
            if let s = model.subscriptions.first(where: { $0.id == id }) {
                Section { Text("Only record a downgrade after changing the plan with your provider. Keep the same currency and billing interval."); TextField("New price per billing period", text: $price).keyboardType(.decimalPad) }
                Button("Record confirmed downgrade") {
                    do {
                        guard let value = Money.parseInput(price), value < s.price else { throw DomainError.invalid("Enter a non-negative price below the current price.") }
                        try model.confirmDowngrade(id, newPrice: value); dismiss()
                    } catch { self.error = error.localizedDescription }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
        }.navigationTitle("Record downgrade")
    }
}

struct AlternativesView: View {
    var subscription: Subscription
    @State private var replacementPrice = ""
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Card { VStack(alignment: .leading, spacing: 12) { Eyebrow(text: "Your current commitment"); SubscriptionRow(subscription: subscription) } }
                ForEach(LocalAIService.alternatives(for: subscription)) { alternative in
                    Card { VStack(alignment: .leading, spacing: 12) { Text(alternative.name).font(.headline); Text(alternative.features); Text(alternative.limitations).foregroundStyle(.secondary); Label(alternative.difficulty, systemImage: "arrow.left.arrow.right").font(.caption); Text(alternative.pricingNote).font(.caption).foregroundStyle(.secondary) } }
                }
                Card {
                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeading(title: "Compare a verified price", subtitle: "Enter a replacement's monthly price in \(subscription.currency).")
                        TextField("Monthly replacement price", text: $replacementPrice).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        if let replacement = Money.parseInput(replacementPrice) {
                            Text("Monthly difference: \(Money.format(subscription.monthlyEquivalent - replacement, currency: subscription.currency))").font(.headline)
                            Text("Annual difference: \(Money.format((subscription.monthlyEquivalent - replacement) * 12, currency: subscription.currency))").foregroundStyle(.secondary)
                        }
                        Text("No current external pricing is connected. Verify features, eligibility and migration costs yourself; a negative difference means higher spending.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }.padding(22).frame(maxWidth: 800).frame(maxWidth: .infinity)
        }.background(Theme.canvas).navigationTitle("Find alternatives")
    }
}

#Preview("Detail") { let model = AppModel.preview(); NavigationStack { SubscriptionDetailView(id: model.subscriptions[0].id) }.environment(model) }
#Preview("Cancellation") { let model = AppModel.preview(); NavigationStack { CancellationView(id: model.subscriptions[3].id) }.environment(model) }
#Preview("Alternatives") { NavigationStack { AlternativesView(subscription: DemoData.portfolio().subscriptions[0]) } }
