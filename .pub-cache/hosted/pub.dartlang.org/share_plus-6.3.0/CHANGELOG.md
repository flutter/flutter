## 6.3.0

 - **FIX**: remove `canLaunch` check (#1315).
 - **FEAT**: Show destination for share with result in example, update example UI (#1314).

## 6.2.0

 - **FIX**: return correct share result on android (#1301).
 - **FEAT**: remove direct dependence of url_launcher (#1295).
 - **DOCS**: #1299 document XFile.fromData (#1300).

## 6.1.0

 - **FIX**: export XFile (#1286).
 - **FEAT**: share XFile created using File.fromData() (#1284).

## 6.0.1

 - **FIX**: Increase min Flutter version to fix dartPluginClass registration (#1275).

## 6.0.0

> Note: This release has breaking changes.

 - **FIX**: lint warnings - add missing dependency for tests (#1233).
 - **FIX**: Show NSSharingServicePicker asynchronously on main thread (#1223).
 - **BREAKING** **REFACTOR**: two-package federated architecture (#1238).

## 5.0.0

> Note: This release has breaking changes.

 - **BREAKING** **FEAT**: Native share UI for Windows (#1158).

## 4.5.3

 - **CHORE**: Version tagging using melos.

## 4.5.2

- Update internal dependencies

## 4.5.1

- Update internal dependencies

## 4.5.0

- iOS: Remove usage of deprecated UIApplication.keyWindow in iOS 13+
- Add `shareXFiles` implementations
- Deprecate `shareFiles*` implementations
- Enable `shareXFiles` implementations on Web

## 4.4.0

- Reverted changes in 4.2.0 due to crash issues. See #1081

## 4.3.0

- iOS: Throw PlatformException when iPad share dialog not appearing (sharePositionOrigin not in sourceView)

## 4.2.0

- iOS: Fix Instagram does not show up in provider list for web links
  - issue #459 appear again
  - put back NSURL for the shareText, when text is pure URL
  - using LPMetadataProvider to get LPLinkMetadata make the user experience better

## 4.1.0

- iOS: Fix text sharing.
  - Previously, the text was being encoded as a URL, this caused the share sheet to appear empty.
  - Now the shared text is not encoded as a URL anymore but rather shared as plain text.
  - Sharing text + subject + attachments should work on apps that support that (e.g. Mail app).
  - Example: Sharing Text + Image on Telegram is possible and both are shared.
  - Some apps still have limitations with sharing. For example, Gmail app does not support the subject field.
  - Related issue: #730

## 4.0.10+1

- Add issue_tracker link.

## 4.0.10

- iOS: Fix 'share text' not showing when share files

## 4.0.9

- iOS: Fix image file names not preserved

## 4.0.8

- iOS: Fix 'Save Image' option not showing

## 4.0.7

- Add documentation iPad

## 4.0.6

- iOS: Fix file names not preserved and poor previews for files

## 4.0.5

- Update dependencies
- Fix analyzer warnings

## 4.0.4

- iOS: Fix subject not working when sharing raw url or files via email

## 4.0.3

- Android: Revert increased minSdkVersion back to 16
- Gracefully fall back from `shareWithResult` to regular `share` methods on unsupported platforms
- Improve documentation for `shareWithResult` methods

## 4.0.2

- Fix type mismatch on Android for some users
- Set min Flutter to 1.20.0 for all platforms
- Lower Android minSdkVersion to 22

## 4.0.1

- Hotfix dependencies

## 4.0.0

- iOS, Android, MacOS: Add `shareWithResult` methods to get feedback on user action
- Android: Increased minSdkVersion to 23
- MacOS: Native sharing implementation

## 3.1.0

- Android: Migrate to Kotlin
- Android: Update dependencies, build config updates

## 3.0.5

- Fix example embedding issue

## 3.0.4

- iOS: Fixed sharing malformed URLs

## 3.0.3

- Improve documentation for `shareFiles` method

## 3.0.2

- Apply code improvements
- Update gradle for plugin
- Update flutter dependencies

## 3.0.1

- Update Android dependencies for plugin and example, bump compileSDK to 31

## 3.0.0

- Remove deprecated method `registerWith` (of Android v1 embedding)

## 2.2.0

- migrate integration_test to flutter sdk

## 2.1.5

- Fixed: Use NSURL for web links (iOS)

## 2.1.4

- Android: migrate to mavenCentral

## 2.1.3

- Update iOS share target to present on the top ViewController. This fixes "Unable to present" errors when the app is already presenting such as in an add to app scenario.

## 2.1.2

- Do not tear down method channel onDetachedFromActivity.

## 2.1.1

- Updated iOS share sheet preview title to use subject when text is not set

## 2.1.0

- Fixes #241 resolves issues with deprecations as of android API version 29 and replaces the requirement for external storage locations with an easy application cache usage.

## 2.0.3

- Improve documentation

## 2.0.2

- Fixed crash on launch when running iOS 12.x and below

## 2.0.1

- Added preview title to iOS share sheet

## 2.0.0

- Migrated to null safety
- Add macOS support (`share_plus_macos`)

## 1.2.0

- Add Web support (`share_plus_web`)
- Rename method channel to avoid conflicts

## 1.1.1

- Transfer to plus-plugins monorepo

## 0.7.0

- Add Linux support for basic share capabilities.

## 0.6.6

- Transfer package to Flutter Community under new name `share_plus`.

## 0.6.5

- Added support for sharing files

## 0.6.4+5

- Update package:e2e -> package:integration_test

## 0.6.4+4

- Update package:e2e reference to use the local version in the flutter/plugins
  repository.

## 0.6.4+3

- Post-v2 Android embedding cleanup.

## 0.6.4+2

- Update lower bound of dart dependency to 2.1.0.

## 0.6.4+1

- Declare API stability and compatibility with `1.0.0` (more details at: https://github.com/flutter/flutter/wiki/Package-migration-to-1.0.0).

## 0.6.4

- Remove Android dependencies fallback.
- Require Flutter SDK 1.12.13+hotfix.5 or greater.
- Fix CocoaPods podspec lint warnings.

## 0.6.3+8

- Replace deprecated `getFlutterEngine` call on Android.

## 0.6.3+7

- Updated gradle version of example.

## 0.6.3+6

- Make the pedantic dev_dependency explicit.

## 0.6.3+5

- Remove the deprecated `author:` field from pubspec.yaml
- Migrate the plugin to the pubspec platforms manifest.
- Require Flutter SDK 1.10.0 or greater.

## 0.6.3+4

- Fix pedantic lints. This shouldn't affect existing functionality.

## 0.6.3+3

- README update.

## 0.6.3+2

- Remove AndroidX warnings.

## 0.6.3+1

- Include lifecycle dependency as a compileOnly one on Android to resolve
  potential version conflicts with other transitive libraries.

## 0.6.3

- Support the v2 Android embedder.
- Update to AndroidX.
- Migrate to using the new e2e test binding.
- Add a e2e test.

## 0.6.2+4

- Define clang module for iOS.

## 0.6.2+3

- Fix iOS crash when setting subject to null.

## 0.6.2+2

- Update and migrate iOS example project.

## 0.6.2+1

- Specify explicit type for `invokeMethod`.
- Use `const` for `Rect`.
- Updated minimum Flutter SDK to 1.6.0.

## 0.6.2

- Add optional subject to fill email subject in case user selects email app.

## 0.6.1+2

- Update Dart code to conform to current Dart formatter.

## 0.6.1+1

- Fix analyzer warnings about `const Rect` in tests.

## 0.6.1

- Updated Android compileSdkVersion to 28 to match other plugins.

## 0.6.0+1

- Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.6.0

- **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.5.3

- Added missing test package dependency.
- Bumped version of mockito package dependency to pick up Dart 2 support.

## 0.5.2

- Fixes iOS sharing

## 0.5.1

- Updated Gradle tooling to match Android Studio 3.1.2.

## 0.5.0

- **Breaking change**. Namespaced the `share` method inside a `Share` class.
- Fixed crash when sharing on iPad.
- Added functionality to specify share sheet origin on iOS.

## 0.4.0

- **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 0.3.2

- Fixed Dart 2 type error.

## 0.3.1

- Simplified and upgraded Android project template to Android SDK 27.
- Updated package description.

## 0.3.0

- **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).

## 0.2.2

- Added FLT prefix to iOS types

## 0.2.1

- Updated README
- Bumped buildToolsVersion to 25.0.3

## 0.2.0

- Upgrade to new plugin registration. (https://groups.google.com/forum/#!topic/flutter-dev/zba1Ynf2OKM)

## 0.1.0

- Initial Open Source release.
