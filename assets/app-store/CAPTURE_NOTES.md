# Capture and release notes

The iPad demo banner originally overlapped iPadOS 18's top tab navigation. Commit e517de0 places the banner above the TabView. Native screenshots verify that the navigation is fully visible after this change.

## Calendar crash resolved

The earlier calendar crash came from a UIKit recursive self-sizing layout loop: the calendar's lazy grid was inside a SwiftUI List. Commit 93ad910 moves the calendar into a scroll view with explicit cards. Calendar navigation, month changes and timeline/upcoming modes pass on iPhone and iPad with both iOS 18 and 26 in [run 34373542156](https://github.com/lanray07/SubSense-AI/actions/runs/34373542156). That run identified separate acceptance-test failures, so it is not the final release gate.

All eight screenshots per device were recaptured successfully in [run 34375255138](https://github.com/lanray07/SubSense-AI/actions/runs/34375255138). The iPhone collection shows the repaired calendar; iPad retains its complementary detail, settings, goals and reminders collection. Capture tests do not certify the full app for release; see docs/VALIDATION.md for acceptance results.
