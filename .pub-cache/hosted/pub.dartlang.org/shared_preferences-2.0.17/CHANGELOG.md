## 2.0.17

* Updates code for stricter lint checks.

## 2.0.16

* Switches to the new `shared_preferences_foundation` implementation package
  for iOS and macOS.
* Updates code for `no_leading_underscores_for_local_identifiers` lint.
* Updates minimum Flutter version to 2.10.

## 2.0.15

* Minor fixes for new analysis options.

## 2.0.14

* Adds OS version support information to README.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.0.13

* Updates documentation on README.md.

## 2.0.12

* Removes dependency on `meta`.

## 2.0.11

* Corrects example for mocking in readme.

## 2.0.10

* Removes obsolete manual registration of Windows and Linux implementations.

## 2.0.9

* Fixes newly enabled analyzer options.
* Updates example app Android compileSdkVersion to 31.
* Moved Android and iOS implementations to federated packages.

## 2.0.8

* Update minimum Flutter SDK to 2.5 and iOS deployment target to 9.0.

## 2.0.7

* Add iOS unit test target.
* Updated Android lint settings.
* Fix string clash with double entries on Android

## 2.0.6

* Migrate maven repository from jcenter to mavenCentral.

## 2.0.5

* Fix missing declaration of windows' default_package

## 2.0.4

* Fix a regression with simultaneous writes on Android.

## 2.0.3

* Android: don't create additional Handler when method channel is called.

## 2.0.2

* Don't create additional thread pools when method channel is called.

## 2.0.1

* Removed deprecated [AsyncTask](https://developer.android.com/reference/android/os/AsyncTask) was deprecated in API level 30 ([#3481](https://github.com/flutter/plugins/pull/3481))

## 2.0.0

* Migrate to null-safety.

**Breaking changes**:

* Setters no longer accept null to mean removing values. If you were previously using `set*(key, null)` for removing, use `remove(key)` instead.

## 0.5.13+2

* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))

## 0.5.13+1

* Update Flutter SDK constraint.

## 0.5.13

* Update integration test examples to use `testWidgets` instead of `test`.

## 0.5.12+4

* Remove unused `test` dependency.

## 0.5.12+3

* Check in windows/ directory for example/

## 0.5.12+2

* Update android compileSdkVersion to 29.

## 0.5.12+1

* Check in linux/ directory for example/

## 0.5.12

* Keep handling deprecated Android v1 classes for backward compatibility.

## 0.5.11

* Support Windows by default.

## 0.5.10

* Update package:e2e -> package:integration_test

## 0.5.9

* Update package:e2e reference to use the local version in the flutter/plugins
  repository.

## 0.5.8

* Support Linux by default.

## 0.5.7+3

* Post-v2 Android embedding cleanup.

## 0.5.7+2

* Update lower bound of dart dependency to 2.1.0.

## 0.5.7+1

* Declare API stability and compatibility with `1.0.0` (more details at: https://github.com/flutter/flutter/wiki/Package-migration-to-1.0.0).

## 0.5.7

* Remove Android dependencies fallback.
* Require Flutter SDK 1.12.13+hotfix.5 or greater.
* Fix CocoaPods podspec lint warnings.

## 0.5.6+3

* Fix deprecated API usage warning.

## 0.5.6+2

* Make the pedantic dev_dependency explicit.

## 0.5.6+1

* Updated README

## 0.5.6

* Support `web` by default.
* Require Flutter SDK 1.12.13+hotfix.4 or greater.

## 0.5.5

* Support macos by default.

## 0.5.4+10

* Adds a `shared_preferences_macos` package.

## 0.5.4+9

* Remove the deprecated `author:` field from pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 0.5.4+8

* Switch `package:shared_preferences` to `package:shared_preferences_platform_interface`.
  No code changes are necessary in Flutter apps. This is not a breaking change.

## 0.5.4+7

* Restructure the project for Web support.

## 0.5.4+6

* Add missing documentation and a lint to prevent further undocumented APIs.

## 0.5.4+5

* Update and migrate iOS example project by removing flutter_assets, change
  "English" to "en", remove extraneous xcconfigs and framework outputs,
  update to Xcode 11 build settings, and remove ARCHS.

## 0.5.4+4

* `setMockInitialValues` needs to handle non-prefixed keys since that's an implementation detail.

## 0.5.4+3

* Android: Suppress casting warnings.

## 0.5.4+2

* Remove AndroidX warnings.

## 0.5.4+1

* Include lifecycle dependency as a compileOnly one on Android to resolve
  potential version conflicts with other transitive libraries.

## 0.5.4

* Support the v2 Android embedding.
* Update to AndroidX.
* Migrate to using the new e2e test binding.

## 0.5.3+5

* Define clang module for iOS.

## 0.5.3+4

* Copy `List` instances when reading and writing values to prevent mutations from propagating.

## 0.5.3+3

* `setMockInitialValues` can now be called multiple times and will
  `reload()` the singleton if necessary.

## 0.5.3+2

* Fix Gradle version.

## 0.5.3+1

* Add missing template type parameter to `invokeMethod` calls.
* Bump minimum Flutter version to 1.5.0.
* Replace invokeMethod with invokeMapMethod wherever necessary.

## 0.5.3

* Add reload method.

## 0.5.2+2

* Updated Gradle tooling to match Android Studio 3.4.

## 0.5.2+1

* .commit() calls are now run in an async background task on Android.

## 0.5.2

* Add containsKey method.

## 0.5.1+2

* Add a driver test

## 0.5.1+1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.5.1

* Use String to save double in Android.

## 0.5.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.4.3

* Prevent strings that match special prefixes from being saved. This is a bugfix that prevents apps from accidentally setting special values that would be interpreted incorrectly.

## 0.4.2

* Updated Gradle tooling to match Android Studio 3.1.2.

## 0.4.1

* Added getKeys method.

## 0.4.0

* **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 0.3.3

* Fixed Dart 2 issues.

## 0.3.2

* Added an getter that can retrieve values of any type

## 0.3.1

* Simplified and upgraded Android project template to Android SDK 27.
* Updated package description.

## 0.3.0

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).

## 0.2.6

* Added FLT prefix to iOS types

## 0.2.5+1

* Aligned author name with rest of repo.

## 0.2.5

* Fixed crashes when setting null values. They now cause the key to be removed.
* Added remove() method

## 0.2.4+1

* Fixed typo in changelog

## 0.2.4

* Added setMockInitialValues
* Added a test
* Updated README

## 0.2.3

* Suppress warning about unchecked operations when compiling for Android

## 0.2.2

* BREAKING CHANGE: setStringSet API changed to setStringList and plugin now supports
  ordered storage.

## 0.2.1

* Support arbitrary length integers for setInt.

## 0.2.0+1

* Updated README

## 0.2.0

* Upgrade to new plugin registration. (https://groups.google.com/forum/#!topic/flutter-dev/zba1Ynf2OKM)

## 0.1.1

* Upgrade Android SDK Build Tools to 25.0.3.

## 0.1.0

* Initial Open Source release.
