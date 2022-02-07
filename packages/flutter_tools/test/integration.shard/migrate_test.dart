// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_data/migrate_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';


void main() {
  Directory tempDir;
  FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('simple vanilla migrate process succeeds', () async {
    // 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    // Flutter Stable 1.22.6
    final MigrateProject project = MigrateProject('vanilla_app_1_22_6_stable');
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'apply',
      '--verbose',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 1);
    expect(result.stderr.toString(), contains('No migration'));

    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'start',
      '--verbose',
    ], workingDirectory: tempDir.path);
    print(result.stdout);
    expect(result.exitCode, 0);
    expect(result.stdout.toString(), contains('Working directory created at'));

    // Call apply with conflicts remaining. Should fail.
    result = await processManager.run(<String>[
      flutterBin,
      'migrate',
      'apply',
      '--verbose',
    ], workingDirectory: tempDir.path);
    print(result.stdout);
    print(tempDir.childFile('migrate_working_dir/android/app/src/profile/AndroidManifest.xml').readAsStringSync());
    print(tempDir.childFile('migrate_working_dir/pubspec.lock').readAsStringSync());
    expect(result.exitCode, 1);
    // expect(result.stdout.toString(), contains(''));
  });
}
