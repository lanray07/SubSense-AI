import Foundation
import Observation
import StoreKit
#if DEBUG
import OSLog
#endif

@MainActor @Observable
final class StoreManager {
    static let productIDs = ["com.subsense.pro.monthly", "com.subsense.pro.annual"]
    var products: [Product] = []
    var hasPro = false
    var loading = false
    var message: String?
    private var updates: Task<Void, Never>?
    func start() async {
        if updates == nil {
            updates = Task { [weak self] in
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { break }
                    guard case .verified(let transaction) = result else { continue }
                    await self?.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
        await refreshEntitlements()
        await loadProducts()
    }
    func loadProducts() async {
        loading = true; defer { loading = false }
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
            message = products.isEmpty ? "Plans are unavailable. Check your connection or try again later." : nil
        } catch { message = "Unable to load plans. Please try again." }
    }
    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, Self.productIDs.contains(transaction.productID), transaction.revocationDate == nil, !transaction.isUpgraded { active = true }
        }
        hasPro = active
    }
    func purchase(_ action: @MainActor () async throws -> Product.PurchaseResult) async {
        guard !loading else { return }
        loading = true; message = nil; defer { loading = false }
        #if DEBUG
        let diagnostic = Logger(subsystem: "com.subsenseai.app", category: "StoreKitAcceptance")
        diagnostic.notice("Purchase action requested")
        #endif
        do {
            let result = try await action()
            #if DEBUG
            diagnostic.notice("Purchase action returned")
            #endif
            switch result {
            case .success(let result):
                #if DEBUG
                diagnostic.notice("Purchase success; checking verification")
                #endif
                guard case .verified(let transaction) = result else { message = "The purchase could not be verified. Please restore purchases or contact Apple Support."; return }
                #if DEBUG
                diagnostic.notice("Purchase verified; refreshing entitlement")
                #endif
                await refreshEntitlements(); await transaction.finish()
                #if DEBUG
                diagnostic.notice("Entitlement refresh completed")
                #endif
                message = hasPro ? "Your Pro access is ready." : "Your purchase is being confirmed. Try Restore Purchases if access doesn't update."
            case .pending: message = "Purchase awaiting approval. Access updates automatically after approval."
            case .userCancelled: break
            @unknown default: message = "The purchase could not be completed. Please try again."
            }
        } catch { message = "Purchase failed. No access change was made. Please try again." }
    }
    func restore() async {
        loading = true; defer { loading = false }
        do { try await AppStore.sync(); await refreshEntitlements(); message = hasPro ? "Pro purchases restored." : "No active Pro subscription was found for this Apple Account." }
        catch { message = "Couldn't restore purchases. Please try again." }
    }
}
