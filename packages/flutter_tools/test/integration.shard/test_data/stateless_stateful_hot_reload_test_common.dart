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
      '${additionalCommandArgs.isEmpty ? '' : ' with args: $additionalCommandArgs'}', () {
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
      final Completer<void> completer = Completer<void>();
      print('staterunning1'); // ignore: avoid_print
      StreamSubscription<String> subscription = flutter.stdout.listen((String line) {
        if (line.contains('STATELESS')) {
          print('staterunning2'); // ignore: avoid_print
          completer.complete();
        }
      });
      print('staterunning3'); // ignore: avoid_print
      await flutter.run(chrome: chrome, additionalCommandArgs: additionalCommandArgs);
      // Wait for run to finish.
      print('staterunning4'); // ignore: avoid_print
      await completer.future;
      print('staterunning5'); // ignore: avoid_print
      await subscription.cancel();
      print('staterunning6'); // ignore: avoid_print

      await flutter.hotReload();
      print('staterunning7'); // ignore: avoid_print
      final StringBuffer stdout = StringBuffer();
      subscription = flutter.stdout.listen(stdout.writeln);

      // switch to stateful.
      project.toggleState();
      print('staterunning8'); // ignore: avoid_print
      await flutter.hotReload();
      print('staterunning9'); // ignore: avoid_print

      final String logs = stdout.toString();

      expect(logs, contains('STATEFUL'));
      print('staterunning10'); // ignore: avoid_print
      await subscription.cancel();
      print('staterunning11'); // ignore: avoid_print
    });
  });
}
