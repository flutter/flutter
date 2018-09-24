// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze_base.dart';

import '../src/common.dart';
import '../src/context.dart';

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
      expect(inRepo(<String>[fs.path.join(tempDir.path, 'foo')]), isFalse);
      expect(inRepo(<String>[Cache.flutterRoot]), isTrue);
      expect(inRepo(<String>[fs.path.join(Cache.flutterRoot, 'foo')]), isTrue);

      // Relative paths
      fs.currentDirectory = Cache.flutterRoot;
      expect(inRepo(<String>['.']), isTrue);
      expect(inRepo(<String>['foo']), isTrue);
      fs.currentDirectory = tempDir.path;
      expect(inRepo(<String>['.']), isFalse);
      expect(inRepo(<String>['foo']), isFalse);

      // Ensure no exceptions
      inRepo(null);
      inRepo(<String>[]);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });
  });
}
