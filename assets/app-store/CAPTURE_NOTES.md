# Capture and release notes

The iPad demo banner originally overlapped iPadOS 18's top tab navigation. Commit e517de0 places the banner above the TabView. Native screenshots verify that the navigation is fully visible after this change.

## Unresolved iPad calendar crash

Opening Upcoming charges from Home in the iPad Pro 13-inch (M4), iOS 18.5 simulator unexpectedly terminates the app. This reproduced in screenshot workflow runs 34336535773 and 34337656777. The test log reports inability to monitor the event loop, then checks for crash reports for com.subsense.app. The recording returns to the iPad Home screen. The underlying cause has not yet been identified.

This is a release blocker for the calendar on iPad, separate from delivery of App Store image assets. The iPad store collection uses actual working pages rather than showing an invented calendar screen. Capture tests do not certify the full app for release.
