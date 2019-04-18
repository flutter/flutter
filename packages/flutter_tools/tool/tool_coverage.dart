// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:pool/pool.dart';
import 'package:path/path.dart' as path;

/// A temp directory to create synthetic test files in.
final Directory tempDirectory = Directory.systemTemp.createTempSync('_flutter_coverage')..createSync();

/// Generates an html coverage report for the flutter_tool.
///
/// Must be run from the flutter_tools directory.
///
/// Requires lcov and genhtml to be on PATH.
/// See: https://github.com/linux-test-project/lcov.git.
Future<void> main() async {
  await runInContext(() async {
    final CoverageCollector coverageCollector = CoverageCollector(
      flutterProject: await FlutterProject.current(),
    );
    final String flutterRoot = Directory.current.parent.parent.path;
    final String dartPath = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');
    final Pool pool = Pool(Platform.numberOfProcessors);
    final List<Future<void>> pending = <Future<void>>[];

    Future<void> runTest(File testFile) async {
      final PoolResource resource = await pool.request();
      final File fakeTest = File(path.join(tempDirectory.path, testFile.path))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import "package:test/test.dart";
import "${path.absolute(testFile.path)}" as entrypoint;

void main() {
  group('', entrypoint.main);
}
''');
      final int port = await _findPort();
      final Uri coverageUri = Uri.parse('http://127.0.0.1:$port');
      final Completer<void> completer = Completer<void>();
      final Process testProcess = await Process.start(
        dartPath,
        <String>[
          '--packages=${File('.packages').absolute.path}',
          '--pause-isolates-on-exit',
          '--enable-asserts',
          '--enable-vm-service=${coverageUri.port}',
          fakeTest.path,
        ],
        runInShell: true,
        environment: <String, String>{
          'FLUTTER_ROOT': Directory.current.parent.parent.path,
        }).timeout(const Duration(seconds: 30));
      testProcess.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
          print(line);
          if (line.contains('All tests passed') || line.contains('Some tests failed')) {
            completer.complete(null);
          }
        });
      try {
        await completer.future;
        await coverageCollector.collectCoverage(testProcess, coverageUri).timeout(const Duration(seconds: 30));
        testProcess?.kill();
      } on TimeoutException {
        print('Failed to collect coverage for ${testFile.path} after 30 seconds');
      } finally {
        resource.release();
      }
    }

    for (FileSystemEntity fileSystemEntity in Directory('test').listSync(recursive: true)) {
      if (!fileSystemEntity.path.endsWith('_test.dart')) {
        continue;
      }
      pending.add(runTest(fileSystemEntity));
    }
    await Future.wait(pending);
    final String lcovData = await coverageCollector.finalizeCoverage();
    final String lcovPath = path.join('coverage', 'lcov.info');
    final String htmlPath = path.join('coverage', 'report.html');
    File(lcovPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(lcovData);
    await Process.run('genhtml', <String>[lcovPath, '-o', htmlPath,], runInShell: true);
  });
}

Future<int> _findPort() async {
  int port = 0;
  ServerSocket serverSocket;
  try {
    serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4.address, 0);
    port = serverSocket.port;
  } catch (e) {
    // Failures are signaled by a return value of 0 from this function.
    print('_findPort failed: $e');
  }
  if (serverSocket != null) {
    await serverSocket.close();
  }
  return port;
}
