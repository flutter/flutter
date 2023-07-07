[![pub package](https://img.shields.io/pub/v/google_sign_in.svg)](https://pub.dev/packages/google_sign_in)

A Flutter plugin for [Google Sign In](https://developers.google.com/identity/).

|             | Android | iOS     | Web |
|-------------|---------|---------|-----|
| **Support** | SDK 16+ | iOS 11+ | Any |

## Platform integration

### Android integration

To access Google Sign-In, you'll need to make sure to
[register your application](https://firebase.google.com/docs/android/setup).

You don't need to include the google-services.json file in your app unless you
are using Google services that require it. You do need to enable the OAuth APIs
that you want, using the
[Google Cloud Platform API manager](https://console.developers.google.com/). For
example, if you want to mimic the behavior of the Google Sign-In sample app,
you'll need to enable the
[Google People API](https://developers.google.com/people/).

Make sure you've filled out all required fields in the console for
[OAuth consent screen](https://console.developers.google.com/apis/credentials/consent).
Otherwise, you may encounter `APIException` errors.

### iOS integration

1. [First register your application](https://firebase.google.com/docs/ios/setup).
2. Make sure the file you download in step 1 is named
   `GoogleService-Info.plist`.
3. Move or copy `GoogleService-Info.plist` into the `[my_project]/ios/Runner`
   directory.
4. Open Xcode, then right-click on `Runner` directory and select
   `Add Files to "Runner"`.
5. Select `GoogleService-Info.plist` from the file manager.
6. A dialog will show up and ask you to select the targets, select the `Runner`
   target.
7. If you need to authenticate to a backend server you can add a
   `SERVER_CLIENT_ID` key value pair in your `GoogleService-Info.plist`.
   ```xml
   <key>SERVER_CLIENT_ID</key>
   <string>[YOUR SERVER CLIENT ID]</string>
   ```
8. Then add the `CFBundleURLTypes` attributes below into the
   `[my_project]/ios/Runner/Info.plist` file.

```xml
<!-- Put me in the [my_project]/ios/Runner/Info.plist file -->
<!-- Google Sign-in Section -->
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<!-- TODO Replace this value: -->
			<!-- Copied from GoogleService-Info.plist key REVERSED_CLIENT_ID -->
			<string>com.googleusercontent.apps.861823949799-vc35cprkp249096uujjn0vvnmcvjppkn</string>
		</array>
	</dict>
</array>
<!-- End of the Google Sign-in Section -->
```

As an alternative to adding `GoogleService-Info.plist` to your Xcode project,
you can instead configure your app in Dart code. In this case, skip steps 3 to 7
 and pass `clientId` and `serverClientId` to the `GoogleSignIn` constructor:

```dart
GoogleSignIn _googleSignIn = GoogleSignIn(
  ...
  // The OAuth client id of your app. This is required.
  clientId: ...,
  // If you need to authenticate to a backend server, specify its OAuth client. This is optional.
  serverClientId: ...,
);
```

Note that step 8 is still required.

#### iOS additional requirement

Note that according to
https://developer.apple.com/sign-in-with-apple/get-started, starting June 30,
2020, apps that use login services must also offer a "Sign in with Apple" option
when submitting to the Apple App Store.

Consider also using an Apple sign in plugin from pub.dev.

The Flutter Favorite
[sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple) plugin could
be an option.

### Web integration

The new SDK used by the web has fully separated Authentication from Authorization,
so `signIn` and `signInSilently` no longer authorize OAuth `scopes`.

Flutter apps must be able to detect what scopes have been granted by their users,
and if the grants are still valid.

Read below about **Working with scopes, and incremental authorization** for
general information about changes that may be needed on an app, and for more
specific web integration details, see the
[`google_sign_in_web` package](https://pub.dev/packages/google_sign_in_web).

## Usage

### Import the package

To use this plugin, follow the
[plugin installation instructions](https://pub.dev/packages/google_sign_in/install).

### Use the plugin

Add the following import to your Dart code:

```dart
import 'package:google_sign_in/google_sign_in.dart';
```

Initialize `GoogleSignIn` with the scopes you want:

```dart
GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);
```

[Full list of available scopes](https://developers.google.com/identity/protocols/googlescopes).

You can now use the `GoogleSignIn` class to authenticate in your Dart code, e.g.

```dart
Future<void> _handleSignIn() async {
  try {
    await _googleSignIn.signIn();
  } catch (error) {
    print(error);
  }
}
```

In the web, you should use the **Google Sign In button** (and not the `signIn` method)
to guarantee that your user authentication contains a valid `idToken`.

For more details, take a look at the
[`google_sign_in_web` package](https://pub.dev/packages/google_sign_in_web).

## Working with scopes, and incremental authorization.

If your app supports both mobile and web, read this section!

### Checking if scopes have been granted

Users may (or may *not*) grant all the scopes that an application requests at
Sign In. In fact, in the web, no scopes are granted by `signIn`, `silentSignIn`
or the `renderButton` widget anymore.

Applications must be able to:

* Detect if the authenticated user has authorized the scopes they need.
* Determine if the scopes that were granted a few minutes ago are still valid.

There's a new method that enables the checks above, `canAccessScopes`:

```dart
final bool isAuthorized = await _googleSignIn.canAccessScopes(scopes);
```

_(Only implemented in the web platform, from version 6.1.0 of this package)_

### Requesting more scopes when needed

If an app determines that the user hasn't granted the scopes it requires, it
should initiate an Authorization request. (Remember that in the web platform,
this request **must be initiated from an user interaction**, like a button press).

```dart
Future<void> _handleAuthorizeScopes() async {
  final bool isAuthorized = await _googleSignIn.requestScopes(scopes);
  if (isAuthorized) {
    // Do things that only authorized users can do!
    _handleGetContact(_currentUser!);
  }
}
```

The `requestScopes` returns a `boolean` value that is `true` if the user has
granted all the requested scopes or `false` otherwise.

Once your app determines that the current user `isAuthorized` to access the
services for which you need `scopes`, it can proceed normally.

### Authorization expiration

In the web, **the `accessToken` is no longer refreshed**. It expires after 3600
seconds (one hour), so your app needs to be able to handle failed REST requests,
and update its UI to prompt the user for a new Authorization round.

This can be done by combining the error responses from your REST requests with
the `canAccessScopes` and `requestScopes` methods described above.

For more details, take a look at the
[`google_sign_in_web` package](https://pub.dev/packages/google_sign_in_web).

### Does an app always need to check `canAccessScopes`?

The new web SDK implicitly grant access to the `email`, `profile` and `openid` 
scopes when users complete the sign-in process (either via the One Tap UX or the
Google Sign In button).

If an app only needs an `idToken`, or only requests permissions to any/all of
the three scopes mentioned above 
([OpenID Connect scopes](https://developers.google.com/identity/protocols/oauth2/scopes#openid-connect)),
it won't need to implement any additional scope handling.

If an app needs any scope other than `email`, `profile` and `openid`, it **must**
implement a more complete scope handling, as described above.

## Example

Find the example wiring in the
[Google sign-in example application](https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in/example/lib/main.dart).
