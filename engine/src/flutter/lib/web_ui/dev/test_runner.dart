// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pool/pool.dart';
import 'package:test_core/src/runner/hack_register_platform.dart'
    as hack; // ignore: implementation_imports
import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test_core/src/executable.dart'
    as test; // ignore: implementation_imports
import 'package:web_test_utils/goldens.dart';

import 'common.dart';
import 'environment.dart';
import 'exceptions.dart';
import 'integration_tests_manager.dart';
import 'macos_info.dart';
import 'safari_installation.dart';
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
          help:
              'integration tests are using flutter repository for various tasks'
              ', such as flutter drive, flutter pub get. If this flag is set, felt '
              'will use flutter command without cloning the repository. This flag '
              'can save internet bandwidth. However use with caution. Note that '
              'since flutter repo is always synced to youngest commit older than '
              'the engine commit for the tests running in CI, the tests results '
              'won\'t be consistent with CIs when this flag is set. flutter '
              'command should be set in the PATH for this flag to be useful.'
              'This flag can also be used to test local Flutter changes.')
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
    GeneralTestsArgumentParser.instance.populateOptions(argParser);
    IntegrationTestsArgumentParser.instance.populateOptions(argParser);
  }

  @override
  final String name = 'test';

  @override
  final String description = 'Run tests.';

  TestTypesRequested testTypesRequested = null;

  /// How many dart2js build tasks are running at the same time.
  final Pool _pool = Pool(8);

  /// Checks if test harness preparation (such as fetching the goldens,
  /// creating test_results directory or starting ios-simulator) has been done.
  ///
  /// If unit tests already did these steps, integration tests do not have to
  /// repeat them.
  bool _testPreparationReady = false;

  /// Check the flags to see what type of tests are requested.
  TestTypesRequested findTestType() {
    if (boolArg('unit-tests-only') && boolArg('integration-tests-only')) {
      throw ArgumentError('Conflicting arguments: unit-tests-only and '
          'integration-tests-only are both set');
    } else if (boolArg('unit-tests-only')) {
      print('Running the unit tests only');
      return TestTypesRequested.unit;
    } else if (boolArg('integration-tests-only')) {
      if (!isChrome && !isSafariOnMacOS && !isFirefox) {
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
    GeneralTestsArgumentParser.instance.parseOptions(argResults);

    // Check the flags to see what type of integration tests are requested.
    testTypesRequested = findTestType();

    if (isSafariOnMacOS) {
      /// Collect information on the bot.
      final MacOSInfo macOsInfo = new MacOSInfo();
      await macOsInfo.printInformation();
    }

    switch (testTypesRequested) {
      case TestTypesRequested.unit:
        return runUnitTests();
      case TestTypesRequested.integration:
        return runIntegrationTests();
      case TestTypesRequested.all:
        if (runAllTests && isIntegrationTestsAvailable) {
          bool unitTestResult = await runUnitTests();
          bool integrationTestResult = await runIntegrationTests();
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
    // Parse additional arguments specific for integration testing.
    IntegrationTestsArgumentParser.instance.parseOptions(argResults);
    if(!_testPreparationReady) {
      await _prepare();
    }
    return IntegrationTestsManager(
            browser, useSystemFlutter, doUpdateScreenshotGoldens)
        .runTests();
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

    await _prepare();
    await _buildTargets();

    if (runAllTests) {
      await _runAllTestsForCurrentPlatform();
    } else {
      await _runSpecificTests(targetFiles);
    }
    return true;
  }

  /// Preparations before running the tests such as booting simulators or
  /// creating directories.
  Future<void> _prepare() async {
    if (environment.webUiTestResultsDirectory.existsSync()) {
      environment.webUiTestResultsDirectory.deleteSync(recursive: true);
    }
    environment.webUiTestResultsDirectory.createSync(recursive: true);

    // If screenshot tests are available, fetch the screenshot goldens.
    if (isScreenshotTestsAvailable) {
      if (isVerboseLoggingEnabled) {
        print('INFO: Screenshot tests available');
      }
      final GoldensRepoFetcher goldensRepoFetcher = GoldensRepoFetcher(
          environment.webUiGoldensRepositoryDirectory,
          path.join(environment.webUiDevDir.path, 'goldens_lock.yaml'));
      await goldensRepoFetcher.fetch();
    }

    // In order to run iOS Safari unit tests we need to make sure iOS Simulator
    // is booted.
    if (isSafariIOS) {
      await IosSafariArgParser.instance.initIosSimulator();
    }
    _testPreparationReady = true;
  }

  /// Builds all test targets that will be run.
  Future<void> _buildTargets() async {
    final Stopwatch stopwatch = Stopwatch()..start();
    List<FilePath> allTargets;
    if (runAllTests) {
      allTargets = environment.webUiTestDir
          .listSync(recursive: true)
          .whereType<io.File>()
          .where((io.File f) => f.path.endsWith('_test.dart'))
          .map<FilePath>((io.File f) => FilePath.fromWebUi(
              path.relative(f.path, from: environment.webUiRootDir.path)))
          .toList();
    } else {
      allTargets = targetFiles;
    }

    // Separate HTML targets from CanvasKit targets because the two use
    // different dart2js options.
    final List<FilePath> htmlTargets = <FilePath>[];
    final List<FilePath> canvasKitTargets = <FilePath>[];
    final String canvasKitTestDirectory =
        path.join(environment.webUiTestDir.path, 'canvaskit');
    for (FilePath target in allTargets) {
      if (path.isWithin(canvasKitTestDirectory, target.absolute)) {
        canvasKitTargets.add(target);
      } else {
        htmlTargets.add(target);
      }
    }

    if (htmlTargets.isNotEmpty) {
      await _buildTestsInParallel(targets: htmlTargets, forCanvasKit: false);
    }

    // Currently iOS Safari tests are running on simulator, which does not
    // support canvaskit backend.
    if (canvasKitTargets.isNotEmpty) {
      await _buildTestsInParallel(
          targets: canvasKitTargets, forCanvasKit: true);
    }

    _copyFilesFromTestToBuid();
    _copyFilesFromLibToBuid();

    stopwatch.stop();
    print('The build took ${stopwatch.elapsedMilliseconds ~/ 1000} seconds.');

    _cleanupExtraFilesUnderTestDir();
  }

  /// Copy image files from test/ to build/test/.
  ///
  /// By copying all the files helps with the following:
  /// - Tests using on an asset/image are able to reach these files.
  /// - Source maps can locate test files.
  ///
  /// A side effect is this file copies all the images even when only one
  /// target test is asked to run.
  void _copyFilesFromTestToBuid() {
    final List<io.FileSystemEntity> contents =
        environment.webUiTestDir.listSync(recursive: true);
    _copyFiles(contents);
  }

  /// Copy contents of /lib under /build.
  ///
  /// Since the source map are created to assume library files are under
  /// `../../../../lib/src/`. Unless these files are copied under /build,
  /// they are not visible during debug.
  ///
  /// This operation was handled by `build_runner` before we started using
  /// plain `dart2js`.
  void _copyFilesFromLibToBuid() {
    final List<io.FileSystemEntity> contents =
        environment.webUiLibDir.listSync(recursive: true);
    _copyFiles(contents);
  }

  void _copyFiles(List<io.FileSystemEntity> contents) {
    contents.whereType<io.File>().forEach((final io.File entity) {
      final String directoryPath = path.relative(path.dirname(entity.path),
          from: environment.webUiRootDir.path);
      final io.Directory directory = io.Directory(
          path.join(environment.webUiBuildDir.path, directoryPath));
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      final String pathRelativeToWebUi = path.relative(entity.absolute.path,
          from: environment.webUiRootDir.path);
      entity.copySync(
          path.join(environment.webUiBuildDir.path, pathRelativeToWebUi));
    });
  }

  /// Dart2js initially run under /test directory.
  ///
  /// The following files are copied under /build directory after that.
  ///
  void _cleanupExtraFilesUnderTestDir() {
    final List<io.FileSystemEntity> contents =
        environment.webUiTestDir.listSync(recursive: true);
    contents.whereType<io.File>().forEach((final io.File entity) {
      if (path.basename(entity.path).contains('.browser_test.dart.js')) {
        entity.deleteSync();
      }
    });
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

  /// Whether [browser] is set to "firefox".
  bool get isFirefox => browser == 'firefox';

  /// Whether [browser] is set to "safari".
  bool get isSafariOnMacOS => browser == 'safari' && io.Platform.isMacOS;

  /// Whether [browser] is set to "ios-safari".
  bool get isSafariIOS => browser == 'ios-safari' && io.Platform.isMacOS;

  /// Due to lack of resources Chrome integration tests only run on Linux on
  /// LUCI.
  ///
  /// They run on all platforms for local.
  bool get isChromeIntegrationTestAvailable =>
      (isChrome && isLuci && io.Platform.isLinux) || (isChrome && !isLuci);

  /// Due to efficiancy constraints, Firefox integration tests only run on
  /// Linux on LUCI.
  ///
  /// For now Firefox integration tests only run on Linux and Mac on local.
  ///
  // TODO: https://github.com/flutter/flutter/issues/63832
  bool get isFirefoxIntegrationTestAvailable =>
      (isFirefox && isLuci && io.Platform.isLinux) ||
      (isFirefox && !isLuci && !io.Platform.isWindows);

  /// Latest versions of Safari Desktop are only available on macOS.
  ///
  /// Integration testing on LUCI is not supported at the moment.
  // TODO: https://github.com/flutter/flutter/issues/63710
  bool get isSafariIntegrationTestAvailable => isSafariOnMacOS && !isLuci;

  /// Due to various factors integration tests might be missing on a given
  /// platform and given environment.
  /// See: [isChromeIntegrationTestAvailable]
  /// See: [isSafariIntegrationTestAvailable]
  /// See: [isFirefoxIntegrationTestAvailable]
  bool get isIntegrationTestsAvailable =>
      isChromeIntegrationTestAvailable ||
      isFirefoxIntegrationTestAvailable ||
      isSafariIntegrationTestAvailable;

  // Whether the tests will do screenshot testing.
  bool get isScreenshotTestsAvailable =>
      isIntegrationTestsAvailable || isUnitTestsScreenshotsAvailable;

  // For unit tests screenshot tests and smoke tests only run on:
  // "Chrome/iOS" for LUCI/local.
  bool get isUnitTestsScreenshotsAvailable =>
      isChrome && (io.Platform.isLinux || !isLuci) || isSafariIOS;

  /// Use system flutter instead of cloning the repository.
  ///
  /// Read the flag help for more details. Uses PATH to locate flutter.
  bool get useSystemFlutter => boolArg('use-system-flutter');

  /// When running screenshot tests writes them to the file system into
  /// ".dart_tool/goldens".
  bool get doUpdateScreenshotGoldens => boolArg('update-screenshot-goldens');

  /// Runs all tests specified in [targets].
  ///
  /// Unlike [_runAllTestsForCurrentPlatform], this does not filter targets
  /// by platform/browser capabilites, and instead attempts to run all of
  /// them.
  Future<void> _runSpecificTests(List<FilePath> targets) async {
    await _runTestBatch(targets, concurrency: 1, expectFailure: false);
    _checkExitCode();
  }

  /// Runs as many tests as possible on the current OS/browser combination.
  Future<void> _runAllTestsForCurrentPlatform() async {
    final io.Directory testDir = io.Directory(path.join(
      environment.webUiRootDir.path,
      'test',
    ));

    if (isUnitTestsScreenshotsAvailable) {
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

  Future<void> _buildTestsInParallel(
      {List<FilePath> targets, bool forCanvasKit = false}) async {
    final List<TestBuildInput> buildInputs = targets
        .map((FilePath f) => TestBuildInput(f, forCanvasKit: forCanvasKit))
        .toList();

    final results = _pool.forEach(
      buildInputs,
      _buildTest,
    );
    await for (final bool isSuccess in results) {
      if (!isSuccess) {
        throw ToolException('Failed to compile tests.');
      }
    }
  }

  /// Builds the specific test [targets].
  ///
  /// [targets] must not be null.
  ///
  /// Uses `dart2js` for building the test.
  ///
  /// When building for CanvasKit we have to use extra argument
  /// `DFLUTTER_WEB_USE_SKIA=true`.
  ///
  /// Dart2js creates the following outputs:
  /// - target.browser_test.dart.js
  /// - target.browser_test.dart.js.deps
  /// - target.browser_test.dart.js.maps
  /// under the same directory with test file. If all these files are not in
  /// the same directory, Chrome dev tools cannot load the source code during
  /// debug.
  ///
  /// All the files under test already copied from /test directory to /build
  /// directory before test are build. See [_copyFilesFromTestToBuid].
  ///
  /// Later the extra files will be deleted in [_cleanupExtraFilesUnderTestDir].
  Future<bool> _buildTest(TestBuildInput input) async {
    final targetFileName = '${input.path.relativeToWebUi}.browser_test.dart.js';

    final io.Directory directoryToTarget = io.Directory(path.join(
        environment.webUiBuildDir.path,
        path.dirname(input.path.relativeToWebUi)));

    if (!directoryToTarget.existsSync()) {
      directoryToTarget.createSync(recursive: true);
    }

    List<String> arguments = <String>[
      '--no-minify',
      '--disable-inlining',
      '--enable-asserts',
      '--enable-experiment=non-nullable',
      '--no-sound-null-safety',
      if (input.forCanvasKit) '-DFLUTTER_WEB_USE_SKIA=true',
      '-O2',
      '-o',
      targetFileName, // target path.
      '${input.path.relativeToWebUi}', // current path.
    ];

    final int exitCode = await runProcess(
      environment.dart2jsExecutable,
      arguments,
      workingDirectory: environment.webUiRootDir.path,
    );

    if (exitCode != 0) {
      io.stderr.writeln('ERROR: Failed to compile test ${input.path}. '
          'Dart2js exited with exit code $exitCode');
      return false;
    } else {
      return true;
    }
  }

  /// Runs a batch of tests.
  ///
  /// Unless [expectFailure] is set to false, sets [io.exitCode] to a non-zero
  /// value if any tests fail.
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
        // It doesn't make sense to update a screenshot for a test that is
        // expected to fail.
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

/// Used as an input message to the PoolResources that are building a test.
class TestBuildInput {
  /// Test to build.
  final FilePath path;

  /// Whether these tests should be build for CanvasKit.
  ///
  /// `-DFLUTTER_WEB_USE_SKIA=true` is passed to dart2js for CanvasKit.
  final bool forCanvasKit;

  TestBuildInput(this.path, {this.forCanvasKit = false});
}
