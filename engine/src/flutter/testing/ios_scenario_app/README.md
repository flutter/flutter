# Scenario App

[![GitHub Issues or Pull Requests by label](https://img.shields.io/github/issues/flutter/flutter/e%3A%20scenario-app)](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22e%3A+scenario-app%22)

This package simulates a Flutter app that uses the engine (`dart:ui`) only,
in conjunction with iOS-specific embedding code that simulates the use of the
engine in a real app (such as plugins and platform views).

[`run_ios_tests.sh`](run_ios_tests.sh) is used to run the tests on a simulator.

See also:

- [File an issue][file_issue] with the `e: scenario-app` label.
- [`lib/`](lib/), the Dart code and instrumentation for the scenario app.
- [`ios/`](ios/), the iOS-side native code and tests.

[file_issue]: https://github.com/flutter/flutter/issues/new?labels=e:%20scenario-app,engine,team-ios

## Adding a New Scenario

Like a regular Flutter iOS app, the Scenario app consists of the [iOS embedding
code](ios/Scenarios/Scenarios/AppDelegate.m) and the dart logic that are
`Scenario`s.

To introduce a new subclass of [Scenario](lib/src/scenario.dart), add it to the map
in [scenarios.dart](lib/src/scenarios.dart). For an example,
[animated_color_square.dart](lib/src/animated_color_square.dart), which draws a
continuously animating colored square that bounces off the sides of the
viewport.

The Scenarios app loads a `Scenario` when it receives a `set_scenario` method call
on the `driver` platform channel from the objective-c code. However if you're
adding a UI test this is typically not needed as you typically should add a new
launch argument. See
[ScenariosUITests](ios/Scenarios/ScenariosUITests/README.md) for more details.

## Running a specific test

The `run_ios_tests.sh` script runs all tests in the `Scenarios` project. If you're
debugging a specific test, rebuild the `ios_debug_sim_unopt_arm64` engine variant
(assuming testing on a simulator on Apple Silicon chips), and open
`src/out/ios_debug_sim_unopt_arm64/ios_scenario_app/Scenarios.xcworkspace` in xcode.
Use the xcode UI to run the test.
