// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/convert.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  final project = BasicProject();

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    await project.setUpIn(tempDir);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  // Regression test for https://github.com/flutter/flutter/issues/126691
  testWithoutContext('flutter run --start-paused prints DevTools URI', () async {
    final completer = Completer<void>();
    const matcher = 'The Flutter DevTools debugger and profiler on';

    final Process process = await processManager.start(<String>[
      flutterBin,
      'run',
      '--start-paused',
      '-d',
      'flutter-tester',
    ], workingDirectory: tempDir.path);

    final StreamSubscription<String> sub;
    sub = process.stdout.transform(utf8.decoder).listen((String message) {
      if (message.contains(matcher)) {
        completer.complete();
      }
    });
    await completer.future;
    await sub.cancel();
    process.kill();
    await process.exitCode;
  });
}
