// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';
import 'package:vm_service_client/vm_service_client.dart';

import 'test_data/basic_project.dart';
import 'test_driver.dart';

BasicProject _project = new BasicProject();
FlutterTestDriver _flutter;

void main() {
  group('hot reload', () {
    setUp(() async {
      final Directory tempDir = await fs.systemTempDirectory.createTemp('test_app');
      await _project.setUpIn(tempDir);
      _flutter = new FlutterTestDriver(tempDir);
    });

    tearDown(() async {
      try {
        await _flutter.stop();
        _project.cleanup();
      } catch (e) {
        // Don't fail tests if we failed to clean up temp folder.
      }
    });

    test('works without error', () async {
      await _flutter.run();
      await _flutter.hotReload();
    }, skip: true); // https://github.com/flutter/flutter/issues/17833

    test('hits breakpoints with file:// prefixes after reload', () async {
      await _flutter.run(withDebugger: true);

      // Add a breakpoint using a file:// URI.
      await _flutter.addBreakpoint(
          new Uri.file(_project.breakpointFile).toString(),
          _project.breakpointLine);

      await _flutter.hotReload();

      // Ensure we hit the breakpoint.
      final VMIsolate isolate = await _flutter.waitForBreakpointHit();
      expect(isolate.pauseEvent, const isInstanceOf<VMPauseBreakpointEvent>());
    }, skip: true); // https://github.com/flutter/flutter/issues/18441
  }, timeout: const Timeout.factor(3));
}
