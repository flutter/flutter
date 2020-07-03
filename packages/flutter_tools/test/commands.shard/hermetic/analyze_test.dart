// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/analysis.dart';

import '../../src/common.dart';

const String _kFlutterRoot = '/data/flutter';

void main() {
  testWithoutContext('analyze inRepo', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.directory(_kFlutterRoot).createSync(recursive: true);
    final Directory tempDir = fileSystem.systemTempDirectory
      .createTempSync('flutter_analysis_test.');
    Cache.flutterRoot = _kFlutterRoot;

    // Absolute paths
    expect(inRepo(<String>[tempDir.path], fileSystem), isFalse);
    expect(inRepo(<String>[fileSystem.path.join(tempDir.path, 'foo')], fileSystem), isFalse);
    expect(inRepo(<String>[Cache.flutterRoot], fileSystem), isTrue);
    expect(inRepo(<String>[fileSystem.path.join(Cache.flutterRoot, 'foo')], fileSystem), isTrue);

    // Relative paths
    fileSystem.currentDirectory = Cache.flutterRoot;
    expect(inRepo(<String>['.'], fileSystem), isTrue);
    expect(inRepo(<String>['foo'], fileSystem), isTrue);
    fileSystem.currentDirectory = tempDir.path;
    expect(inRepo(<String>['.'], fileSystem), isFalse);
    expect(inRepo(<String>['foo'], fileSystem), isFalse);

    // Ensure no exceptions
    inRepo(null, fileSystem);
    inRepo(<String>[], fileSystem);
  });

  testWithoutContext('AnalysisError from json write correct', () {
    // ignore: always_specify_types
    final Map<String, Object> json = {
      'severity': 'INFO',
      'type': 'TODO',
      // ignore: always_specify_types
      'location': {
        'file': '/Users/.../lib/test.dart',
        'offset': 362,
        'length': 72,
        'startLine': 15,
        'startColumn': 4
      },
      'message': 'Prefer final for variable declarations if they are not reassigned.',
      'hasFix': false
    };
    expect(WrittenError.fromJson(json).toString(),
        '[info] Prefer final for variable declarations if they are not reassigned (/Users/.../lib/test.dart:15:4)');
  });
}

bool inRepo(List<String> fileList, FileSystem fileSystem) {
  if (fileList == null || fileList.isEmpty) {
    fileList = <String>[fileSystem.path.current];
  }
  final String root = fileSystem.path.normalize(fileSystem.path.absolute(Cache.flutterRoot));
  final String prefix = root + fileSystem.path.separator;
  for (String file in fileList) {
    file = fileSystem.path.normalize(fileSystem.path.absolute(file));
    if (file == root || file.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}
