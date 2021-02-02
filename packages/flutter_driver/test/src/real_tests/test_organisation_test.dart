// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  // On CI we only execute the tests in the `test/src/real_test` and
  // `test/src/web_test` directory, see https://github.com/flutter/flutter/blob/master/dev/bots/test.dart.
  // This test ensures that we do not accidentally add tests in the the `test`
  // or `test/src` directory, which would not run on CI.
  test('test files exist only in directories where CI expects them', () {
    final String flutterDriverPath = p.dirname(Platform.script.path);
    expect(p.basename(flutterDriverPath), 'flutter_driver');
    final String flutterDriverTestPath = p.join(flutterDriverPath, 'test');
    final Directory flutterDriverTestDir = Directory(flutterDriverTestPath);
    expect(flutterDriverTestDir.existsSync(), isTrue);
    final List<String> filesInTestDir = flutterDriverTestDir.listSync()
        .map((FileSystemEntity e) => p.basename(e.path))
        .where((String s) => p.extension(s) == '.dart')
        .toList();

    // There are no test files in the `test` directory.
    expect(filesInTestDir, <String>['common.dart']);

    // There are no test files in the src directory.
    final String flutterDriverTestSrcPath = p.join(flutterDriverTestPath, 'src');
    final Directory flutterDriverTestSrcDir = Directory(flutterDriverTestSrcPath);
    expect(flutterDriverTestSrcDir.existsSync(), isTrue);
    final List<String> filesInTestSrcDir = flutterDriverTestSrcDir.listSync()
        .map((FileSystemEntity e) => p.basename(e.path))
        .where((String s) => p.extension(s) == '.dart')
        .toList();

    // There are no test files in the `test/src` directory.
    expect(filesInTestSrcDir, unorderedEquals(<String>[]));
  });
}
