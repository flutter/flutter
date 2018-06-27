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
  group('debugger stepping', () {
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

      // Add a breakpoint and reload to stop on it.
      await _flutter.breakAt(
          _project.breakpointFile,
          20,
          restart: true);

      // Issue 5 steps, ensuring that we end up on the annotated lines each time
      for (int i = 1; i <= _project.numberOfSteps; i++) {
        await _flutter.stepOver();
        final FileLocation location = await _flutter.getSourceLocation();
        expect(location.line, equals(_project.lineForStep(i)));
      }
      // Fails initially because of
      // https://github.com/flutter/flutter/issues/18877
      // but
      // TODO(dantup): test may need tweaking once that's fixed because I'm
      // unable to run it to completion.
    }, skip: true);
  }, timeout: const Timeout.factor(3));
}
