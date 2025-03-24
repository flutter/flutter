# a11y_assessments

This app is used for internal testing.

## Release a new version for Android

pre-requisite: This can and should only be done by a googler and you must also
be in the flutter.dev play console account.

1. Follow https://docs.flutter.dev/deployment/android to create a keystore file if you don't already
have one.

2. Bump the pubspec.yaml version

3. Create a key.properties file in `android/` directory following this format.
```
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<keystore path>
```

4. Run `flutter build appbundle` and upload the artifact to play console

## Release a new version for iOS

pre-requisite: This can and should only be done by a googler and you must also
be in the FLUTTER.IO LLC developer account with iOS distribution permission.

1. Bump the pubspec.yaml version
2. Run `flutter build ipa` and upload the artifact to app store using transporter or other tools.
For more information, see https://docs.flutter.dev/deployment/ios.
3. Once the app is in TestFlight, add appropriate testers to the app so they can start testing.