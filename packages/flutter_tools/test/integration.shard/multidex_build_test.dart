// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_data/multidex_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;
  FlutterRunTestDriver _flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    _flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await _flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('simple build apk succeeds', () async {
    final MultidexProject project = MultidexProject(true);
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
    ], workingDirectory: tempDir.path);

    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('app-debug.apk'));
  });

  testWithoutContext('simple build apk without FlutterMultiDexApplication fails', () async {
    final MultidexProject project = MultidexProject(false);
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
    ], workingDirectory: tempDir.path);

    expect(result.stderr.toString(), contains('Cannot fit requested classes in a single dex file'));
    expect(result.stderr.toString(), contains('The number of method references in a .dex file cannot exceed 64K.'));
    expect(result.exitCode, 1);
  });
}
