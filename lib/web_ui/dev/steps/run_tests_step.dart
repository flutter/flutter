// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as pathlib;
// TODO(yjbanov): remove hacks when this is fixed:
//                https://github.com/dart-lang/test/issues/1521
import 'package:test_api/src/backend/group.dart' as hack;
import 'package:test_api/src/backend/live_test.dart' as hack;
import 'package:test_api/src/backend/runtime.dart' as hack;
import 'package:test_core/src/executable.dart' as test;
import 'package:test_core/src/runner/configuration/reporters.dart' as hack;
import 'package:test_core/src/runner/engine.dart' as hack;
import 'package:test_core/src/runner/hack_register_platform.dart' as hack;
import 'package:test_core/src/runner/reporter.dart' as hack;

import '../browser.dart';
import '../environment.dart';
import '../exceptions.dart';
import '../test_platform.dart';
import '../utils.dart';
import '../watcher.dart';

// Maximum number of tests that run concurrently.
const int _testConcurrency = int.fromEnvironment('FELT_TEST_CONCURRENCY', defaultValue: 10);

/// Runs web tests.
///
/// Assumes the artifacts from [CompileTestsStep] are available, either from
/// running it prior to this step locally, or by having the build graph copy
/// them from another bot.
class RunTestsStep implements PipelineStep {
  RunTestsStep({
    required this.browserEnvironment,
    required this.isDebug,
    required this.doUpdateScreenshotGoldens,
    this.testFiles,
  });

  final BrowserEnvironment browserEnvironment;
  final List<FilePath>? testFiles;
  final bool isDebug;
  final bool doUpdateScreenshotGoldens;

  /// Global list of shards that failed.
  ///
  /// This is used to make sure that when there's a test failure anywhere we
  /// exit with a non-zero exit code.
  ///
  /// Shards must never be removed from this list, only added.
  List<String> failedShards = <String>[];

  /// Whether all test shards succeeded.
  bool get allShardsPassed => failedShards.isEmpty;

  @override
  String get description => 'run_tests';

  @override
  bool get isSafeToInterrupt => true;

  @override
  Future<void> interrupt() async {}

  @override
  Future<void> run() async {
    _copyTestFontsIntoWebUi();
    await _prepareTestResultsDirectory();
    await browserEnvironment.prepareEnvironment();

    final List<FilePath> testFiles = this.testFiles ?? findAllTests();

    // Separate screenshot tests from unit-tests. Screenshot tests must run
    // one at a time. Otherwise, they will end up screenshotting each other.
    // This is not an issue for unit-tests.
    final FilePath failureSmokeTestPath = FilePath.fromWebUi(
      'test/golden_tests/golden_failure_smoke_test.dart',
    );
    final List<FilePath> screenshotTestFiles = <FilePath>[];
    final List<FilePath> unitTestFiles = <FilePath>[];

    for (final FilePath testFilePath in testFiles) {
      if (!testFilePath.absolute.endsWith('_test.dart')) {
        // Not a test file at all. Skip.
        continue;
      }
      if (testFilePath == failureSmokeTestPath) {
        // A smoke test that fails on purpose. Skip.
        continue;
      }

      // All files under test/golden_tests are considered golden tests.
      final bool isUnderGoldenTestsDirectory =
          pathlib.split(testFilePath.relativeToWebUi).contains('golden_tests');
      // Any file whose name ends with "_golden_test.dart" is run as a golden test.
      final bool isGoldenTestFile = pathlib
          .basename(testFilePath.relativeToWebUi)
          .endsWith('_golden_test.dart');
      if (isUnderGoldenTestsDirectory || isGoldenTestFile) {
        screenshotTestFiles.add(testFilePath);
      } else {
        unitTestFiles.add(testFilePath);
      }
    }

    // This test returns a non-zero exit code on purpose. Run it separately.
    if (testFiles.contains(failureSmokeTestPath)) {
      await _runTestBatch(
        testFiles: <FilePath>[failureSmokeTestPath],
        browserEnvironment: browserEnvironment,
        concurrency: 1,
        expectFailure: true,
        isDebug: isDebug,
        doUpdateScreenshotGoldens: doUpdateScreenshotGoldens,
      );
    }

    // Run all unit-tests as a single batch and with high concurrency.
    if (unitTestFiles.isNotEmpty) {
      await _runTestBatch(
        testFiles: unitTestFiles,
        browserEnvironment: browserEnvironment,
        concurrency: _testConcurrency,
        expectFailure: false,
        isDebug: isDebug,
        doUpdateScreenshotGoldens: doUpdateScreenshotGoldens,
      );
      _checkExitCode('Unit tests');
    }

    // Run screenshot tests one at a time. Otherwise, tests end up
    // screenshotting each other.
    for (final FilePath screenshotTestFilePath in screenshotTestFiles) {
      await _runTestBatch(
        testFiles: <FilePath>[screenshotTestFilePath],
        browserEnvironment: browserEnvironment,
        concurrency: 1,
        expectFailure: false,
        isDebug: isDebug,
        doUpdateScreenshotGoldens: doUpdateScreenshotGoldens,
      );
      _checkExitCode('Golden tests');
    }

    if (!allShardsPassed) {
      throw ToolExit(_createFailedShardsMessage());
    }
  }

  void _checkExitCode(String shard) {
    if (io.exitCode != 0) {
      failedShards.add(shard);
    }
  }

  String _createFailedShardsMessage() {
    final StringBuffer message = StringBuffer(
      'The following test shards failed:\n',
    );
    for (final String failedShard in failedShards) {
      message.writeln(' - $failedShard');
    }
    return message.toString();
  }
}

Future<void> _prepareTestResultsDirectory() async {
  if (environment.webUiTestResultsDirectory.existsSync()) {
    environment.webUiTestResultsDirectory.deleteSync(recursive: true);
  }
  environment.webUiTestResultsDirectory.createSync(recursive: true);
}

const List<String> _kTestFonts = <String>[
  'ahem.ttf',
  'Roboto-Regular.ttf',
  'NotoNaskhArabic-Regular.ttf',
  'NotoColorEmoji.ttf',
];

void _copyTestFontsIntoWebUi() {
  final String fontsPath = pathlib.join(
    environment.flutterDirectory.path,
    'third_party',
    'txt',
    'third_party',
    'fonts',
  );

  for (final String fontFile in _kTestFonts) {
    final io.File sourceTtf = io.File(pathlib.join(fontsPath, fontFile));
    final String destinationTtfPath =
        pathlib.join(environment.webUiRootDir.path, 'lib', 'assets', fontFile);
    sourceTtf.copySync(destinationTtfPath);
  }
}

/// Runs a batch of tests.
///
/// Unless [expectFailure] is set to false, sets [io.exitCode] to a non-zero
/// value if any tests fail.
Future<void> _runTestBatch({
  required List<FilePath> testFiles,
  required bool isDebug,
  required BrowserEnvironment browserEnvironment,
  required bool doUpdateScreenshotGoldens,
  required int concurrency,
  required bool expectFailure,
}) async {
  final String configurationFilePath = pathlib.join(
    environment.webUiRootDir.path,
    browserEnvironment.packageTestConfigurationYamlFile,
  );
  final List<String> testArgs = <String>[
    ...<String>['-r', 'compact'],
    '--concurrency=$concurrency',
    if (isDebug) '--pause-after-load',
    // Don't pollute logs with output from tests that are expected to fail.
    if (expectFailure)
      '--reporter=name-only',
    '--platform=${browserEnvironment.packageTestRuntime.identifier}',
    '--precompiled=${environment.webUiBuildDir.path}',
    '--configuration=$configurationFilePath',
    '--',
    ...testFiles.map((FilePath f) => f.relativeToWebUi).toList(),
  ];

  if (expectFailure) {
    hack.registerReporter(
      'name-only',
      hack.ReporterDetails(
      'Prints the name of the test, but suppresses all other test output.',
      (_, hack.Engine engine, __) => NameOnlyReporter(engine)),
    );
  }

  hack.registerPlatformPlugin(<hack.Runtime>[
    browserEnvironment.packageTestRuntime,
  ], () {
    return BrowserPlatform.start(
      browserEnvironment: browserEnvironment,
      // It doesn't make sense to update a screenshot for a test that is
      // expected to fail.
      doUpdateScreenshotGoldens: !expectFailure && doUpdateScreenshotGoldens,
    );
  });

  // We want to run tests with `web_ui` as a working directory.
  final dynamic originalCwd = io.Directory.current;
  io.Directory.current = environment.webUiRootDir.path;
  try {
    await test.main(testArgs);
  } finally {
    io.Directory.current = originalCwd;
  }

  if (expectFailure) {
    if (io.exitCode != 0) {
      // It failed, as expected.
      print('Test successfully failed, as expected.');
      io.exitCode = 0;
    } else {
      io.stderr.writeln(
        'Tests ${testFiles.join(', ')} did not fail. Expected failure.',
      );
      io.exitCode = 1;
    }
  }
}

/// Prints the name of the test, but suppresses all other test output.
///
/// This is useful to prevent pollution of logs by tests that are expected to
/// fail.
class NameOnlyReporter implements hack.Reporter {
  NameOnlyReporter(hack.Engine testEngine) {
    testEngine.onTestStarted.listen(_printTestName);
  }

  void _printTestName(hack.LiveTest test) {
    print('Running ${test.groups.map((hack.Group group) => group.name).join(' ')} ${test.individualName}');
  }

  @override
  void pause() {}

  @override
  void resume() {}
}
