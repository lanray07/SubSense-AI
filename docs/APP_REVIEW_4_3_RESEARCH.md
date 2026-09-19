# App Review Guideline 4.3(a) Research

Researched 19 September 2026 from Apple primary sources only.

## What Apple's published rules say

- [Guideline 4.3(a)](https://developer.apple.com/app-store/review/guidelines/#spam) prohibits creating multiple Bundle IDs for the same app. Apple's example is publishing a separate map app for each city instead of one app containing all cities. Apple recommends one app with variations delivered through in-app purchase.
- [Guideline 4.3(b)](https://developer.apple.com/app-store/review/guidelines/#spam) separately prohibits apps that are indistinguishable from apps already widely available unless they provide a meaningfully different or improved experience.
- Nearby rules address related concerns: [4.1(a)](https://developer.apple.com/app-store/review/guidelines/#copycats) prohibits minor changes to another app's name or UI; [4.2](https://developer.apple.com/app-store/review/guidelines/#minimum-functionality) requires useful, unique, app-like functionality; and 4.2.6 rejects apps produced from commercialised templates unless submitted directly by the content provider.

The rejection's wording about a similar "binary, metadata, and/or concept" is broader than the literal public text of 4.3(a). The notice does not establish whether Apple detected another Bundle ID, shared source or assets, a template, or merely a similar concept. We should not guess which comparison Apple made.

## Official resolution paths

Apple says a rejected developer can [reply to App Review in App Store Connect](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/reply-to-app-review-messages), correspond with the reviewer, and attach screenshots or supporting documents before resubmission. Apple also says developers can use App Store Connect to ask questions and provide additional information about a rejection ([App Review Guidelines, "After You Submit"](https://developer.apple.com/app-store/review/guidelines/#after-you-submit)).

In [Tips from App Review](https://developer.apple.com/forums/thread/810791), Apple's App Review team says the reply is handled by a specialist familiar with the app. The same reply can request a call with an Apple representative and specify a preferred time and language. This supports seeking precise clarification before spending effort on a speculative redesign.

For an unresolved submission, Apple permits the rejected item to be edited, added for review, and then resubmitted. An item removed from that submission cannot be added back to the same submission. Apple only expressly says the same build can be resubmitted after a **metadata** issue is fixed; this 4.3 rejection should not be assumed to be metadata-only unless App Review confirms that. See [Manage a submission with unresolved issues](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/manage-a-submission-with-unresolved-issues).

If Apple misunderstood the app's concept or functionality, or the developer believes the review was unfair, Apple provides an [App Review Board appeal](https://developer.apple.com/app-store/review/#appeals). Apple instructs developers to give specific compliance reasons, file only one appeal for each failed submission, and respond to requests for more information before appealing. The authenticated appeal form is at [Submit an appeal](https://developer.apple.com/contact/app-store/?topic=appeal).

## Recommended response order

1. Reply in App Store Connect before resubmitting. State only facts that can be substantiated: who designed and developed the app, whether this account has submitted any other app using the same source/assets, and whether the source came from a commercial template or third party.
2. Ask App Review to clarify whether the concern is another Bundle ID, shared source/assets, metadata, or the concept, and—if possible—to identify the specific element requiring remediation.
3. Explain the app's distinctive functionality through concrete user workflows, not adjectives. Attach a short feature walkthrough, screenshots, or a development-history summary if they substantiate independent development. Apple's [submission guidance](https://developer.apple.com/app-store/review/guidelines/#before-you-submit) specifically asks for detailed explanations of non-obvious features and in-app purchases, with supporting documentation where appropriate.
4. If Apple identifies genuine duplicated/template material, make material changes to the binary, content, and functionality before resubmitting. Renaming metadata or changing visual polish alone does not answer a source-code or concept concern.
5. If Apple maintains the rejection despite evidence that 4.3(a) does not apply, submit the single permitted appeal. Map each factual point directly to 4.3(a), include evidence, and explain why this is one independently developed app rather than multiple Bundle IDs of the same app.

Apple publishes no guaranteed 4.3 remediation checklist and does not promise that cosmetic or metadata changes will resolve a binary/concept rejection. Repeatedly resubmitting unchanged without clarifying the trigger is therefore a poor fit for Apple's published process and the extended-review warning in the rejection.
