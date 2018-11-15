// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
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
    extraOptions: <String>['--flavor', 'paid']
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

TaskFunction createEmbeddedAndroidViewsIntegrationTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/android_views',
    'lib/main.dart',
  );
}

TaskFunction createAndroidSemanticsIntegrationTest() {
  return DriverTest(
    '${flutterDirectory.path}/dev/integration_tests/android_semantics_testing',
    'lib/main.dart',
  );
}

TaskFunction createFlutterCreateOfflineTest() {
  return () async {
    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_create_test.');
    String output;
    await inDirectory(tempDir, () async {
      output = await eval(path.join(flutterDirectory.path, 'bin', 'flutter'), <String>['create', '--offline', 'flutter_create_test']);
    });
    if (output.contains(RegExp('building flutter tool', caseSensitive: false))) {
      return TaskResult.failure('`flutter create --offline` should not rebuild flutter tool');
    } else if (!output.contains('All done!')) {
      return TaskResult.failure('`flutter create` failed');
    }
    return TaskResult.success(null);
  };
}

class DriverTest {

  DriverTest(
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

      if (deviceOperatingSystem == DeviceOperatingSystem.ios)
        await prepareProvisioningCertificates(testDirectory);
      final List<String> options = <String>[
        '-v',
        '-t',
        testTarget,
        '-d',
        deviceId,
      ];
      options.addAll(extraOptions);
      await flutter('drive', options: options);

      return TaskResult.success(null);
    });
  }
}
