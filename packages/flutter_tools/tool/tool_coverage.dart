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
import 'package:path/path.dart' as path;

final ArgParser argParser = ArgParser()
  ..addOption('output-html',
    defaultsTo: 'coverage/report.html',
    help: 'The output path for the genhtml report.'
  )
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
  )
  ..addOption('genhtml',
    defaultsTo: 'genhtml',
    help: 'The genhtml executable.');


/// Generates an html coverage report for the flutter_tool.
///
/// Example invocation:
///
///    dart tool/tool_coverage.dart --packages=.packages --test-directory=test
Future<void> main(List<String> arguments) async {
  final ArgResults argResults = argParser.parse(arguments);
  await runInContext(() async {
    final CoverageCollector coverageCollector = CoverageCollector(
      flutterProject: await FlutterProject.current(),
    );
    /// A temp directory to create synthetic test files in.
    final Directory tempDirectory = Directory.systemTemp.createTempSync('_flutter_coverage')
      ..createSync();
    final String flutterRoot = File(Platform.script.toFilePath()).parent.parent.parent.parent.path;
    await ToolCoverageRunner(tempDirectory, coverageCollector, flutterRoot, argResults).collectCoverage();
  });
}

class ToolCoverageRunner {
  ToolCoverageRunner(
    this.tempDirectory,
    this.coverageCollector,
    this.flutterRoot,
    this.argResults,
  );

  final ArgResults argResults;
  final Pool pool = Pool(Platform.numberOfProcessors);
  final Directory tempDirectory;
  final CoverageCollector coverageCollector;
  final String flutterRoot;

  Future<void> collectCoverage() async {
    final List<Future<void>> pending = <Future<void>>[];

    final Directory testDirectory = Directory(argResults['test-directory']);
    final List<FileSystemEntity> fileSystemEntities = testDirectory.listSync(recursive: true);
    for (FileSystemEntity fileSystemEntity in fileSystemEntities) {
      if (!fileSystemEntity.path.endsWith('_test.dart')) {
        continue;
      }
      pending.add(_runTest(fileSystemEntity));
    }
    await Future.wait(pending);

    final String lcovData = await coverageCollector.finalizeCoverage();
    final String outputLcovPath = argResults['output-lcov'];
    final String outputHtmlPath = argResults['output-html'];
    final String genHtmlExecutable = argResults['genhtml'];
    File(outputLcovPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(lcovData);
    await Process.run(genHtmlExecutable, <String>[outputLcovPath, '-o', outputHtmlPath], runInShell: true);
  }

  // Creates a synthetic test file to wrap the test main in a group invocation.
  // This will set up several fields used by the test methods on the context. Normally
  // this would be handled automatically by the test runner, but since we're executing
  // the files directly with dart we need to handle it manually.
  String _createTest(File testFile) {
    final File fakeTest = File(path.join(tempDirectory.path, testFile.path))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import "package:test/test.dart";
import "${path.absolute(testFile.path)}" as entrypoint;

void main() {
  group('', entrypoint.main);
}
''');
    return fakeTest.path;
  }

  Future<void> _runTest(File testFile) async {
    final PoolResource resource = await pool.request();
    final String testPath = _createTest(testFile);
    final int port = await _findPort();
    final Uri coverageUri = Uri.parse('http://127.0.0.1:$port');
    final Completer<void> completer = Completer<void>();
    final String packagesPath = argResults['packages'];
    final Process testProcess = await Process.start(
      Platform.resolvedExecutable,
      <String>[
        '--packages=$packagesPath',
        '--pause-isolates-on-exit',
        '--enable-asserts',
        '--enable-vm-service=${coverageUri.port}',
        testPath,
      ],
      runInShell: true,
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
