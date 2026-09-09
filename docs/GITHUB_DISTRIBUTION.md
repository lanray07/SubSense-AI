# Xcode distribution through GitHub

Verified on 9 September 2026: [run 34340054417](https://github.com/lanray07/SubSense-AI/actions/runs/34340054417), source commit `fad6fca`, passed core tests and archived, cloud-signed, and uploaded version 1.0 (2.1) using Xcode 26.3. Xcode reported `Upload succeeded` and `EXPORT SUCCEEDED`.

Run **Archive and upload to App Store Connect** from GitHub Actions on `main`. It uses the newest stable Xcode installed on the macOS runner, runs the portable core tests, archives the Release app for iOS devices, and asks Xcode to sign and upload it using the existing App Store Connect API credentials.

Required repository secrets:

- `APPLE_TEAM_ID`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY` (PEM, escaped-newline PEM, or base64 PEM)

The app bundle ID is `com.subsenseai.app`, matching the existing App Store Connect app. The marketing version is 1.0; build numbers use the workflow run number and attempt. API key material is written only into the temporary runner directory with restricted permissions, removed even on failure, and excluded from artifacts.

Distribution requires the API key to have sufficient Apple permissions for provisioning, cloud signing, and uploading. Having secret names configured alone does not prove those permissions. The workflow logs and App Store Connect processing result determine success.

The workflow uploads a build but does not submit an App Store review or release the app. Simulator UI checks run separately in **Apple build and tests**. Known UI failures, including the calendar termination described in `assets/app-store/CAPTURE_NOTES.md`, must be resolved before release; a successful archive or upload does not resolve them.
