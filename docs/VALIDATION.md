# Validation and release status

This document distinguishes executed checks from work that needs Apple hardware/tooling. No phase is certified complete solely from a syntax parse.

## Executed on Windows

- `swift test --scratch-path C:\Users\User\AppData\Local\Temp\SubSenseBuild`: portable core compiled and **20 tests passed**, including strict localised price input, currency-specific income scoring and forecast boundaries.
- `swiftc -frontend -parse` across app source files: Swift syntax accepted. This does **not** type-check SwiftUI, SwiftData, Charts, UIKit, Vision or StoreKit.
- Project/resource generation, plist/JSON/XML parsing, resource path checks, source-reference completeness and secret/placeholder scans.

## Apple build gate — not executed here

Run the committed macOS workflow or the README Xcode commands. Resolve any SDK type-check, availability, link, asset or StoreKit schema error before release. Run on minimum iOS 17 and a current iOS simulator/device, including iPad. UI tests are provided but have not run here.

Manual acceptance paths:

1. New install → five onboarding pages → empty home → add service → kill/relaunch → verify persistence.
2. Add/edit/delete every billing frequency; test missing dates, free trial, cancelled and paused records, unknown usage and a zero-price plan.
3. Monthly Jan 31, Feb 29 annual and custom daily billing across timezone and daylight-saving boundaries.
4. Mixed GBP/USD/EUR portfolios remain separate in totals, sorting, audit, Copilot and every report.
5. Price edit preserves original currency and interval; category or currency change does not claim a bogus increase.
6. Never/rarely used versus daily/essential ratings explain their impact on scores and savings.
7. Cancellation is explicit and provider-confirmed; repeating confirmation does not duplicate the event. Downgrade preserves price history and records only the price delta.
8. Notification permission denied/granted, trial ending, 1/3/7/14/30-day settings, long annual renewal and cancellation plan. Verify the pending queue and private lock-screen content on a physical device. Confirm nothing schedules from demo mode.
9. Receipt screenshot/text import → ambiguous amounts or currencies → review → cancel leaves no record. Test large, empty, non-UTF8 and malformed files.
10. Free entry limit; Pro purchase; restore; pending approval; user cancellation; failed verification; offline entitlements; monthly-to-annual upgrade; grace period; expiry; refund/revocation; billing retry. Use StoreKit Transaction Manager and sandbox accounts. Test local fixture configuration explicitly; no trial should be shown.
11. Lock, failed authentication, app switching, foreground/background, sheets and exported preview content. A private screen must never remain in the app switcher. Test startup while protected data is unavailable.
12. Export every report to PDF/CSV/JSON, inspect pagination, non-Latin names, comma/quote/newline handling, formula-like names, huge notes and separate currencies. Confirm deletion removes local state/reminders and temporary exports but never claims to cancel provider plans.
13. VoiceOver traversal, largest accessibility text sizes, landscape, iPad split view, light/dark, Increase Contrast, Differentiate Without Color and Reduce Motion. Native controls have meaningful labels, but visual/accessibility QA is not yet performed.

## Product scope still requiring release work

- No real generative provider, live alternatives catalogue or current pricing source. The current local provider is functional and disclosed, but narrower than unrestricted AI chat.
- Receipt extraction is intentionally conservative: amount and frequency parsing, first-line name guess; renewal date/category/usage require user confirmation. No bulk CSV import is shipped.
- No bank/email account integrations, server sync or multi-device household accounts.
- No realised-cash savings ledger or reconstructed historical counts/spend. Only recorded audit snapshots and labelled annualised reductions are shown.
- Provider icons are original letter tiles, not licensed company logos. No verified provider-specific cancellation URL catalogue is bundled.
- English string catalog is seeded with static UI strings. Dynamic model-generated explanations and enum labels need a dedicated localisation pass before adding another language.
- Marketing screenshots require simulator capture and design review. UI test attachments cover several main screens, not all seven final App Store panels.
- Verify all premium entry points, app-lock snapshot protection, report layout and notification scheduling on Apple devices before shipping.

## App Store setup

Create an owned bundle ID and signing team. Create the two products and group in App Store Connect, configure paid-app agreements, verify storefront pricing, add support/privacy URLs and business contact details, then submit sandbox-tested builds. Review the actual built privacy report and App Privacy answers. In-app explanatory text is not a substitute for a publicly hosted privacy policy. Supply content rights and accurate screenshots.

Do not market this checkout as production-ready until Apple builds, StoreKit sandbox testing, accessibility/layout review, privacy review and device acceptance tests pass.
