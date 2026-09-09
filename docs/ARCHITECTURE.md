# Architecture and integration contracts

## State and persistence

SwiftUI owns feature-local form state. One main-actor observable `AppModel` owns the active portfolio and service instances. Screens read this model; editors work on value copies, then validate and save atomically. The repository protocol isolates SwiftData and supports an in-memory fixture implementation. Errors leave the last saved portfolio visible.

SwiftData persists a single versioned Codable `PortfolioRecord`. Aggregate boundaries keep subscription edits, cancellation state and savings events in one commit. Version 1 is explicit; decoding an unknown version fails safely. Production migrations must decode the old schema, transform it, validate it and persist only after a successful migration; do not silently discard decoding failures.

This is suitable for a personal portfolio. A later multi-user sync implementation should normalise subscriptions, immutable events and household membership rather than synchronising opaque aggregate blobs with last-write-wins semantics.

## Calculations

Use `Decimal` until chart rendering, where a `Double` is required. Currency grouping is explicit throughout dashboards, forecasts, simulations and exports. Store raw period prices; format only for display.

Recurring dates are calculated by adding each interval to the original renewal anchor. They are not added repeatedly to the previous clamped date, so Jan 31 / Feb 28 / Mar 31 remains stable. The forecast window includes its first day and excludes the end boundary. Date-only commitments use the user's calendar. A timezone change may affect presentation; a future sync schema should store date-only components and original billing timezone explicitly.

Scores are heuristics, never observed usage or financial advice. Cancellation: up to 65 usage points, 12 category overlap, 10 relative high cost, 8 price increase and 5 near-renewal points; subtract 25 for an essential service. Clamp to 0–100. Unknown usage adds zero. Health is 100 minus average active Cancel Score, with an optional matching-currency income penalty. Value uses reported utilisation and within-currency category cost.

Potential savings includes each active non-essential rarely/never-used commitment exactly once. Duplicate and overlap warnings add no extra savings. Estimates do not account for fees, non-refundable annual charges or replacement purchases.

## AI and discovery

`AIService` exposes audit, waste, recommendation, value comparison, cancellation planning, chat and receipt extraction operations. `LocalAIService` is the shipped deterministic implementation, also suitable as the mock provider for tests. The UI names this mode plainly.

A production generative provider requires a separately deployed authenticated backend. Send only explicitly consented fields, use short-lived authentication, rate limits, budget limits, schema-validated responses and an allowlist of subscription IDs. Never trust generated amounts: recompute savings with the local engine. Receipt text is untrusted data, never instructions. Do not log receipts or financial notes. Store backend secrets only in server-managed secret storage; client session tokens belong in Keychain when authentication is actually introduced.

No backend configuration or credentials are required today. `PortfolioSyncService` and `SubscriptionDiscoverySource` are extension points, not simulated live integrations. A discovery implementation returns drafts; explicit user confirmation remains mandatory. Apple's StoreKit access here is limited to this app's own Pro products.

## StoreKit

Product IDs: `com.subsense.pro.monthly` and `com.subsense.pro.annual` in the same subscription group. Replace identifiers consistently if needed. Production prices come from StoreKit. Entitlements use verified `Transaction.currentEntitlements`, preserving StoreKit's handling of grace periods. Verified updates refresh state and finish transactions. Unverified, pending and cancelled purchase results do not unlock access.

No introductory offer is configured, so the CTA does not promise a trial. Add a trial only with StoreKit eligibility checks and accurate duration/renewal disclosures. Local demo access does not mutate the purchased entitlement and cannot be persisted into the real portfolio.

References checked during implementation: [Apple current entitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements), [SwiftData ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer), [privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files).

## Privacy and notifications

No SDK analytics, advertising or remote AI requests. The app's directory requests complete file protection. Preferences contain onboarding/lock state, not financial records. DeviceOwnerAuthentication supports biometrics or passcode; cancelling authentication never reveals the protected root. Export files use file protection, live in a bounded temporary directory and are cleared on next normal launch/deletion.

Notifications are opt-in. Names and prices are hidden by default. Subscription and cancellation reminders share the nearest-60 budget. Scheduling is serialised to avoid stale batches racing with a later edit. Refresh occurs on save and foreground. Demo entries never schedule alerts. New near-term commitments whose alert date has already passed require in-app review rather than backdated notifications.
