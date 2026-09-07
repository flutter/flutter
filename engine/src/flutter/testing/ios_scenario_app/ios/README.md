# Scenario App: iOS Tests

As mentioned in the [top-level README](../README.md), this directory contains
the iOS-specific native code and tests for the [scenario app](../lib). To run
the tests, you will need to build the engine with the appropriate configuration.

For example, after building `ios_debug_sim_unopt` (to run on Intel Macs) or `ios_debug_sim_unopt_arm64` (to run on ARM Macs),
run:

```sh
$ engine/src/flutter/testing/ios_scenario_app/run_ios_tests.sh ios_debug_sim_unopt
```

or:

```sh
$ engine/src/flutter/testing/ios_scenario_app/run_ios_tests.sh ios_debug_sim_unopt_arm64
```

The paths above are relative to the root of the checkout, but the script
resolves everything from its own location, so it can be run from any directory.

To run or debug in Xcode, open the xcodeproj file located in
`<engine_out_dir>/ios_debug_sim_unopt/ios_scenario_app/Scenarios/Scenarios.xcodeproj`.

## CI Configuration

See [`ci/builders/mac_unopt.json`](../../../../ci/builders/mac_unopt.json), and
grep for `run_ios_tests.sh`.

## iOS Platform View Tests

For PlatformView tests on iOS, register the scenario in
[scenarios.dart](../lib/src/scenarios.dart) and add its launch argument to
`scenarioArguments` in
[SceneDelegate.m](Scenarios/Scenarios/SceneDelegate.m). The golden identifier
is derived from the launch argument -- drop the leading `--` and swap `-` for
`_` -- so it does not need to be registered anywhere else. Also, add a
[GoldenPlatformViewTests](Scenarios/ScenariosUITests/GoldenPlatformViewTests.h)
in [PlatformViewUITests.m](Scenarios/ScenariosUITests/PlatformViewUITests.m).

If `PlatformViewRotation` is failing, make sure
`Simulator app Device > Rotate Device Automatically` is selected, or run:

```bash
defaults write com.apple.iphonesimulator RotateWindowWhenSignaledByGuest -int 1
```

## Generating Golden Images on iOS

Screenshots are saved as
[XCTAttachment](https://developer.apple.com/documentation/xctest/activities_and_attachments/adding_attachments_to_tests_and_activities?language=objc)'s.

A path in the form of
`/Users/$USER/Library/Developer/Xcode/DerivedData/Scenarios-$HASH` will be
printed to the console.

Inside that directory there is a directory
`./Build/Products/Debug-iphonesimulator/ScenariosUITests-Runner.app/PlugIns/ScenariosUITests.xctest/`
which is where all the images that were compared against golden reside.
