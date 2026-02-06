# iOS Add-to-App UIScene Integration Test

This directory contains the assets and templates for an integration test that verifies the behavior of Flutter in an add-to-app scenario on iOS, specifically with regards to UIScene lifecycle events.

The test is located at `dev/devicelab/bin/tasks/module_uiscene_test_ios.dart`.

## Purpose

This test ensures that Flutter behaves correctly when integrated into a native iOS application that uses UIScene for lifecycle management. It covers various scenarios, including:

*   The native app has migrated to UIScene, but the Flutter plugin has not.
*   Both the native app and the Flutter plugin have migrated to UIScene.
*   The native app has not migrated to UIScene, but the Flutter plugin has.
*   Neither the native app nor the Flutter plugin has migrated to UIScene.

The test checks whether the correct lifecycle events (e.g., scene-based or application-based) are sent to the Flutter plugin in each scenario.

## Directory Structure

*   `xcode_uikit_swift`: A template for a native iOS app using UIKit and Swift. This app acts as the host for the Flutter module.
*   `native`: Contains Swift files used to replace files in the `xcode_uikit_swift` template for different test scenarios. This includes different implementations of `AppDelegate.swift`, `SceneDelegate.swift`, `ViewController.swift`, and the UI tests that verify the lifecycle events.
*   `flutterapp`: Contains the `main.dart` and `pubspec.yaml` files for the Flutter module (`my_module`) used in the test.
*   `flutterplugin`: Contains the files for the Flutter plugin (`my_plugin`) used in the test, including different implementations for migrated and unmigrated lifecycle event handling.

Dart template files don't have a .dart extension so the analyzer will ignore them. They don't work on their own outside of the module, app, or plugin they're copied into.

## How to run the test

This test is intended to be run as a Flutter devicelab test. To run it locally, you can use the following command from the `flutter/dev/devicelab` directory:

```bash
../../bin/cache/dart-sdk/bin/dart bin/test_runner.dart test -t module_uiscene_test_ios
```

You can also run it with a local engine build:

```bash
../../bin/cache/dart-sdk/bin/dart bin/test_runner.dart test -t module_uiscene_test_ios --local-engine <your_local_engine> --local-engine-host host_debug
```

The test create the Flutter module, Flutter plugin, and native iOS app and deletes them at the end of the test. You can also create these files in a specific directory that will not be deleted:

```bash
../../bin/cache/dart-sdk/bin/dart bin/test_runner.dart test -t module_uiscene_test_ios --task-args destination=[/path/to/copy/destination]
```

## Adding a new scenario

To add a new test scenario, you need to modify the `scenarios` map in the `Scenarios` class in `dev/devicelab/bin/tasks/module_uiscene_test_ios.dart`.

Each scenario is defined by a list of `FileReplacements` that swap out files in the generated Xcode project with templates from this directory.

To add a new scenario:

1.  Add a new entry to the `scenarios` map. The key is the name of your new scenario.
2.  The value is a `List<FileReplacements>`. Each `FileReplacements` object takes a source template file and a destination path in the generated project.
3.  If your scenario requires new file content, add the new template files to the appropriate subdirectory (`native`, `flutterapp`, or `flutterplugin`).
4.  Reference these new template files in the `FileReplacements` for your new scenario.
