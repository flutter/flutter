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

import 'chrome.dart';
import 'chrome_installer.dart';
import 'test_platform.dart';
import 'environment.dart';
import 'utils.dart';

class TestCommand extends Command<bool> {
  TestCommand() {
    argParser
      ..addFlag(
        'debug',
        help: 'Pauses the browser before running a test, giving you an '
            'opportunity to add breakpoints or inspect loaded code before '
            'running the code.',
      )
      ..addFlag(
        'update-screenshot-goldens',
        defaultsTo: false,
        help: 'When running screenshot tests writes them to the file system into '
            '.dart_tool/goldens. Use this option to bulk-update all screenshots, '
            'for example, when a new browser version affects pixels.',
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

    _copyTestFontsIntoWebUi();
    await _buildHostPage();

    final List<FilePath> targets =
        this.targets.map((t) => FilePath.fromCwd(t)).toList();
    await _buildTests(targets: targets);
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
  List<String> get targets => argResults.rest;

  /// See [ChromeInstallerCommand.chromeVersion].
  String get chromeVersion => argResults['chrome-version'];

  /// When running screenshot tests writes them to the file system into
  /// ".dart_tool/goldens".
  bool get doUpdateScreenshotGoldens => argResults['update-screenshot-goldens'];

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

  Future<void> _buildHostPage() async {
    final String hostDartPath = path.join('lib', 'static', 'host.dart');
    final io.File hostDartFile = io.File(path.join(
      environment.webEngineTesterRootDir.path,
      hostDartPath,
    ));
    final io.File timestampFile = io.File(path.join(
      environment.webEngineTesterRootDir.path,
      '$hostDartPath.js.timestamp',
    ));

    final String timestamp = hostDartFile.statSync().modified.millisecondsSinceEpoch.toString();
    if (timestampFile.existsSync()) {
      final String lastBuildTimestamp = timestampFile.readAsStringSync();
      if (lastBuildTimestamp == timestamp) {
        // The file is still fresh. No need to rebuild.
        return;
      } else {
        // Record new timestamp, but don't return. We need to rebuild.
        print('${hostDartFile.path} timestamp changed. Rebuilding.');
      }
    } else {
      print('Building ${hostDartFile.path}.');
    }

    final int exitCode = await runProcess(
      environment.dart2jsExecutable,
      <String>[
        hostDartPath,
        '-o',
        '$hostDartPath.js',
      ],
      workingDirectory: environment.webEngineTesterRootDir.path,
    );

    if (exitCode != 0) {
      io.stderr.writeln(
          'Failed to compile ${hostDartFile.path}. Compiler exited with exit code $exitCode');
      io.exit(1);
    }

    // Record the timestamp to avoid rebuilding unless the file changes.
    timestampFile.writeAsStringSync(timestamp);
  }

  Future<void> _buildTests({ List<FilePath> targets }) async {
    final int exitCode = await runProcess(
      environment.pubExecutable,
      <String>[
        'run',
        'build_runner',
        'build',
        'test',
        '-o',
        'build',
        if (targets != null)
          for (FilePath path in targets)
            ...[
              '--build-filter=${path.relativeToWebUi}.js',
              '--build-filter=${path.relativeToWebUi}.browser_test.dart.js',
            ],
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
      ...<String>['-r', 'compact'],
      '--concurrency=$concurrency',
      if (isDebug) '--pause-after-load',
      '--platform=chrome',
      '--precompiled=${environment.webUiRootDir.path}/build',
      '--',
      ...testFiles.map((f) => f.relativeToWebUi).toList(),
    ];
    hack.registerPlatformPlugin(<Runtime>[Runtime.chrome], () {
      return BrowserPlatform.start(
        root: io.Directory.current.path,
        // It doesn't make sense to update a screenshot for a test that is expected to fail.
        doUpdateScreenshotGoldens: !expectFailure && doUpdateScreenshotGoldens,
      );
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

const List<String> _kTestFonts = <String>['ahem.ttf', 'Roboto-Regular.ttf'];

void _copyTestFontsIntoWebUi() {
  final String fontsPath = path.join(
    environment.flutterDirectory.path,
    'third_party',
    'txt',
    'third_party',
    'fonts',
  );

  for (String fontFile in _kTestFonts) {
    final io.File sourceTtf = io.File(path.join(fontsPath, fontFile));
    final String destinationTtfPath = path.join(environment.webUiRootDir.path, 'lib', 'assets', fontFile);
    sourceTtf.copySync(destinationTtfPath);
  }
}
