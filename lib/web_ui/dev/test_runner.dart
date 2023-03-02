// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import 'package:watcher/src/watch_event.dart';

import 'pipeline.dart';
import 'steps/compile_tests_step.dart';
import 'steps/run_tests_step.dart';
import 'utils.dart';

/// Runs tests.
class TestCommand extends Command<bool> with ArgUtils<bool> {
  TestCommand() {
    argParser
      ..addFlag(
        'debug',
        help: 'Pauses the browser before running a test, giving you an '
            'opportunity to add breakpoints or inspect loaded code before '
            'running the code.',
      )
      ..addFlag(
        'watch',
        abbr: 'w',
        help: 'Run in watch mode so the tests re-run whenever a change is '
            'made.',
      )
      ..addFlag(
        'use-system-flutter',
        help: 'integration tests are using flutter repository for various tasks'
            ', such as flutter drive, flutter pub get. If this flag is set, felt '
            'will use flutter command without cloning the repository. This flag '
            'can save internet bandwidth. However use with caution. Note that '
            'since flutter repo is always synced to youngest commit older than '
            'the engine commit for the tests running in CI, the tests results '
            "won't be consistent with CIs when this flag is set. flutter "
            'command should be set in the PATH for this flag to be useful.'
            'This flag can also be used to test local Flutter changes.')
      ..addFlag(
        'require-skia-gold',
        help:
            'Whether we require Skia Gold to be available or not. When this '
            'flag is true, the tests will fail if Skia Gold is not available.',
      )
      ..addFlag(
        'update-screenshot-goldens',
        help:
            'When running screenshot tests writes them to the file system into '
            '.dart_tool/goldens. Use this option to bulk-update all screenshots, '
            'for example, when a new browser version affects pixels.',
      )
      ..addOption(
        'browser',
        defaultsTo: 'chrome',
        help: 'An option to choose a browser to run the tests. By default '
              'tests run in Chrome.',
      )
      ..addFlag(
        'fail-early',
        help: 'If set, causes the test runner to exit upon the first test '
              'failure. If not set, the test runner will continue running '
              'test despite failures and will report them after all tests '
              'finish.',
      )
      ..addOption(
        'canvaskit-path',
        help: 'Optional. The path to a local build of CanvasKit to use in '
              'tests. If omitted, the test runner uses the default CanvasKit '
              'build.',
      )
      ..addFlag(
        'wasm',
        help: 'Whether the test we are running are compiled to webassembly.'
      )
      ..addFlag(
        'use-local-canvaskit',
        help: 'Optional. Whether or not to use the locally built version of '
              'CanvasKit in the tests.',
      );
  }

  @override
  final String name = 'test';

  @override
  final String description = 'Run tests.';

  bool get isWatchMode => boolArg('watch');

  bool get failEarly => boolArg('fail-early');

  bool get isWasm => boolArg('wasm');

  /// Whether to start the browser in debug mode.
  ///
  /// In this mode the browser pauses before running the test to allow
  /// you set breakpoints or inspect the code.
  bool get isDebug => boolArg('debug');

  /// Paths to targets to run, e.g. a single test.
  List<String> get targets => argResults!.rest;

  /// The target test files to run.
  List<FilePath> get targetFiles => targets.map((String t) => FilePath.fromCwd(t)).toList();

  /// Whether all tests should run.
  bool get runAllTests => targets.isEmpty;

  /// The name of the browser to run tests in.
  String get browserName => stringArg('browser');

  /// When running screenshot tests, require Skia Gold to be available and
  /// reachable.
  bool get requireSkiaGold => boolArg('require-skia-gold');

  /// When running screenshot tests writes them to the file system into
  /// ".dart_tool/goldens".
  bool get doUpdateScreenshotGoldens => boolArg('update-screenshot-goldens');

  /// Path to a CanvasKit build. Overrides the default CanvasKit.
  String? get overridePathToCanvasKit => argResults!['canvaskit-path'] as String?;

  /// Whether or not to use the locally built version of CanvasKit.
  bool get useLocalCanvasKit => boolArg('use-local-canvaskit');

  @override
  Future<bool> run() async {
    final List<FilePath> testFiles = runAllTests
          ? findAllTests()
          : targetFiles;

    final Pipeline testPipeline = Pipeline(steps: <PipelineStep>[
      if (isWatchMode) ClearTerminalScreenStep(),
      CompileTestsStep(
        testFiles: testFiles,
        useLocalCanvasKit: useLocalCanvasKit,
        isWasm: isWasm
      ),
      RunTestsStep(
        browserName: browserName,
        testFiles: testFiles,
        isDebug: isDebug,
        isWasm: isWasm,
        doUpdateScreenshotGoldens: doUpdateScreenshotGoldens,
        requireSkiaGold: requireSkiaGold,
        overridePathToCanvasKit: overridePathToCanvasKit,
      ),
    ]);

    try {
      await testPipeline.run();
      if (isWatchMode) {
        print('');
        print('Initial test succeeded!');
      }
    } catch(error, stackTrace) {
      if (isWatchMode) {
        // The error is printed but not rethrown in watch mode because
        // failures are expected. The idea is that the developer corrects the
        // error, saves the file, and the pipeline reruns.
        print('');
        print('Initial test failed!\n');
        print(error);
        print(stackTrace);
      } else {
        rethrow;
      }
    }

    if (isWatchMode) {
      final FilePath dir = FilePath.fromWebUi('');
      print('');
      print(
          'Watching ${dir.relativeToCwd}/lib and ${dir.relativeToCwd}/test to re-run tests');
      print('');
      await PipelineWatcher(
          dir: dir.absolute,
          pipeline: testPipeline,
          ignore: (WatchEvent event) {
            // Ignore font files that are copied whenever tests run.
            if (event.path.endsWith('.ttf')) {
              return true;
            }

            // React to changes in lib/ and test/ folders.
            final String relativePath =
                path.relative(event.path, from: dir.absolute);
            if (path.isWithin('lib', relativePath) ||
                path.isWithin('test', relativePath)) {
              return false;
            }

            // Ignore anything else.
            return true;
          }).start();
    }
    return true;
  }
}

/// Clears the terminal screen and places the cursor at the top left corner.
///
/// This works on Linux and Mac. On Windows, it's a no-op.
class ClearTerminalScreenStep implements PipelineStep {
  @override
  String get description => 'clearing terminal screen';

  @override
  bool get isSafeToInterrupt => false;

  @override
  Future<void> interrupt() async {}

  @override
  Future<void> run() async {
    if (!io.Platform.isWindows) {
      // See: https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_sequences
      print('\x1B[2J\x1B[1;2H');
    }
  }
}
