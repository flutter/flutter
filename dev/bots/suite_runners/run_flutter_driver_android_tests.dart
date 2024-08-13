// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart' as path;
import '../run_command.dart';
import '../utils.dart';

final int _defaultTestRepeatTimes = () {
  final String? envTimes = io.Platform.environment['TEST_REPEAT'];
  return envTimes == null ? 1 : int.tryParse(envTimes) ?? 1;
}();

/// To run this test locally:
///
/// 1. Connect an Android device or emulator.
/// 2. Run the following command from the root of the Flutter repository:
///
/// ```sh
/// SHARD=flutter_driver_android bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// ```
///
/// For debugging, it is recommended to instead just run and launch these tests
/// individually _in_ the `dev/integration_tests/android_driver_test` directory.
Future<void> runFlutterDriverAndroidTests({int? times}) async {
  times ??= _defaultTestRepeatTimes;
  if (times > 1) {
    print('Running Flutter Driver Android tests $times times...');
  }

  try {
    for (int i = 0; i < times; i++) {
      await _runFlutterDriverAndroidTests();
    }
  } on io.ProcessException catch (e) {
    print('Failed to run Flutter Driver Android tests: $e');
    print('Trying to fetch Android emulator crash logs...');
    await _writeAndroidEmulatorCrashLogs();
  }
}

Future<void> _writeAndroidEmulatorCrashLogs() async {
  // Try finding the `crashreport` tool.
  // i.e. ~/Android/Sdk/platform-tools/crashreport
  String? androidSdkRoot = io.Platform.environment['ANDROID_HOME'];
  androidSdkRoot ??= io.Platform.environment['ANDROID_SDK_ROOT'];
  if (androidSdkRoot == null) {
    print('Failed to find Android SDK root. Try setting ANDROID_HOME.');
    return;
  }

  final String crashReportPath = path.join(
    androidSdkRoot,
    'emulator',
    'crashreport',
  );

  // Run crashreport -l to list crash logs.
  final io.ProcessResult result = await io.Process.run(
    crashReportPath,
    <String>[
      '-u',
    ],
  );
  if (result.exitCode != 0) {
    print('Failed to list crash logs: ${result.stderr}');
    return;
  }

  print('Crash logs:');
  print(result.stdout);
  print(result.stderr);
}

Future<void> _runFlutterDriverAndroidTests() async {
  print('Running Flutter Driver Android tests...');

  // Print out the results of `adb devices`, for uh, science:
  print('Listing devices...');
  final io.ProcessResult devices = await _adb(
    <String>[
      'devices',
    ],
  );
  print(devices.stdout);
  print(devices.stderr);

  // We need to configure the emulator to disable confirmations before the
  // application starts. Some of these configuration options won't work once
  // the application is running.
  print('Configuring device...');
  await _configureForScreenshotTesting();

  // TODO(matanlurey): Should we be using another instrumentation method?
  await runCommand(
    'flutter',
    <String>[
      'drive',
      '--verbose',
      // There are no reason to enable development flags for this test.
      // Disable them to work around flakiness issues, and in general just
      // make less things start up unnecessarily.
      '--no-dds',
      '--no-enable-dart-profiling',
      '--test-arguments=test',
      '--test-arguments=--reporter=expanded',
    ],
    workingDirectory: path.join(
      'dev',
      'integration_tests',
      'android_driver_test',
    ),
  );
}

// TODO(matanlurey): Move this code into flutter_driver instead of here.
Future<void> _configureForScreenshotTesting() async {
  // Disable confirmation for immersive mode.
  final io.ProcessResult immersive = await _adb(
    <String>[
      'shell',
      'settings',
      'put',
      'secure',
      'immersive_mode_confirmations',
      'confirmed',
    ],
  );

  if (immersive.exitCode != 0) {
    throw StateError('Failed to configure device: ${immersive.stderr}');
  }

  const Map<String, String> settings = <String, String>{
    'show_surface_updates': '1',
    'transition_animation_scale': '0',
    'window_animation_scale': '0',
    'animator_duration_scale': '0',
  };

  for (final MapEntry<String, String> entry in settings.entries) {
    final io.ProcessResult result = await _adb(
      <String>[
        'shell',
        'settings',
        'put',
        'global',
        entry.key,
        entry.value,
      ],
    );

    if (result.exitCode != 0) {
      throw StateError('Failed to configure device: ${result.stderr}');
    }
  }
}

Future<io.ProcessResult> _adb(
  List<String> args, {
  Encoding? stdoutEncoding = io.systemEncoding,
}) {
  // TODO(matanlurey): Ideally we should specify the device target here.
  return io.Process.run(
    'adb',
    <String>[
      ...args,
    ],
    stdoutEncoding: stdoutEncoding,
  );
}
