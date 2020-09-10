// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/stateless_stateful_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

// This test verifies that we can hot reload a stateless widget into a
// stateful one and back.
void main() {
  Directory tempDir;
  final HotReloadProject _project = HotReloadProject();
  FlutterRunTestDriver _flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('hot_reload_test.');
    await _project.setUpIn(tempDir);
    _flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await _flutter?.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('Can switch between stateless and stateful', () async {
    await _flutter.run();
    await _flutter.hotReload();
    final StringBuffer stdout = StringBuffer();
    final StreamSubscription<String> subscription = _flutter.stdout.listen(stdout.writeln);

    // switch to stateful.
    _project.toggleState();
    await _flutter.hotReload();

    // switch to stateless.
    _project.toggleState();
    await _flutter.hotReload();

    final String logs = stdout.toString();

    expect(logs, contains('STATELESS'));
    expect(logs, contains('STATEFUL'));
    await subscription.cancel();
  });
}
