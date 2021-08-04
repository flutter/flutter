// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  final String dartBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'dart');
  Directory tempDir;

  setUp(() {
    tempDir = createResolvedTempDirectorySync('exit_code_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  testWithoutContext('dart.sh/bat can return a zero exit code', () async {
    tempDir.childFile('main.dart')
      .writeAsStringSync('''
import 'dart:io';
void main() {
  exit(0);
}
''');

    final ProcessResult result = await processManager.run(<String>[
      dartBin,
      fileSystem.path.join(tempDir.path, 'main.dart'),
    ]);

    print(result.stdout);
    print(result.stderr);
    expect(result.exitCode, 0);
  });

  testWithoutContext('dart.sh/bat can return a non-zero exit code', () async {
    tempDir.childFile('main.dart')
      .writeAsStringSync('''
import 'dart:io';
void main() {
  exit(1);
}
''');

    final ProcessResult result = await processManager.run(<String>[
      dartBin,
      fileSystem.path.join(tempDir.path, 'main.dart'),
    ]);

    print(result.stdout);
    print(result.stderr);
    expect(result.exitCode, 1);
  });
}
