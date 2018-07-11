// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:source_span/src/file.dart';
import 'package:test/test.dart';

import 'test_data/stepping_project.dart';
import 'test_driver.dart';

SteppingProject _project = new SteppingProject();
FlutterTestDriver _flutter;

void main() {
  group('debugger', () {
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

    test('can step over statements', () async {
      await _flutter.run(withDebugger: true);

      // Stop at the initial breakpoint that the expected steps are based on.
      await _flutter.breakAt(_project.breakpointFile, 20, restart: true);

      // Issue 5 steps, ensuring that we end up on the annotated lines each time.
      for (int i = 1; i <= _project.numberOfSteps; i++) {
        // TODO(dantup): Requires an updated version of vm_server_client
        // that includes https://github.com/dart-lang/vm_service_client/pull/33
        await _flutter.stepOverOrOverAsyncSuspension();
        final FileLocation location = await _flutter.getSourceLocation();
        final int actualLine = location.line;
        final int expectedLine = _project.lineForStep(i);
        expect(actualLine, equals(expectedLine),
          reason: 'After $i steps, debugger should stop at $expectedLine but stopped at $actualLine');
      }
      // Fails initially because of
      // https://github.com/flutter/flutter/issues/18877
      // but
      // TODO(dantup): test may need tweaking once that's fixed because I'm
      // unable to run it to completion.
    }, skip: true);
  }, timeout: const Timeout.factor(3));
}
