// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    String flutterRoot = platform.environment['FLUTTER_ROOT'];
    if (flutterRoot == null) {
      throw new Exception('Please set FLUTTER_ROOT env var before running tests.');
    }
    String flutterTools = fs.path.join(flutterRoot, 'packages', 'flutter_tools');
    assert(fs.path.equals(fs.currentDirectory.path, flutterTools));
  });

  test('no unauthorized imports of dart:io', () {
    bool _isNotWhitelisted(FileSystemEntity entity) => entity.path != fs.path.join('lib', 'src', 'base', 'io.dart');

    for (String path in <String>['lib', 'bin']) {
      fs.directory(path)
        .listSync(recursive: true)
        .where(_isDartFile)
        .where(_isNotWhitelisted)
        .map(_asFile)
        .forEach((File file) {
          for (String line in file.readAsLinesSync()) {
            if (line.startsWith(new RegExp('import.*dart:io')) &&
                !line.contains('ignore: dart_io_import')) {
              fail("${file.path} imports 'dart:io'; import 'lib/src/base/io.dart' instead");
            }
          }
        }
      );
    }
  });

  test('no unauthorized imports of package:path', () {
    for (String path in <String>['lib', 'bin', 'test']) {
      fs.directory(path)
          .listSync(recursive: true)
          .where(_isDartFile)
          .map(_asFile)
          .forEach((File file) {
        for (String line in file.readAsLinesSync()) {
          if (line.startsWith(new RegExp('import.*package:path/path.dart'))) {
            fail("${file.path} imports 'package:path/path.dart'; use 'fs.path' instead");
          }
        }
      }
      );
    }
  });
}

bool _isDartFile(FileSystemEntity entity) => entity is File && entity.path.endsWith('.dart');

File _asFile(FileSystemEntity entity) => entity;
