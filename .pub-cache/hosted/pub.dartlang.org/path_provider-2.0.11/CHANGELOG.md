## 2.0.11

* Updates references to the obsolete master branch.
* Fixes integration test permission issue on recent versions of macOS.

## 2.0.10

* Removes unnecessary imports.
* Adds OS version support information to README.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.0.9

* Updates documentation on README.md.
* Updates example application.

## 2.0.8

* Updates example app Android compileSdkVersion to 31.
* Removes obsolete manual registration of Windows and Linux implementations.

## 2.0.7

* Moved Android and iOS implementations to federated packages.

## 2.0.6

* Added support for Background Platform Channels on Android when it is
  available.

## 2.0.5

* Update minimum Flutter SDK to 2.5 and iOS deployment target to 9.0.

## 2.0.4

* Updated Android lint settings.
* Specify Java 8 for Android build.

## 2.0.3

* Add iOS unit test target.
* Remove references to the Android V1 embedding.

## 2.0.2

* Migrate maven repository from jcenter to mavenCentral.

## 2.0.1

* Update platform_plugin_interface version requirement.

## 2.0.0

* Migrate to null safety.
* BREAKING CHANGE: Path accessors that return non-nullable results will throw
  a `MissingPlatformDirectoryException` if the platform implementation is unable
  to get the corresponding directory (except on platforms where the method is
  explicitly unsupported, where they will continue to throw `UnsupportedError`).

## 1.6.28

* Drop unused UUID dependency for tests.

## 1.6.27

* Update the example app: remove the deprecated `RaisedButton` and `FlatButton` widgets.

## 1.6.26

* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))

## 1.6.25

* Update Flutter SDK constraint.

## 1.6.24

* Remove unused `test` dependency.
* Update Dart SDK constraint in example.

## 1.6.23

* Check in windows/ directory for example/

## 1.6.22

* Switch to guava-android dependency instead of full guava.

## 1.6.21

* Update android compileSdkVersion to 29.

## 1.6.20

* Check in linux/ directory for example/

## 1.6.19

* Android implementation does path queries in the background thread rather than UI thread.

## 1.6.18

* Keep handling deprecated Android v1 classes for backward compatibility.

## 1.6.17

* Update Windows endorsement verison again, to pick up the fix for
  web compilation in projects that include path_provider.

## 1.6.16

* Update Windows endorsement verison

## 1.6.15

* Endorse Windows implementation.
* Remove the need to call disablePathProviderPlatformOverride in tests

## 1.6.14

* Update package:e2e -> package:integration_test

## 1.6.13

* Update package:e2e reference to use the local version in the flutter/plugins
  repository.

## 1.6.12

* Fixed a Java lint in a test.

## 1.6.11

* Updated documentation to reflect the need for changes in testing for federated plugins

## 1.6.10

* Linux implementation endorsement

## 1.6.9

* Post-v2 Android embedding cleanups.

## 1.6.8

* Update lower bound of dart dependency to 2.1.0.

## 1.6.7

* Remove Android dependencies fallback.
* Require Flutter SDK 1.12.13+hotfix.5 or greater.
* Fix CocoaPods podspec lint warnings.

## 1.6.6

* Replace deprecated `getFlutterEngine` call on Android.

## 1.6.5

* Remove unused class name in pubspec.

## 1.6.4

* Endorsed macOS implementation.

## 1.6.3

* Use `path_provider_platform_interface` in core plugin.

## 1.6.2

* Move package contents into `path_provider` for platform federation.

## 1.6.1

* Make the pedantic dev_dependency explicit.

## 1.6.0

* Support for retrieving the downloads directory was added.
  The call for this is `getDownloadsDirectory`.

## 1.5.1

* Remove the deprecated `author:` field from pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 1.5.0

* Add macOS support.

## 1.4.5

* Add support for v2 plugins APIs.

## 1.4.4

* Update driver tests in the example app to e2e tests.

## 1.4.3

* Update driver tests in the example app to e2e tests.
* Add missing DartDocs and a lint to prevent further regressions.

## 1.4.2

* Update and migrate iOS example project by removing flutter_assets, change
  "English" to "en", remove extraneous xcconfigs, update to Xcode 11 build
  settings, remove ARCHS, and build pods as libraries instead of frameworks.

## 1.4.1

* Remove AndroidX warnings.

## 1.4.0

* Support retrieving storage paths on Android devices with multiple external
  storage options. This adds a new class `AndroidEnvironment` that shadows the
  directory names from Androids `android.os.Environment` class.
* Fixes `getLibraryDirectory` semantics & tests.

## 1.3.1

* Define clang module for iOS.

## 1.3.0

* Added iOS-only support for `getLibraryDirectory`.
* Update integration tests and example test.
* Update example app UI to use a `ListView` show the list of content.
* Update .gitignore to include Xcode build output folder `**/DerivedData/`

## 1.2.2

* Correct the integration test for Android's `getApplicationSupportDirectory` call.
* Introduce `setMockPathProviderPlatform` for API for tests.
* Adds missing unit and integration tests.

## 1.2.1

* Fix fall through bug.

## 1.2.0

* On Android, `getApplicationSupportDirectory` is now supported using `getFilesDir`.
* `getExternalStorageDirectory` now returns `null` instead of throwing an
  exception if no external files directory is available.

## 1.1.2

* `getExternalStorageDirectory` now uses `getExternalFilesDir` on Android.

## 1.1.1

* Cast error codes as longs in iOS error strings to ensure compatibility
  between arm32 and arm64.

## 1.1.0

* Added `getApplicationSupportDirectory`.
* Updated documentation for `getApplicationDocumentsDirectory` to suggest
  using `getApplicationSupportDirectory` on iOS and
  `getExternalStorageDirectory` on Android.
* Updated documentation for `getTemporaryDirectory` to suggest using it
  for caches of files that do not need to be backed up.
* Updated integration tests and example to reflect the above changes.

## 1.0.0

* Added integration tests.

## 0.5.0+1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.5.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.4.1

* Updated Gradle tooling to match Android Studio 3.1.2.

## 0.4.0

* **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 0.3.1

* Simplified and upgraded Android project template to Android SDK 27.
* Updated package description.

## 0.3.0

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).

## 0.2.2

* Add FLT prefix to iOS types

## 0.2.1+1

* Updated README

## 0.2.1

* Add function to determine external storage directory.

## 0.2.0

* Upgrade to new plugin registration. (https://groups.google.com/forum/#!topic/flutter-dev/zba1Ynf2OKM)

## 0.1.3

* Upgrade Android SDK Build Tools to 25.0.3.

## 0.1.2

* Add test.

## 0.1.1

* Change to README.md.

## 0.1.0

* Initial Open Source release.
