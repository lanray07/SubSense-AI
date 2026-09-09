# Xcode distribution through GitHub

Verified on 9 September 2026: [run 34378446730](https://github.com/lanray07/SubSense-AI/actions/runs/34378446730), source commit `48e53c5`, passed all 20 core tests and archived, cloud-signed, and uploaded version 1.0 (4.1) using Xcode 26.3. Xcode reported `Upload succeeded` and `EXPORT SUCCEEDED` at 16:52 UTC.

**Submitted at 18:36 BST on 9 September 2026.** App Store Connect confirmed **4 Items Submitted**. Version 1.0 (4.1), the SubSense Pro group, SubSense Pro Monthly and SubSense Pro Annual each show **Waiting for Review** in [submission e2f534c9-77c8-413e-ad6a-6970f05ab4fa](https://appstoreconnect.apple.com/apps/6810100372/distribution/reviewsubmissions/details/e2f534c9-77c8-413e-ad6a-6970f05ab4fa). Automatic release after approval remains selected. Submission is not approval.

Run **Archive and upload to App Store Connect** from GitHub Actions on `main`. It uses the newest stable Xcode installed on the macOS runner, runs the portable core tests, archives the Release app for iOS devices, and asks Xcode to sign and upload it using the existing App Store Connect API credentials.

Required repository secrets:

- `APPLE_TEAM_ID`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY` (PEM, escaped-newline PEM, or base64 PEM)

The app bundle ID is `com.subsenseai.app`, matching the existing App Store Connect app. The marketing version is 1.0; build numbers use the workflow run number and attempt. API key material is written only into the temporary runner directory with restricted permissions, removed even on failure, and excluded from artifacts.

Distribution requires the API key to have sufficient Apple permissions for provisioning, cloud signing, and uploading. Having secret names configured alone does not prove those permissions. The workflow logs and App Store Connect processing result determine success.

The workflow uploads a build; the final review submission was completed separately through App Store Connect. Simulator UI checks run in **Release validation**, covering iPhone and iPad with iOS 18.2 and 26. See `docs/VALIDATION.md` for executed acceptance results and the unresolved iOS 18.5 simulator limitation, and `assets/app-store/CAPTURE_NOTES.md` for the resolved calendar crash. A successful archive or upload alone is not a release certification.
