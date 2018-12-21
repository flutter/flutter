// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  FlutterRunTestDriver _flutterRun, _flutterAttach;
  final BasicProject _project = BasicProject();
  Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync();
    await _project.setUpIn(tempDir);
    _flutterRun = FlutterRunTestDriver(tempDir, logPrefix: 'RUN');
    _flutterAttach = FlutterRunTestDriver(tempDir, logPrefix: 'ATTACH');
  });

  tearDown(() async {
    await _flutterAttach.detach();
    await _flutterRun.stop();
    tryToDelete(tempDir);
  });

  group('attached process', () {
    test('writes pid-file', () async {
      final File pidFile = tempDir.childFile('test.pid');
      await _flutterRun.run(withDebugger: true);
      await _flutterAttach.attach(
        _flutterRun.vmServicePort,
        pidFile: pidFile,
      );
      expect(pidFile.existsSync(), isTrue);
    });
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
      _flutterAttach = FlutterRunTestDriver(tempDir, logPrefix: 'ATTACH-2');
      await _flutterAttach.attach(_flutterRun.vmServicePort);
      await _flutterAttach.hotReload();
    });
  }, timeout: const Timeout.factor(6));
}
