# SubSense AI

Native iPhone and iPad subscription manager and savings copilot. SwiftUI, SwiftData, Apple Charts, StoreKit 2, Vision and local notifications. Minimum iOS 17. No runtime third-party dependencies or embedded credentials.

**Build status:** The portable Swift package compiles and its tests pass on Windows. App sources pass a Swift syntax parse. The iOS target has **not** been compiled or run against an Apple SDK in this environment; Xcode and the simulator are unavailable on Windows. This is a substantial local-first implementation, **not a verified App Store-ready release**. See [validation and release work](docs/VALIDATION.md).

## Open on a Mac

1. Open `SubSense.xcodeproj` in Xcode 16 or newer.
2. Select the **SubSense** scheme and an iPhone or iPad simulator.
3. Run. Onboarding offers an isolated demo portfolio; the normal app starts empty.
4. For a physical device, choose your development team and a bundle identifier you own in Signing & Capabilities.
5. The shared Debug scheme selects `SubSense.storekit` for local purchases. Prices in that file are test fixtures. Production screens read `Product.displayPrice` from StoreKit.

```sh
swift test
xcodebuild -project SubSense.xcodeproj -scheme SubSense \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SubSense.xcodeproj -scheme SubSense \
  -destination 'platform=iOS Simulator,name=<installed iPhone simulator>' test
```

The GitHub workflow runs core tests, builds the iOS app and runs UI tests with screenshot attachments on macOS. It has been created locally, not dispatched or verified remotely.

On this Windows installation, SwiftPM needs a scratch path outside the spaced workspace path:

```powershell
swift test --scratch-path "$env:LOCALAPPDATA\Temp\SubSenseBuild"
```

## What is implemented

- Five native tabs, five-step onboarding, light/dark semantic surfaces, iPad width constraints, Dynamic Type text styles, VoiceOver labels and reduced-motion-aware onboarding.
- Manual CRUD: weekly/monthly/quarterly/yearly/custom-day/lifetime billing, price history, trial dates, usage, purpose, licence counts, household labels, notes and payment nicknames.
- Separate currency totals, anchored recurring renewal calculations, 7/14/30-day forecasts, calendar/timeline views and notification preferences.
- Explainable health, value and cancellation scores; low-use waste, category overlap, provider duplication, trial, price and stale-review signals.
- Local rules audit, snapshot history, a limited local Copilot, receipt text parsing and on-device screenshot OCR. Extracted details must be reviewed in the editor and explicitly saved.
- Savings simulator, cancellation checklist/reminder, provider-confirmed cancellation and downgrade recording, annualised reductions and goals.
- Household labels, business licence analysis and AI Stack views. These are local classifications, not shared accounts or a cloud service.
- StoreKit verified entitlements, transaction listener, purchase/restore, five-entry free limit and Pro feature entry points. No free trial is advertised or configured.
- Device authentication lock, local data protection, private notification content, data deletion and CSV/PDF/JSON exports. Export is accessible without Pro before deletion.
- Preview fixtures, unit tests, UI test sources, local StoreKit configuration, app icon assets and App Store copy.

## Honest boundaries

The bundled `LocalAIService` is a deterministic mock/offline provider implementing `AIService`, not an LLM. It never observes device usage. No external API, banking, email account, cross-device sync, live pricing or third-party cancellation integration is claimed or present. Alternatives compare strategies and a price entered by the user; they are not a live vendor catalogue. No automatic price detection is performed.

Weekly normalisation uses 52 charges/year; custom-day normalisation uses 365 days/year. Forecasts use actual calendar occurrences. Trials contribute their entered post-trial price to projected recurring spend. Lifetime, paused and cancelled records do not contribute. Different currencies are never added together.

Savings events describe annualised reductions at an action date, **not realised money saved**. True cash-flow savings, historical subscription counts and historical monthly spend require a richer event ledger; the app shows recorded audit snapshots and labelled projections instead of inventing a history. Notifications fill the nearest 60 events and need periodic app openings to replenish.

## Structure

```text
SubSense.xcodeproj/          Shared app and UI test targets; local Swift package
Sources/SubSenseCore/        Codable value models, money, renewals, scoring, AI abstraction
Tests/SubSenseCoreTests/     Swift Testing calculation and model suite
SubSense/App/                Dependency graph, observable portfolio state, protected root
SubSense/Design/             Reusable cards, typography, score rings, brand components
SubSense/Features/           Native screens and forms
SubSense/Services/           SwiftData, StoreKit, notifications, OCR, reports
SubSense/Resources/          Icon, string catalog, privacy manifest, StoreKit fixture
SubSenseUITests/             Simulator navigation, CRUD and screenshot tests
docs/                       Architecture, release validation, store metadata
scripts/                    Reproducible project/resource generation
```

`AppModel` coordinates mutations through an injected repository and publishes them only after a successful save. `PortfolioRecord` stores a versioned Codable aggregate inside SwiftData. This keeps the financial domain portable and testable. Context save failures roll back; a corrupt store produces a recoverable startup error rather than replacing user data. Demo changes stay entirely in memory.

The committed Xcode project is ready to open; no generator is required. After adding files, regenerate it with `python3 scripts/generate_project.py`. Resource regeneration additionally needs Pillow: `python3 scripts/generate_resources.py`.

See [architecture](docs/ARCHITECTURE.md), [validation](docs/VALIDATION.md) and [App Store copy](docs/APP_STORE.md).
