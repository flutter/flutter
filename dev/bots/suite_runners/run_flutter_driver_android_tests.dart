// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as path;
import '../run_command.dart';
import '../utils.dart';

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
/// individually _in_ the `dev/integration_tests/native_driver_test` directory.
Future<void> runFlutterDriverAndroidTests() async {
  final String? crashreport = _findCrashReportTool();
  print('Running Flutter Driver Android tests...');

  await _runFlutterDriver(
    entrypoint: 'lib/flutter_rendered_blue_rectangle_main.dart',
    crashreport: crashreport,
  );
  await _runFlutterDriver(
    entrypoint: 'lib/platform_view_blue_orange_gradient_main.dart',
    crashreport: crashreport,
  );
  await _runFlutterDriver(
    entrypoint: 'lib/external_texture_smiley_face_main.dart',
    crashreport: crashreport,
  );
}

Future<void> _runFlutterDriver({
  required String entrypoint,
  required String? crashreport,
}) async {
  bool failed = false;
  try {
    final CommandResult result = await runCommand(
      'flutter',
      <String>[
        'drive',
        entrypoint,
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
        'native_driver_test',
      ),
    );
    if (result.exitCode != 0) {
      failed = true;
    }
  } catch (e) {
    failed = true;
  }
  if (failed) {
    if (crashreport == null) {
      print('Failed to run Flutter Driver test. No crash report tool found.');
      return;
    }
    final CommandResult resultL = await runCommand(crashreport, <String>['-l']);
    if (resultL.exitCode != 0) {
      print('Failed to run crash report tool: ${resultL.flattenedStderr}');
      return;
    }
    if (resultL.flattenedStdout?.isEmpty ?? true) {
      print('No crash reports found');
      return;
    } else {
      print('Crash reports found:');
      print(resultL.flattenedStdout);
    }
    final CommandResult resultU = await runCommand(crashreport, <String>['-u']);
    if (resultU.exitCode != 0) {
      print('Failed to upload crash reports: ${resultU.flattenedStderr}');
      return;
    }
    if (resultU.flattenedStdout?.isEmpty ?? true) {
      print('No crash reports uploaded');
    } else {
      print('Crash reports uploaded:');
      print(resultU.flattenedStdout);
    }
  }
}

String? _findCrashReportTool() {
  final String executable;
  if (isLuci) {
    // On CI, the full path looks something like this:
    // /b/s/w/ir/cache/avd/src/.android_emulator/android_35_google_apis_x64/emulator/crashreport
    //
    // To programatically reconstruct it, we use two environment variables:
    // "EMULATOR_VERSION" which looks like "android_35_google_apis_x64.textpb"
    // "AVD_ROOT" which looks like "/b/s/w/ir/cache/avd"
    //
    // This is still somewhat fragile, but it's the best we can do.
    final String? emulatorVersion = io.Platform.environment['EMULATOR_VERSION'];
    if (emulatorVersion == null) {
      print('EMULATOR_VERSION is not set');
      return null;
    }
    final String? avdRoot = io.Platform.environment['AVD_ROOT'];
    if (avdRoot == null) {
      print('AVD_ROOT is not set');
      return null;
    }

    final String emulatorName = path.basenameWithoutExtension(emulatorVersion);
    executable = path.join(
      avdRoot,
      'src',
      '.android_emulator',
      emulatorName,
      'emulator',
      'crashreport',
    );
  } else if (io.Platform.environment['ANDROID_HOME'] case final String androidHome) {
    executable = path.join(
      androidHome,
      'emulator',
      'crashreport',
    );
  } else if (io.Platform.isMacOS) {
    executable = path.join(
      io.Platform.environment['HOME']!,
      'Library',
      'Android',
      'sdk',
      'emulator',
      'crashreport',
    );
  } else if (io.Platform.isWindows) {
    executable = path.join(
      io.Platform.environment['LOCALAPPDATA']!,
      'Android',
      'Sdk',
      'emulator',
      'crashreport',
    );
  } else if (io.Platform.isLinux) {
    executable = path.join(
      io.Platform.environment['HOME']!,
      'Android',
      'Sdk',
      'emulator',
      'crashreport',
    );
  } else {
    throw UnsupportedError(
      'Unsupported platform: ${io.Platform.operatingSystem}',
    );
  }
  final io.File file = io.File(executable);
  if (!file.existsSync()) {
    return null;
  }
  return executable;
}
