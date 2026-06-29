// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  final project = BasicProject();

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('disable_service_origin_check_test.');
    await project.setUpIn(tempDir);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext(
    'VM service origin check is active by default and blocks non-localhost origins',
    () async {
      final completer = Completer<Uri>();
      final Process process = await processManager.start(<String>[
        flutterBin,
        'run',
        '--no-dds',
        '--start-paused',
        '--show-test-device',
        '-d',
        'flutter-tester',
        ...getLocalEngineArguments(),
      ], workingDirectory: tempDir.path);

      final StreamSubscription<String> subErr = transformToLines(
        process.stderr,
      ).listen((String line) {});

      final StreamSubscription<String> sub;
      sub = transformToLines(process.stdout).listen((String line) {
        if (line.contains('is available at: http://127.0.0.1:')) {
          final exp = RegExp(r'is available at: (http://127.0.0.1:\d+/[^ \n\r]*)');
          final match = exp.firstMatch(line);
          if (match != null) {
            final uri = Uri.parse(match.group(1)!);
            completer.complete(uri);
          }
        }
      });

      final Uri vmServiceUri = await completer.future.timeout(const Duration(seconds: 60));
      await sub.cancel();
      await subErr.cancel();

      final wsUri = vmServiceUri.replace(scheme: 'ws', path: '${vmServiceUri.path}ws');

      // Connecting with a localhost origin should succeed.
      final wsLocal = await WebSocket.connect(
        wsUri.toString(),
        headers: <String, dynamic>{'Origin': 'http://localhost'},
      );
      await wsLocal.close();

      // Connecting with a non-localhost origin should fail.
      await expectLater(
        WebSocket.connect(
          wsUri.toString(),
          headers: <String, dynamic>{'Origin': 'http://evil.com'},
        ),
        throwsA(isA<WebSocketException>()),
      );

      process.kill();
      await process.exitCode;
    },
  );

  testWithoutContext(
    'VM service origin check is disabled with --disable-service-origin-check',
    () async {
      final completer = Completer<Uri>();
      final Process process = await processManager.start(<String>[
        flutterBin,
        'run',
        '--no-dds',
        '--start-paused',
        '--show-test-device',
        '-d',
        'flutter-tester',
        '--disable-service-origin-check',
        ...getLocalEngineArguments(),
      ], workingDirectory: tempDir.path);

      final StreamSubscription<String> subErr = transformToLines(
        process.stderr,
      ).listen((String line) {});

      final StreamSubscription<String> sub;
      sub = transformToLines(process.stdout).listen((String line) {
        if (line.contains('is available at: http://127.0.0.1:')) {
          final exp = RegExp(r'is available at: (http://127.0.0.1:\d+/[^ \n\r]*)');
          final match = exp.firstMatch(line);
          if (match != null) {
            final uri = Uri.parse(match.group(1)!);
            completer.complete(uri);
          }
        }
      });

      final Uri vmServiceUri = await completer.future.timeout(const Duration(seconds: 60));
      await sub.cancel();
      await subErr.cancel();

      final wsUri = vmServiceUri.replace(scheme: 'ws', path: '${vmServiceUri.path}ws');

      // Connecting with a non-localhost origin should succeed.
      final ws = await WebSocket.connect(
        wsUri.toString(),
        headers: <String, dynamic>{'Origin': 'http://evil.com'},
      );
      await ws.close();

      process.kill();
      await process.exitCode;
    },
  );
}
