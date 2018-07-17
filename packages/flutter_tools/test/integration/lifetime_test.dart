// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';

import 'test_data/basic_project.dart';
import 'test_driver.dart';

BasicProject _project = new BasicProject();
FlutterTestDriver _flutter;

const Duration requiredLifespan = Duration(seconds: 5);

void main() {
  group('flutter run', () {
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

    test('does not terminate', () async {
      await _flutter.run();
      await new Future<void>.delayed(requiredLifespan);
      expect(_flutter.hasExited, equals(false));
    });

    test('does not terminate when a debugger is attached', () async {
      await _flutter.run(withDebugger: true);
      await new Future<void>.delayed(requiredLifespan);
      expect(_flutter.hasExited, equals(false));
    });

    test('does not terminate when a debugger is attached and pause-on-exceptions', () async {
      await _flutter.run(withDebugger: true, pauseOnExceptions: true);
      await new Future<void>.delayed(requiredLifespan);
      expect(_flutter.hasExited, equals(false));
    });
  }, timeout: const Timeout.factor(3));
}
