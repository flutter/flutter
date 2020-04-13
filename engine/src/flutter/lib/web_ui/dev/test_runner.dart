// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
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

import 'environment.dart';
import 'exceptions.dart';
import 'integration_tests_manager.dart';
import 'supported_browsers.dart';
import 'test_platform.dart';
import 'utils.dart';

/// The type of tests requested by the tool user.
enum TestTypesRequested {
  /// For running the unit tests only.
  unit,

  /// For running the integration tests only.
  integration,

  /// For running both unit and integration tests.
  all,
}

class TestCommand extends Command<bool> with ArgUtils {
  TestCommand() {
    argParser
      ..addFlag(
        'debug',
        help: 'Pauses the browser before running a test, giving you an '
            'opportunity to add breakpoints or inspect loaded code before '
            'running the code.',
      )
      ..addFlag(
        'unit-tests-only',
        defaultsTo: false,
        help: 'felt test command runs the unit tests and the integration tests '
            'at the same time. If this flag is set, only run the unit tests.',
      )
      ..addFlag(
        'integration-tests-only',
        defaultsTo: false,
        help: 'felt test command runs the unit tests and the integration tests '
            'at the same time. If this flag is set, only run the integration '
            'tests.',
      )
      ..addFlag('use-system-flutter',
        defaultsTo: false,
        help: 'integration tests are using flutter repository for various tasks'
        ', such as flutter drive, flutter pub get. If this flag is set, felt '
        'will use flutter command without cloning the repository. This flag '
        'can save internet bandwidth. However use with caution. Note that '
        'since flutter repo is always synced to youngest commit older than '
        'the engine commit for the tests running in CI, the tests results '
        'won\'t be consistent with CIs when this flag is set. flutter '
        'command should be set in the PATH for this flag to be useful.'
        'This flag can also be used to test local Flutter changes.'
      )
      ..addFlag(
        'update-screenshot-goldens',
        defaultsTo: false,
        help:
            'When running screenshot tests writes them to the file system into '
            '.dart_tool/goldens. Use this option to bulk-update all screenshots, '
            'for example, when a new browser version affects pixels.',
      )
      ..addOption(
        'browser',
        defaultsTo: 'chrome',
        help: 'An option to choose a browser to run the tests. Tests only work '
            ' on Chrome for now.',
      );

    SupportedBrowsers.instance.argParsers
        .forEach((t) => t.populateOptions(argParser));
  }

  @override
  final String name = 'test';

  @override
  final String description = 'Run tests.';

  TestTypesRequested testTypesRequested = null;

  /// Check the flags to see what type of tests are requested.
  TestTypesRequested findTestType() {
    if (boolArg('unit-tests-only') && boolArg('integration-tests-only')) {
      throw ArgumentError('Conflicting arguments: unit-tests-only and '
          'integration-tests-only are both set');
    } else if (boolArg('unit-tests-only')) {
      print('Running the unit tests only');
      return TestTypesRequested.unit;
    } else if (boolArg('integration-tests-only')) {
      if (!isChrome) {
        throw UnimplementedError(
            'Integration tests are only available on Chrome Desktop for now');
      }
      return TestTypesRequested.integration;
    } else {
      return TestTypesRequested.all;
    }
  }

  @override
  Future<bool> run() async {
    SupportedBrowsers.instance
      ..argParsers.forEach((t) => t.parseOptions(argResults));

    // Check the flags to see what type of integration tests are requested.
    testTypesRequested = findTestType();

    switch (testTypesRequested) {
      case TestTypesRequested.unit:
        return runUnitTests();
      case TestTypesRequested.integration:
        return runIntegrationTests();
      case TestTypesRequested.all:
        // TODO(nurhan): https://github.com/flutter/flutter/issues/53322
        // TODO(nurhan): Expand browser matrix for felt integration tests.
        if (runAllTests && isChrome) {
          bool integrationTestResult = await runIntegrationTests();
          bool unitTestResult = await runUnitTests();
          if (integrationTestResult != unitTestResult) {
            print('Tests run. Integration tests passed: $integrationTestResult '
                'unit tests passed: $unitTestResult');
          }
          return integrationTestResult && unitTestResult;
        } else {
          return await runUnitTests();
        }
    }
    return false;
  }

  Future<bool> runIntegrationTests() async {
    // TODO(nurhan): https://github.com/flutter/flutter/issues/52983
    if (io.Platform.environment['LUCI_CONTEXT'] != null) {
      return true;
    }

    return IntegrationTestsManager(browser, useSystemFlutter).runTests();
  }

  Future<bool> runUnitTests() async {
    _copyTestFontsIntoWebUi();
    await _buildHostPage();
    if (io.Platform.isWindows) {
      // On Dart 2.7 or greater, it gives an error for not
      // recognized "pub" version and asks for "pub" get.
      // See: https://github.com/dart-lang/sdk/issues/39738
      await _runPubGet();
    }

    await _buildTests(targets: targetFiles);

    // Many tabs will be left open after Safari runs, quit Safari during
    // cleanup.
    if (browser == 'safari') {
      cleanupCallbacks.add(() async {
        // Only close Safari if felt is running in CI environments. Do not close
        // Safari for the local testing.
        if (io.Platform.environment['LUCI_CONTEXT'] != null || isCirrus) {
          print('INFO: Safari tests ran. Quit Safari.');
          await runProcess(
            'sudo',
            ['pkill', '-lf', 'Safari'],
            workingDirectory: environment.webUiRootDir.path,
          );
        } else {
          print('INFO: Safari tests ran. Please quit Safari tabs.');
        }
      });
    }

    if (runAllTests) {
      await _runAllTests();
    } else {
      await _runTargetTests(targetFiles);
    }
    return true;
  }

  /// Whether to start the browser in debug mode.
  ///
  /// In this mode the browser pauses before running the test to allow
  /// you set breakpoints or inspect the code.
  bool get isDebug => boolArg('debug');

  /// Paths to targets to run, e.g. a single test.
  List<String> get targets => argResults.rest;

  /// The target test files to run.
  ///
  /// The value can be null if the developer prefers to run all the tests.
  List<FilePath> get targetFiles => (targets.isEmpty)
      ? null
      : targets.map((t) => FilePath.fromCwd(t)).toList();

  /// Whether all tests should run.
  bool get runAllTests => targets.isEmpty;

  /// The name of the browser to run tests in.
  String get browser => (argResults != null) ? stringArg('browser') : 'chrome';

  /// Whether [browser] is set to "chrome".
  bool get isChrome => browser == 'chrome';

  /// Use system flutter instead of cloning the repository.
  ///
  /// Read the flag help for more details. Uses PATH to locate flutter.
  bool get useSystemFlutter => boolArg('use-system-flutter');

  /// When running screenshot tests writes them to the file system into
  /// ".dart_tool/goldens".
  bool get doUpdateScreenshotGoldens => boolArg('update-screenshot-goldens');

  Future<void> _runTargetTests(List<FilePath> targets) async {
    await _runTestBatch(targets, concurrency: 1, expectFailure: false);
    _checkExitCode();
  }

  Future<void> _runAllTests() async {
    final io.Directory testDir = io.Directory(path.join(
      environment.webUiRootDir.path,
      'test',
    ));

    // Screenshot tests and smoke tests only run in Chrome.
    if (isChrome) {
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
    } else {
      final List<FilePath> unitTestFiles = <FilePath>[];
      for (io.File testFile
          in testDir.listSync(recursive: true).whereType<io.File>()) {
        final FilePath testFilePath = FilePath.fromCwd(testFile.path);
        if (!testFilePath.absolute.endsWith('_test.dart')) {
          // Not a test file at all. Skip.
          continue;
        }
        if (!path
            .split(testFilePath.relativeToWebUi)
            .contains('golden_tests')) {
          unitTestFiles.add(testFilePath);
        }
      }
      // Run all unit-tests as a single batch.
      await _runTestBatch(unitTestFiles, concurrency: 10, expectFailure: false);
      _checkExitCode();
    }
  }

  void _checkExitCode() {
    if (io.exitCode != 0) {
      throw ToolException('Process exited with exit code ${io.exitCode}.');
    }
  }

  Future<void> _runPubGet() async {
    final int exitCode = await runProcess(
      environment.pubExecutable,
      <String>[
        'get',
      ],
      workingDirectory: environment.webUiRootDir.path,
    );

    if (exitCode != 0) {
      throw ToolException(
          'Failed to run pub get. Exited with exit code $exitCode');
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

    final String timestamp =
        hostDartFile.statSync().modified.millisecondsSinceEpoch.toString();
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
      throw ToolException('Failed to compile ${hostDartFile.path}. Compiler '
          'exited with exit code $exitCode');
    }

    // Record the timestamp to avoid rebuilding unless the file changes.
    timestampFile.writeAsStringSync(timestamp);
  }

  Future<void> _buildTests({List<FilePath> targets}) async {
    List<String> arguments = <String>[
      'run',
      'build_runner',
      'build',
      'test',
      '-o',
      'build',
      if (targets != null)
        for (FilePath path in targets) ...[
          '--build-filter=${path.relativeToWebUi}.js',
          '--build-filter=${path.relativeToWebUi}.browser_test.dart.js',
        ],
    ];
    final int exitCode = await runProcess(
      environment.pubExecutable,
      arguments,
      workingDirectory: environment.webUiRootDir.path,
    );

    if (exitCode != 0) {
      throw ToolException(
          'Failed to compile tests. Compiler exited with exit code $exitCode');
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
      '--platform=${SupportedBrowsers.instance.supportedBrowserToPlatform[browser]}',
      '--precompiled=${environment.webUiRootDir.path}/build',
      SupportedBrowsers.instance.browserToConfiguration[browser],
      '--',
      ...testFiles.map((f) => f.relativeToWebUi).toList(),
    ];

    hack.registerPlatformPlugin(<Runtime>[
      SupportedBrowsers.instance.supportedBrowsersToRuntimes[browser]
    ], () {
      return BrowserPlatform.start(
        browser,
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
    final String destinationTtfPath =
        path.join(environment.webUiRootDir.path, 'lib', 'assets', fontFile);
    sourceTtf.copySync(destinationTtfPath);
  }
}
