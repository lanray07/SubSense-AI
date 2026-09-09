# Validation and release status

Updated 9 September 2026. Version 1.0 (4.1), the Pro group and both plans were submitted at 18:36 BST and are **Waiting for Review**. Apple builds and simulator tests run on GitHub macOS runners because the local workspace is Windows.

## Executed acceptance checks

[Release validation 34376045879](https://github.com/lanray07/SubSense-AI/actions/runs/34376045879), source `b3ae2e7`, ran on iPhone 16 Pro and iPad Pro 13-inch (M4), using iOS 18 and 26 with Xcode 26.3.

- All 20 portable core tests passed in each job. They cover renewal dates, currency separation, price validation, scoring and forecasts.
- All ten native UI acceptance tests passed on both iOS 26 devices.
- Nine of ten native UI tests passed on both iOS 18 devices; the purchase test required further investigation and a focused rerun.
- Passing flows covered onboarding, saving and reopening an edited subscription, validation and search, calendar navigation, demo navigation, the five-entry free limit, receipt review and report export, and both screenshot sets.
- Dark mode, the largest accessibility text setting, privacy-sheet navigation and landscape passed on all four configurations. Native screenshots were visually reviewed on iPhone and iPad.

The final purchase implementation uses SwiftUI's `PurchaseAction` to supply payment presentation context. Both monthly and annual plans were purchased through the native UI; restore, monthly expiration and annual refund revocation were verified on:

| Devices | Runtime and toolchain | Result and evidence |
| --- | --- | --- |
| iPhone 16 Pro and iPad Pro 13-inch M4 | iOS 26, Xcode 26.3 | Both passed in [34381680122](https://github.com/lanray07/SubSense-AI/actions/runs/34381680122), source `2bca680` |
| iPhone 16 Pro and iPad Pro 13-inch M4 | iOS 18.2, Xcode 16.2 | Both passed in [34382940646](https://github.com/lanray07/SubSense-AI/actions/runs/34382940646), source `42c1380` |

No production behavior changed after build 4.1. Subsequent commits adjusted acceptance tests, added debug-only transaction logging and made simulator startup bounded with one restart. The release-validation workflow defaults to the verified iOS 18.2/26 pairing. Its `current` and `paired` options retain the iOS 18.5 diagnostic configurations.

### Remaining simulator limitation

iOS 18.5 commerce tests did not pass with either Xcode 16.4 or 26.3. In [diagnostic run 34382584676](https://github.com/lanray07/SubSense-AI/actions/runs/34382584676), the app logged entry into Apple's purchase action but no return within 90 seconds. The app remained responsive, and the simulator's StoreKit service repeatedly logged unsuccessful push-service connections. The same production purchase path passed on iOS 18.2 and 26. This isolates the failure to the tested iOS 18.5 setup, but does not establish an Apple-confirmed root cause or prove physical-device behavior on 18.5. The failed runs remain visible; they have not been counted as passes.

## Repairs verified by the acceptance suite

- Replaced the calendar's nested List/grid layout after reproducing a UIKit recursive self-sizing crash.
- Made editor validation errors visible, improved receipt keyboard dismissal and maintained accessible layouts at large text sizes.
- Kept StoreKit initialization alive across the loading-screen transition and added a paywall product-load retry.
- Removed misleading onboarding and internal implementation text from customer-facing screens.

## Store media and metadata

[Screenshot capture 34375255138](https://github.com/lanray07/SubSense-AI/actions/runs/34375255138) passed for iPhone and iPad. Eight screenshots per device family were composed from genuine native captures, visually reviewed and uploaded in order. The iPhone images are 1284 × 2778 and the 13-inch iPad images are 2064 × 2752. Two subscription artworks are 1024 × 1024. The asset archive passed its integrity check.

Both subscriptions have review screenshots, production pricing and public support/privacy URLs. App privacy states Data Not Collected, consistent with the local app implementation. See [distribution evidence](GITHUB_DISTRIBUTION.md) for the signed upload and final submission status.

## Scope of this evidence

StoreKit checks use Apple's local test configuration; they do not charge a live account. Simulator checks do not establish physical-device Face ID behavior, delivery of every notification, or every real billing state. The iOS 17 deployment target is compiler-checked, but this matrix runs iOS 18 and 26. English is the only release language.

The Copilot is an on-device rules service. The app has no bank/email integration, remote generative service, server sync or shared household account. Receipt extraction requires review. Savings are labelled annualised reductions, not realised cash savings. These boundaries are disclosed in the product and store copy.
