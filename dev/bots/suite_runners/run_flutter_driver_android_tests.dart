// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;
import '../run_command.dart';
import '../utils.dart';

/// To run this test locally:
///
/// 1. Connect an Android device or emulator.
/// 2. Run `dart pub get` in dev/bots
/// 3. Run the following command from the root of the Flutter repository:
///
/// ```sh
/// SHARD=flutter_driver_android bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// ```
///
/// For debugging, you need to instead run and launch these tests
/// individually _in_ the `dev/integration_tests/native_driver_test` directory.
/// Comparisons against goldens cant happen locally.
Future<void> runFlutterDriverAndroidTests() async {
  print('Running Flutter Driver Android tests...');

  await runCommand(
    'flutter',
    <String>[
      'drive',
      'lib/flutter_rendered_blue_rectangle_main.dart',
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

  await runCommand(
    'flutter',
    <String>[
      'drive',
      'lib/platform_view_blue_orange_gradient_main.dart',
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

  await runCommand(
    'flutter',
    <String>[
      'drive',
      'lib/external_texture_smiley_face_main.dart',
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

  // A simulated cutout overlay is necessary to test display_cutout_rotation.
  // Using adb to enable a cutout overlay once the test app is running breaks
  // the connection with FlutterDriver; therefore, this setting must be set
  // before `flutter drive` is executed.
  await runCommand(
    'adb',
    <String>[
      'shell',
      'settings',
      'put',
      'global',
      'development_settings_enabled',
      '1',
    ],
  );
  await runCommand(
    'adb',
    <String>[
      'shell',
      'cmd',
      'overlay',
      'enable',
      'com.android.internal.display.cutout.emulation.tall',
    ],
  );
  await runCommand(
    'flutter',
    <String>[
      'drive',
      'lib/display_cutout_rotation_main.dart',
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
}
