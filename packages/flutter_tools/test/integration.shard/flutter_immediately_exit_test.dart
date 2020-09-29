// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../src/common.dart';
import 'test_data/project_with_immediate_exit.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;
  final ProjectWithImmediateExit _project = ProjectWithImmediateExit();
  FlutterRunTestDriver _flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    await _project.setUpIn(tempDir);
    _flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });


  testWithoutContext('flutter_tools gracefully handles quick app shutdown', () async {
    final String flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );

    final StringBuffer stderr = StringBuffer();

    final Process process = await processManager.start(<String>[
      flutterBin,
      'run',
      '--disable-service-auth-codes',
      '--show-test-device',
      '-dflutter-tester',
    ], workingDirectory: tempDir.path);

    transformToLines(process.stderr).listen((String line) => stderr.writeln(line));
    await process.exitCode;
    expect(stderr.toString(), contains('Error connecting to the service protocol'));
  });
}
