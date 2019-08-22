# Scenario App

This folder contains a dart:ui application and scripts to compile it to JIT or
AOT for exercising embedders.

It intentionally has no dependencies on the Flutter framework or tooling, such
that it should be buildable as a presubmit or postsubmit to the engine even in
the face of changes to Dart or dart:ui that require upstream changes in the
Flutter tooling.

To add a new scenario, create a new subclass of `Scenario` and add it to the
map in `main.dart`. For an example, see animated_color_square.dart, which draws
a continuously animating colored square that bounces off the sides of the
viewport.

## Building for iOS

In this folder, after building the `ios_host` and `ios_profile` engine targets,
run:

```bash
./compile_ios_aot.sh ../../../out/host_profile ../../../out/ios_profile/clang_x64/
```

This will create an `App.framework` copy it as well as the correct
`Flutter.framework` to where the Xcode project expects to find them.

You can then use `xcodebuild` to build the `ios/Scenarios/Scenarios.xcodeproj`,
or open that in Xcode and build it that way.

Compiling to JIT mode is similar, using the `compile_ios_jit.sh` script.

## Building for Android

In this folder, after building the `host_profile` and `android_profile_arm64`
engine targets, run:

```bash
./compile_android_aot.sh ../../../out/host_profile ../../../out/android_profile_arm64/clang_x64/
```

This will produce a suitable `libapp.so` for building with an Android app and
copy it (along with flutter.jar) to where Gradle will expect to find it to build
the app in the `android/` folder. The app can be run by opening it in Android
Studio and running it, or by running `./gradlew assemble` in the `android/`
folder and installing the APK from the correct folder in
`android/app/build/outputs/apk`.
