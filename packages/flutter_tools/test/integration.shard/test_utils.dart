// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';

/// Creates a temporary directory but resolves any symlinks to return the real
/// underlying path to avoid issues with breakpoints/hot reload.
/// https://github.com/flutter/flutter/pull/21741
Directory createResolvedTempDirectorySync(String prefix) {
  assert(prefix.endsWith('.'));
  final Directory tempDirectory = globals.fs.systemTempDirectory.createTempSync('flutter_$prefix');
  return globals.fs.directory(tempDirectory.resolveSymbolicLinksSync());
}

void writeFile(String path, String content, [bool sendToFuture = false]) {
  final File file = globals.fs.file(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
  // When making edits for hot reload changes, the synchronous file write combined
  // with the immediate hot reload request may arrive too close together
  // Ensure the change is recognized by sending it into the future.
  if (sendToFuture) {
    file.setLastModifiedSync(DateTime.now().add(const Duration(seconds: 10)));
  }
}

Future<void> getPackages(String folder) async {
  final List<String> command = <String>[
    globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter'),
    'pub',
    'get',
    '--offline',
  ];
  final ProcessResult result = await globals.processManager.run(command, workingDirectory: folder);
  if (result.exitCode != 0) {
    throw Exception('flutter pub get failed: ${result.stderr}\n${result.stdout}');
  }
}
