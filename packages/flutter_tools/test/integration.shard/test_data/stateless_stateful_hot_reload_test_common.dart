// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import '../../src/common.dart';
import '../test_data/stateless_stateful_project.dart';
import '../test_driver.dart';
import '../test_utils.dart';

// This test verifies that we can hot reload a stateless widget into a
// stateful one and back.
void testAll({bool chrome = false, List<String> additionalCommandArgs = const <String>[]}) {
  group('chrome: $chrome'
      '${additionalCommandArgs.isEmpty ? '' : 'with args: $additionalCommandArgs'}', () {
    late Directory tempDir;
    final HotReloadProject project = HotReloadProject();
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

    testWithoutContext('Can switch from stateless to stateful', () async {
      await flutter.run(chrome: chrome, additionalCommandArgs: additionalCommandArgs);
      await flutter.hotReload();
      final StringBuffer stdout = StringBuffer();
      final Completer<void> completer = Completer<void>();
      final StreamSubscription<String> subscription = flutter.stdout.listen((String line) {
        stdout.writeln(line);
        if (line.contains('STATELESS')) {
          completer.complete();
        }
      });

      // Wait for run to finish.
      await completer.future;
      // switch to stateful.
      project.toggleState();
      await flutter.hotReload();

      final String logs = stdout.toString();

      expect(logs, contains('STATEFUL'));
      await subscription.cancel();
    });
  });
}
