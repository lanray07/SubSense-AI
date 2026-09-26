# Xcode distribution through GitHub

Verified again on 26 September 2026: [run 36244614984](https://github.com/lanray07/SubSense-AI/actions/runs/36244614984) passed all 20 core tests and archived, cloud-signed, and uploaded version 1.0 (5.1) using Xcode 26.3. Xcode reported `Upload succeeded` and `EXPORT SUCCEEDED`; App Store Connect processed build 5.1 as Ready to Submit.

The original four-item submission was rejected under Guideline 4.3(a), followed by a clarification response on 19 September. Apple then requested under Guideline 2.1(b) that both subscription products be submitted with a new binary. Build 4.1 was replaced by build 5.1, and the app version, SubSense Pro group, SubSense Pro Monthly, and SubSense Pro Annual were resubmitted together on **26 September 2026 at 14:34 BST**. All four items now show **Waiting for Review** in [submission e2f534c9-77c8-413e-ad6a-6970f05ab4fa](https://appstoreconnect.apple.com/apps/6810100372/distribution/reviewsubmissions/details/e2f534c9-77c8-413e-ad6a-6970f05ab4fa).

Run **Archive and upload to App Store Connect** from GitHub Actions on `main`. It uses the newest stable Xcode installed on the macOS runner, runs the portable core tests, archives the Release app for iOS devices, and asks Xcode to sign and upload it using the existing App Store Connect API credentials.

Required repository secrets:

- `APPLE_TEAM_ID`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY` (PEM, escaped-newline PEM, or base64 PEM)

The app bundle ID is `com.subsenseai.app`, matching the existing App Store Connect app. The marketing version is 1.0; build numbers use the workflow run number and attempt. API key material is written only into the temporary runner directory with restricted permissions, removed even on failure, and excluded from artifacts.

Distribution requires the API key to have sufficient Apple permissions for provisioning, cloud signing, and uploading. Having secret names configured alone does not prove those permissions. The workflow logs and App Store Connect processing result determine success.

The workflow uploads a build; the final review submission was completed separately through App Store Connect. Simulator UI checks run in **Release validation**, covering iPhone and iPad with iOS 18.2 and 26. See `docs/VALIDATION.md` for executed acceptance results and the unresolved iOS 18.5 simulator limitation, and `assets/app-store/CAPTURE_NOTES.md` for the resolved calendar crash. A successful archive or upload alone is not a release certification.
