// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';

import 'src/common.dart';

void main() {
  final String flutterTools = fs.path.join(getFlutterRoot(), 'packages', 'flutter_tools');

  test('no unauthorized imports of dart:io', () {
    final String whitelistedPath = fs.path.join(flutterTools, 'lib', 'src', 'base', 'io.dart');
    bool _isNotWhitelisted(FileSystemEntity entity) => entity.path != whitelistedPath;

    for (String dirName in <String>['lib', 'bin']) {
      final Iterable<File> files = fs.directory(fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .where(_isNotWhitelisted)
        .map(_asFile);
      for (File file in files) {
        for (String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*dart:io')) &&
              !line.contains('ignore: dart_io_import')) {
            final String relativePath = fs.path.relative(file.path, from:flutterTools);
            fail("$relativePath imports 'dart:io'; import 'lib/src/base/io.dart' instead");
          }
        }
      }
    }
  });

  test('no unauthorized imports of package:path', () {
    for (String dirName in <String>['lib', 'bin', 'test']) {
      final Iterable<File> files = fs.directory(fs.path.join(flutterTools, dirName))
        .listSync(recursive: true)
        .where(_isDartFile)
        .map(_asFile);
      for (File file in files) {
        for (String line in file.readAsLinesSync()) {
          if (line.startsWith(RegExp(r'import.*package:path/path.dart'))) {
            final String relativePath = fs.path.relative(file.path, from:flutterTools);
            fail("$relativePath imports 'package:path/path.dart'; use 'fs.path' instead");
          }
        }
      }
    }
  });
}

bool _isDartFile(FileSystemEntity entity) => entity is File && entity.path.endsWith('.dart');

File _asFile(FileSystemEntity entity) => entity;
