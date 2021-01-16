// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

/// Verifies that `dart migrate` will run successfuly on the default `flutter create`
/// template.
void main() {
  testWithoutContext('dart migrate succeedes on flutter create template', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', platform.isWindows ? 'flutter.bat' : 'flutter');
    final String dartBin = fileSystem.path.join(getFlutterRoot(), 'bin', platform.isWindows ? 'dart.bat' : 'dart');

    Directory tempDir;
    try {
      tempDir = createResolvedTempDirectorySync('dart_migrate_test.');
      final ProcessResult createResult = await processManager.run(<String>[
        flutterBin,
        'create',
        'foo',
      ], workingDirectory: tempDir.path);
      if (createResult.exitCode != 0) {
        fail('flutter create did not work: ${createResult.stdout}${createResult.stderr}');
      }

      final ProcessResult migrateResult = await processManager.run(<String>[
        dartBin,
        'migrate',
        '--apply-changes',
      ], workingDirectory: fileSystem.path.join(tempDir.path, 'foo'));
      if (migrateResult.exitCode != 0) {
        fail('dart migrate did not work: ${migrateResult.stdout}${migrateResult.stderr}');
      }

      final ProcessResult analyzeResult = await processManager.run(<String>[
        flutterBin,
        'analyze',
      ], workingDirectory: fileSystem.path.join(tempDir.path, 'foo'));
      if (analyzeResult.exitCode != 0) {
        fail('flutter analyze had errors: ${analyzeResult.stdout}${analyzeResult.stderr}');
      }
    } finally {
      tempDir?.deleteSync(recursive: true);
    }
  });
}
