# App Store submission assets

## Subscription product images

- `subscriptions/pro-monthly-1024.png` — monthly product's optional Image field.
- `subscriptions/pro-annual-1024.png` — annual product's optional Image field.

Both are 1024 × 1024 opaque RGB PNGs, rendered from editable SVG sources. They extend the existing circular renewal-arrow and sparkle identity. They contain no price, discount or trial claim. Regenerate with `node scripts/create_store_artwork.cjs` (requires sharp).

## Actual screenshot capture

The `App Store screenshot capture` GitHub workflow runs the native app in an iPhone 14 Plus simulator and exports XCTest screenshot attachments. Source captures retain the app's demo banner and illustrative records. No generated screen or invented UI is used.

The source PNGs are in `raw/`. `scripts/compose_store_screenshots.cjs` creates 1284 × 2778 marketing layouts in `iphone-6.5/`, preserving each full screenshot without retouching app content. Open `index.html` for the visual gallery.

The four public screenshots were captured from commit `f166497` by successful [workflow run 34333360269](https://github.com/lanray07/SubSense-AI/actions/runs/34333360269). They were uploaded to the English (U.S.) iPhone 6.5-inch screenshot set on 9 September 2026, ordered dashboard, subscriptions, insights, Copilot. Both 1024-square subscription artworks were also uploaded to their respective product Image fields.

Subscription Review Information → Screenshot uses the raw Pro paywall capture, not the square promotional artwork. App previews are videos and are separate from screenshot images.
