// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart' as pathlib;
// TODO(yjbanov): remove hacks when this is fixed:
//                https://github.com/dart-lang/test/issues/1521
import 'package:skia_gold_client/skia_gold_client.dart';
import 'package:test_api/src/backend/runtime.dart' as hack;
import 'package:test_core/src/executable.dart' as test;
import 'package:test_core/src/runner/hack_register_platform.dart' as hack;

import '../browser.dart';
import '../common.dart';
import '../environment.dart';
import '../exceptions.dart';
import '../felt_config.dart';
import '../pipeline.dart';
import '../test_platform.dart';
import '../utils.dart';

/// Runs a test suite.
///
/// Assumes the artifacts from previous steps are available, either from
/// running them prior to this step locally, or by having the build graph copy
/// them from another bot.
class RunSuiteStep implements PipelineStep {
  RunSuiteStep(this.suite, {
    required this.startPaused,
    required this.isVerbose,
    required this.doUpdateScreenshotGoldens,
    required this.requireSkiaGold,
    required this.overridePathToCanvasKit,
    required this.useDwarf,
    this.testFiles,
  });

  final TestSuite suite;
  final Set<FilePath>? testFiles;
  final bool startPaused;
  final bool isVerbose;
  final bool doUpdateScreenshotGoldens;
  final String? overridePathToCanvasKit;
  final bool useDwarf;

  /// Require Skia Gold to be available and reachable.
  final bool requireSkiaGold;

  bool get isWasm => suite.testBundle.compileConfig.compiler == Compiler.dart2wasm;

  @override
  String get description => 'run_suite';

  @override
  bool get isSafeToInterrupt => true;

  @override
  Future<void> interrupt() async {}

  @override
  Future<void> run() async {
    _prepareTestResultsDirectory();
    final BrowserEnvironment browserEnvironment = getBrowserEnvironment(
      suite.runConfig.browser,
      enableWasmGC: isWasm,
      useDwarf: useDwarf,
    );
    await browserEnvironment.prepare();

    final SkiaGoldClient? skiaClient = await _createSkiaClient();
    final String configurationFilePath = pathlib.join(
      environment.webUiRootDir.path,
      browserEnvironment.packageTestConfigurationYamlFile,
    );
    final String bundleBuildPath = getBundleBuildDirectory(suite.testBundle).path;
    final List<String> testArgs = <String>[
      ...<String>['-r', 'compact'],
      // Disable concurrency. Running with concurrency proved to be flaky.
      '--concurrency=1',
      if (startPaused) '--pause-after-load',
      '--platform=${browserEnvironment.packageTestRuntime.identifier}',
      '--precompiled=$bundleBuildPath',
      '--configuration=$configurationFilePath',

      // TODO(jacksongardner): Set the default timeout to five minutes when
      // https://github.com/dart-lang/test/issues/2006 is fixed.
      '--',
      ..._collectTestPaths(),
    ];

    hack.registerPlatformPlugin(<hack.Runtime>[
      browserEnvironment.packageTestRuntime,
    ], () {
      return BrowserPlatform.start(
        suite,
        browserEnvironment: browserEnvironment,
        doUpdateScreenshotGoldens: doUpdateScreenshotGoldens,
        skiaClient: skiaClient,
        overridePathToCanvasKit: overridePathToCanvasKit,
        isVerbose: isVerbose,
      );
    });

    print('[${suite.name.ansiCyan}] Running...');

    // We want to run tests with the test set's directory as a working directory.
    final io.Directory testSetDirectory = io.Directory(pathlib.join(
      environment.webUiTestDir.path,
      suite.testBundle.testSet.directory,
    ));
    final dynamic originalCwd = io.Directory.current;
    io.Directory.current = testSetDirectory;
    try {
      await test.main(testArgs);
    } finally {
      io.Directory.current = originalCwd;
    }

    await browserEnvironment.cleanup();

    // Since we are just calling `main()` on the test executable, it will modify
    // the exit code. We use this as a signal that there were some tests that failed.
    if (io.exitCode != 0) {
      print('[${suite.name.ansiCyan}] ${'Some tests failed.'.ansiRed}');
      // Change the exit code back to 0 when we're done. Failures will be bubbled up
      // at the end of the pipeline and we'll exit abnormally if there were any
      // failures in the pipeline.
      io.exitCode = 0;
      throw ToolExit('Some unit tests failed in suite ${suite.name.ansiCyan}.');
    } else {
      print('[${suite.name.ansiCyan}] ${'All tests passed!'.ansiGreen}');
    }
  }

  io.Directory _prepareTestResultsDirectory() {
    final io.Directory resultsDirectory = io.Directory(pathlib.join(
      environment.webUiTestResultsDirectory.path,
      suite.name,
    ));
    if (resultsDirectory.existsSync()) {
      resultsDirectory.deleteSync(recursive: true);
    }
    resultsDirectory.createSync(recursive: true);
    return resultsDirectory;
  }

  List<String> _collectTestPaths() {
    final io.Directory bundleBuild = getBundleBuildDirectory(suite.testBundle);
    final io.File resultsJsonFile = io.File(pathlib.join(
      bundleBuild.path,
      'results.json',
    ));
    if (!resultsJsonFile.existsSync()) {
      throw ToolExit('Could not find built bundle ${suite.testBundle.name.ansiMagenta} for suite ${suite.name.ansiCyan}.');
    }
    final String jsonString = resultsJsonFile.readAsStringSync();
    final dynamic jsonContents = const JsonDecoder().convert(jsonString);
    final dynamic results = jsonContents['results'];
    final List<String> testPaths = <String>[];
    results.forEach((dynamic k, dynamic v) {
      final String result = v as String;
      final String testPath = k as String;
      if (testFiles != null) {
        if (!testFiles!.contains(FilePath.fromTestSet(suite.testBundle.testSet, testPath))) {
          return;
        }
      }
      if (result == 'success') {
        testPaths.add(testPath);
      }
    });
    return testPaths;
  }

  Future<SkiaGoldClient?> _createSkiaClient() async {
    final Renderer renderer = suite.testBundle.compileConfig.renderer;
    final CanvasKitVariant? variant = suite.runConfig.variant;
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      getSkiaGoldDirectoryForSuite(suite),
      dimensions: <String, String> {
        'Browser': suite.runConfig.browser.name,
        if (isWasm) 'Wasm': 'true',
        'Renderer': renderer.name,
        if (variant != null) 'CanvasKitVariant': variant.name,
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
