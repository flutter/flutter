// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  FlutterRunTestDriver flutterRun, flutterAttach;
  final BasicProject project = BasicProject();
  Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('attach_test.');
    await project.setUpIn(tempDir);
    flutterRun = FlutterRunTestDriver(tempDir,    logPrefix: '   RUN  ');
    flutterAttach = FlutterRunTestDriver(tempDir, logPrefix: 'ATTACH  ');
  });

  tearDown(() async {
    await flutterAttach.detach();
    await flutterRun.stop();
    tryToDelete(tempDir);
  });

  test('writes pid-file', () async {
    final File pidFile = tempDir.childFile('test.pid');
    flutterRun.stdout.listen(print);
    await flutterRun.run(withDebugger: true);
    await flutterAttach.attach(
      flutterRun.vmServicePort,
      pidFile: pidFile,
    );
    expect(pidFile.existsSync(), isTrue);
  });

  test('can hot reload', () async {
    await flutterRun.run(withDebugger: true);
    await flutterAttach.attach(flutterRun.vmServicePort);
    await flutterAttach.hotReload();
  });

  test('can detach, reattach, hot reload', () async {
    await flutterRun.run(withDebugger: true);
    await flutterAttach.attach(flutterRun.vmServicePort);
    await flutterAttach.detach();
    await flutterAttach.attach(flutterRun.vmServicePort);
    await flutterAttach.hotReload();
  });

  test('killing process behaves the same as detach ', () async {
    await flutterRun.run(withDebugger: true);
    await flutterAttach.attach(flutterRun.vmServicePort);
    await flutterAttach.quit();
    flutterAttach = FlutterRunTestDriver(tempDir, logPrefix: 'ATTACH-2');
    await flutterAttach.attach(flutterRun.vmServicePort);
    await flutterAttach.hotReload();
  });
}
