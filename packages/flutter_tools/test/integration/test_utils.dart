// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/process_manager.dart';

import '../src/common.dart';

/// Creates a temporary directory but resolves any symlinks to return the real
/// underlying path to avoid issues with breakpoints/hot reload.
/// https://github.com/flutter/flutter/pull/21741
Directory createResolvedTempDirectorySync() {
  final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_expression_test.');
  return fs.directory(tempDir.resolveSymbolicLinksSync());
}

void writeFile(String path, String content) {
  fs.file(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}

void writePackages(String folder) {
  writeFile(fs.path.join(folder, '.packages'), '''
test:${fs.path.join(fs.currentDirectory.path, 'lib')}/
''');
}

void writePubspec(String folder) {
  writeFile(fs.path.join(folder, 'pubspec.yaml'), '''
name: test
dependencies:
  flutter:
    sdk: flutter
''');
}

Future<void> getPackages(String folder) async {
  final List<String> command = <String>[
    fs.path.join(getFlutterRoot(), 'bin', 'flutter'),
    'packages',
    'get'
  ];
  final Process process = await processManager.start(command, workingDirectory: folder);
  final StringBuffer errorOutput = StringBuffer();
  process.stderr.transform(utf8.decoder).listen(errorOutput.write);
  final int exitCode = await process.exitCode;
  if (exitCode != 0)
    throw Exception(
        'flutter packages get failed: ${errorOutput.toString()}');
}
