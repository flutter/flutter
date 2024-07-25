// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;
import '../utils.dart';

Future<void> runFlutterDriverAndroidTests() async {
  print('Running Flutter Driver Android tests...');

  await runDartTest(
    path.join(flutterRoot, 'packages', 'flutter_driver'),
    testPaths: <String>[
      'test/src/native_tests/android',
    ],
  );
}
