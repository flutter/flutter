## 6.1.4

* Adds compatibility with `http` 1.0.

## 6.1.3

* Clarifies `canAccessScopes` method documentation.

## 6.1.2

* Fixes unawaited_futures violations.

## 6.1.1

* Removes obsolete null checks on non-nullable values.

## 6.1.0

* Exposes the new method `canAccessScopes`.
  * This method is only needed, and implemented, on the web platform.
    * Other platforms will throw an `UnimplementedError`.
* Updates example app to separate Authentication from Authorization for those
  platforms where scopes are not automatically granted upon `signIn` (like the web).
  * When `signInSilently` is successful, it returns a User object again on the web.
  * Updates README with information about these changes.
* Updates minimum Flutter version to 3.3.
* Aligns Dart and Flutter SDK constraints.

## 6.0.2

* Updates iOS minimum version in README.

## 6.0.1

* Updates links for the merge of flutter/plugins into flutter/packages.

## 6.0.0

* **Breaking change** for platform `web`:
  * Endorses `google_sign_in_web: ^0.11.0` as the web implementation of the plugin.
    * The web package is now backed by the **Google Identity Services (GIS) SDK**,
    instead of the **Google Sign-In for Web JS SDK**, which is set to be deprecated
    after March 31, 2023.
    * Migration information can be found in the
      [`google_sign_in_web` package README](https://pub.dev/packages/google_sign_in_web).

For every platform other than `web`, this version should be identical to `5.4.4`.

## 5.4.4

* Adds documentation for iOS auth with SERVER_CLIENT_ID
* Updates minimum Flutter version to 3.0.

## 5.4.3

* Updates code for stricter lint checks.

## 5.4.2

* Updates minimum Flutter version to 2.10.
* Adds override for `GoogleSignInPlatform.initWithParams`.
* Fixes tests to recognize new default `forceCodeForRefreshToken` request attribute.

## 5.4.1

* Fixes avoid_redundant_argument_values lint warnings and minor typos.

## 5.4.0

* Adds support for configuring `serverClientId` through `GoogleSignIn` constructor.
* Adds support for Dart-based configuration as alternative to `GoogleService-Info.plist` for iOS.

## 5.3.3

* Updates references to the obsolete master branch.

## 5.3.2

* Enables mocking models by changing overridden operator == parameter type from `dynamic` to `Object`.
* Updates tests to use a mock platform instead of relying on default
  method channel implementation internals.
* Removes example workaround to build for arm64 iOS simulators.

## 5.3.1

* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 5.3.0

* Moves Android and iOS implementations to federated packages.

## 5.2.5

* Migrates from `ui.hash*` to `Object.hash*`.
* Adds OS version support information to README.

## 5.2.4

* Internal code cleanup for stricter analysis options.

## 5.2.3

* Bumps the Android dependency on `com.google.android.gms:play-services-auth` and therefore removes the need for `jetifier`.

## 5.2.2

* Updates Android compileSdkVersion to 31.
* Removes dependency on `meta`.

## 5.2.1

 Change the placeholder of the GoogleUserCircleAvatar to a transparent image.

## 5.2.0

* Add `GoogleSignInAccount.serverAuthCode`. Mark `GoogleSignInAuthentication.serverAuthCode` as deprecated.

## 5.1.1

* Update minimum Flutter SDK to 2.5 and iOS deployment target to 9.0.

## 5.1.0

* Add reAuthenticate option to signInSilently to allow re-authentication to be requested

* Updated Android lint settings.

## 5.0.7

* Mark iOS arm64 simulators as unsupported.

## 5.0.6

* Remove references to the Android V1 embedding.

## 5.0.5

* Add iOS unit and UI integration test targets.
* Add iOS unit test module map.
* Exclude arm64 simulators in example app.

## 5.0.4

* Migrate maven repo from jcenter to mavenCentral.

## 5.0.3

* Fixed links in `README.md`.
* Added documentation for usage on the web.

## 5.0.2

* Fix flutter/flutter#48602 iOS flow shows account selection, if user is signed in to Google on the device.

## 5.0.1

* Update platforms `init` function to prioritize `clientId` property when available;
* Updates `google_sign_in_platform_interface` version.

## 5.0.0

* Migrate to null safety.

## 4.5.9

* Update the example app: remove the deprecated `RaisedButton` and `FlatButton` widgets.

## 4.5.8

* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))

## 4.5.7

* Update Flutter SDK constraint.

## 4.5.6

* Fix deprecated member warning in tests.

## 4.5.5

* Update android compileSdkVersion to 29.

## 4.5.4

* Keep handling deprecated Android v1 classes for backward compatibility.

## 4.5.3

* Update package:e2e -> package:integration_test

## 4.5.2

* Update package:e2e reference to use the local version in the flutter/plugins
  repository.

## 4.5.1

* Add note on Apple sign in requirement in README.

## 4.5.0

* Add support for getting `serverAuthCode`.

## 4.4.6

* Update lower bound of dart dependency to 2.1.0.

## 4.4.5

* Fix requestScopes to allow subsequent calls on Android.

## 4.4.4

* OCMock module import -> #import, unit tests compile generated as library.
* Fix CocoaPods podspec lint warnings.

## 4.4.3

* Upgrade google_sign_in_web to version ^0.9.1

## 4.4.2

* Android: make the Delegate non-final to allow overriding.

## 4.4.1

* Android: Move `GoogleSignInWrapper` to a separate class.

## 4.4.0

* Migrate to Android v2 embedder.

## 4.3.0

* Add support for method introduced in `google_sign_in_platform_interface` 1.1.0.

## 4.2.0

* Migrate to AndroidX.

## 4.1.5

* Remove unused variable.

## 4.1.4

* Make the pedantic dev_dependency explicit.

## 4.1.3

* Make plugin example meet naming convention.

## 4.1.2

* Added a new error code `network_error`, and return it when a network error occurred.

## 4.1.1

* Support passing `clientId` to the web plugin programmatically.

## 4.1.0

* Support web by default.
* Require Flutter SDK `v1.12.13+hotfix.4` or greater.

## 4.0.17

* Add missing documentation and fix an unawaited future in the example app.

## 4.0.16

* Remove the deprecated `author:` field from pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 4.0.15

* Export SignInOption from interface since it is used in the frontend as a type.

## 4.0.14

* Port plugin code to use the federated Platform Interface, instead of a MethodChannel directly.

## 4.0.13

* Fix `GoogleUserCircleAvatar` to handle new style profile image URLs.

## 4.0.12

* Move google_sign_in plugin to google_sign_in/google_sign_in to prepare for federated implementations.

## 4.0.11

* Update iOS CocoaPod dependency to 5.0 to fix deprecated API usage issue.

## 4.0.10

* Remove AndroidX warning.

## 4.0.9

* Update and migrate iOS example project.
* Define clang module for iOS.

## 4.0.8

* Get rid of `MethodCompleter` and serialize async actions using chained futures.
  This prevents a bug when sign in methods are being used in error handling zones.

## 4.0.7

* Switch from using `api` to `implementation` for dependency on `play-services-auth`,
  preventing version mismatch build failures in some Android configurations.

## 4.0.6

* Fixed the `PlatformException` leaking from `catchError()` in debug mode.

## 4.0.5

* Update README with solution to `APIException` errors.

## 4.0.4

* Revert changes in 4.0.3.

## 4.0.3

* Update guava to `27.0.1-android`.
* Add correct @NonNull annotations to reduce compiler warnings.

## 4.0.2

* Add missing template type parameter to `invokeMethod` calls.
* Bump minimum Flutter version to 1.5.0.
* Replace invokeMethod with invokeMapMethod wherever necessary.

## 4.0.1+3

* Update example to gracefully handle null user information.

## 4.0.1+2

* Fix README.md to correctly spell `GoogleService-Info.plist`.

## 4.0.1+1

* Remove categories.

## 4.0.1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 4.0.0+1

* Added a better error message for iOS when the app is missing necessary URL schemes.

## 4.0.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

  This was originally incorrectly pushed in the `3.3.0` update.

## 3.3.0+1

* **Revert the breaking 3.3.0 update**. 3.3.0 was known to be breaking and
  should have incremented the major version number instead of the minor. This
  revert is in and of itself breaking for anyone that has already migrated
  however. Anyone who has already migrated their app to AndroidX should
  immediately update to `4.0.0` instead. That's the correctly versioned new push
  of `3.3.0`.

## 3.3.0

* **BAD**. This was a breaking change that was incorrectly published on a minor
  version upgrade, should never have happened. Reverted by 3.3.0+1.

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 3.2.4

* Increase play-services-auth version to 16.0.1

## 3.2.3

* Change google-services.json and GoogleService-Info.plist of example.

## 3.2.2

* Don't use the result code when handling signin. This results in better error codes because result code always returns "cancelled".

## 3.2.1

* Set http version to be compatible with flutter_test.

## 3.2.0

* Add support for clearing authentication cache for Android.

## 3.1.0

* Add support to recover authentication for Android.

## 3.0.6

* Remove flaky displayName assertion

## 3.0.5

* Added missing http package dependency.

## 3.0.4

* Updated Gradle tooling to match Android Studio 3.1.2.

## 3.0.3+1

* Added documentation on where to find the list of available scopes.

## 3.0.3

* Added support for games sign in on Android.

## 3.0.2

* Updated Google Play Services dependency to version 15.0.0.

## 3.0.1

* Simplified podspec for Cocoapods 1.5.0, avoiding link issues in app archives.

## 3.0.0

* **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 2.1.2

* Added a Delegate interface (IDelegate) that can be implemented by clients in
  order to override the functionality (for testing purposes for example).

## 2.1.1

* Fixed Dart 2 type errors.

## 2.1.0

* Enabled use in Swift projects.

## 2.0.1

* Simplified and upgraded Android project template to Android SDK 27.
* Updated package description.

## 2.0.0

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).
* Relaxed GMS dependency to [11.4.0,12.0[

## 1.0.3

* Add FLT prefix to iOS types

## 1.0.2

* Support setting foregroundColor in the avatar.

## 1.0.1

* Change GMS dependency to 11.+

## 1.0.0

* Make GoogleUserCircleAvatar fade profile image over the top of placeholder
* Bump to released version

## 0.3.1

* Updated GMS to always use latest patch version for 11.0.x builds

## 0.3.0

* Add a new `GoogleIdentity` interface, implemented by `GoogleSignInAccount`.
* Move `GoogleUserCircleAvatar` to "widgets" library (exported by
  base library for backwards compatibility) and make it take an instance
  of `GoogleIdentity`, thus allowing it to be used by other packages that
  provide implementations of `GoogleIdentity`.

## 0.2.1

* Plugin can (once again) be used in apps that extend `FlutterActivity`
* `signInSilently` is guaranteed to never throw
* A failed sign-in (caused by a failing `init` step) will no longer block subsequent sign-in attempts

## 0.2.0

* Updated dependencies
* **Breaking Change**: You need to add a maven section with the "https://maven.google.com" endpoint to the repository section of your `android/build.gradle`. For example:
```gradle
allprojects {
    repositories {
        jcenter()
        maven {                              // NEW
            url "https://maven.google.com"   // NEW
        }                                    // NEW
    }
}
```

## 0.1.0

* Update to use `GoogleSignIn` CocoaPod


## 0.0.6

* Fix crash on iOS when signing in caused by nil uiDelegate

## 0.0.5

* Require the use of `support-v4` library on Android. This is an API change in
  that plugin users will need their activity class to be an instance of
  `android.support.v4.app.FragmentActivity`. Flutter framework provides such
  an activity out of the box: `io.flutter.app.FlutterFragmentActivity`
* Ignore "Broken pipe" errors affecting iOS simulator
* Update to non-deprecated `application:openURL:options:` on iOS

## 0.0.4

* Prevent race conditions when GoogleSignIn methods are called concurrently (#94)

## 0.0.3

* Fix signOut and disconnect (they were silently ignored)
* Fix test (#10050)

## 0.0.2

* Don't try to sign in again if user is already signed in

## 0.0.1

* Initial Release
