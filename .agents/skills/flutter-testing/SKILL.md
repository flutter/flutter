---
name: flutter-testing
description: >-
  Guides on how to run, write, and configure tests in the Flutter (Framework and Engine) repositories.
  Similar to a testing cheatsheet for Flutter contributors.
  Use when needing to run unit tests, integration tests, or engine tests locally, or when adding a new test to the CI (LUCI) configuration.
  Don't use for general Dart package testing outside the Flutter repositories.
---

# Flutter Testing Guide (Monorepo)

This skill helps you run, write, and configure tests in the Flutter monorepo, which contains both the **Framework** and the **Engine** code.

---

## Repository Structure (Monorepo)

The `flutter/flutter` and `flutter/engine` repositories are merged into a single monorepo:
- **Repository Root**: The base directory of the cloned repository.
- **Framework Code**: Located at the root (e.g., `packages/flutter`, `examples/`).
- **Engine Code**: Located under the **`engine/src/flutter`** directory.
- **Engine Build Output**: Located under **`engine/src/out`**.

---

## 1. Framework Tests (`packages/flutter`, `examples/`)

### Unit Tests
Dart unit tests are located in the `test/` subdirectory of the package under test (written using the `flutter_test` package).

*   **Run all tests in a package**:
    Navigate to the package directory and run `flutter test`.
    ```bash
    cd examples/hello_world
    flutter test
    ```
*   **Run a specific test file**:
    ```bash
    flutter test lib/my_app_test.dart
    ```
*   **Simulate CI tests locally** (run from repository root):
    ```bash
    # Run all tests
    dart dev/bots/test.dart
    # Run static analysis
    dart --enable-asserts dev/bots/analyze.dart
    ```

### Golden File Tests (Widget Level)
Golden file tests compare the rendered pixels of a widget against a master baseline image using **Skia Gold** (`flutter-gold.skia.org`) on the host machine.

*   **Writing a Golden Test**:
    1.  Add the `reduced-test-set` tag at the very top of your test file (so it runs on Mac/Windows CI pre-submit):
        ```dart
        @Tags(<String>['reduced-test-set'])
        ```
    2.  Wrap the widget subtree you want to capture in a **`RepaintBoundary`** (otherwise it captures the full 2400x1800 viewport):
        ```dart
        await tester.pumpWidget(
          const RepaintBoundary(
            child: MyWidget(),
          ),
        );
        ```
    3.  Assert using `matchesGoldenFile`. Use the format `test_filename.subtest.png`:
        ```dart
        await expectLater(
          find.byType(RepaintBoundary),
          matchesGoldenFile('my_widget_test.basic.png'),
        );
        ```
*   **Running/Updating Goldens Locally**:
    Navigate to the package (e.g., `packages/flutter`) and run with the `--update-goldens` flag:
    ```bash
    flutter test --update-goldens test/widgets/my_widget_test.dart
    ```

---

## 2. Native Android Golden Tests (Engine/Embedder Level)

If you need to test **native Android features** (such as `SystemUiMode` which renders OS-level status/navigation bars, or Platform Views) with goldens, you must use the **`dev/integration_tests/android_engine_test`** package.

This package uses the custom **`android_driver_extensions`** tool to take real native screenshots of the OS screen via ADB and compare them using Skia Gold.

### Step 1: Create the App (`lib/my_test_main.dart`)
*   Use `ensureAndroidDevice()` and enable the native driver commands.
*   Implement a `handler` in `enableFlutterDriverExtension` to receive instructions from the driver script:
    ```dart
    import 'package:android_driver_extensions/extension.dart';
    import 'package:flutter_driver/driver_extension.dart';

    void main() async {
      ensureAndroidDevice();
      enableFlutterDriverExtension(
        commands: <CommandExtension>[nativeDriverCommands],
        handler: (String? message) async {
          if (message == 'trigger_action') {
            // Perform native operation (e.g. switch SystemUiMode)
            return 'ok';
          }
          return 'unknown';
        },
      );
      runApp(const MyVisualApp());
    }
    ```

### Step 2: Create the Driver (`test_driver/my_test_main_test.dart`)
*   Connect to `NativeDriver` and configure it for screenshots.
*   Trigger actions via `requestData` and assert screenshots using `matchesGoldenFile` from `android_driver_extensions`:
    ```dart
    import 'package:android_driver_extensions/native_driver.dart';
    import 'package:android_driver_extensions/skia_gold.dart';
    import 'package:flutter_driver/flutter_driver.dart';
    import 'package:test/test.dart';
    import '_luci_skia_gold_prelude.dart';

    void main() async {
      late final FlutterDriver flutterDriver;
      late final NativeDriver nativeDriver;

      setUpAll(() async {
        if (isLuci) {
          await enableSkiaGoldComparator(namePrefix: 'android_engine_test$goldenVariant');
        }
        flutterDriver = await FlutterDriver.connect();
        nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
        await nativeDriver.configureForScreenshotTesting();
        await flutterDriver.waitUntilFirstFrameRasterized();
      });

      test('should match native screenshot', () async {
        await flutterDriver.requestData('trigger_action');
        await Future<void>.delayed(const Duration(seconds: 1)); // Wait for native transition

        await expectLater(
          nativeDriver.screenshot(),
          matchesGoldenFile('my_test_action.png'),
        );
      });
    }
    ```

### How to Run Locally
1.  Connect an Android device/emulator.
2.  Generate/update baselines locally:
    ```bash
    UPDATE_GOLDENS=1 flutter drive lib/my_test_main.dart
    ```
3.  Verify against baselines:
    ```bash
    flutter drive lib/my_test_main.dart
    ```

### CI Integration (LUCI)
These tests are **automatically discovered** by the `run_android_engine_tests.dart` runner script in CI if they follow the `*_main.dart` naming convention in `dev/integration_tests/android_engine_test/lib/`. 
*   **No `.ci.yaml` modifications are required** for individual new test files in this package.

---

## 3. Integration Tests (`integration_test` package)

The `integration_test` package enables self-driving testing of Flutter code on devices and emulators.
*   **Run using `flutter drive`**:
    ```bash
    flutter drive \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/foo_test.dart
    ```

#### Capture Screenshots (Device screenshots) in Integration Tests
To take screenshots on a physical device/emulator and save them to the host machine (without automated Skia Gold comparison):

1.  **In your Integration Test** (`integration_test/my_test.dart`):
    ```dart
    final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    await binding.takeScreenshot('my_screenshot_name');
    ```
2.  **In your Custom Driver** (`test_driver/my_test.dart`):
    ```dart
    import 'dart:io';
    import 'package:integration_test/integration_test_driver_extended.dart';

    Future<void> main() async {
      await integrationDriver(
        onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final File image = File('screenshots/$name.png');
          image.writeAsBytesSync(bytes);
          return true;
        },
      );
    }
    ```

---

## 4. Where to Place New Integration Tests

When adding new integration tests, you have two primary locations in the monorepo:

### Option A: Add to the existing `integration_ui` package (Preferred for general UI/Framework tests)
The **`dev/integration_tests/ui`** directory is a shared testbed designed for multiple integration tests.
1.  Add App UI to `dev/integration_tests/ui/lib/my_test.dart`.
2.  Add Driver to `dev/integration_tests/ui/test_driver/my_test_test.dart`.
3.  Run: `flutter drive -t lib/my_test.dart --driver test_driver/my_test_test.dart`.

### Option B: Create a new integration test app (For complex or isolated scenarios)
If your test requires a highly specific Android configuration (e.g., custom Android Manifest, specific Gradle dependencies, or unique platform channels) that could conflict with other tests, create a new project directory under `dev/integration_tests/`.

---

## 5. Enabling New Tests in Continuous Integration (CI)

*(Only applicable for standalone tasks outside of automatically globbed packages like `android_engine_test`)*.

1.  **Create a DeviceLab Task File** under `dev/devicelab/bin/tasks/<name>.dart` that executes the test.
2.  **Configure the Target in `.ci.yaml`** under `targets:` with `bringup: true` (staging pool, non-blocking).
3.  **Assign Ownership in `TESTOWNERS`** mapping the task file to your GitHub handle and team.
4.  **Graduate the Test** by removing `bringup: true` from `.ci.yaml` once stable.

---

## 6. Engine Tests (`engine/src/flutter`)

All engine-specific tests must be run from the engine source directory: **`engine/src/flutter`**.

### C++ Core Engine Tests
*   **Run via Python runner**:
    ```bash
    cd engine/src/flutter
    testing/run_tests.py --type=engine
    ```
*   **Run GTest executables directly**:
    ```bash
    cd engine/src/flutter
    ../out/host_debug_unopt/shell_unittests --gtest_filter="ShellTest.WaitFor*"
    ```

### Android Java Embedder Tests (JUnit / Robolectric)
*   **Run Android JUnit/Robolectric tests** (requires `$JAVA_HOME` set to JDK v8):
    ```bash
    cd engine/src/flutter
    testing/run_tests.py --type=java
    ```

### iOS Objective-C Embedder Tests (XCTest)
*   **Run iOS XCTests**:
    ```bash
    cd engine/src/flutter
    testing/run_tests.py --type=objc
    ```

### Dart `dart:ui` Tests
*   **Run dart:ui tests**:
    ```bash
    cd engine/src/flutter
    testing/run_tests.py --type=dart
    ```

### Running Framework Tests with Local Engine Build
```bash
flutter test \
  --local-engine-src-path=engine/src \
  --local-engine=host_debug_unopt \
  --local-engine-host=host_debug_unopt \
  packages/flutter
```
