// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

// Test that configOnly creates the gradlew file and does not assemble and app.
void main() {
  late Directory tempDir;
  late String flutterBin;
  late Directory exampleAppDir;

  ProcessResult runSync(List<String> cmd, [int expectedCode = 0]) {
    final ProcessResult result = processManager.runSync(
      cmd,
      workingDirectory: tempDir.path,
    );

    if (result.exitCode != expectedCode) {
      fail(
        'Sub-process "${cmd.join(' ')}" exited with unexpected code ${result.exitCode}\n\n'
         'stdout:\n${result.stdout}\n\n'
         'stderr:\n${result.stderr}',
      );
    }

    return result;
  }

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_build_test.');
    flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );
    exampleAppDir = tempDir.childDirectory('bbb').childDirectory('example');

    runSync(
      <String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'create',
        '--template=plugin',
        '--platforms=android',
        'bbb',
        '-v',
      ],
    );
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  test(
    'flutter build apk --config-only should create gradlew and not assemble',
    () async {
      final File gradleFile = fileSystem
          .directory(exampleAppDir)
          .childDirectory('android')
          .childFile(platform.isWindows ? 'gradlew.bat' : 'gradlew');
      // Ensure file is gone prior to configOnly running.
      await gradleFile.delete();

      final ProcessResult result = runSync(
        <String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'apk',
          '--target-platform=android-arm',
          '--config-only',
        ],
      );

      expect(gradleFile, exists);
      expect(result.stdout, contains(RegExp(r'Config complete')));
      expect(result.stdout, isNot(contains(RegExp(r'Running Gradle task'))));
    },
  );
}


