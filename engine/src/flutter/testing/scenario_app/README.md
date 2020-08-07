# Scenario App

This folder contains e2e integration tests for the engine in conjunction with a
fake dart:ui framework running in JIT or AOT.

It intentionally has no dependencies on the Flutter framework or tooling, such
that it should be buildable as a presubmit or postsubmit to the engine even in
the face of changes to Dart or dart:ui that require upstream changes in the
Flutter tooling.

## Adding a New Scenario

Create a new subclass of [Scenario](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/lib/src/scenario.dart#L9)
and add it to the map in [main.dart](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/lib/main.dart#L17).
For an example, see [animated_color_square.dart](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/lib/src/animated_color_square.dart#L15),
which draws a continuously animating colored square that bounces off the sides
of the viewport.

Then set the scenario from the Android or iOS app by calling "set_scenario" on
platform channel.

## Running for iOS

```sh
./build_and_run_ios_tests.sh
```

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

## Running for Android

The test is run on a x86 emulator. To run the test locally, you must create an emulator running API level 28, and set the following screen settings in the avd's `config.ini` file:

```
hw.lcd.density = 480
hw.lcd.height = 1920
hw.lcd.width = 1080
```

This file is typically located in your `$HOME/.android/avd/<avd>` folder.

Once the emulator is up, you can run the test by running:

```bash
./build_and_run_android_tests.sh
```

### Generating Golden Images on Android

In the `android` directory, run:

```bash
./gradlew app:recordDebugAndroidTestScreenshotTest
```

The screenshots are recorded into `android/reports/screenshots`.

### Verifying Golden Images on Android

In the `android` directory, run:

```bash
./gradlew app:verifyDebugAndroidTestScreenshotTest
```

## Changing dart:ui code

If you change the dart:ui interface, remember to point the sky_engine and
sky_services clauses to your local engine's output path before compiling.