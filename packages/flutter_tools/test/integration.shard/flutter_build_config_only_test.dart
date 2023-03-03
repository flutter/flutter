// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

// Test that configOnly creates the gradlew file and does not assemble and app.
void main() {
  late Directory tempDir;
  late String flutterBin;
  late Directory exampleAppDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_build_test.');
    flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );
    exampleAppDir = tempDir.childDirectory('bbb').childDirectory('example');

    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=plugin',
      '--platforms=android',
      'bbb',
    ], workingDirectory: tempDir.path);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  test(
    'flutter build apk --configOnly should create gradlew and not assemble',
    () async {
      final ProcessResult result = processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'apk',
        '--target-platform=android-arm',
        '--configOnly',
      ], workingDirectory: exampleAppDir.path);

      expect(result.stdout, contains(RegExp(r'.*Config complete.*')));
      expect(
          result.stdout, isNot(contains(RegExp(r'.*No config.*'))));
    },
  );
}
