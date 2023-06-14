# Scenario App

This folder contains e2e integration tests for the engine in conjunction with a
fake dart:ui framework running in JIT or AOT.

It intentionally has no dependencies on the Flutter framework or tooling, such
that it should be buildable as a presubmit or postsubmit to the engine even in
the face of changes to Dart or dart:ui that require upstream changes in the
Flutter tooling.

## Adding a New Scenario

Create a new subclass of [Scenario](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/lib/src/scenario.dart#L9)
and add it to the map in [scenarios.dart](https://github.com/flutter/engine/blob/db4d423ad9c6dad373618712690acd06b0a385fd/testing/scenario_app/lib/src/scenarios.dart#L22).
For an example, see [animated_color_square.dart](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/lib/src/animated_color_square.dart#L15),
which draws a continuously animating colored square that bounces off the sides
of the viewport.

Then set the scenario from the Android or iOS app by calling "set_scenario" on
platform channel.

## Running for iOS

Build the `ios_debug_sim_unopt` engine variant, and run

```sh
./run_ios_tests.sh
```

in your shell.

To run or debug in Xcode, open the xcodeproj file located in
`<engine_out_dir>/ios_debug_sim_unopt/scenario_app/Scenarios/Scenarios.xcodeproj`.

### iOS Platform View Tests

For PlatformView tests on iOS, you'll also have to edit the dictionaries in
[AppDelegate.m](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/ios/Scenarios/Scenarios/AppDelegate.m#L29) and [GoldenTestManager.m](https://github.com/flutter/engine/blob/db4d423ad9c6dad373618712690acd06b0a385fd/testing/scenario_app/ios/Scenarios/ScenariosUITests/GoldenTestManager.m#L25) so that the correct golden image can be found.  Also, you'll have to add a [GoldenPlatformViewTests](https://github.com/flutter/engine/blob/5d9509ae056b04c30295df27f201f31af9777842/testing/scenario_app/ios/Scenarios/ScenariosUITests/GoldenPlatformViewTests.h#L18) in [PlatformViewUITests.m](https://github.com/flutter/engine/blob/af2ffc02b72af2a89242ca3c89e18269b1584ce5/testing/scenario_app/ios/Scenarios/ScenariosUITests/PlatformViewUITests.m).

If `PlatformViewRotation` is failing, make sure Simulator app Device > Rotate Device Automatically
is selected, or run:

```bash
defaults write com.apple.iphonesimulator RotateWindowWhenSignaledByGuest -int 1
```

### Generating Golden Images on iOS

Screenshots are saved as
[XCTAttachment](https://developer.apple.com/documentation/xctest/activities_and_attachments/adding_attachments_to_tests_and_activities?language=objc)'s.
If you look at the output from running the tests you'll find a path in the form:
`/Users/$USER/Library/Developer/Xcode/DerivedData/Scenarios-$HASH`.
Inside that directory you'll find
`./Build/Products/Debug-iphonesimulator/ScenariosUITests-Runner.app/PlugIns/ScenariosUITests.xctest/` which is where all the images that were
compared against golden reside.

## Running for Android

### Integration tests

For emulators running on a x64 host, build `android_debug_unopt_x64` using
`./tools/gn --android --unoptimized --goma --android-cpu=x64`.

Then, launch the emulator, and run `./testing/scenario_app/run_android_tests.sh android_debug_unopt_x64`.

If you wish to build a different engine variant, make sure to pass that variant to the script `run_android_tests.sh`.

If you make a change to the source code, you would need to rebuild the same engine variant.

### Smoke test on FTL

To run the smoke test on Firebase TestLab test, build `android_profile_arm64`, and run
`./flutter/ci/firebase_testlab.py`. If you wish to test a different variant, e.g.
debug arm64, pass `--variant android_debug_arm64`.

### Updating Gradle dependencies

If a Gradle dependency is updated, lockfiles must be regenerated.

To generate new lockfiles, run:

```bash
cd android/app
../../../../../third_party/gradle/bin/gradle generateLockfiles
```
