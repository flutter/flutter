// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;
import '../run_command.dart';
import '../utils.dart';

Future<void> runFlutterDriverAndroidTests() async {
  print('Running Flutter Driver Android tests...');

  // TODO(matanlurey): Should we be using another instrumentation method?
  await runCommand(
    'flutter',
    <String>[
      'drive',
    ],
    workingDirectory: path.join(
      'dev',
      'integration_tests',
      'android_driver_test',
    ),
  );
}
