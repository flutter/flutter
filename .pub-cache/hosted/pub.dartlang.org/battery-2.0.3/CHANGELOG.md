## 2.0.3

* Update README to point to Plus Plugins version.

## 2.0.2

* Migrate maven repository from jcenter to mavenCentral.

## 2.0.1

* Update platform_plugin_interface version requirement.

## 2.0.0

* Migrate to null safety.

## 1.0.11

* Update the example app: remove the deprecated `RaisedButton` and `FlatButton` widgets.

## 1.0.10

* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))

## 1.0.9

* Update Flutter SDK constraint.

## 1.0.8

* Update Dart SDK constraint in example.

## 1.0.7

* Update android compileSdkVersion to 29.

## 1.0.6

* Keep handling deprecated Android v1 classes for backward compatibility.

## 1.0.5

* Ported to use platform interface.

## 1.0.4+1

* Moved everything from battery to battery/battery

## 1.0.4

* Updated README.md.

## 1.0.3

* Update package:e2e to use package:integration_test


## 1.0.2

* Update package:e2e reference to use the local version in the flutter/plugins
  repository.

## 1.0.1

* Update lower bound of dart dependency to 2.1.0.

## 1.0.0

* Bump the package version to 1.0.0 following ecosystem pre-migration (https://github.com/amirh/bump_to_1.0/projects/1).

## 0.3.1+10

* Update minimum Flutter version to 1.12.13+hotfix.5
* Fix CocoaPods podspec lint warnings.

## 0.3.1+9

* Declare API stability and compatibility with `1.0.0` (more details at: https://github.com/flutter/flutter/wiki/Package-migration-to-1.0.0).

## 0.3.1+8

* Make the pedantic dev_dependency explicit.

## 0.3.1+7

* Clean up various Android workarounds no longer needed after framework v1.12.

## 0.3.1+6

* Remove the deprecated `author:` field from pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 0.3.1+5

* Fix pedantic linter errors.

## 0.3.1+4

* Update and migrate iOS example project.

## 0.3.1+3

* Remove AndroidX warning.

## 0.3.1+2

* Include lifecycle dependency as a compileOnly one on Android to resolve
  potential version conflicts with other transitive libraries.

## 0.3.1+1

* Android: Use android.arch.lifecycle instead of androidx.lifecycle:lifecycle in `build.gradle` to support apps that has not been migrated to AndroidX.

## 0.3.1

* Support the v2 Android embedder.

## 0.3.0+6

* Define clang module for iOS.

## 0.3.0+5

* Fix Gradle version.

## 0.3.0+4

* Update Dart code to conform to current Dart formatter.

## 0.3.0+3

* Fix `batteryLevel` usage example in README

## 0.3.0+2

* Bump the minimum Flutter version to 1.2.0.
* Add template type parameter to `invokeMethod` calls.

## 0.3.0+1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.3.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.2.3

* Updated mockito dependency to 3.0.0 to get Dart 2 support.
* Update test package dependency to 1.3.0, and fixed tests to match.

## 0.2.2

* Updated Gradle tooling to match Android Studio 3.1.2.

## 0.2.1

* Fixed Dart 2 type error.
* Removed use of deprecated parameter in example.

## 0.2.0

* **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 0.1.1

* Fixed warnings from the Dart 2.0 analyzer.
* Simplified and upgraded Android project template to Android SDK 27.
* Updated package description.

## 0.1.0

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).

## 0.0.2

* Add FLT prefix to iOS types.

## 0.0.1+1

* Updated README

## 0.0.1

* Initial release
