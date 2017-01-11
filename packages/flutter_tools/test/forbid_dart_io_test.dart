// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    String flutterRoot = Platform.environment['FLUTTER_ROOT'];
    assert(fs.currentDirectory.path == '$flutterRoot/packages/flutter_tools');
  });

  test('no unauthorized imports of dart:io', () {
    for (String path in <String>['lib', 'bin', 'test']) {
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
}

bool _isDartFile(FileSystemEntity entity) =>
    entity is File && entity.path.endsWith('.dart');

bool _isNotWhitelisted(FileSystemEntity entity) =>
    entity.path != 'lib/src/base/io.dart';

File _asFile(FileSystemEntity entity) => entity;
