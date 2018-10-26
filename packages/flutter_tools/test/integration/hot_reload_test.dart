// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:vm_service_client/vm_service_client.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  group('hot', () {
    Directory tempDir;
    final BasicProject _project = BasicProject();
    FlutterTestDriver _flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync();
      await _project.setUpIn(tempDir);
      _flutter = FlutterTestDriver(tempDir);
    });

    tearDown(() async {
      await _flutter.stop();
      tryToDelete(tempDir);
    });

    test('reload works without error', () async {
      await _flutter.run();
      await _flutter.hotReload();
    });

    test('restart works without error', () async {
      await _flutter.run();
      await _flutter.hotRestart();
    });

    test('reload hits breakpoints after reload', () async {
      await _flutter.run(withDebugger: true);
      final VMIsolate isolate = await _flutter.breakAt(
          _project.breakpointUri,
          _project.breakpointLine);
      expect(isolate.pauseEvent, isInstanceOf<VMPauseBreakpointEvent>());
    });
  }, timeout: const Timeout.factor(6));
}
