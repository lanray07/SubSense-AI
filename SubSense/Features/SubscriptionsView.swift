import SwiftUI
import SubSenseCore

enum SubscriptionFilter: String, CaseIterable {
    case all = "All", monthly = "Monthly", annual = "Annual", trials = "Trials", high = "High Cost", low = "Low Usage", soon = "Renewing Soon", increased = "Price Increased", cancel = "Cancel Recommended", ai = "AI Tools", business = "Business SaaS"
}
enum SubscriptionSort: String, CaseIterable { case renewal = "Renewal date", expensive = "Most expensive", cheapest = "Cheapest", low = "Lowest value", high = "Highest value", saving = "Biggest potential saving" }

struct SubscriptionsView: View {
    @Environment(AppModel.self) private var model
    @State private var search = ""
    @State private var filter: SubscriptionFilter = .all
    @State private var sort: SubscriptionSort = .renewal
    @State private var deleteTarget: Subscription?
    private var filtered: [Subscription] {
        let upcoming = Set(model.engine.renewals(model.subscriptions, from: Date(), days: 8).map { $0.subscription.id })
        let result = model.subscriptions.filter { s in
            let text = [s.name, s.provider, s.category, s.notes, s.status.rawValue, "\(s.price)", s.currency].joined(separator: " ")
            guard search.isEmpty || text.localizedCaseInsensitiveContains(search) else { return false }
            switch filter {
            case .all: return true
            case .monthly: return s.billingFrequency == .monthly
            case .annual: return s.billingFrequency == .yearly
            case .trials: return s.status == .trial
            case .high:
                let peers = model.active.filter { $0.currency == s.currency }
                let average = peers.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent } / Decimal(max(1, peers.count))
                return s.isRecurring && s.monthlyEquivalent > average * 15 / 10
            case .low: return s.usageFrequency == .rarely || s.usageFrequency == .never
            case .soon: return upcoming.contains(s.id)
            case .increased: return s.priceIncrease != nil
            case .cancel: return model.engine.cancelScore(s, portfolio: model.subscriptions).value >= 60
            case .ai: return s.category == "AI Tools"
            case .business: return s.scope != .personal
            }
        }
        return result.sorted { a, b in
            if a.currency != b.currency { return a.currency < b.currency }
            switch sort {
            case .renewal:
                let left = model.engine.renewals([a], from: Date(), days: 400).first?.date ?? .distantFuture
                let right = model.engine.renewals([b], from: Date(), days: 400).first?.date ?? .distantFuture
                return left < right
            case .expensive: return a.monthlyEquivalent > b.monthlyEquivalent
            case .cheapest: return a.monthlyEquivalent < b.monthlyEquivalent
            case .low: return model.engine.valueScore(a, portfolio: model.subscriptions).value < model.engine.valueScore(b, portfolio: model.subscriptions).value
            case .high: return model.engine.valueScore(a, portfolio: model.subscriptions).value > model.engine.valueScore(b, portfolio: model.subscriptions).value
            case .saving: return a.monthlyEquivalent > b.monthlyEquivalent
            }
        }
    }
    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SubscriptionFilter.allCases, id: \.self) { item in
                            Button(item.rawValue) { filter = item }.font(.caption.weight(.semibold)).padding(.horizontal, 14).padding(.vertical, 10)
                                .foregroundStyle(filter == item ? Color.white : Theme.accent).background(filter == item ? Theme.action : Theme.accent.opacity(0.08), in: Capsule())
                                .accessibilityAddTraits(filter == item ? .isSelected : [])
                        }
                    }
                }.listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            }
            if filtered.isEmpty { ContentUnavailableView.search(text: search.isEmpty ? filter.rawValue : search) }
            ForEach(Array(Set(filtered.map(\.currency))).sorted(), id: \.self) { currency in
                Section(currency) {
                    ForEach(filtered.filter { $0.currency == currency }) { s in
                        NavigationLink { SubscriptionDetailView(id: s.id) } label: { SubscriptionRow(subscription: s) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) { deleteTarget = s }
                                Button("Edit") { model.sheet = .edit(s) }.tint(Theme.accent)
                            }
                            .contextMenu {
                                Button("Edit subscription", systemImage: "pencil") { model.sheet = .edit(s) }
                                Button("Mark as essential", systemImage: "heart") { model.keep(s) }
                                Button("Delete record", systemImage: "trash", role: .destructive) { deleteTarget = s }
                            }
                    }
                }
            }
            Section { Text("Costs are sorted within each currency. High Cost means over 1.5× your average monthly cost in that currency.").font(.caption).foregroundStyle(.secondary) }
        }.navigationTitle("Subscriptions").searchable(text: $search, prompt: "Name, category, notes or cost")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Menu { Picker("Sort", selection: $sort) { ForEach(SubscriptionSort.allCases, id: \.self) { Text($0.rawValue).tag($0) } } } label: { Image(systemName: "arrow.up.arrow.down") }.accessibilityLabel("Sort subscriptions") }
                ToolbarItem(placement: .topBarTrailing) { Button { model.sheet = .add } label: { Image(systemName: "plus") }.accessibilityLabel("Add subscription") }
            }
            .confirmationDialog("Delete \(deleteTarget?.name ?? "subscription")? This removes the record, not the provider's subscription.", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }), titleVisibility: .visible) {
                Button("Delete record", role: .destructive) { if let s = deleteTarget { model.delete(s.id) }; deleteTarget = nil }
            }
    }
}

struct SubscriptionEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State var subscription: Subscription
    @State private var priceText = ""
    @State private var hasRenewal = false
    @State private var customCategory = ""
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("The essentials") {
                    TextField("Subscription name", text: $subscription.name).textContentType(.organizationName)
                    TextField("Provider", text: $subscription.provider)
                    HStack { TextField("Price per billing period", text: $priceText).keyboardType(.decimalPad); Picker("Currency", selection: $subscription.currency) { ForEach(Locale.commonISOCurrencyCodes.sorted(), id: \.self) { Text($0).tag($0) } }.labelsHidden() }
                    Picker("Billing frequency", selection: $subscription.billingFrequency) { ForEach(BillingFrequency.allCases, id: \.self) { Text($0.label).tag($0) } }
                    if subscription.billingFrequency == .custom { Stepper("Every \(subscription.customDays) days", value: $subscription.customDays, in: 1...3650) }
                    Picker("Category", selection: $subscription.category) { ForEach(Array(Set(SubscriptionCategory.all + [subscription.category])).sorted(), id: \.self) { Text($0).tag($0) } }
                    if model.canUsePro { TextField("Custom category (optional)", text: $customCategory) }
                    Toggle("Variable price", isOn: $subscription.variablePrice)
                }
                Section {
                    DatePicker("Start date", selection: $subscription.startDate, displayedComponents: .date)
                    Picker("Status", selection: $subscription.status) { ForEach([SubscriptionStatus.active, .trial, .paused], id: \.self) { Text($0.rawValue.capitalized).tag($0) }; if subscription.status == .cancelled { Text("Cancelled").tag(SubscriptionStatus.cancelled) } }
                    if subscription.billingFrequency != .lifetime {
                        Toggle("Known renewal date", isOn: $hasRenewal)
                        if hasRenewal { DatePicker("Next billing date", selection: Binding(get: { subscription.nextBillingDate ?? Date() }, set: { subscription.nextBillingDate = $0 }), displayedComponents: .date) }
                    }
                    if subscription.status == .trial { DatePicker("Trial ends", selection: Binding(get: { subscription.trialEndDate ?? Date() }, set: { subscription.trialEndDate = $0 }), displayedComponents: .date) }
                } header: { Text("Timing") } footer: { Text("For trials, enter the post-trial price. Missing dates are excluded from forecasts. To record a cancellation and savings, use the Cancellation Assistant.") }
                Section("How it fits your life") {
                    Picker("Usage", selection: $subscription.usageFrequency) { ForEach(UsageRating.allCases, id: \.self) { Text($0.label).tag($0) } }
                    Toggle("Essential to me", isOn: $subscription.favourite)
                    Picker("Purpose", selection: $subscription.scope) { ForEach(SubscriptionScope.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }
                    if model.canUsePro {
                        Picker("Household profile", selection: $subscription.household) { ForEach(Array(Set(model.data.user.household.members + [subscription.household])).sorted(), id: \.self) { Text($0).tag($0) } }
                    }
                    if subscription.scope != .personal {
                        Stepper("Licences: \(subscription.seats)", value: $subscription.seats, in: 1...10000)
                        Stepper("Unused licences: \(subscription.unusedSeats)", value: $subscription.unusedSeats, in: 0...subscription.seats)
                    }
                    TextField("Payment method nickname", text: $subscription.paymentNickname)
                    TextField("Notes", text: $subscription.notes, axis: .vertical).lineLimit(3...6)
                }
                if let error { Section { Text(error).foregroundStyle(.red) } }
            }.navigationTitle(model.subscriptions.contains(where: { $0.id == subscription.id }) ? "Edit subscription" : "Add subscription").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).fontWeight(.semibold) }
                }
                .onAppear { if priceText.isEmpty { priceText = subscription.price == 0 ? "" : Money.input(subscription.price) }; hasRenewal = subscription.nextBillingDate != nil }
                .onChange(of: subscription.status) { _, value in if value == .trial && subscription.trialEndDate == nil { subscription.trialEndDate = Date() } }
                .onChange(of: hasRenewal) { _, value in if value && subscription.nextBillingDate == nil { subscription.nextBillingDate = Date() } }
        }
    }
    private func save() {
        guard let price = Money.parseInput(priceText) else { error = "Enter a valid price."; return }
        var edited = subscription
        if let original = model.subscriptions.first(where: { $0.id == edited.id }), original.price != price {
            edited.priceHistory.append(.init(date: original.updatedAt, price: original.price, currency: original.currency, frequency: original.billingFrequency, customDays: original.customDays))
        }
        edited.price = price; edited.updatedAt = Date(); edited.lastReviewedAt = Date(); edited.isDemo = model.isDemo
        if !hasRenewal || edited.billingFrequency == .lifetime { edited.nextBillingDate = nil }
        if edited.status != .trial { edited.trialEndDate = nil }
        if !customCategory.trimmingCharacters(in: .whitespaces).isEmpty { edited.category = customCategory.trimmingCharacters(in: .whitespaces) }
        do { try model.save(edited); dismiss() } catch { self.error = error.localizedDescription }
    }
}

#Preview { NavigationStack { SubscriptionsView() }.environment(AppModel.preview()) }
#Preview("Add") { SubscriptionEditor(subscription: Subscription()).environment(AppModel.preview()) }
