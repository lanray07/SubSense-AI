# App Review response: Guidelines 4.3 and 4.2.6

Prepared for submission `e2f534c9-77c8-413e-ad6a-6970f05ab4fa` after the rejection received in October 2026. This response is intended for the Resolution Center. Do not resubmit the binary with this reply; Apple specifically asked for a reply instead of a resubmission when the developer believes the app already complies.

## Reply draft

Hello App Review,

SubSense AI is an independently developed standalone product, not a purchased template, app-generation-service product, or client app.

1. SubSense is a private, local subscription portfolio. Users record weekly, monthly, quarterly, annual, custom-day, trial, lifetime, paused, and cancelled commitments. It separates currencies, calculates anchored renewal dates, forecasts charges, and schedules private reminders. Rules explain Value, Cancel, and Health Scores from user-entered cost, usage, price history, essential status, and category overlap. Users model savings, plan cancellations, record provider-confirmed outcomes, and track projected annualised reductions. Receipt OCR creates a user-reviewed draft; the Copilot is deterministic and on-device.

2. It is for individuals and household organisers with recurring consumer or work subscriptions who want clarity without connecting a bank or email account. Freelancers can track SaaS licences, but SubSense is not accounting software, a bank aggregator, or a cancellation service.

3. Many trackers provide a list and alert or require financial-account access. SubSense combines local operation with irregular billing, currency-separated totals, explainable scoring, price-history/overlap signals, scenario comparison, cancellation planning, goals, and outcome recording. It covers identify -> explain -> plan -> remind -> record outcome on-device. Estimates are distinguished from realised savings; it never claims to observe usage or cancel with providers.

4. No external TestFlight beta group ran before submission, so there is no external-user feedback to report; internal testing is not beta feedback. Acceptance covered iPhone and 13-inch iPad on iOS 18.2/26, 20 domain tests, ten native UI flows, and purchase, restore, expiry, and refund-revocation for both plans. Production fixes included a crashing calendar layout, visible validation errors, receipt keyboard dismissal, StoreKit launch lifetime, paywall product-load retry, and large-text/landscape layouts. Evidence: https://github.com/lanray07/SubSense-AI/blob/main/docs/VALIDATION.md

5. SubSense is standalone, not part of a suite. Other account apps serve separate domains. MoneyPlain concerns budgets and net-worth records, ActionDesk concerns paperwork/actions, and PlanBridge concerns planning workflows. None includes SubSense's portfolio, renewal engine, scoring, cancellation, or savings-outcome workflow.

6. It cannot be added to another account app without creating a different product. SubSense has its own aggregate model, recurrence engine, scoring, calendar, notification policy, receipt review, StoreKit entitlement, exports, privacy disclosures, and navigation.

7. No account app shares SubSense's domain models, calculation engine, data, copy, icon, screenshots, receipt fixtures, or subscription assets. The closest repository comparison found 5.5% matching substantive Swift lines, primarily conventions: SwiftUI navigation/settings, StoreKit purchase/restore, notifications, Vision OCR, export/share helpers, and tests. These connect Apple frameworks to each app; SubSense's logic and assets are repository-specific.

8. The binary shares no codebase, SDK, template, or content library with a third-party app. It uses Apple system frameworks. SubSenseCore is first-party source in this repository containing app-specific models and calculations.

9. The app was conceived, developed, branded, and submitted by Olanrewaju Bankole for this account. No client, partner, template vendor, or content provider supplied its concept, branding, or content. Source/history: https://github.com/lanray07/SubSense-AI

We respectfully ask App Review to reconsider the submission under Guidelines 4.3(a), 4.3(b), and 4.2.6. We can provide more evidence if helpful.

Kind regards,

Olanrewaju Bankole

## Evidence checked

- App Store Connect currently shows no TestFlight tester group and invites the developer to create one.
- The Xcode project has no remote Swift package dependency. Its only package product, `SubSenseCore`, is the first-party local package declared in the repository root.
- The account contains other apps, but SubSense is not presented or implemented as one member of a shared suite.
- `docs/ARCHITECTURE.md` documents the subscription-specific model and integration boundaries.
- `docs/VALIDATION.md` records the executed device, UI, and StoreKit validation matrix.
- `docs/APP_REVIEW_4_3_RESPONSE.md` records the earlier clarification response and source-overlap audit.
