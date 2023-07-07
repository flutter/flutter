## 2.0.3

* Remove references to the Android V1 embedding.
* Updated Android lint settings.
* Started using Background Platform Channels when available.

## 2.0.2

* Update README to point to Plus Plugins version.

## 2.0.1

* Migrate maven repository from jcenter to mavenCentral.

## 2.0.0

* Migrate to null safety.
* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))

## 1.0.1

* Update Flutter SDK constraint.

## 1.0.0

* Announce 1.0.0.

## 0.4.2+10

* Update Dart SDK constraint in example.

## 0.4.2+9

* Update android compileSdkVersion to 29.

## 0.4.2+8

* Keep handling deprecated Android v1 classes for backward compatibility.

## 0.4.2+7

* Port device_info plugin to use platform interface.

## 0.4.2+6

* Moved everything from device_info to device_info/device_info

## 0.4.2+5

* Update package:e2e reference to use the local version in the flutter/plugins
  repository.

## 0.4.2+4

Update lower bound of dart dependency to 2.1.0.

## 0.4.2+3

* Declare API stability and compatibility with `1.0.0` (more details at: https://github.com/flutter/flutter/wiki/Package-migration-to-1.0.0).

## 0.4.2+2

* Fix CocoaPods podspec lint warnings.

## 0.4.2+1

* Bump the minimum Flutter version to 1.12.13+hotfix.5.
* Remove deprecated API usage warning in AndroidIntentPlugin.java.
* Migrates the Android example to V2 embedding.
* Bumps AGP to 3.6.1.

## 0.4.2

* Add systemFeatures to AndroidDeviceInfo.

## 0.4.1+5

* Make the pedantic dev_dependency explicit.

## 0.4.1+4

* Remove the deprecated `author:` field from pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 0.4.1+3

* Fix pedantic errors. Adds some missing documentation and fixes unawaited
  futures in the tests.

## 0.4.1+2

* Remove AndroidX warning.

## 0.4.1+1

* Include lifecycle dependency as a compileOnly one on Android to resolve
  potential version conflicts with other transitive libraries.

## 0.4.1

* Support the v2 Android embedding.
* Update to AndroidX.
* Migrate to using the new e2e test binding.
* Add a e2e test.


## 0.4.0+4

* Define clang module for iOS.

## 0.4.0+3

* Update and migrate iOS example project.

## 0.4.0+2

* Bump minimum Flutter version to 1.5.0.
* Add missing template type parameter to `invokeMethod` calls.
* Replace invokeMethod with invokeMapMethod wherever necessary.

## 0.4.0+1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.4.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.3.0

* Added ability to get Android ID for Android devices

## 0.2.1

* Updated Gradle tooling to match Android Studio 3.1.2.

## 0.2.0

* **Breaking change**. Set SDK constraints to match the Flutter beta release.

## 0.1.2

* Fixed Dart 2 type errors.

## 0.1.1

* Simplified and upgraded Android project template to Android SDK 27.
* Updated package description.

## 0.1.0

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version of the plugin. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).

## 0.0.5

* Added FLT prefix to iOS types

## 0.0.4

* Fixed Java/Dart communication error with empty lists

## 0.0.3

* Added support for utsname

## 0.0.2

* Fixed broken type comparison
* Added "isPhysicalDevice" field, detecting emulators/simulators

## 0.0.1

* Implements platform-specific device/OS properties
