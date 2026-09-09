# App Store submission assets

## Expanded iPhone and iPad collection

The collection contains eight screens per device. Both show dashboard, subscriptions, insights, and Copilot. iPhone adds renewal calendar, savings simulator, subscription health, and privacy. iPad adds subscription details, settings, goals, and reminder preferences. iPhone layouts are 1284 × 2778. Native iPad Pro 13-inch (M4) captures and layouts are 2064 × 2752, matching the 13-inch App Store Connect slot.

Generate iPhone layouts with `node scripts/compose_store_screenshots.cjs`, iPad layouts with `node scripts/compose_store_screenshots.cjs --ipad`, then regenerate the gallery with `node scripts/create_store_gallery.cjs`. Layout generation requires sharp. Set `CODEX_NODE_MODULES` when sharp is in a shared runtime instead of the local node_modules directory.

## Subscription product images

- `subscriptions/pro-monthly-1024.png` — monthly product's optional Image field.
- `subscriptions/pro-annual-1024.png` — annual product's optional Image field.

Both are 1024 × 1024 opaque RGB PNGs, rendered from editable SVG sources. They extend the existing circular renewal-arrow and sparkle identity. They contain no price, discount or trial claim. Regenerate with `node scripts/create_store_artwork.cjs` (requires sharp).

## Actual screenshot capture

The `App Store screenshot capture` GitHub workflow runs the native app in iPhone 14 Plus and iPad Pro 13-inch simulators and exports XCTest screenshot attachments. Source captures retain the app's demo banner and illustrative records. No generated screen or invented UI is used.

The source PNGs are in `raw/` and `raw-ipad/`. The compositor preserves each full screenshot without retouching app content. Open `index.html` for the visual gallery.

All eight screenshots per device were recaptured from commit `1d4631c` in successful [run 34375255138](https://github.com/lanray07/SubSense-AI/actions/runs/34375255138), after the calendar layout and profile-label fixes.

Later app changes improve StoreKit startup, accessibility-sized demo status and receipt keyboard dismissal; they do not change these default-size store panels.

All eight images per device are supplied for the English (U.S.) iPhone 6.5-inch and iPad 13-inch screenshot sets. Both 1024-square subscription artworks are uploaded to their respective product Image fields. See [capture notes](CAPTURE_NOTES.md) for the resolved calendar crash. Screenshot capture checks do not certify the full app for release.

Subscription Review Information → Screenshot uses the raw Pro paywall capture, not the square promotional artwork. App previews are videos and are separate from screenshot images.

`raw/review-pro-features.png` and `raw/review-pro-purchase.png` were refreshed from the passing screenshot test on iPhone 16 Pro, iOS 18, in [run 34373542156](https://github.com/lanray07/SubSense-AI/actions/runs/34373542156). They are 1206 × 2622 native captures. The local StoreKit products match the configured UK monthly (£1.49) and annual (£9.99) prices. This verifies screenshot contents, not live App Store billing. The purchase capture shows both plans and renewal terms and is uploaded to both products' review screenshot fields.
