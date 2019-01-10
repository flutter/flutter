// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:vm_service_lib/vm_service_lib.dart';

import '../src/common.dart';
import 'test_data/hot_reload_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  group('hot', () {
    Directory tempDir;
    final HotReloadProject _project = HotReloadProject();
    FlutterRunTestDriver _flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync();
      await _project.setUpIn(tempDir);
      _flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await _flutter.stop();
      tryToDelete(tempDir);
    });

    test('reload works without error', () async {
      await _flutter.run();
      await _flutter.hotReload();
    });

    test('newly added code executes during reload', () async {
      await _flutter.run();
      _project.uncommentHotReloadPrint();
      final StringBuffer stdout = StringBuffer();
      final StreamSubscription<String> sub = _flutter.stdout.listen(stdout.writeln);
      try {
            await _flutter.hotReload();
            expect(stdout.toString(), contains('(((((RELOAD WORKED)))))'));
      } finally {
        await sub.cancel();
      }
    });

    test('restart works without error', () async {
      await _flutter.run();
      await _flutter.hotRestart();
    });

    test('reload hits breakpoints after reload', () async {
      await _flutter.run(withDebugger: true);
      final Isolate isolate = await _flutter.breakAt(
          _project.breakpointUri,
          _project.breakpointLine);
      expect(isolate.pauseEvent.kind, equals(EventKind.kPauseBreakpoint));
    });
  }, timeout: const Timeout.factor(6));
}
