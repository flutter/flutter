// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  Directory tempDir;

  setUp(() {
    FlutterCommandRunner.initFlutterRoot();
    tempDir = Directory.systemTemp.createTempSync('analysis_test');
  });

  tearDown(() {
    tempDir?.deleteSync(recursive: true);
  });

  group('analyze', () {

    testUsingContext('inRepo', () {
      AnalyzeCommand cmd = new AnalyzeCommand();
      // Absolute paths
      expect(cmd.inRepo(<String>[tempDir.path]), isFalse);
      expect(cmd.inRepo(<String>[path.join(tempDir.path, 'foo')]), isFalse);
      expect(cmd.inRepo(<String>[Cache.flutterRoot]), isTrue);
      expect(cmd.inRepo(<String>[path.join(Cache.flutterRoot, 'foo')]), isTrue);
      // Relative paths
      String oldWorkingDirectory = path.current;
      try {
        Directory.current = Cache.flutterRoot;
        expect(cmd.inRepo(<String>['.']), isTrue);
        expect(cmd.inRepo(<String>['foo']), isTrue);
        Directory.current = tempDir.path;
        expect(cmd.inRepo(<String>['.']), isFalse);
        expect(cmd.inRepo(<String>['foo']), isFalse);
      } finally {
        Directory.current = oldWorkingDirectory;
      }
      // Ensure no exceptions
      cmd.inRepo(null);
      cmd.inRepo(<String>[]);
    });
  });
}
