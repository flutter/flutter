# Release Commands (Windows PowerShell)

Use these commands from the project root.

## 1) Set location

Set-Location C:\Users\steme\Documents\AP\flutter\examples\personal_training_app

## 2) Clean and fetch deps

flutter clean
flutter pub get

## 3) Staging builds

### Staging Web (App Check key required for web tests)
flutter build web --release --dart-define=APP_ENV=staging --dart-define=RECAPTCHA_SITE_KEY=YOUR_STAGING_RECAPTCHA_KEY

### Staging Android AAB
flutter build appbundle --release --dart-define=APP_ENV=staging

### Staging Android APK
flutter build apk --release --dart-define=APP_ENV=staging

## 4) Production builds

### Production Web (required)
flutter build web --release --dart-define=APP_ENV=production --dart-define=RECAPTCHA_SITE_KEY=YOUR_PRODUCTION_RECAPTCHA_KEY

### Production Android AAB (Play Store)
flutter build appbundle --release --dart-define=APP_ENV=production

### Production Android APK (direct install/testing)
flutter build apk --release --dart-define=APP_ENV=production

### Production iOS IPA (App Store Connect)
Requires macOS with Xcode and an Apple Developer account.

1. Open a macOS terminal and run from project root:

flutter clean
flutter pub get
flutter build ipa --release --dart-define=APP_ENV=production --export-options-plist=ios/ExportOptions-AppStore.plist

2. Upload the generated IPA to App Store Connect:

xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey YOUR_API_KEY_ID --apiIssuer YOUR_ISSUER_ID

Alternative: open `ios/Runner.xcworkspace` in Xcode and use Product > Archive, then Distribute App.

3. In App Store Connect, create/select the new version and attach the uploaded build.

### iOS CI build from Windows (GitHub Actions)
Use this when developing on Windows but needing a macOS iOS build.

1. Push your branch to GitHub.
2. In GitHub, go to Actions > iOS Build.
3. Click Run workflow and choose `production` or `staging`.
4. Download artifact `ios-runner-app-<env>` from the workflow run.

Note: this workflow builds `Runner.app` without code signing. For App Store upload, you still need signing + IPA export on macOS/CI signing setup.

## 5) Firebase rules publish workflow

1. Copy FIREBASE_SECURITY_RULES_STAGING.json into Firebase Realtime Database Rules for staging project and publish.
2. Copy FIREBASE_SECURITY_RULES_PRODUCTION.json into Firebase Realtime Database Rules for production project and publish.

## 6) Recommended verification

1. Run the app in release mode and verify client login.
2. Verify instructor login and dashboard load.
3. Verify workout fetch/sync and rest day reads.
4. Verify no permission-denied errors in critical flows.

## 7) Common issues

- If web build fails with App Check error, RECAPTCHA_SITE_KEY is missing or invalid.
- If Android signing fails, check android/key.properties and local keystore path.
- If login fails after rules publish, verify the correct rules file was applied to the correct Firebase project.
- iOS builds cannot be created on Windows; use a macOS machine or CI mac runner.
- If iOS signing fails, set a real bundle ID (not `com.example...`) and configure Team/Signing in Xcode.
