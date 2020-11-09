// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:process/process.dart';

import '../src/common.dart';

/// The [FileSystem] for the integration test environment.
const FileSystem fileSystem = LocalFileSystem();

/// The [Platform] for the integration test environment.
const Platform platform = LocalPlatform();

/// The [ProcessManager] for the integration test environment.
const ProcessManager processManager = LocalProcessManager();

/// Creates a temporary directory but resolves any symlinks to return the real
/// underlying path to avoid issues with breakpoints/hot reload.
/// https://github.com/flutter/flutter/pull/21741
Directory createResolvedTempDirectorySync(String prefix) {
  assert(prefix.endsWith('.'));
  final Directory tempDirectory = fileSystem.systemTempDirectory.createTempSync('flutter_$prefix');
  return fileSystem.directory(tempDirectory.resolveSymbolicLinksSync());
}

void writeFile(String path, String content) {
  fileSystem.file(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content)
    ..setLastModifiedSync(DateTime.now().add(const Duration(seconds: 10)));
}

void writePackages(String folder) {
  writeFile(fileSystem.path.join(folder, '.packages'), '''
test:${fileSystem.path.join(fileSystem.currentDirectory.path, 'lib')}/
''');
}

void writePubspec(String folder) {
  writeFile(fileSystem.path.join(folder, 'pubspec.yaml'), '''
name: test
dependencies:
  flutter:
    sdk: flutter
''');
}

Future<void> getPackages(String folder) async {
  final List<String> command = <String>[
    fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter'),
    'pub',
    'get',
  ];
  final ProcessResult result = await processManager.run(command, workingDirectory: folder);
  if (result.exitCode != 0) {
    throw Exception('flutter pub get failed: ${result.stderr}\n${result.stdout}');
  }
}
