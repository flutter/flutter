// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  Directory tempDir;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    tempDir = fs.systemTempDirectory.createTempSync('analysis_duplicate_names_test');
  });

  tearDown(() {
    tempDir?.deleteSync(recursive: true);
  });

  group('analyze', () {
    testUsingContext('flutter analyze with two files with the same name', () async {
      final File dartFileA = fs.file(fs.path.join(tempDir.path, 'a.dart'));
      dartFileA.parent.createSync();
      dartFileA.writeAsStringSync('library test;');
      final File dartFileB = fs.file(fs.path.join(tempDir.path, 'b.dart'));
      dartFileB.writeAsStringSync('library test;');

      final AnalyzeCommand command = new AnalyzeCommand();
      applyMocksToCommand(command);
      return createTestCommandRunner(command).run(
        <String>['analyze', '--no-current-package', dartFileA.path, dartFileB.path]
      ).then<Null>((Null value) {
        expect(testLogger.statusText, contains('Analyzing'));
        expect(testLogger.statusText, contains('No issues found!'));
      });

    });
  });
}
