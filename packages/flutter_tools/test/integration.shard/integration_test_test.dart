// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', platform.isWindows ? 'flutter.bat' : 'flutter');

void main() {
  Directory tempDir;
  setUpAll(() {
    tempDir = createResolvedTempDirectorySync('int_test.');
  });

  tearDownAll(() {
    tryToDelete(tempDir);
  });

  testWithoutContext('flutter project default integration_test smoke test', () async {
    const String projectName = 'integration_test_sample';
    ProcessResult result = await processManager.run(
      <String>[
        flutterBin,
        'create',
        projectName,
      ],
      workingDirectory: tempDir.path,
    );

    expect(result.exitCode, 0);

    final Directory projectDir = tempDir.childDirectory(projectName);
    expect(projectDir.existsSync(), true);
    final Directory integrationTestDir = projectDir.childDirectory('integration_test');
    expect(integrationTestDir.existsSync(), true);
    expect(integrationTestDir.childFile('driver.dart').existsSync(), true);
    expect(integrationTestDir.childFile('app_test.dart').existsSync(), true);

    result = await processManager.run(
      <String>[
        flutterBin,
        'drive',
        '-d', 'flutter-tester',
        '--driver', 'integration_test/driver.dart',
        '-t', 'integration_test/app_test.dart',
      ],
      workingDirectory: projectDir.path,
    );

    if (result.exitCode != 0) {
      print('================================= STDOUT =======================================');
      print(result.stdout);
      print('================================= STDERR =======================================');
      print(result.stderr);
      fail('flutter drive failed, see output.');
    }
  });
}
