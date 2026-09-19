# App Review 4.3(a) response

Prepared 19 September 2026 for submission `e2f534c9-77c8-413e-ad6a-6970f05ab4fa`. This is a draft for the App Store Connect Resolution Center. Do not resubmit build 4.1 until App Review answers the clarification request or the app receives material changes that address the identified match.

## Draft reply

Hello App Review,

Thank you for the review. We want to resolve the Guideline 4.3(a) concern correctly and avoid resubmitting the unchanged app without understanding the specific match.

Could you please clarify whether the concern is based on:

1. binary or source-code similarity,
2. shared visual assets or metadata,
3. the subscription-management concept, or
4. another app or Bundle ID submitted by this developer account?

If possible, please identify the app, Bundle ID, or specific elements that App Review considers similar. That will let us make a material and targeted correction rather than a cosmetic change.

SubSense AI is a single iPhone and iPad subscription portfolio app with Bundle ID `com.subsenseai.app`. It was developed as a separate project and was not purchased from a third-party app template. Its public source and development history are available at:

https://github.com/lanray07/SubSense-AI

The shipping app has subscription-specific data and workflows, including:

- renewal calculations for weekly, monthly, quarterly, yearly, custom-day, trial, lifetime, paused, and cancelled records;
- currency-separated totals, upcoming-renewal forecasts, a calendar, and local reminders;
- explainable Value, Cancel, and Health Scores based on the user's entered costs, usage, price history, and category overlaps;
- a savings simulator, cancellation checklist, cancellation reminders, and recorded cancellation or downgrade outcomes;
- on-device receipt text recognition with user review before saving;
- a local rules-based subscription Copilot, with no remote generative-AI service; and
- local persistence, device lock, private notifications, and CSV, PDF, and JSON export.

Some standard platform implementation patterns, such as StoreKit purchase and restore handling, settings, navigation, and reusable SwiftUI components, are developer-owned conventions used across our projects. SubSense AI's domain model, calculations, content, workflows, application assets, and Bundle ID are specific to this app.

Please let us know which binary, metadata, asset, or concept triggered the 4.3(a) finding and what type of material change App Review expects. We are happy to provide a feature walkthrough or arrange a call if that would help.

Kind regards,

Olanrewaju Bankole

## Evidence retained in the repository

- `README.md` documents the implemented feature set and the app's limitations.
- `docs/ARCHITECTURE.md` describes the separate subscription-domain architecture.
- `docs/VALIDATION.md` links the iPhone, iPad, StoreKit, and release validation runs.
- `docs/GITHUB_DISTRIBUTION.md` links the signed build and identifies the submitted Bundle ID.
- `docs/APP_REVIEW_4_3_RESEARCH.md` records Apple's published rule and official resolution paths.

## Audit notes

The account has several SwiftUI apps with related developer conventions and clustered submission dates. MoneyPlain AI received the same 4.3(a) wording at the same review timestamp. A normalized line comparison found that 5.5% of SubSense's distinct substantive Swift lines also occur in MoneyPlain; most matches are common SwiftUI, StoreKit, Vision, notification, and test patterns. Comparisons with MindHarbor AI, CivicRule AI, and PlanBridge AI produced 1.8%, 2.4%, and 2.8% overlap respectively. These figures support separate domain implementations, while the repeated product naming, visual system, paywall structure, and feature labels can still create a template-like account-level impression.

The next safe action is to request clarification. Repeatedly resubmitting build 4.1 without knowing whether Apple matched the binary, assets, metadata, or concept is not recommended.
