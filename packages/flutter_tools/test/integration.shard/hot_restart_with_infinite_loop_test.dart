// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/infinite_loop_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  final InfiniteLoopProject project = InfiniteLoopProject();
  late FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_restart_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  // Possible regression test for https://github.com/flutter/flutter/issues/161466
  testWithoutContext("Hot restart doesn't hang when UI isolate is in an infinite loop", () async {
    await flutter.run(withDebugger: true);

    // This call will fail to return if the hot restart hangs.
    await flutter.hotRestart();
  });
}
