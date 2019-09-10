// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test_core/src/runner/hack_register_platform.dart' as hack; // ignore: implementation_imports
import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test_core/src/executable.dart' as test; // ignore: implementation_imports

import 'test_platform.dart';
import 'environment.dart';

Future<void> runTests() async {
  await _buildHostPage();
  await _buildTests();

  if (environment.targets.isEmpty) {
    await _runAllTests();
  } else {
    await _runSingleTest(environment.targets);
  }
}

Future<void> _runSingleTest(List<String> targets) async {
  await _runTestBatch(targets, concurrency: 1, expectFailure: false);
  _checkExitCode();
}

Future<void> _runAllTests() async {
  final io.Directory testDir = io.Directory(path.join(
    environment.webUiRootDir.path,
    'test',
  ));

  // Separate screenshot tests from unit-tests. Screenshot tests must run
  // one at a time. Otherwise, they will end up screenshotting each other.
  // This is not an issue for unit-tests.
  const String failureSmokeTestPath = 'test/golden_tests/golden_failure_smoke_test.dart';
  final List<String> screenshotTestFiles = <String>[];
  final List<String> unitTestFiles = <String>[];

  for (io.File testFile in testDir.listSync(recursive: true).whereType<io.File>()) {
    final String testFilePath = path.relative(testFile.path, from: environment.webUiRootDir.path);
    if (!testFilePath.endsWith('_test.dart')) {
      // Not a test file at all. Skip.
      continue;
    }
    if (testFilePath.endsWith(failureSmokeTestPath)) {
      // A smoke test that fails on purpose. Skip.
      continue;
    }
    if (path.split(testFilePath).contains('golden_tests')) {
      screenshotTestFiles.add(testFilePath);
    } else {
      unitTestFiles.add(testFilePath);
    }
  }

  // This test returns a non-zero exit code on purpose. Run it separately.
  if (io.Platform.environment['CIRRUS_CI'] != 'true') {
    await _runTestBatch(
      <String>[failureSmokeTestPath],
      concurrency: 1,
      expectFailure: true,
    );
    _checkExitCode();
  }

  // Run all unit-tests as a single batch.
  await _runTestBatch(unitTestFiles, concurrency: 10, expectFailure: false);
  _checkExitCode();

  // Run screenshot tests one at a time.
  for (String testFilePath in screenshotTestFiles) {
    await _runTestBatch(<String>[testFilePath], concurrency: 1, expectFailure: false);
    _checkExitCode();
  }
}

void _checkExitCode() {
  if (io.exitCode != 0) {
    io.stderr.writeln('Process exited with exit code ${io.exitCode}.');
    io.exit(1);
  }
}

// TODO(yjbanov): skip rebuild if host.dart hasn't changed.
Future<void> _buildHostPage() async {
  final io.Process pubRunTest = await io.Process.start(
    environment.dart2jsExecutable,
    <String>[
      'lib/static/host.dart',
      '-o',
      'lib/static/host.dart.js',
    ],
    workingDirectory: environment.goldenTesterRootDir.path,
  );

  final StreamSubscription stdoutSub = pubRunTest.stdout.listen(io.stdout.add);
  final StreamSubscription stderrSub = pubRunTest.stderr.listen(io.stderr.add);
  final int exitCode = await pubRunTest.exitCode;
  stdoutSub.cancel();
  stderrSub.cancel();

  if (exitCode != 0) {
    io.stderr.writeln('Failed to compile tests. Compiler exited with exit code $exitCode');
    io.exit(1);
  }
}

Future<void> _buildTests() async {
  // TODO(yjbanov): learn to build only requested tests: https://github.com/flutter/flutter/issues/37810
  final io.Process pubRunTest = await io.Process.start(
    environment.pubExecutable,
    <String>[
      'run',
      'build_runner',
      'build',
      'test',
      '-o',
      'build',
    ],
  );

  final StreamSubscription stdoutSub = pubRunTest.stdout.listen(io.stdout.add);
  final StreamSubscription stderrSub = pubRunTest.stderr.listen(io.stderr.add);
  final int exitCode = await pubRunTest.exitCode;
  stdoutSub.cancel();
  stderrSub.cancel();

  if (exitCode != 0) {
    io.stderr.writeln('Failed to compile tests. Compiler exited with exit code $exitCode');
    io.exit(1);
  }
}

Future<int> _runTestBatch(
  List<String> testFiles, {
    @required int concurrency,
    @required bool expectFailure,
  }
) async {
  final List<String> testArgs = <String>[
    '--no-color',
    ...<String>['-r', 'compact'],
    '--concurrency=$concurrency',
    if (environment.isDebug)
      '--pause-after-load',
    '--platform=chrome',
    '--precompiled=${environment.webUiRootDir.path}/build',
    '--',
    ...testFiles,
  ];
  hack.registerPlatformPlugin(
    <Runtime>[Runtime.chrome],
    () {
      return BrowserPlatform.start(root: io.Directory.current.path);
    }
  );
  await test.main(testArgs);

  if (expectFailure) {
    if (io.exitCode != 0) {
      // It failed, as expected.
      io.exitCode = 0;
    } else {
      io.stderr.writeln(
        'Tests ${testFiles.join(', ')} did not fail. Expected failure.',
      );
      io.exitCode = 1;
    }
  }

  return io.exitCode;
}
