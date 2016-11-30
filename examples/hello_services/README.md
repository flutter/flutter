# Example of embedding Flutter using FlutterView

This project demonstrates how to embed Flutter within an iOS or Android
application. On iOS, the iOS and Flutter components are built with Xcode. On
Android, the Android and Flutter components are built with Android Studio or
gradle.

You can read more about
[accessing platform and third-party services in Flutter](https://flutter.io/platform-services/).

## iOS

### Configure

Create an `ios/Flutter/Generated.xcconfig` file with this entry:

 * `FLUTTER_ROOT=[absolute path to the Flutter SDK]`

There are a number of other parameters you can control with this file:

 * `FLUTTER_APPLICATION_PATH`: The path to the directory that contains your
   `pubspec.yaml` file relative to your `xcodeproj` file.
 * `FLUTTER_BUILD_MODE`: Whether to build for `debug`, `profile`, or `release`.
   Defaults to `release`.
 * `FLUTTER_TARGET`: The path to your `main.dart` relative to your
   `pubspec.yaml`. Defaults to `lib/main.dart`.
 * `FLUTTER_FRAMEWORK_DIR`: The absolute path to the directory that contains
   `Flutter.framework`. Defaults to the `ios-release` version of
   `Flutter.framework` in the `bin/cache` directory of the Flutter SDK.

### Build

Once you've configured your project, you can open `ios/HelloServices.xcodeproj`
in Xcode and build the project as usual.

## Android

### Configure

Create an `android/local.properties` file with these entries:

 * `sdk.dir=[path to the Android SDK]`
 * `flutter.sdk=[path to the Flutter SDK]`

There are a number of other parameters you can control with this file:

 * `flutter.buildMode`: Whether to build for `debug`, `profile`, or `release`.
   Defaults to `release`.
 * `flutter.jar`: The path to `flutter.jar`. Defaults to the
   `android-arm-release` version of `flutter.jar` in the `bin/cache` directory
   of the Flutter SDK.

See `android/app/build.gradle` for project specific settings, including:

 * `source`: The path to the directory that contains your `pubspec.yaml` file
   relative to your `build.gradle` file.
 * `target`: The path to your `main.dart` relative to your `pubspec.yaml`.
   Defaults to `lib/main.dart`.

### Build

To build directly with `gradle`, use the following commands:

 * `cd android`
 * `gradle wrapper`
 * `./gradlew build`

To build with Android Studio, open the `android` folder in Android Studio and
build the project as usual.
