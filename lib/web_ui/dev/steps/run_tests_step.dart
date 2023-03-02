// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as pathlib;
// TODO(yjbanov): remove hacks when this is fixed:
//                https://github.com/dart-lang/test/issues/1521
import 'package:skia_gold_client/skia_gold_client.dart';
import 'package:test_api/src/backend/group.dart' as hack;
import 'package:test_api/src/backend/live_test.dart' as hack;
import 'package:test_api/src/backend/runtime.dart' as hack;
import 'package:test_core/src/executable.dart' as test;
import 'package:test_core/src/runner/configuration/reporters.dart' as hack;
import 'package:test_core/src/runner/engine.dart' as hack;
import 'package:test_core/src/runner/hack_register_platform.dart' as hack;
import 'package:test_core/src/runner/reporter.dart' as hack;

import '../browser.dart';
import '../common.dart';
import '../environment.dart';
import '../exceptions.dart';
import '../pipeline.dart';
import '../test_platform.dart';
import '../utils.dart';

/// Runs web tests.
///
/// Assumes the artifacts from [CompileTestsStep] are available, either from
/// running it prior to this step locally, or by having the build graph copy
/// them from another bot.
class RunTestsStep implements PipelineStep {
  RunTestsStep({
    required this.browserName,
    required this.isDebug,
    required this.doUpdateScreenshotGoldens,
    required this.requireSkiaGold,
    this.testFiles,
    required this.overridePathToCanvasKit,
    required this.isWasm
  });

  final String browserName;
  final List<FilePath>? testFiles;
  final bool isDebug;
  final bool isWasm;
  final bool doUpdateScreenshotGoldens;
  final String? overridePathToCanvasKit;

  /// Require Skia Gold to be available and reachable.
  final bool requireSkiaGold;

  @override
  String get description => 'run_tests';

  @override
  bool get isSafeToInterrupt => true;

  @override
  Future<void> interrupt() async {}

  @override
  Future<void> run() async {
    await _prepareTestResultsDirectory();

    final BrowserEnvironment browserEnvironment = getBrowserEnvironment(browserName, enableWasmGC: isWasm);
    await browserEnvironment.prepare();

    final SkiaGoldClient? skiaClient = await _createSkiaClient();
    final List<FilePath> testFiles = this.testFiles ?? findAllTests();

    final TestsByRenderer sortedTests = sortTestsByRenderer(testFiles, isWasm);

    bool testsPassed = true;

    if (sortedTests.htmlTests.isNotEmpty) {
      await _runTestBatch(
        testFiles: sortedTests.htmlTests,
        renderer: Renderer.html,
        browserEnvironment: browserEnvironment,
        expectFailure: false,
        isDebug: isDebug,
        isWasm: isWasm,
        doUpdateScreenshotGoldens: doUpdateScreenshotGoldens,
        skiaClient: skiaClient,
        overridePathToCanvasKit: overridePathToCanvasKit,
      );
      testsPassed &= io.exitCode == 0;
    }

    if (sortedTests.canvasKitTests.isNotEmpty) {
      await _runTestBatch(
        testFiles: sortedTests.canvasKitTests,
        renderer: Renderer.canvasKit,
        browserEnvironment: browserEnvironment,
        expectFailure: false,
        isDebug: isDebug,
        isWasm: isWasm,
        doUpdateScreenshotGoldens: doUpdateScreenshotGoldens,
        skiaClient: skiaClient,
        overridePathToCanvasKit: overridePathToCanvasKit,
      );
      testsPassed &= io.exitCode == 0;
    }

    // TODO(jacksongardner): enable this test suite on safari
    // For some reason, Safari is flaky when running the Skwasm test suite
    // See https://github.com/flutter/flutter/issues/115312
    if (browserName != kSafari && sortedTests.skwasmTests.isNotEmpty) {
      await _runTestBatch(
        testFiles: sortedTests.skwasmTests,
        renderer: Renderer.skwasm,
        browserEnvironment: browserEnvironment,
        expectFailure: false,
        isDebug: isDebug,
        isWasm: isWasm,
        doUpdateScreenshotGoldens: doUpdateScreenshotGoldens,
        skiaClient: skiaClient,
        overridePathToCanvasKit: overridePathToCanvasKit,
      );
      testsPassed &= io.exitCode == 0;
    }

    await browserEnvironment.cleanup();

    if (!testsPassed) {
      throw ToolExit('Some tests failed');
    }
  }

  Future<SkiaGoldClient?> _createSkiaClient() async {
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      environment.webUiSkiaGoldDirectory,
      dimensions: <String, String> {
        'Browser': browserName,
        if (isWasm) 'Wasm': 'true',
      },
    );

    if (await _checkSkiaClient(skiaClient)) {
      return skiaClient;
    }

    if (requireSkiaGold) {
      throw ToolExit('Skia Gold is required but is unavailable.');
    }

    return null;
  }

  /// Checks whether the Skia Client is usable in this environment.
  Future<bool> _checkSkiaClient(SkiaGoldClient skiaClient) async {
    // Now let's check whether Skia Gold is reachable or not.
    if (isLuci) {
      if (isSkiaGoldClientAvailable) {
        try {
          await skiaClient.auth();
          return true;
        } catch (e) {
          print(e);
        }
      }
    } else {
      try {
        // Check if we can reach Gold.
        await skiaClient.getExpectationForTest('');
        return true;
      } on io.OSError catch (_) {
        print('OSError occurred, could not reach Gold.');
      } on io.SocketException catch (_) {
        print('SocketException occurred, could not reach Gold.');
      }
    }

    return false;
  }
}

Future<void> _prepareTestResultsDirectory() async {
  if (environment.webUiTestResultsDirectory.existsSync()) {
    environment.webUiTestResultsDirectory.deleteSync(recursive: true);
  }
  environment.webUiTestResultsDirectory.createSync(recursive: true);
}

/// Runs a batch of tests.
///
/// Unless [expectFailure] is set to false, sets [io.exitCode] to a non-zero
/// value if any tests fail.
Future<void> _runTestBatch({
  required List<FilePath> testFiles,
  required Renderer renderer,
  required bool isDebug,
  required bool isWasm,
  required BrowserEnvironment browserEnvironment,
  required bool doUpdateScreenshotGoldens,
  required bool expectFailure,
  required SkiaGoldClient? skiaClient,
  required String? overridePathToCanvasKit,
}) async {
  final String configurationFilePath = pathlib.join(
    environment.webUiRootDir.path,
    browserEnvironment.packageTestConfigurationYamlFile,
  );
  final String precompiledBuildDir = pathlib.join(
    environment.webUiBuildDir.path,
    getBuildDirForRenderer(renderer),
  );
  final List<String> testArgs = <String>[
    ...<String>['-r', 'compact'],
    // Disable concurrency. Running with concurrency proved to be flaky.
    '--concurrency=1',
    if (isDebug) '--pause-after-load',
    // Don't pollute logs with output from tests that are expected to fail.
    if (expectFailure)
      '--reporter=name-only',
    '--platform=${browserEnvironment.packageTestRuntime.identifier}',
    '--precompiled=$precompiledBuildDir',
    '--configuration=$configurationFilePath',
    '--',
    ...testFiles.map((FilePath f) => f.relativeToWebUi),
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
      renderer: renderer,
      // It doesn't make sense to update a screenshot for a test that is
      // expected to fail.
      doUpdateScreenshotGoldens: !expectFailure && doUpdateScreenshotGoldens,
      skiaClient: skiaClient,
      overridePathToCanvasKit: overridePathToCanvasKit,
      isWasm: isWasm,
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
