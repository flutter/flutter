// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
/// individually _in_ the `dev/integration_tests/android_driver_test` directory.
Future<void> runFlutterDriverAndroidTests() async {
  print('Running Flutter Driver Android tests...');

  // TODO(matanlurey): Should we be using another instrumentation method?
  await runCommand(
    'flutter',
    <String>[
      'drive',
      '--test-arguments=test',
    ],
    workingDirectory: path.join(
      'dev',
      'integration_tests',
      'android_driver_test',
    ),
  );
}
