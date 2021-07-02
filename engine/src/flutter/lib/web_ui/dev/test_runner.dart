// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:pool/pool.dart';

// TODO(yjbanov): remove hacks when this is fixed:
//                https://github.com/dart-lang/test/issues/1521
import 'package:test_api/src/backend/live_test.dart'
    as hack;
import 'package:test_api/src/backend/group.dart'
    as hack;
import 'package:test_core/src/runner/configuration/reporters.dart'
    as hack;
import 'package:test_core/src/runner/engine.dart'
    as hack;
import 'package:test_core/src/runner/hack_register_platform.dart'
    as hack;
import 'package:test_core/src/runner/reporter.dart'
    as hack;
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_core/src/executable.dart'
    as test;
import 'package:web_test_utils/goldens.dart';

import 'browser.dart';
import 'chrome.dart';
import 'chrome_installer.dart';
import 'common.dart';
import 'edge.dart';
import 'edge_installation.dart';
import 'environment.dart';
import 'exceptions.dart';
import 'firefox.dart';
import 'firefox_installer.dart';
import 'integration_tests_manager.dart';
import 'macos_info.dart';
import 'safari_installation.dart';
import 'safari_ios.dart';
import 'safari_macos.dart';
import 'test_platform.dart';
import 'utils.dart';
import 'watcher.dart';

/// Global list of shards that failed.
///
/// This is used to make sure that when there's a test failure anywhere we
/// exit with a non-zero exit code.
///
/// Shards must never be removed from this list, only added.
List<String> failedShards = <String>[];

/// Whether all test shards succeeded.
bool get allShardsPassed => failedShards.isEmpty;

/// The type of tests requested by the tool user.
enum TestTypesRequested {
  /// For running the unit tests only.
  unit,

  /// For running the integration tests only.
  integration,

  /// For running both unit and integration tests.
  all,
}

/// Command-line argument parsers that parse browser-specific options.
final List<BrowserArgParser> _browserArgParsers  = <BrowserArgParser>[
  ChromeArgParser.instance,
  EdgeArgParser.instance,
  FirefoxArgParser.instance,
  SafariArgParser.instance,
];

/// Creates an environment for a browser.
///
/// The [browserName] matches the browser name passed as the `--browser` option.
BrowserEnvironment _createBrowserEnvironment(String browserName) {
  switch (browserName) {
    case 'chrome': return ChromeEnvironment();
    case 'edge': return EdgeEnvironment();
    case 'firefox': return FirefoxEnvironment();
    case 'safari': return SafariMacOsEnvironment();
    case 'ios-safari': return SafariIosEnvironment();
  }
  throw UnsupportedError('Browser $browserName is not supported.');
}

/// Runs tests.
class TestCommand extends Command<bool> with ArgUtils {
  TestCommand() {
    argParser
      ..addFlag(
        'debug',
        defaultsTo: false,
        help: 'Pauses the browser before running a test, giving you an '
            'opportunity to add breakpoints or inspect loaded code before '
            'running the code.',
      )
      ..addFlag(
        'watch',
        defaultsTo: false,
        abbr: 'w',
        help: 'Run in watch mode so the tests re-run whenever a change is '
            'made.',
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
      ..addFlag(
        'skip-goldens-repo-fetch',
        defaultsTo: false,
        help: 'If set reuses the existig flutter/goldens repo clone. Use this '
            'to avoid overwriting local changes when iterating on golden '
            'tests. This is off by default.',
      )
      ..addOption(
        'browser',
        defaultsTo: 'chrome',
        help: 'An option to choose a browser to run the tests. Tests only work '
            ' on Chrome for now.',
      )
      ..addFlag(
        'fail-early',
        defaultsTo: false,
        negatable: true,
        help: 'If set, causes the test runner to exit upon the first test '
              'failure. If not set, the test runner will continue running '
              'test despite failures and will report them after all tests '
              'finish.',
      );

    for (BrowserArgParser browserArgParser in _browserArgParsers) {
      browserArgParser.populateOptions(argParser);
    }
    GeneralTestsArgumentParser.instance.populateOptions(argParser);
    IntegrationTestsArgumentParser.instance.populateOptions(argParser);
  }

  @override
  final String name = 'test';

  @override
  final String description = 'Run tests.';

  bool get isWatchMode => boolArg('watch')!;

  bool get failEarly => boolArg('fail-early')!;

  /// How many dart2js build tasks are running at the same time.
  final Pool _pool = Pool(8);

  /// Whether test harness preparation (such as fetching the goldens,
  /// creating test_results directory or starting ios-simulator) has been done.
  ///
  /// If unit tests already did these steps, integration tests do not have to
  /// repeat them.
  bool _testPreparationReady = false;

  /// Check the flags to see what type of tests are requested.
  TestTypesRequested get testType {
    if (boolArg('unit-tests-only')! && boolArg('integration-tests-only')!) {
      throw ArgumentError('Conflicting arguments: unit-tests-only and '
          'integration-tests-only are both set');
    } else if (boolArg('unit-tests-only')!) {
      print('Running the unit tests only');
      return TestTypesRequested.unit;
    } else if (boolArg('integration-tests-only')!) {
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
    for (BrowserArgParser browserArgParser in _browserArgParsers) {
      browserArgParser.parseOptions(argResults!);
    }
    GeneralTestsArgumentParser.instance.parseOptions(argResults!);

    /// Collect information on the bot.
    if (isSafariOnMacOS && isLuci) {
      final MacOSInfo macOsInfo = new MacOSInfo();
      await macOsInfo.printInformation();
    }

    final Pipeline testPipeline = Pipeline(steps: <PipelineStep>[
      ClearTerminalScreenStep(),
      TestRunnerStep(this),
    ]);
    await testPipeline.start();

    if (isWatchMode) {
      final FilePath dir = FilePath.fromWebUi('');
      print('');
      print('Initial test run is done!');
      print(
          'Watching ${dir.relativeToCwd}/lib and ${dir.relativeToCwd}/test to re-run tests');
      print('');
      await PipelineWatcher(
          dir: dir.absolute,
          pipeline: testPipeline,
          ignore: (event) {
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
      return true;
    } else {
      if (!allShardsPassed) {
        io.stderr.writeln(_createFailedShardsMessage());
      }
      return allShardsPassed;
    }
  }

  String _createFailedShardsMessage() {
    final StringBuffer message = StringBuffer(
      'The following test shards failed:\n',
    );
    for (String failedShard in failedShards) {
      message.writeln(' - $failedShard');
    }
    return message.toString();
  }

  Future<bool> runTests() async {
    try {
      switch (testType) {
        case TestTypesRequested.unit:
          return runUnitTests();
        case TestTypesRequested.integration:
          return runIntegrationTests();
        case TestTypesRequested.all:
          if (runAllTests && isIntegrationTestsAvailable) {
            bool unitTestResult = await runUnitTests();
            bool integrationTestResult = await runIntegrationTests();
            if (integrationTestResult != unitTestResult) {
              print(
                  'Tests run. Integration tests passed: $integrationTestResult '
                  'unit tests passed: $unitTestResult');
            }
            return integrationTestResult && unitTestResult;
          } else {
            return await runUnitTests();
          }
      }
    } on TestFailureException {
      return true;
    }
  }

  Future<bool> runIntegrationTests() async {
    // Parse additional arguments specific for integration testing.
    IntegrationTestsArgumentParser.instance.parseOptions(argResults!);
    await _prepare();
    final bool result = await IntegrationTestsManager(
            browser, useSystemFlutter, doUpdateScreenshotGoldens)
        .runTests();
    if (!result) {
      failedShards.add('Integration tests');
    }
    return result;
  }

  Future<bool> runUnitTests() async {
    _copyTestFontsIntoWebUi();
    await _buildHostPage();
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
    if (_testPreparationReady) {
      return;
    }
    if (environment.webUiTestResultsDirectory.existsSync()) {
      environment.webUiTestResultsDirectory.deleteSync(recursive: true);
    }
    environment.webUiTestResultsDirectory.createSync(recursive: true);

    // If screenshot tests are available, fetch the screenshot goldens.
    if (isScreenshotTestsAvailable && !skipGoldensRepoFetch) {
      if (isVerboseLoggingEnabled) {
        print('INFO: Fetching goldens repo');
      }
      final GoldensRepoFetcher goldensRepoFetcher = GoldensRepoFetcher(
          environment.webUiGoldensRepositoryDirectory,
          path.join(environment.webUiDevDir.path, 'goldens_lock.yaml'));
      await goldensRepoFetcher.fetch();
    }

    await browserEnvironment.prepareEnvironment();
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

    stopwatch.stop();
    print('The build took ${stopwatch.elapsedMilliseconds ~/ 1000} seconds.');
  }

  /// Whether to start the browser in debug mode.
  ///
  /// In this mode the browser pauses before running the test to allow
  /// you set breakpoints or inspect the code.
  bool get isDebug => boolArg('debug')!;

  /// Paths to targets to run, e.g. a single test.
  List<String> get targets => argResults!.rest;

  /// The target test files to run.
  List<FilePath> get targetFiles => targets.map((t) => FilePath.fromCwd(t)).toList();

  /// Whether all tests should run.
  bool get runAllTests => targets.isEmpty;

  /// The name of the browser to run tests in.
  String get browser => stringArg('browser')!;

  /// The browser environment for the [browser].
  BrowserEnvironment get browserEnvironment => (_browserEnvironment ??= _createBrowserEnvironment(browser));
  BrowserEnvironment? _browserEnvironment;

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

  /// Due to efficiency constraints, Firefox integration tests only run on
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
  bool get useSystemFlutter => boolArg('use-system-flutter')!;

  /// When running screenshot tests writes them to the file system into
  /// ".dart_tool/goldens".
  bool get doUpdateScreenshotGoldens => boolArg('update-screenshot-goldens')!;

  /// Whether to fetch the goldens repo prior to running tests.
  bool get skipGoldensRepoFetch => boolArg('skip-goldens-repo-fetch')!;

  /// Runs all tests specified in [targets].
  ///
  /// Unlike [_runAllTestsForCurrentPlatform], this does not filter targets
  /// by platform/browser capabilities, and instead attempts to run all of
  /// them.
  Future<void> _runSpecificTests(List<FilePath> targets) async {
    await _runTestBatch(targets, concurrency: 1, expectFailure: false);
    _checkExitCode(
      'Some of the following tests: ' +
      targets.map((FilePath path) => path.relativeToWebUi).join(', '),
    );
  }

  /// Runs as many tests as possible on the current OS/browser combination.
  Future<void> _runAllTestsForCurrentPlatform() async {
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

      // All files under test/golden_tests are considered golden tests.
      final bool isUnderGoldenTestsDirectory =
          path.split(testFilePath.relativeToWebUi).contains('golden_tests');
      // Any file whose name ends with "_golden_test.dart" is run as a golden test.
      final bool isGoldenTestFile = path
          .basename(testFilePath.relativeToWebUi)
          .endsWith('_golden_test.dart');
      if (isUnderGoldenTestsDirectory || isGoldenTestFile) {
        screenshotTestFiles.add(testFilePath);
      } else {
        unitTestFiles.add(testFilePath);
      }
    }

    if (isUnitTestsScreenshotsAvailable) {
      // This test returns a non-zero exit code on purpose. Run it separately.
      if (io.Platform.environment['CIRRUS_CI'] != 'true') {
        await _runTestBatch(
          <FilePath>[failureSmokeTestPath],
          concurrency: 1,
          expectFailure: true,
        );
        _checkExitCode('Smoke test');
      }
    }

    // Run all unit-tests as a single batch.
    await _runTestBatch(unitTestFiles, concurrency: 10, expectFailure: false);
    _checkExitCode('Unit tests');

    if (isUnitTestsScreenshotsAvailable) {
      // Run screenshot tests one at a time.
      for (FilePath testFilePath in screenshotTestFiles) {
        await _runTestBatch(
          <FilePath>[testFilePath],
          concurrency: 1,
          expectFailure: false,
        );
        _checkExitCode('Golden tests');
      }
    }
  }

  void _checkExitCode(String shard) {
    if (io.exitCode != 0) {
      if (isWatchMode) {
        io.exitCode = 0;
        throw TestFailureException();
      } else {
        failedShards.add(shard);
        if (failEarly) {
          throw ToolException(_createFailedShardsMessage());
        }
      }
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

  Future<void> _buildTestsInParallel({
    required List<FilePath> targets,
    bool forCanvasKit = false,
  }) async {
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

  /// Compiles one test using `dart2js`.
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
  /// directory before test are build. See [_copyFilesFromTestToBuild].
  ///
  /// Later the extra files will be deleted in [_cleanupExtraFilesUnderTestDir].
  Future<bool> _buildTest(TestBuildInput input) async {
    String targetFileName = path.join(
      environment.webUiBuildDir.path,
      '${input.path.relativeToWebUi}.browser_test.dart.js',
    );

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
      '--no-sound-null-safety',

      // We do not want to auto-select a renderer in tests. As of today, tests
      // are designed to run in one specific mode. So instead, we specify the
      // renderer explicitly.
      '-DFLUTTER_WEB_AUTO_DETECT=false',
      '-DFLUTTER_WEB_USE_SKIA=${input.forCanvasKit}',

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
    required int concurrency,
    required bool expectFailure,
  }) async {
    final String configurationFilePath = path.join(
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
      ...testFiles.map((f) => f.relativeToWebUi).toList(),
    ];

    if (expectFailure) {
      hack.registerReporter(
        'name-only',
        hack.ReporterDetails(
        'Prints the name of the test, but suppresses all other test output.',
        (_, hack.Engine engine, __) => NameOnlyReporter(engine)),
      );
    }

    hack.registerPlatformPlugin(<Runtime>[
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
}

const List<String> _kTestFonts = <String>[
  'ahem.ttf',
  'Roboto-Regular.ttf',
  'NotoNaskhArabic-Regular.ttf',
  'NotoColorEmoji.ttf',
];

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

class TestFailureException implements Exception {}

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

/// Clears the terminal screen and places the cursor at the top left corner.
///
/// This works on Linux and Mac. On Windows, it's a no-op.
class ClearTerminalScreenStep implements PipelineStep {
  @override
  String get name => 'clearing terminal screen';

  @override
  bool get isSafeToInterrupt => false;

  @override
  Future<void> interrupt() async {}

  @override
  Future<void> run() async {
    if (!io.Platform.isWindows) {
      // See: https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_sequences
      print("\x1B[2J\x1B[1;2H");
    }
  }
}

/// Runs tests by calling [TestCommand.runTests].
class TestRunnerStep implements PipelineStep {
  TestRunnerStep(this.testCommand);

  TestCommand testCommand;

  @override
  String get name => 'test runner';

  @override
  Future<void> interrupt() async {
    // Interrupt this step by killing all spawned processes (browsers, web drivers, etc).
    cleanup();
  }

  @override
  bool get isSafeToInterrupt => true;

  @override
  Future<void> run() async {
    await testCommand.runTests();
  }
}
