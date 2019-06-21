// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:pool/pool.dart';

final ArgParser argParser = ArgParser()
  ..addOption('output-lcov',
    defaultsTo: 'coverage/lcov.info',
    help: 'The output path for the lcov data.'
  )
  ..addOption('test-directory',
    defaultsTo: 'test/',
    help: 'The path to the test directory.'
  )
  ..addOption('packages',
    defaultsTo: '.packages',
    help: 'The path to the .packages file.'
  );

/// Generates an html coverage report for the flutter_tool.
///
/// Example invocation:
///
///    dart tool/tool_coverage.dart --packages=.packages --test-directory=test
Future<void> main(List<String> arguments) async {
  final ArgResults argResults = argParser.parse(arguments);
  await runInContext(() async {
    final CoverageCollector coverageCollector = CoverageCollector(
      flutterProject: FlutterProject.current(),
    );
    final String flutterRoot = File(Platform.script.toFilePath()).parent.parent.parent.parent.path;
    await ToolCoverageRunner(coverageCollector, flutterRoot, argResults).collectCoverage();
  });
}

class ToolCoverageRunner {
  ToolCoverageRunner(
    this.coverageCollector,
    this.flutterRoot,
    this.argResults,
  );

  final ArgResults argResults;
  final Pool pool = Pool(1);
  final CoverageCollector coverageCollector;
  final String flutterRoot;

  Future<void> collectCoverage() async {
    final List<Future<void>> pending = <Future<void>>[];

    final Directory testDirectory = Directory(argResults['test-directory']);
    final List<FileSystemEntity> fileSystemEntities = testDirectory.listSync(recursive: true);
    for (FileSystemEntity fileSystemEntity in fileSystemEntities) {
      // Skip non-tests and expensive integration tests.
      if (!fileSystemEntity.path.endsWith('_test.dart') || fileSystemEntity.path.contains('integration')) {
        continue;
      }
      pending.add(_runTest(fileSystemEntity));
      break; // TEST: remove
    }
    await Future.wait(pending);

    final String lcovData = await coverageCollector.finalizeCoverage();
    final String outputLcovPath = argResults['output-lcov'];
    File(outputLcovPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(lcovData);
  }

  Future<void> _runTest(File testFile) async {
    final PoolResource resource = await pool.request();
    final int port = await _findPort();
    final Uri coverageUri = Uri.parse('http://127.0.0.1:$port');
    final Completer<void> completer = Completer<void>();
    final String packagesPath = argResults['packages'];
    final Process testProcess = await Process.start(
      Platform.resolvedExecutable,
      <String>[
        '--packages=$packagesPath',
        '--pause-isolates-on-exit',
        '--disable-service-auth-codes',
        '--enable-vm-service=${coverageUri.port}',
        testFile.path,
      ],
      environment: <String, String>{
        'FLUTTER_ROOT': flutterRoot,
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
    testProcess.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(print);
    try {
      await completer.future;
      await coverageCollector.collectCoverage(testProcess, coverageUri)
        .timeout(const Duration(seconds: 30));
      testProcess?.kill();
    } on TimeoutException {
      print('Failed to collect coverage for ${testFile.path} after 10 seconds');
    } finally {
      resource.release();
    }
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
}
