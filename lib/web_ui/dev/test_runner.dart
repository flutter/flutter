// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test_core/src/runner/hack_register_platform.dart'
    as hack; // ignore: implementation_imports
import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test_core/src/executable.dart'
    as test; // ignore: implementation_imports

import 'chrome_installer.dart';
import 'test_platform.dart';
import 'environment.dart';
import 'utils.dart';

class TestsCommand extends Command<bool> {
  TestsCommand() {
    argParser
      ..addMultiOption(
        'target',
        abbr: 't',
        help: 'The path to the target to run. When omitted, runs all targets.',
      )
      ..addFlag(
        'debug',
        help: 'Pauses the browser before running a test, giving you an '
            'opportunity to add breakpoints or inspect loaded code before '
            'running the code.',
      );

    addChromeVersionOption(argParser);
  }

  @override
  final String name = 'test';

  @override
  final String description = 'Run tests.';

  @override
  Future<bool> run() async {
    Chrome.version = chromeVersion;

    _copyAhemFontIntoWebUi();
    await _buildHostPage();
    await _buildTests();

    final List<FilePath> targets =
        this.targets.map((t) => FilePath.fromCwd(t)).toList();
    if (targets.isEmpty) {
      await _runAllTests();
    } else {
      await _runTargetTests(targets);
    }
    return true;
  }

  /// Whether to start the browser in debug mode.
  ///
  /// In this mode the browser pauses before running the test to allow
  /// you set breakpoints or inspect the code.
  bool get isDebug => argResults['debug'];

  /// Paths to targets to run, e.g. a single test.
  List<String> get targets => argResults['target'];

  /// See [ChromeInstallerCommand.chromeVersion].
  String get chromeVersion => argResults['chrome-version'];

  Future<void> _runTargetTests(List<FilePath> targets) async {
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
    final FilePath failureSmokeTestPath = FilePath.fromWebUi(
      'test/golden_tests/golden_failure_smoke_test.dart',
    );
    final List<FilePath> screenshotTestFiles = <FilePath>[];
    final List<FilePath> unitTestFiles = <FilePath>[];

    for (io.File testFile
        in testDir.listSync(recursive: true).whereType<io.File>()) {
      final FilePath testFilePath = FilePath.fromCwd(testFile.path);
      if (!testFilePath.absolute.endsWith('_test.dart')) {
        // Not a test file at all. Skip.
        continue;
      }
      if (testFilePath == failureSmokeTestPath) {
        // A smoke test that fails on purpose. Skip.
        continue;
      }
      if (path.split(testFilePath.relativeToWebUi).contains('golden_tests')) {
        screenshotTestFiles.add(testFilePath);
      } else {
        unitTestFiles.add(testFilePath);
      }
    }

    // This test returns a non-zero exit code on purpose. Run it separately.
    if (io.Platform.environment['CIRRUS_CI'] != 'true') {
      await _runTestBatch(
        <FilePath>[failureSmokeTestPath],
        concurrency: 1,
        expectFailure: true,
      );
      _checkExitCode();
    }

    // Run all unit-tests as a single batch.
    await _runTestBatch(unitTestFiles, concurrency: 10, expectFailure: false);
    _checkExitCode();

    // Run screenshot tests one at a time.
    for (FilePath testFilePath in screenshotTestFiles) {
      await _runTestBatch(
        <FilePath>[testFilePath],
        concurrency: 1,
        expectFailure: false,
      );
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
    final int exitCode = await runProcess(
      environment.dart2jsExecutable,
      <String>[
        'lib/static/host.dart',
        '-o',
        'lib/static/host.dart.js',
      ],
      workingDirectory: environment.goldenTesterRootDir.path,
    );

    if (exitCode != 0) {
      io.stderr.writeln(
          'Failed to compile tests. Compiler exited with exit code $exitCode');
      io.exit(1);
    }
  }

  Future<void> _buildTests() async {
    // TODO(yjbanov): learn to build only requested tests: https://github.com/flutter/flutter/issues/37810
    final int exitCode = await runProcess(
      environment.pubExecutable,
      <String>[
        'run',
        'build_runner',
        'build',
        'test',
        '-o',
        'build',
      ],
      workingDirectory: environment.webUiRootDir.path,
    );

    if (exitCode != 0) {
      io.stderr.writeln(
          'Failed to compile tests. Compiler exited with exit code $exitCode');
      io.exit(1);
    }
  }

  /// Runs a batch of tests.
  ///
  /// Unless [expectFailure] is set to false, sets [io.exitCode] to a non-zero value if any tests fail.
  Future<void> _runTestBatch(
    List<FilePath> testFiles, {
    @required int concurrency,
    @required bool expectFailure,
  }) async {
    final List<String> testArgs = <String>[
      '--no-color',
      ...<String>['-r', 'compact'],
      '--concurrency=$concurrency',
      if (isDebug) '--pause-after-load',
      '--platform=chrome',
      '--precompiled=${environment.webUiRootDir.path}/build',
      '--',
      ...testFiles.map((f) => f.relativeToWebUi).toList(),
    ];
    hack.registerPlatformPlugin(<Runtime>[Runtime.chrome], () {
      return BrowserPlatform.start(root: io.Directory.current.path);
    });

    // We want to run tests with `web_ui` as a working directory.
    final dynamic backupCwd = io.Directory.current;
    io.Directory.current = environment.webUiRootDir.path;
    await test.main(testArgs);
    io.Directory.current = backupCwd;

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
  }
}

void _copyAhemFontIntoWebUi() {
  final io.File sourceAhemTtf = io.File(path.join(
      environment.flutterDirectory.path,
      'third_party',
      'txt',
      'third_party',
      'fonts',
      'ahem.ttf'));
  final String destinationAhemTtfPath =
      path.join(environment.webUiRootDir.path, 'lib', 'assets', 'ahem.ttf');
  sourceAhemTtf.copySync(destinationAhemTtfPath);
}
