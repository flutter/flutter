// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_data/web_define_project.dart';
import 'test_utils.dart';

/// Asserts --web-define placeholders were substituted and none remain.
void _expectSubstituted(String contents) {
  expect(contents, contains(WebDefineProject.kVersion));
  expect(contents, contains(WebDefineProject.kApiUrl));
  expect(contents, isNot(contains('{{MY_VERSION}}')));
  expect(contents, isNot(contains('{{API_URL}}')));
}

void main() {
  late Directory tempDir;
  final project = WebDefineProject();

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('web_define_build_test.');
    await project.setUpIn(tempDir);
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  for (final mode in const <String>['--debug', '--profile', '--release']) {
    testWithoutContext('flutter build web $mode substitutes --web-define in output', () async {
      final ProcessResult result = processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'web',
        '--no-pub',
        '--no-web-resources-cdn',
        '--web-define=MY_VERSION=${WebDefineProject.kVersion}',
        '--web-define=API_URL=${WebDefineProject.kApiUrl}',
        mode,
      ], workingDirectory: tempDir.path);
      expect(result, const ProcessResultMatcher());

      final File indexHtml = fileSystem.file(
        fileSystem.path.join(tempDir.path, 'build', 'web', 'index.html'),
      );
      expect(indexHtml, exists);
      _expectSubstituted(indexHtml.readAsStringSync());

      final File bootstrapJs = fileSystem.file(
        fileSystem.path.join(tempDir.path, 'build', 'web', 'flutter_bootstrap.js'),
      );
      expect(bootstrapJs, exists);
      _expectSubstituted(bootstrapJs.readAsStringSync());
    });
  }
}
