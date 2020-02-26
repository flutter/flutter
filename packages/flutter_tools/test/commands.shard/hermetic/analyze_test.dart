// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze_base.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

const String _kFlutterRoot = '/data/flutter';

void main() {
  FileSystem fs;
  Directory tempDir;

  setUp(() {
    fs = MemoryFileSystem();
    fs.directory(_kFlutterRoot).createSync(recursive: true);
    Cache.flutterRoot = _kFlutterRoot;
    tempDir = fs.systemTempDirectory.createTempSync('flutter_analysis_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  group('analyze', () {
    testUsingContext('inRepo', () {
      // Absolute paths
      expect(inRepo(<String>[tempDir.path]), isFalse);
      expect(inRepo(<String>[globals.fs.path.join(tempDir.path, 'foo')]), isFalse);
      expect(inRepo(<String>[Cache.flutterRoot]), isTrue);
      expect(inRepo(<String>[globals.fs.path.join(Cache.flutterRoot, 'foo')]), isTrue);

      // Relative paths
      globals.fs.currentDirectory = Cache.flutterRoot;
      expect(inRepo(<String>['.']), isTrue);
      expect(inRepo(<String>['foo']), isTrue);
      globals.fs.currentDirectory = tempDir.path;
      expect(inRepo(<String>['.']), isFalse);
      expect(inRepo(<String>['foo']), isFalse);

      // Ensure no exceptions
      inRepo(null);
      inRepo(<String>[]);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}
