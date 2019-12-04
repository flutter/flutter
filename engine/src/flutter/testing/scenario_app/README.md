# Scenario App

This folder contains a dart:ui application and scripts to compile it to JIT or
AOT for exercising embedders.

It intentionally has no dependencies on the Flutter framework or tooling, such
that it should be buildable as a presubmit or postsubmit to the engine even in
the face of changes to Dart or dart:ui that require upstream changes in the
Flutter tooling.

## Running for iOS

```sh
cd ${ENGINE_REPO}/..
gclient sync
./flutter/tools/gn --unoptimized --runtime-mode debug --simulator --ios
ninja -C out/ios_debug_sim_unopt
cd ${ENGINE_REPO}/testing/scenario_app
./run_ios_tests.sh
```

## Adding a New Scenario

Create a new subclass of [Scenario](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/lib/src/scenario.dart#L9) and add it to the
map in [main.dart](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/lib/main.dart#L17). For an example, see [animated_color_square.dart](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/lib/src/animated_color_square.dart#L15), which draws
a continuously animating colored square that bounces off the sides of the
viewport.

### iOS Platform View Tests

For PlatformView tests on iOS, you'll also have to edit the dictionaries in
[AppDelegate.m](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/ios/Scenarios/Scenarios/AppDelegate.m#L29) and [PlatformViewGoldenTestManager.m](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/ios/Scenarios/ScenariosUITests/PlatformViewGoldenTestManager.m#L24) so that the correct golden image can be found.  Also, you'll have to add a [GoldenPlatformViewTests](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/ios/Scenarios/ScenariosUITests/GoldenPlatformViewTests.h#L18) in [PlatformViewUITests.m](https://github.com/flutter/engine/blob/af2ffc02b72af2a89242ca3c89e18269b1584ce5/testing/scenario_app/ios/Scenarios/ScenariosUITests/PlatformViewUITests.m).

### Generating Golden Images on iOS

Screenshots are saved as
[XCTAttachment](https://developer.apple.com/documentation/xctest/activities_and_attachments/adding_attachments_to_tests_and_activities?language=objc)'s.
If you look at the output from running the tests you'll find a path in the form:
`/Users/$USER/Library/Developer/Xcode/DerivedData/Scenarios-$HASH`.
Inside that directory you'll find
`./Build/Products/Debug-iphonesimulator/ScenariosUITests-Runner.app/PlugIns/ScenariosUITests.xctest/` which is where all the images that were
compared against golden reside.

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

## Changing dart:ui code

If you change the dart:ui interface, remember to point the sky_engine and
sky_services clauses to your local engine's output path before compiling.