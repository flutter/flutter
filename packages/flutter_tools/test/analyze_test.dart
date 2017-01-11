// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze_base.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  Directory tempDir;

  setUp(() {
    FlutterCommandRunner.initFlutterRoot();
    tempDir = fs.systemTempDirectory.createTempSync('analysis_test');
  });

  tearDown(() {
    tempDir?.deleteSync(recursive: true);
  });

  group('analyze', () {

    testUsingContext('inRepo', () {
      // Absolute paths
      expect(inRepo(<String>[tempDir.path]), isFalse);
      expect(inRepo(<String>[path.join(tempDir.path, 'foo')]), isFalse);
      expect(inRepo(<String>[Cache.flutterRoot]), isTrue);
      expect(inRepo(<String>[path.join(Cache.flutterRoot, 'foo')]), isTrue);
      // Relative paths
      String oldWorkingDirectory = fs.currentDirectory.path;
      try {
        fs.currentDirectory = Cache.flutterRoot;
        expect(inRepo(<String>['.']), isTrue);
        expect(inRepo(<String>['foo']), isTrue);
        fs.currentDirectory = tempDir.path;
        expect(inRepo(<String>['.']), isFalse);
        expect(inRepo(<String>['foo']), isFalse);
      } finally {
        fs.currentDirectory = oldWorkingDirectory;
      }
      // Ensure no exceptions
      inRepo(null);
      inRepo(<String>[]);
    });
  });
}
