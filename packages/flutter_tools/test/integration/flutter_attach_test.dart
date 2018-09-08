// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';

void main() {
  FlutterTestDriver _flutterRun, _flutterAttach;
  final BasicProject _project = new BasicProject();
  Directory tempDir;

  setUp(() async {
    tempDir = fs.systemTempDirectory.createTempSync('flutter_attach_test.');
    await _project.setUpIn(tempDir);
    _flutterRun = new FlutterTestDriver(tempDir, logPrefix: 'RUN');
    _flutterAttach = new FlutterTestDriver(tempDir, logPrefix: 'ATTACH');
  });

  tearDown(() async {
    await _flutterAttach.detach();
    await _flutterRun.stop();
    tryToDelete(tempDir);
  });

  group('attached process', () {
    test('can hot reload', () async {
      await _flutterRun.run(withDebugger: true);
      await _flutterAttach.attach(_flutterRun.vmServicePort);
      await _flutterAttach.hotReload();
    });
    test('can detach, reattach, hot reload', () async {
      await _flutterRun.run(withDebugger: true);
      await _flutterAttach.attach(_flutterRun.vmServicePort);
      await _flutterAttach.detach();
      await _flutterAttach.attach(_flutterRun.vmServicePort);
      await _flutterAttach.hotReload();
    });
    test('killing process behaves the same as detach ', () async {
      await _flutterRun.run(withDebugger: true);
      await _flutterAttach.attach(_flutterRun.vmServicePort);
      await _flutterAttach.quit();
      _flutterAttach = new FlutterTestDriver(tempDir, logPrefix: 'ATTACH-2');
      await _flutterAttach.attach(_flutterRun.vmServicePort);
      await _flutterAttach.hotReload();
    });
  }, timeout: const Timeout.factor(6));
}
