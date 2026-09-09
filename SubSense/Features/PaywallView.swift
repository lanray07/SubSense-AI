import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @State private var selectedID = "com.subsense.pro.annual"
    @State private var manage = false
    @State private var legal: LegalPage?
    private var selected: Product? { store.products.first { $0.id == selectedID } ?? store.products.first }
    var body: some View {
        SheetShell(title: "SubSense Pro") {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    BrandMark(size: 60)
                    Text(store.hasPro ? "More clarity.\nMore possibilities." : "Stop paying for subscriptions you don't need.").font(.system(.largeTitle, design: .serif)).tracking(-0.8)
                    Text("Finding just one unused subscription could pay for SubSense Pro.").foregroundStyle(.secondary).lineSpacing(4)
                    ForEach(["Unlimited subscriptions", "Local savings audit & recommendations", "Value Score & Cancel Score", "Price history & advanced insights", "Subscription Copilot", "Savings simulator & household profiles", "CSV, PDF & JSON exports"], id: \.self) { item in Label(item, systemImage: "checkmark.circle.fill").foregroundStyle(Theme.accent).font(.subheadline) }
                    if store.hasPro {
                        Label("Your Pro access is active", systemImage: "checkmark.seal.fill").font(.headline)
                        Button("Manage subscription") { manage = true }.buttonStyle(PrimaryButtonStyle())
                    } else {
                        if store.loading { ProgressView("Loading plans…").frame(maxWidth: .infinity) }
                        ForEach(store.products, id: \.id) { product in
                            Button { selectedID = product.id } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) { Text(product.displayName).font(.headline); Text(product.description).font(.caption).foregroundStyle(.secondary) }
                                    Spacer(); Text(product.displayPrice).font(.title3.weight(.semibold))
                                    Image(systemName: selected?.id == product.id ? "checkmark.circle.fill" : "circle")
                                }.padding(20).background(Theme.card, in: RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(selected?.id == product.id ? Theme.accent : .clear, lineWidth: 1.5))
                            }.buttonStyle(.plain)
                        }
                        if let selected {
                            Button("Subscribe · \(selected.displayPrice)") { Task { await store.purchase(selected) } }.buttonStyle(PrimaryButtonStyle()).disabled(store.loading)
                            Text("Auto-renews at \(selected.displayPrice) \(selected.id.hasSuffix("annual") ? "per year" : "per month") unless cancelled at least 24 hours before the current period ends. Manage or cancel in your Apple Account settings. Payment is charged to your Apple Account.").font(.caption).foregroundStyle(.secondary)
                        } else if !store.loading { Button("Retry loading plans") { Task { await store.loadProducts() } }.buttonStyle(.bordered) }
                    }
                    if let message = store.message { Text(message).font(.subheadline).foregroundStyle(.secondary) }
                    Button("Restore Purchases") { Task { await store.restore() } }.disabled(store.loading).frame(maxWidth: .infinity)
                    HStack { Button("Terms") { legal = .terms }; Spacer(); Button("Privacy Policy") { legal = .privacy } }.font(.caption)
                    Text("Free includes five subscriptions, basic insights and renewal reminders. No introductory trial is configured in this build.").font(.caption).foregroundStyle(.secondary)
                }.padding(26).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }.background(Theme.canvas).manageSubscriptionsSheet(isPresented: $manage)
                .sheet(item: $legal) { page in
                    switch page {
                    case .privacy: PrivacyView()
                    case .terms: SheetShell(title: "Terms") { ScrollView { VStack(alignment: .leading, spacing: 20) { Text("SubSense provides subscription records and estimates from information you enter. You are responsible for confirming billing dates, prices, provider terms and cancellations. The app does not execute third-party cancellations or provide financial advice."); Text("SubSense Pro renews automatically unless cancelled through your Apple Account. Deleting local data does not cancel Pro. Apple handles payment, refunds and subscription management."); Link("Apple Standard Licensed Application EULA", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) }.padding(24) } }
                    }
                }
        }
    }
    enum LegalPage: String, Identifiable { case terms, privacy; var id: String { rawValue } }
}

#Preview { PaywallView().environment(StoreManager()) }
