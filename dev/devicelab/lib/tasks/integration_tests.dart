// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import '../framework/adb.dart';
import '../framework/framework.dart';
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

TaskFunction createExternalUiIntegrationTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/external_ui',
    'lib/main.dart',
  );
}

TaskFunction createPlatformChannelSampleTest() {
  return DriverTest(
    '${flutterDirectory.path}/examples/platform_channel',
    'test_driver/button_tap.dart',
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

TaskFunction createCodegenerationIntegrationTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/codegen',
    'lib/main.dart',
  );
}

TaskFunction createImageLoadingIntegrationTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/image_loading',
    'lib/main.dart',
  );
}

TaskFunction createFlutterCreateOfflineTest() {
  return () async {
    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_create_test.');
    String output;
    // The default create template has an actual online dependency against
    // a pub package. Make sure it's available in pub cache first before
    // trying to resolve it offline.
    await inDirectory(tempDir, () async {
      output = await eval(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['pub', 'cache', 'add', 'cupertino_icons', '--version', '1.0.0'],
      );
    });
    await inDirectory(tempDir, () async {
      output = await eval(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['create', '--offline', 'flutter_create_test'],
      );
    });
    if (output.contains(RegExp('building flutter tool', caseSensitive: false))) {
      return TaskResult.failure('`flutter create --offline` should not rebuild flutter tool');
    } else if (!output.contains('All done!')) {
      return TaskResult.failure('`flutter create` failed');
    }
    return TaskResult.success(null);
  };
}

TaskFunction createAndroidSplashScreenKitchenSinkTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/android_splash_screens/splash_screen_kitchen_sink',
    'test_driver/main.dart',
  );
}

/// Executes a driver test that takes a screenshot and compares it against a golden image.
/// The golden image is served by Flutter Gold (https://flutter-gold.skia.org/).
TaskFunction createFlutterDriverScreenshotTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/flutter_driver_screenshot_test',
    'lib/main.dart',
  );
}

TaskFunction createIOSPlatformViewTests() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/ios_platform_view_tests',
    'lib/main.dart',
  );
}

class DriverTest {
  DriverTest(
    this.testDirectory,
    this.testTarget, {
      this.extraOptions = const <String>[],
      this.environment =  const <String, String>{},
    }
  );

  final String testDirectory;
  final String testTarget;
  final List<String> extraOptions;
  final Map<String, String> environment;

  Future<TaskResult> call() {
    return inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      final List<String> options = <String>[
        '-v',
        '-t',
        testTarget,
        '-d',
        deviceId,
        ...extraOptions,
      ];
      await flutter('drive', options: options, environment: Map<String, String>.from(environment));

      return TaskResult.success(null);
    });
  }
}
