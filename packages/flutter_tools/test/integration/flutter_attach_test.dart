// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';

void main() {
  FlutterTestDriver _flutterRun, _flutterAttach;
  final BasicProject _project = new BasicProject();
  Directory tempDir;

  setUp(() async {
    tempDir = fs.systemTempDirectory.createTempSync('flutter_attach_test.');
    await _project.setUpIn(tempDir);
    _flutterRun = new FlutterTestDriver(tempDir);
    _flutterAttach = new FlutterTestDriver(tempDir);
  });

  tearDown(() async {
    await _flutterRun.stop();
    await _flutterAttach.stop();
    tryToDelete(tempDir);
  });

  group('attached process', () {
    testUsingContext('can hot reload', () async {
      await _flutterRun.run(withDebugger: true);
      await _flutterAttach.attach(_flutterRun.vmServicePort);
      await _flutterAttach.hotReload();
    });
    // TODO(dantup): Unskip after https://github.com/flutter/flutter/issues/17833.
  }, timeout: const Timeout.factor(6), skip: platform.isWindows);
}
