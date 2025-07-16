// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('build_windows_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  // This test, when run on a Windows host, can validate that the underlying
  // build process does not generate a build.ninja file when only
  // configuration is requested.
  testWithoutContext('build windows --config-only does not create build.ninja', () async {
    // Create a dummy project.
    final String projectPath = await createProject(
      tempDir,
      arguments: <String>[
        '--template=app',
        '--platforms=windows',
      ],
    );
    final Directory windowsDir = tempDir.childDirectory('lib');

    // Run a build in config-only mode.
    final ProcessResult result = await processManager.run(
      <String>[
        flutterBin,
        'build',
        'windows',
        '--config-only',
        '--no-pub',
        '-v',
      ],
      workingDirectory: projectPath,
    );

    expect(result, const ProcessResultMatcher());
    expect(
      windowsDir.childFile('build.ninja').existsSync(),
      isFalse,
      reason: 'build.ninja should not be created in config-only mode',
    );
  },
  // This test can only be run on Windows hosts.
  skip: !platform.isWindows);
}
