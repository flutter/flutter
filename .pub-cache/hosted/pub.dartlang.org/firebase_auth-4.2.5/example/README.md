# Firebase Auth Example

[![pub package](https://img.shields.io/pub/v/firebase_auth.svg)](https://pub.dev/packages/firebase_auth)

Demonstrates how to use the `firebase_auth` plugin and enable multiple auth providers.

## Phone Auth

1. Enable phone authentication in the [Firebase console]((https://console.firebase.google.com/u/0/project/_/authentication/providers)).
2. Ensure your [SHA-1 key](https://firebase.flutter.dev/docs/installation/android#generating-android-credentials) is added to the Firebase Console
3. Add test phone number and verification code to the Firebase console.
  - For this sample the number `+1 408-555-6969` and verification code `888888` are used.
4. For iOS set the `URL Schemes` to the `REVERSE_CLIENT_ID` from the `GoogleServices-Info.plist` file.
5. Enter the phone number `+1 408-555-6969` and press the `Verify phone number` button.
6. Once the phone number is verified the app displays the test
   verification code.
7. Enter the verficication code `888888` and press "Sign in with phone number"
8. Signed in user ID is now displayed in the UI.

## Google Sign-In

1. Enable Google authentication in the [Firebase console](https://console.firebase.google.com/u/0/project/_/authentication/providers).
2. For Android, add your app's package name and SHA-1 fingerprint to the [Settings page](https://console.firebase.google.com/project/_/settings/general) of the Firebase console. Refer to [Authenticating Your Client]('https://developers.google.com/android/guides/client-auth') for details on how to get your app's SHA-1 fingerprint.
3. For iOS set the `URL Schemes` to the `REVERSE_CLIENT_ID` from the `GoogleServices-Info.plist` file (same step for `Phone Auth` above).
4. Select `Google` under `Social Authentication` and click the `Sign In With Google` button.
5. Signed in user's details are displayed in the UI.

### Running on Web

Make sure you run the example app on port 5000, since `localhost:5000` is
whitelisted for Google authentication. To do so, run:

```
flutter run -d web-server --web-port 5000
```

## GitHub Sign-In
To get your `clientId` and `clientSecret`: 
1. Visit https://github.com/settings/developers.
2. Create a new OAuth application.
3. Set **Home Page URL** to `https://react-native-firebase-testing.firebaseapp.com`.
4. Set **Authorization callback URL** to `https://react-native-firebase-testing.firebaseapp.com/__/auth/handler`.
5. After you register your app, add the `clientId` and `clientSecret` to the example app config in [`lib/config.dart`](./lib/config.dart).

## Twitter Sign-In
Twitter sign in requires you to add keys from Twitter Developer API to Firebase Console, which means you cannot use the provided configurations with the example app, instead, **please create a new Firebase project**, then enable Twitter as an Auth provider (*optionally you can enable the rest of providers supported in this example*).

To get your `apiKey` and `apiSecretKey` for Twitter:
1. Sign up for a developer account on [Twitter Developer](https://developer.twitter.com).
2. Create a new app and copy your keys.
3. From the dashboard, go to your app settings, then go to OAuth settings and turn on OAuth 1.0a, then add 2 callback URLs:
   1. `flutterfireauth://`
   2. `https://react-native-firebase-testing.firebaseapp.com/__/auth/handler`
4. Add your keys to the example app config in [`lib/config.dart`](./lib/config.dart).

## Getting Started

For help getting started with Flutter, view the online
[documentation](http://flutter.io/).
