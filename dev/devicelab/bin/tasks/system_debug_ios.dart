// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

import 'service_extensions_test.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(() async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final String deviceId = device.deviceId;

    final Directory testDirectory =
        dir('${flutterDirectory.path}/dev/integration_tests/ui');
    await inDirectory<void>(testDirectory, () async {
      await flutter('packages', options: <String>['get']);

      await checkNoWarningHostLaunch(deviceId);
      await checkNoWarningXcodeLaunch(deviceId);
      await checkWarningHomeScreenLaunch(deviceId);
    });
    return TaskResult.success(<String, dynamic>{});
  });
}

const String expectedWarning =
    'Launching a debug-mode app from the home screen may cause problems.';

// When a debug-mode app is launched from the host there should be no warnings.
Future<void> checkNoWarningHostLaunch(String deviceId) async {
  final String output = await evalFlutter('drive', options: <String>[
    '--debug',
    '--verbose',
    '--verbose-system-logs',
    '-d',
    deviceId,
    'lib/empty.dart',
  ]);

  expect(!output.contains(expectedWarning));
}

// When a debug-mode app is launched from Xcode there should be no warnings. The
// Xcode launch is simulated by keeping LLDB attached throughout the lifetime of
// the app.
Future<void> checkNoWarningXcodeLaunch(String deviceId) async {
  await flutter('build',
      options: <String>['ios', '--debug', '--verbose', 'lib/exit.dart']);

  final String output = await eval(
      '${flutterDirectory.path}/bin/cache/artifacts/ios-deploy/ios-deploy',
      <String>[
        '--bundle',
        'build/ios/iphoneos/Runner.app',
        '-d', // Actually start the app in LLDB, don't just install it.
        '--noninteractive',
        '--args',
        '--verbose-logging',
      ]);

  expect(output.contains('success') && !output.contains(expectedWarning));
}

// When a debug-mode app is launched from the home screen there should be a
// warning every ~100 launches. We lower the threshold from to 1 via
// "--verbose-system-logs" and simulate a home-screen-launch by setting an
// environment variable. The environment variable forces "flutter drive" to not
// pass a flag which it normally passes to debug-mode apps, imitating launchd,
// which doesn't pass any command-line flags.
Future<void> checkWarningHomeScreenLaunch(String deviceId) async {
  final String output = await evalFlutter('drive', options: <String>[
    '--debug',
    '--verbose',
    '--verbose-system-logs',
    '-d',
    deviceId,
    'lib/empty.dart',
  ], environment: <String, String>{
    'FLUTTER_TOOLS_DEBUG_WITHOUT_CHECKED_MODE': 'true',
  });
  expect(output.contains(expectedWarning));
}