// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  FlutterRunTestDriver _flutterRun, _flutterAttach;
  final BasicProject _project = BasicProject();
  Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('attach_test.');
    await _project.setUpIn(tempDir);
    _flutterRun = FlutterRunTestDriver(tempDir,    logPrefix: '   RUN  ');
    _flutterAttach = FlutterRunTestDriver(
      tempDir,
      logPrefix: 'ATTACH  ',
      // Only one DDS instance can be connected to the VM service at a time.
      // DDS can also only initialize if the VM service doesn't have any existing
      // clients, so we'll just let _flutterRun be responsible for spawning DDS.
      spawnDdsInstance: false,
    );
  });

  tearDown(() async {
    await _flutterAttach.detach();
    await _flutterRun.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('writes pid-file', () async {
    final File pidFile = tempDir.childFile('test.pid');
    await _flutterRun.run(withDebugger: true);
    await _flutterAttach.attach(
      _flutterRun.vmServicePort,
      pidFile: pidFile,
    );
    expect(pidFile.existsSync(), isTrue);
  });

  testWithoutContext('can hot reload', () async {
    await _flutterRun.run(withDebugger: true);
    await _flutterAttach.attach(_flutterRun.vmServicePort);
    await _flutterAttach.hotReload();
  });

  testWithoutContext('can detach, reattach, hot reload', () async {
    await _flutterRun.run(withDebugger: true);
    await _flutterAttach.attach(_flutterRun.vmServicePort);
    await _flutterAttach.detach();
    await _flutterAttach.attach(_flutterRun.vmServicePort);
    await _flutterAttach.hotReload();
  });

  testWithoutContext('killing process behaves the same as detach ', () async {
    await _flutterRun.run(withDebugger: true);
    await _flutterAttach.attach(_flutterRun.vmServicePort);
    await _flutterAttach.quit();
    _flutterAttach = FlutterRunTestDriver(
      tempDir,
      logPrefix: 'ATTACH-2',
      spawnDdsInstance: false,
    );
    await _flutterAttach.attach(_flutterRun.vmServicePort);
    await _flutterAttach.hotReload();
  });
}
