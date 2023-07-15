// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/hot_reload_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  final HotReloadProject project = HotReloadProject(preHotRestartHook: true);
  late FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_reload_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('hot restart will invoke pre-hot restart callbacks first', () async {
    final StringBuffer stdout = StringBuffer();
    flutter.stdout.listen(stdout.writeln);
    await flutter.run();
    await flutter.hotRestart();

    expect(stdout.toString(), contains('INVOKE PRE HOT RESTART CALLBACK'));
  });
}
