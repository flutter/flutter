// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

TaskFunction createChannelsIntegrationTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/channels',
    'lib/main.dart',
  );
}

TaskFunction createPlatformInteractionTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/platform_interaction',
    'lib/main.dart',
  );
}

TaskFunction createFlavorsTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/flavors',
    'lib/main.dart',
    extraOptions: <String>['--flavor', 'paid'],
  );
}

TaskFunction createIntegrationTestFlavorsTest() {
  return IntegrationTest(
    '${flutterDirectory.path}/dev/integration_tests/flavors',
    'integration_test/integration_test.dart',
    extraOptions: <String>['--flavor', 'paid'],
  );
}

TaskFunction createExternalUiIntegrationTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/external_ui',
    'lib/main.dart',
  );
}

TaskFunction createPlatformChannelSampleTest({String? deviceIdOverride}) {
  return DriverTest(
    '${flutterDirectory.path}/examples/platform_channel',
    'test_driver/button_tap.dart',
    deviceIdOverride: deviceIdOverride,
  );
}

TaskFunction createPlatformChannelSwiftSampleTest() {
  return DriverTest(
    '${flutterDirectory.path}/examples/platform_channel_swift',
    'test_driver/button_tap.dart',
  );
}

TaskFunction createEmbeddedAndroidViewsIntegrationTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/android_views',
    'lib/main.dart',
  );
}

TaskFunction createHybridAndroidViewsIntegrationTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/hybrid_android_views',
    'lib/main.dart',
  );
}

TaskFunction createAndroidSemanticsIntegrationTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/android_semantics_testing',
    'lib/main.dart',
  );
}

TaskFunction createIOSPlatformViewTests() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/ios_platform_view_tests',
    'lib/main.dart',
    extraOptions: <String>[
      '--dart-define=ENABLE_DRIVER_EXTENSION=true',
    ],
  );
}

TaskFunction createEndToEndKeyboardTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/ui',
    'lib/keyboard_resize.dart',
  );
}

TaskFunction createEndToEndFrameNumberTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/ui',
    'lib/frame_number.dart',
  );
}

TaskFunction createEndToEndDriverTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/ui',
    'lib/driver.dart',
  );
}

TaskFunction createEndToEndScreenshotTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/ui',
    'lib/screenshot.dart',
  );
}

TaskFunction createEndToEndKeyboardTextfieldTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/ui',
    'lib/keyboard_textfield.dart',
  );
}

TaskFunction dartDefinesTask() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/ui',
    'lib/defines.dart', extraOptions: <String>[
    '--dart-define=test.valueA=Example,A',
    '--dart-define=test.valueB=Value',
    ],
  );
}

TaskFunction createEndToEndIntegrationTest() {
  return IntegrationTest(
    '${flutterDirectory.path}/dev/integration_tests/ui',
    'integration_test/integration_test.dart',
  );
}

TaskFunction createSpellCheckIntegrationTest() {
  return IntegrationTest(
    '${flutterDirectory.path}/dev/integration_tests/spell_check',
    'integration_test/integration_test.dart',
  );
}

TaskFunction createWindowsStartupDriverTest({String? deviceIdOverride}) {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/windows_startup_test',
    'lib/main.dart',
    deviceIdOverride: deviceIdOverride,
  );
}

class DriverTest {
  DriverTest(
    this.testDirectory,
    this.testTarget, {
      this.extraOptions = const <String>[],
      this.deviceIdOverride,
    }
  );

  final String testDirectory;
  final String testTarget;
  final List<String> extraOptions;
  final String? deviceIdOverride;

  Future<TaskResult> call() {
    return inDirectory<TaskResult>(testDirectory, () async {
      String deviceId;
      if (deviceIdOverride != null) {
        deviceId = deviceIdOverride!;
      } else {
        final Device device = await devices.workingDevice;
        await device.unlock();
        deviceId = device.deviceId;
      }
      await flutter('packages', options: <String>['get']);

      final List<String> options = <String>[
        '--no-android-gradle-daemon',
        '-v',
        '-t',
        testTarget,
        '-d',
        deviceId,
        ...extraOptions,
      ];
      await flutter('drive', options: options);

      return TaskResult.success(null);
    });
  }
}

class IntegrationTest {
  IntegrationTest(
    this.testDirectory,
    this.testTarget, {
      this.extraOptions = const <String>[],
    }
  );

  final String testDirectory;
  final String testTarget;
  final List<String> extraOptions;

  Future<TaskResult> call() {
    return inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      final List<String> options = <String>[
        '-v',
        '-d',
        deviceId,
        testTarget,
        ...extraOptions,
      ];
      await flutter('test', options: options);

      return TaskResult.success(null);
    });
  }
}
