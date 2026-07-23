# Play Store Setup Guide

## Configuration Completed ✅

The app has been configured with the following Play Store-ready settings:

### 1. App Identity
- **App Name**: SIM Training Partner
- **Package Name**: com.simtraining.personaltrainingapp
- **Version**: 1.0.0 (Build 1)

### 2. Build Configuration
- Minimum SDK: 21 (Android 5.0+)
- Target SDK: Latest
- App signing configured for release builds

### 3. Permissions
- INTERNET permission added (if needed for future features)

---

## Required Steps to Complete

### Step 1: Create App Signing Key

Run this command in PowerShell to generate your keystore:

```powershell
keytool -genkey -v -keystore c:\Users\steme\Documents\AP\flutter\examples\personal_training_app\android\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

When prompted:
1. Enter a secure password (remember this!)
2. Re-enter the password
3. Fill in your information (name, organization, etc.)
4. Confirm with 'yes'

### Step 2: Update key.properties

After creating the keystore, edit `android/key.properties` and replace the placeholder passwords:

```
storePassword=YOUR_ACTUAL_PASSWORD
keyPassword=YOUR_ACTUAL_PASSWORD
keyAlias=upload
storeFile=app/upload-keystore.jks
```

**IMPORTANT**: Never commit key.properties to version control! It's already in .gitignore.

### Step 3: Build Release APK/AAB

To build an APK for testing:
```bash
flutter build apk --release
```

To build an App Bundle for Play Store (recommended):
```bash
flutter build appbundle --release
```

The output will be in:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### Step 4: Test the Release Build

Install and test the release APK:
```bash
flutter install --release
```

Or manually install:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Step 5: Prepare Play Store Listing

Create the following assets for your Play Store listing:

#### Required Graphics:
1. **App Icon** (512x512 PNG) - High-res version of your launcher icon
2. **Feature Graphic** (1024x500 PNG) - Banner for store listing
3. **Screenshots** - At least 2 screenshots:
   - Phone: 16:9 or 9:16 ratio
   - Minimum 320px on shorter side
   - Maximum 3840px on longer side

#### Store Listing Details:
- **Short Description** (80 chars): "Track workouts, build routines, and achieve your fitness goals"
- **Full Description** (4000 chars): Include app features, benefits, and usage
- **Category**: Health & Fitness
- **Content Rating**: Complete the questionnaire
- **Privacy Policy**: Required if collecting user data

### Step 6: Create Play Console Account

1. Go to https://play.google.com/console
2. Pay the one-time $25 registration fee
3. Complete account setup

### Step 7: Upload to Play Console

1. Create a new app in Play Console
2. Complete all required sections:
   - App content (Privacy policy, ads, etc.)
   - Content rating
   - Target audience
   - Store listing
3. Upload your AAB file in the "Release" section
4. Choose release type (Internal, Closed, Open, or Production)
5. Submit for review

---

## Build Configuration Details

### Signing Configuration (build.gradle.kts)
The app is configured to:
- Use release signing when key.properties exists
- Fall back to debug signing if keystore is not configured
- This allows testing with `flutter run --release` before creating the keystore

### Security Best Practices
- Keep your keystore file secure and backed up
- Never share your keystore passwords
- The upload-keystore.jks should NOT be committed to git
- Consider using Play App Signing for additional security

---

## Troubleshooting

### Build Fails with Signing Error
- Ensure key.properties exists and has correct values
- Verify keystore file path is correct
- Check that passwords match what you set during keystore creation

### Package Name Already Exists
- If testing: You can change the package name in build.gradle.kts
- For production: Ensure the package name is unique

### Version Conflicts
- Each upload to Play Store requires a higher versionCode
- Update in pubspec.yaml: `version: 1.0.0+2` (increment the number after +)

---

## Next Release Checklist

When preparing future updates:

1. ✅ Update version in pubspec.yaml (e.g., 1.0.1+2)
2. ✅ Test thoroughly on physical devices
3. ✅ Update release notes
4. ✅ Build release AAB: `flutter build appbundle --release`
5. ✅ Upload to Play Console
6. ✅ Submit for review

---

## Additional Resources

- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/android)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
