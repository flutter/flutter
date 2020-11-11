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
  Directory tempDir;
  final BasicProject _project = BasicProject();

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    await _project.setUpIn(tempDir);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext('flutter run --observatory-port selects provided port', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    int port = 0;
    final ServerSocket serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    port = serverSocket.port;
    await serverSocket.close();

    final Process process = await processManager.start(<String>[
      flutterBin,
      'run',
      '--show-test-device',
      '--observatory-port=$port',
      '-d',
      'flutter-tester',
    ], workingDirectory: tempDir.path);
    final Completer<void> completer = Completer<void>();
    process.stdout
      .transform(utf8.decoder)
      .listen((String line) {
        print(line);
        if (line.contains('An Observatory debugger and profiler on Flutter test device is available at')) {
          if (line.contains('http://127.0.0.1:$port')) {
            completer.complete();
          } else {
            completer.completeError(Exception('Did not forward to provided port $port, instead found $line'));
          }
        }
      });
    process.stderr
      .transform(utf8.decoder)
      .listen(print);
    await completer.future;
    process.kill();
    await process.exitCode;
  });
}
