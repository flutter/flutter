# Example of using FlutterView in an iOS app.

This project demonstrates how to embed Flutter within an iOS application
and build the iOS and Flutter components with Xcode.

## Configure

Create an `ios/Flutter/Generated.xcconfig` file with this entry:

  * `FLUTTER_ROOT=[absolute path to the Flutter SDK]`

There are a number of other parameters you can control with this file:

  * `FLUTTER_APPLICATION_PATH`: The path that contains your `pubspec.yaml` file
     relative to your `xcodeproj` file.
  * `FLUTTER_TARGET`: The path to your `main.dart` relative to your
     `pubspec.yaml`. Defaults to `lib/main.dart`.
  * `FLUTTER_FRAMEWORK_DIR`: The absolute path to the directory that contains
    `Flutter.framework`. Defaults to the `ios-release` version of
    `Flutter.framework` in the `bin/cache` directory of the Flutter SDK.

## Build

Once you've configured your project, you can open `ios/HelloServices.xcodeproj`
in Xcode and build the project as usual.
