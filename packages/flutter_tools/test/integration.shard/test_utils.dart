// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/process_manager.dart';

import '../src/common.dart';

/// Creates a temporary directory but resolves any symlinks to return the real
/// underlying path to avoid issues with breakpoints/hot reload.
/// https://github.com/flutter/flutter/pull/21741
Directory createResolvedTempDirectorySync(String prefix) {
  assert(prefix.endsWith('.'));
  final Directory tempDirectory = fs.systemTempDirectory.createTempSync('flutter_$prefix');
  return fs.directory(tempDirectory.resolveSymbolicLinksSync());
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
    'pub',
    'get',
  ];
  final ProcessResult result = await processManager.run(command, workingDirectory: folder);
  if (result.exitCode != 0) {
    throw Exception('flutter pub get failed: ${result.stderr}\n${result.stdout}');
  }
}
