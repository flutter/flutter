// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Runs the tests for the flutter/flutter repository.
//
//
// By default, test output is filtered and only errors are shown. (If a
// particular test takes longer than _quietTimeout in utils.dart, the output is
// shown then also, in case something has hung.)
//
//  --verbose stops the output cleanup and just outputs everything verbatim.
//
//
// By default, errors are non-fatal; all tests are executed and the output
// ends with a summary of the errors that were detected.
//
// Exit code is 1 if there was an error.
//
//  --abort-on-error causes the script to exit immediately when hitting an error.
//
//
// By default, all tests are run. However, the tests support being split by
// shard and subshard. (Inspect the code to see what shards and subshards are
// supported.)
//
// If the CIRRUS_TASK_NAME environment variable exists, it is used to determine
// the shard and sub-shard, by parsing it in the form shard-subshard-platform,
// ignoring the platform.
//
// For local testing you can just set the SHARD and SUBSHARD environment
// variables. For example, to run all the framework tests you can just set
// SHARD=framework_tests. Some shards support named subshards, like
// SHARD=framework_tests SUBSHARD=widgets. Others support arbitrary numbered
// subsharding, like SHARD=build_tests SUBSHARD=1_2 (where 1_2 means "one of
// two" as in run the first half of the tests).
//
// So for example to run specifically the third subshard of the Web tests you
// would set SHARD=web_tests SUBSHARD=2 (it's zero-based).
//
// By default, where supported, tests within a shard are executed in a random
// order to (eventually) catch inter-test dependencies.
//
//  --test-randomize-ordering-seed=<n> sets the shuffle seed for reproducing runs.
//
//
// All other arguments are treated as arguments to pass to the flutter tool when
// running tests.

import 'dart:convert';
import 'dart:core' as system show print;
import 'dart:core' hide print;
import 'dart:io' as system show exit;
import 'dart:io' hide exit;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'run_command.dart';
import 'suite_runners/run_add_to_app_life_cycle_tests.dart';
import 'suite_runners/run_analyze_tests.dart';
import 'suite_runners/run_android_preview_integration_tool_tests.dart';
import 'suite_runners/run_customer_testing_tests.dart';
import 'suite_runners/run_docs_tests.dart';
import 'suite_runners/run_flutter_packages_tests.dart';
import 'suite_runners/run_framework_coverage_tests.dart';
import 'suite_runners/run_fuchsia_precache.dart';
import 'suite_runners/run_realm_checker_tests.dart';
import 'suite_runners/run_skp_generator_tests.dart';
import 'suite_runners/run_verify_binaries_codesigned_tests.dart';
import 'suite_runners/run_web_tests.dart';
import 'utils.dart';

typedef ShardRunner = Future<void> Function();

String get platformFolderName {
  if (Platform.isWindows) {
    return 'windows-x64';
  }
  if (Platform.isMacOS) {
    return 'darwin-x64';
  }
  if (Platform.isLinux) {
    return 'linux-x64';
  }
  throw UnsupportedError('The platform ${Platform.operatingSystem} is not supported by this script.');
}
final String flutterTester = path.join(flutterRoot, 'bin', 'cache', 'artifacts', 'engine', platformFolderName, 'flutter_tester$exe');

/// Environment variables to override the local engine when running `pub test`,
/// if such flags are provided to `test.dart`.
final Map<String,String> localEngineEnv = <String, String>{};

const String kTestHarnessShardName = 'test_harness_tests';

const String CIRRUS_TASK_NAME = 'CIRRUS_TASK_NAME';

/// When you call this, you can pass additional arguments to pass custom
/// arguments to flutter test. For example, you might want to call this
/// script with the parameter --local-engine=host_debug_unopt to
/// use your own build of the engine.
///
/// To run the tool_tests part, run it with SHARD=tool_tests
///
/// Examples:
/// SHARD=tool_tests bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// bin/cache/dart-sdk/bin/dart dev/bots/test.dart --local-engine=host_debug_unopt --local-engine-host=host_debug_unopt
Future<void> main(List<String> args) async {
  try {
    printProgress('STARTING ANALYSIS');
    for (final String arg in args) {
      if (arg.startsWith('--local-engine=')) {
        localEngineEnv['FLUTTER_LOCAL_ENGINE'] = arg.substring('--local-engine='.length);
        flutterTestArgs.add(arg);
      } else if (arg.startsWith('--local-engine-host=')) {
        localEngineEnv['FLUTTER_LOCAL_ENGINE_HOST'] = arg.substring('--local-engine-host='.length);
        flutterTestArgs.add(arg);
      } else if (arg.startsWith('--local-engine-src-path=')) {
        localEngineEnv['FLUTTER_LOCAL_ENGINE_SRC_PATH'] = arg.substring('--local-engine-src-path='.length);
        flutterTestArgs.add(arg);
      } else if (arg.startsWith('--test-randomize-ordering-seed=')) {
        shuffleSeed = arg.substring('--test-randomize-ordering-seed='.length);
      } else if (arg.startsWith('--verbose')) {
        print = (Object? message) {
          system.print(message);
        };
      } else if (arg.startsWith('--abort-on-error')) {
        onError = () {
          system.exit(1);
        };
      } else {
        flutterTestArgs.add(arg);
      }
    }
    if (Platform.environment.containsKey(CIRRUS_TASK_NAME)) {
      printProgress('Running task: ${Platform.environment[CIRRUS_TASK_NAME]}');
    }
    final WebTestsSuite webTestsSuite = WebTestsSuite(flutterTestArgs);
    await selectShard(<String, ShardRunner>{
      'add_to_app_life_cycle_tests': addToAppLifeCycleRunner,
      'build_tests': _runBuildTests,
      'framework_coverage': frameworkCoverageRunner,
      'framework_tests': _runFrameworkTests,
      'tool_tests': _runToolTests,
      'web_tool_tests': _runWebToolTests,
      'tool_integration_tests': _runIntegrationToolTests,
      'android_preview_tool_integration_tests': androidPreviewIntegrationToolTestsRunner,
      'tool_host_cross_arch_tests': _runToolHostCrossArchTests,
      // All the unit/widget tests run using `flutter test --platform=chrome --web-renderer=html`
      'web_tests': webTestsSuite.runWebHtmlUnitTests,
      // All the unit/widget tests run using `flutter test --platform=chrome --web-renderer=canvaskit`
      'web_canvaskit_tests': webTestsSuite.runWebCanvasKitUnitTests,
      // All the unit/widget tests run using `flutter test --platform=chrome --wasm --web-renderer=skwasm`
      'web_skwasm_tests': webTestsSuite.runWebSkwasmUnitTests,
      // All web integration tests
      'web_long_running_tests': webTestsSuite.webLongRunningTestsRunner,
      'flutter_plugins': flutterPackagesRunner,
      'skp_generator': skpGeneratorTestsRunner,
      'realm_checker': realmCheckerTestRunner,
      'customer_testing': customerTestingRunner,
      'analyze': analyzeRunner,
      'fuchsia_precache': fuchsiaPrecacheRunner,
      'docs': docsRunner,
      'verify_binaries_codesigned': verifyCodesignedTestRunner,
      kTestHarnessShardName: _runTestHarnessTests, // Used for testing this script; also run as part of SHARD=framework_tests, SUBSHARD=misc.
    });
  } catch (error, stackTrace) {
    foundError(<String>[
      'UNEXPECTED ERROR!',
      error.toString(),
      ...stackTrace.toString().split('\n'),
      'The test.dart script should be corrected to catch this error and call foundError().',
      '${yellow}Some tests are likely to have been skipped.$reset',
    ]);
    system.exit(255);
  }
  if (hasError) {
    reportErrorsAndExit('${bold}Test failed.$reset');
  }
  reportSuccessAndExit('${bold}Test successful.$reset');
}

/// Verify the Flutter Engine is the revision in
/// bin/cache/internal/engine.version.
Future<void> _validateEngineHash() async {
  if (runningInDartHHHBot) {
    // The Dart HHH bots intentionally modify the local artifact cache
    // and then use this script to run Flutter's test suites.
    // Because the artifacts have been changed, this particular test will return
    // a false positive and should be skipped.
    print('${yellow}Skipping Flutter Engine Version Validation for swarming bot $luciBotId.');
    return;
  }
  final String expectedVersion = File(engineVersionFile).readAsStringSync().trim();
  final CommandResult result = await runCommand(flutterTester, <String>['--help'], outputMode: OutputMode.capture);
  if (result.flattenedStdout!.isNotEmpty) {
    foundError(<String>[
      '${red}The stdout of `$flutterTester --help` was not empty:$reset',
      ...result.flattenedStdout!.split('\n').map((String line) => ' $gray┆$reset $line'),
    ]);
  }
  final String actualVersion;
  try {
    actualVersion = result.flattenedStderr!.split('\n').firstWhere((final String line) {
      return line.startsWith('Flutter Engine Version:');
    });
  } on StateError {
    foundError(<String>[
      '${red}Could not find "Flutter Engine Version:" line in `${path.basename(flutterTester)} --help` stderr output:$reset',
      ...result.flattenedStderr!.split('\n').map((String line) => ' $gray┆$reset $line'),
    ]);
    return;
  }
  if (!actualVersion.contains(expectedVersion)) {
    foundError(<String>['${red}Expected "Flutter Engine Version: $expectedVersion", but found "$actualVersion".$reset']);
  }
}

Future<void> _runTestHarnessTests() async {
  printProgress('${green}Running test harness tests...$reset');

  await _validateEngineHash();

  // Verify that the tests actually return failure on failure and success on
  // success.
  final String automatedTests = path.join(flutterRoot, 'dev', 'automated_tests');

  // We want to run these tests in parallel, because they each take some time
  // to run (e.g. compiling), so we don't want to run them in series, especially
  // on 20-core machines. However, we have a race condition, so for now...
  // Race condition issue: https://github.com/flutter/flutter/issues/90026
  final List<ShardRunner> tests = <ShardRunner>[
    () => runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'pass_test.dart'),
      printOutput: false,
    ),
    () => runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'fail_test.dart'),
      expectFailure: true,
      printOutput: false,
    ),
    () => runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'pending_timer_fail_test.dart'),
      expectFailure: true,
      printOutput: false,
      outputChecker: (CommandResult result) {
        return result.flattenedStdout!.contains('failingPendingTimerTest')
          ? null
          : 'Failed to find the stack trace for the pending Timer.\n\n'
            'stdout:\n${result.flattenedStdout}\n\n'
            'stderr:\n${result.flattenedStderr}';
      },
    ),
    () => runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'fail_test_on_exception_after_test.dart'),
      expectFailure: true,
      printOutput: false,
      outputChecker: (CommandResult result) {
        const String expectedError = '══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════\n'
            'The following StateError was thrown running a test (but after the test had completed):\n'
            'Bad state: Exception thrown after test completed.';
        if (result.flattenedStdout!.contains(expectedError)) {
          return null;
        }
        return 'Failed to find expected output on stdout.\n\n'
          'Expected output:\n$expectedError\n\n'
          'Actual stdout:\n${result.flattenedStdout}\n\n'
          'Actual stderr:\n${result.flattenedStderr}';
      },
    ),
    () => runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'crash1_test.dart'),
      expectFailure: true,
      printOutput: false,
    ),
    () => runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'crash2_test.dart'),
      expectFailure: true,
      printOutput: false,
    ),
    () => runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'syntax_error_test.broken_dart'),
      expectFailure: true,
      printOutput: false,
    ),
    () => runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'missing_import_test.broken_dart'),
      expectFailure: true,
      printOutput: false,
    ),
    () => runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'disallow_error_reporter_modification_test.dart'),
      expectFailure: true,
      printOutput: false,
    ),
  ];

  List<ShardRunner> testsToRun;

  // Run all tests unless sharding is explicitly specified.
  final String? shardName = Platform.environment[kShardKey];
  if (shardName == kTestHarnessShardName) {
    testsToRun = selectIndexOfTotalSubshard<ShardRunner>(tests);
  } else {
    testsToRun = tests;
  }
  for (final ShardRunner test in testsToRun) {
    await test();
  }

  // Verify that we correctly generated the version file.
  final String? versionError = await verifyVersion(File(path.join(flutterRoot, 'version')));
  if (versionError != null) {
    foundError(<String>[versionError]);
  }
}

final String _toolsPath = path.join(flutterRoot, 'packages', 'flutter_tools');

Future<void> _runGeneralToolTests() async {
  await runDartTest(
    _toolsPath,
    testPaths: <String>[path.join('test', 'general.shard')],
    enableFlutterToolAsserts: false,

    // Detect unit test time regressions (poor time delay handling, etc).
    // This overrides the 15 minute default for tools tests.
    // See the README.md and dart_test.yaml files in the flutter_tools package.
    perTestTimeout: const Duration(seconds: 2),
  );
}

Future<void> _runCommandsToolTests() async {
  await runDartTest(
    _toolsPath,
    forceSingleCore: true,
    testPaths: <String>[path.join('test', 'commands.shard')],
  );
}

Future<void> _runWebToolTests() async {
  final List<File> allFiles = Directory(path.join(_toolsPath, 'test', 'web.shard'))
      .listSync(recursive: true).whereType<File>().toList();
  final List<String> allTests = <String>[];
  for (final File file in allFiles) {
    if (file.path.endsWith('_test.dart')) {
      allTests.add(file.path);
    }
  }
  await runDartTest(
    _toolsPath,
    forceSingleCore: true,
    testPaths: selectIndexOfTotalSubshard<String>(allTests),
    includeLocalEngineEnv: true,
  );
}

Future<void> _runToolHostCrossArchTests() {
  return runDartTest(
    _toolsPath,
    // These are integration tests
    forceSingleCore: true,
    testPaths: <String>[path.join('test', 'host_cross_arch.shard')],
  );
}

Future<void> _runIntegrationToolTests() async {
  final List<String> allTests = Directory(path.join(_toolsPath, 'test', 'integration.shard'))
      .listSync(recursive: true).whereType<File>()
      .map<String>((FileSystemEntity entry) => path.relative(entry.path, from: _toolsPath))
      .where((String testPath) => path.basename(testPath).endsWith('_test.dart')).toList();

  await runDartTest(
    _toolsPath,
    forceSingleCore: true,
    testPaths: selectIndexOfTotalSubshard<String>(allTests),
    collectMetrics: true,
  );
}

Future<void> _runToolTests() async {
  await selectSubshard(<String, ShardRunner>{
    'general': _runGeneralToolTests,
    'commands': _runCommandsToolTests,
  });
}

Future<void> runForbiddenFromReleaseTests() async {
  // Build a release APK to get the snapshot json.
  final Directory tempDirectory = Directory.systemTemp.createTempSync('flutter_forbidden_imports.');
  final List<String> command = <String>[
    'build',
    'apk',
    '--target-platform',
    'android-arm64',
    '--release',
    '--analyze-size',
    '--code-size-directory',
    tempDirectory.path,
    '-v',
  ];

  await runCommand(
    flutter,
    command,
    workingDirectory: path.join(flutterRoot, 'examples', 'hello_world'),
  );

  // First, a smoke test.
  final List<String> smokeTestArgs = <String>[
    path.join(flutterRoot, 'dev', 'forbidden_from_release_tests', 'bin', 'main.dart'),
    '--snapshot', path.join(tempDirectory.path, 'snapshot.arm64-v8a.json'),
    '--package-config', path.join(flutterRoot, 'examples', 'hello_world', '.dart_tool', 'package_config.json'),
    '--forbidden-type', 'package:flutter/src/widgets/framework.dart::Widget',
  ];
  await runCommand(
    dart,
    smokeTestArgs,
    workingDirectory: flutterRoot,
    expectNonZeroExit: true,
  );

  // Actual test.
  final List<String> args = <String>[
    path.join(flutterRoot, 'dev', 'forbidden_from_release_tests', 'bin', 'main.dart'),
    '--snapshot', path.join(tempDirectory.path, 'snapshot.arm64-v8a.json'),
    '--package-config', path.join(flutterRoot, 'examples', 'hello_world', '.dart_tool', 'package_config.json'),
    '--forbidden-type', 'package:flutter/src/widgets/widget_inspector.dart::WidgetInspectorService',
    '--forbidden-type', 'package:flutter/src/widgets/framework.dart::DebugCreator',
    '--forbidden-type', 'package:flutter/src/foundation/print.dart::debugPrint',
  ];
  await runCommand(
    dart,
    args,
    workingDirectory: flutterRoot,
  );
}

/// Verifies that APK, and IPA (if on macOS), and native desktop builds the
/// examples apps without crashing. It does not actually launch the apps. That
/// happens later in the devicelab. This is just a smoke-test. In particular,
/// this will verify we can build when there are spaces in the path name for the
/// Flutter SDK and target app.
///
/// Also does some checking about types included in hello_world.
Future<void> _runBuildTests() async {
  final List<Directory> exampleDirectories = Directory(path.join(flutterRoot, 'examples')).listSync()
    // API example builds will be tested in a separate shard.
    .where((FileSystemEntity entity) => entity is Directory && path.basename(entity.path) != 'api').cast<Directory>().toList()
    ..add(Directory(path.join(flutterRoot, 'packages', 'integration_test', 'example')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'android_semantics_testing')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'android_views')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'channels')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'hybrid_android_views')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'flutter_gallery')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'ios_platform_view_tests')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'ios_app_with_extensions')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'non_nullable')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'platform_interaction')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'spell_check')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'ui')));

  // The tests are randomly distributed into subshards so as to get a uniform
  // distribution of costs, but the seed is fixed so that issues are reproducible.
  final List<ShardRunner> tests = <ShardRunner>[
    for (final Directory exampleDirectory in exampleDirectories)
      () => _runExampleProjectBuildTests(exampleDirectory),
    ...<ShardRunner>[
      // Web compilation tests.
      () => _flutterBuildDart2js(
            path.join('dev', 'integration_tests', 'web'),
            path.join('lib', 'main.dart'),
          ),
      // Should not fail to compile with dart:io.
      () => _flutterBuildDart2js(
            path.join('dev', 'integration_tests', 'web_compile_tests'),
            path.join('lib', 'dart_io_import.dart'),
          ),
      // Should be able to compile with a call to:
      // BackgroundIsolateBinaryMessenger.ensureInitialized.
      () => _flutterBuildDart2js(
            path.join('dev', 'integration_tests', 'web_compile_tests'),
            path.join('lib', 'background_isolate_binary_messenger.dart'),
          ),
    ],
    runForbiddenFromReleaseTests,
  ]..shuffle(math.Random(0));

  await runShardRunnerIndexOfTotalSubshard(tests);
}

Future<void> _runExampleProjectBuildTests(Directory exampleDirectory, [File? mainFile]) async {
  // Only verify caching with flutter gallery.
  final bool verifyCaching = exampleDirectory.path.contains('flutter_gallery');
  final String examplePath = path.relative(exampleDirectory.path, from: Directory.current.path);
  final List<String> additionalArgs = <String>[
    if (mainFile != null) path.relative(mainFile.path, from: exampleDirectory.absolute.path),
  ];
  if (Directory(path.join(examplePath, 'android')).existsSync()) {
    await _flutterBuildApk(examplePath, release: false, additionalArgs: additionalArgs, verifyCaching: verifyCaching);
    await _flutterBuildApk(examplePath, release: true, additionalArgs: additionalArgs, verifyCaching: verifyCaching);
  } else {
    print('Example project ${path.basename(examplePath)} has no android directory, skipping apk');
  }
  if (Platform.isMacOS) {
    if (Directory(path.join(examplePath, 'ios')).existsSync()) {
      await _flutterBuildIpa(examplePath, release: false, additionalArgs: additionalArgs, verifyCaching: verifyCaching);
      await _flutterBuildIpa(examplePath, release: true, additionalArgs: additionalArgs, verifyCaching: verifyCaching);
    } else {
      print('Example project ${path.basename(examplePath)} has no ios directory, skipping ipa');
    }
  }
  if (Platform.isLinux) {
    if (Directory(path.join(examplePath, 'linux')).existsSync()) {
      await _flutterBuildLinux(examplePath, release: false, additionalArgs: additionalArgs, verifyCaching: verifyCaching);
      await _flutterBuildLinux(examplePath, release: true, additionalArgs: additionalArgs, verifyCaching: verifyCaching);
    } else {
      print('Example project ${path.basename(examplePath)} has no linux directory, skipping Linux');
    }
  }
  if (Platform.isMacOS) {
    if (Directory(path.join(examplePath, 'macos')).existsSync()) {
      await _flutterBuildMacOS(examplePath, release: false, additionalArgs: additionalArgs, verifyCaching: verifyCaching);
      await _flutterBuildMacOS(examplePath, release: true, additionalArgs: additionalArgs, verifyCaching: verifyCaching);
    } else {
      print('Example project ${path.basename(examplePath)} has no macos directory, skipping macOS');
    }
  }
  if (Platform.isWindows) {
    if (Directory(path.join(examplePath, 'windows')).existsSync()) {
      await _flutterBuildWin32(examplePath, release: false, additionalArgs: additionalArgs, verifyCaching: verifyCaching);
      await _flutterBuildWin32(examplePath, release: true, additionalArgs: additionalArgs, verifyCaching: verifyCaching);
    } else {
      print('Example project ${path.basename(examplePath)} has no windows directory, skipping Win32');
    }
  }
}

Future<void> _flutterBuildApk(String relativePathToApplication, {
  required bool release,
  bool verifyCaching = false,
  List<String> additionalArgs = const <String>[],
}) async {
  printProgress('${green}Testing APK ${release ? 'release' : 'debug'} build$reset for $cyan$relativePathToApplication$reset...');
  await _flutterBuild(relativePathToApplication, 'APK', 'apk',
    release: release,
    verifyCaching: verifyCaching,
    additionalArgs: additionalArgs
  );
}

Future<void> _flutterBuildIpa(String relativePathToApplication, {
  required bool release,
  List<String> additionalArgs = const <String>[],
  bool verifyCaching = false,
}) async {
  assert(Platform.isMacOS);
  printProgress('${green}Testing IPA ${release ? 'release' : 'debug'} build$reset for $cyan$relativePathToApplication$reset...');
  await _flutterBuild(relativePathToApplication, 'IPA', 'ios',
    release: release,
    verifyCaching: verifyCaching,
    additionalArgs: <String>[...additionalArgs, '--no-codesign'],
  );
}

Future<void> _flutterBuildLinux(String relativePathToApplication, {
  required bool release,
  bool verifyCaching = false,
  List<String> additionalArgs = const <String>[],
}) async {
  assert(Platform.isLinux);
  await runCommand(flutter, <String>['config', '--enable-linux-desktop']);
  printProgress('${green}Testing Linux ${release ? 'release' : 'debug'} build$reset for $cyan$relativePathToApplication$reset...');
  await _flutterBuild(relativePathToApplication, 'Linux', 'linux',
    release: release,
    verifyCaching: verifyCaching,
    additionalArgs: additionalArgs
  );
}

Future<void> _flutterBuildMacOS(String relativePathToApplication, {
  required bool release,
  bool verifyCaching = false,
  List<String> additionalArgs = const <String>[],
}) async {
  assert(Platform.isMacOS);
  await runCommand(flutter, <String>['config', '--enable-macos-desktop']);
  printProgress('${green}Testing macOS ${release ? 'release' : 'debug'} build$reset for $cyan$relativePathToApplication$reset...');
  await _flutterBuild(relativePathToApplication, 'macOS', 'macos',
    release: release,
    verifyCaching: verifyCaching,
    additionalArgs: additionalArgs
  );
}

Future<void> _flutterBuildWin32(String relativePathToApplication, {
  required bool release,
  bool verifyCaching = false,
  List<String> additionalArgs = const <String>[],
}) async {
  assert(Platform.isWindows);
  printProgress('${green}Testing ${release ? 'release' : 'debug'} Windows build$reset for $cyan$relativePathToApplication$reset...');
  await _flutterBuild(relativePathToApplication, 'Windows', 'windows',
    release: release,
    verifyCaching: verifyCaching,
    additionalArgs: additionalArgs
  );
}

Future<void> _flutterBuild(
  String relativePathToApplication,
  String platformLabel,
  String platformBuildName, {
  required bool release,
  bool verifyCaching = false,
  List<String> additionalArgs = const <String>[],
}) async {
  await runCommand(flutter,
    <String>[
      'build',
      platformBuildName,
      ...additionalArgs,
      if (release)
        '--release'
      else
        '--debug',
      '-v',
    ],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
  );

  if (verifyCaching) {
    printProgress('${green}Testing $platformLabel cache$reset for $cyan$relativePathToApplication$reset...');
    await runCommand(flutter,
      <String>[
        'build',
        platformBuildName,
        '--performance-measurement-file=perf.json',
        ...additionalArgs,
        if (release)
          '--release'
        else
          '--debug',
        '-v',
      ],
      workingDirectory: path.join(flutterRoot, relativePathToApplication),
    );
    final File file = File(path.join(flutterRoot, relativePathToApplication, 'perf.json'));
    if (!_allTargetsCached(file)) {
      foundError(<String>[
        '${red}Not all build targets cached after second run.$reset',
        'The target performance data was: ${file.readAsStringSync().replaceAll('},', '},\n')}',
      ]);
    }
  }
}

bool _allTargetsCached(File performanceFile) {
  final Map<String, Object?> data = json.decode(performanceFile.readAsStringSync())
    as Map<String, Object?>;
  final List<Map<String, Object?>> targets = (data['targets']! as List<Object?>)
    .cast<Map<String, Object?>>();
  return targets.every((Map<String, Object?> element) => element['skipped'] == true);
}

Future<void> _flutterBuildDart2js(String relativePathToApplication, String target, { bool expectNonZeroExit = false }) async {
  printProgress('${green}Testing Dart2JS build$reset for $cyan$relativePathToApplication$reset...');
  await runCommand(flutter,
    <String>['build', 'web', '-v', '--target=$target'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
    expectNonZeroExit: expectNonZeroExit,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );
}

Future<void> _runFrameworkTests() async {
  final List<String> trackWidgetCreationAlternatives = <String>['--track-widget-creation', '--no-track-widget-creation'];

  Future<void> runWidgets() async {
    printProgress('${green}Running packages/flutter tests $reset for ${cyan}test/widgets/$reset');
    for (final String trackWidgetCreationOption in trackWidgetCreationAlternatives) {
      await runFlutterTest(
        path.join(flutterRoot, 'packages', 'flutter'),
        options: <String>[trackWidgetCreationOption],
        tests: <String>[ path.join('test', 'widgets') + path.separator ],
      );
    }
    // Try compiling code outside of the packages/flutter directory with and without --track-widget-creation
    for (final String trackWidgetCreationOption in trackWidgetCreationAlternatives) {
      await runFlutterTest(
        path.join(flutterRoot, 'dev', 'integration_tests', 'flutter_gallery'),
        options: <String>[trackWidgetCreationOption],
        fatalWarnings: false, // until we've migrated video_player
      );
    }
    // Run release mode tests (see packages/flutter/test_release/README.md)
    await runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--dart-define=dart.vm.product=true'],
      tests: <String>['test_release${path.separator}'],
    );
    // Run profile mode tests (see packages/flutter/test_profile/README.md)
    await runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--dart-define=dart.vm.product=false', '--dart-define=dart.vm.profile=true'],
      tests: <String>['test_profile${path.separator}'],
    );
  }

  Future<void> runImpeller() async {
    printProgress('${green}Running packages/flutter tests $reset in Impeller$reset');
    await runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--enable-impeller'],
    );
  }


  Future<void> runLibraries() async {
    final List<String> tests = Directory(path.join(flutterRoot, 'packages', 'flutter', 'test'))
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((Directory dir) => !dir.path.endsWith('widgets'))
      .map<String>((Directory dir) => path.join('test', path.basename(dir.path)) + path.separator)
      .toList();
    printProgress('${green}Running packages/flutter tests$reset for $cyan${tests.join(", ")}$reset');
    for (final String trackWidgetCreationOption in trackWidgetCreationAlternatives) {
      await runFlutterTest(
        path.join(flutterRoot, 'packages', 'flutter'),
        options: <String>[trackWidgetCreationOption],
        tests: tests,
      );
    }
  }

  Future<void> runExampleTests() async {
    await runCommand(
      flutter,
      <String>['config', '--enable-${Platform.operatingSystem}-desktop'],
      workingDirectory: flutterRoot,
    );
    await runCommand(
      dart,
      <String>[path.join(flutterRoot, 'dev', 'tools', 'examples_smoke_test.dart')],
      workingDirectory: path.join(flutterRoot, 'examples', 'api'),
    );
    for (final FileSystemEntity entity in Directory(path.join(flutterRoot, 'examples')).listSync()) {
      if (entity is! Directory || !Directory(path.join(entity.path, 'test')).existsSync()) {
        continue;
      }
      await runFlutterTest(entity.path);
    }
  }

  Future<void> runTracingTests() async {
    final String tracingDirectory = path.join(flutterRoot, 'dev', 'tracing_tests');

    // run the tests for debug mode
    await runFlutterTest(tracingDirectory, options: <String>['--enable-vmservice']);

    Future<List<String>> verifyTracingAppBuild({
      required String modeArgument,
      required String sourceFile,
      required Set<String> allowed,
      required Set<String> disallowed,
    }) async {
      try {
        await runCommand(
          flutter,
          <String>[
            'build', 'appbundle', '--$modeArgument', path.join('lib', sourceFile),
          ],
          workingDirectory: tracingDirectory,
        );
        final Archive archive = ZipDecoder().decodeBytes(File(path.join(tracingDirectory, 'build', 'app', 'outputs', 'bundle', modeArgument, 'app-$modeArgument.aab')).readAsBytesSync());
        final ArchiveFile libapp = archive.findFile('base/lib/arm64-v8a/libapp.so')!;
        final Uint8List libappBytes = libapp.content as Uint8List; // bytes decompressed here
        final String libappStrings = utf8.decode(libappBytes, allowMalformed: true);
        await runCommand(flutter, <String>['clean'], workingDirectory: tracingDirectory);
        return <String>[
          for (final String pattern in allowed)
            if (!libappStrings.contains(pattern))
              'When building with --$modeArgument, expected to find "$pattern" in libapp.so but could not find it.',
          for (final String pattern in disallowed)
            if (libappStrings.contains(pattern))
              'When building with --$modeArgument, expected to not find "$pattern" in libapp.so but did find it.',
        ];
      } catch (error, stackTrace) {
        return <String>[
          error.toString(),
          ...stackTrace.toString().trimRight().split('\n'),
        ];
      }
    }

    final List<String> results = <String>[];
    results.addAll(await verifyTracingAppBuild(
      modeArgument: 'profile',
      sourceFile: 'control.dart', // this is the control, the other two below are the actual test
      allowed: <String>{
        'TIMELINE ARGUMENTS TEST CONTROL FILE',
        'toTimelineArguments used in non-debug build', // we call toTimelineArguments directly to check the message does exist
      },
      disallowed: <String>{
        'BUILT IN DEBUG MODE', 'BUILT IN RELEASE MODE',
      },
    ));
    results.addAll(await verifyTracingAppBuild(
      modeArgument: 'profile',
      sourceFile: 'test.dart',
      allowed: <String>{
        'BUILT IN PROFILE MODE', 'RenderTest.performResize called', // controls
        'BUILD', 'LAYOUT', 'PAINT', // we output these to the timeline in profile builds
        // (LAYOUT and PAINT also exist because of NEEDS-LAYOUT and NEEDS-PAINT in RenderObject.toStringShort)
      },
      disallowed: <String>{
        'BUILT IN DEBUG MODE', 'BUILT IN RELEASE MODE',
        'TestWidget.debugFillProperties called', 'RenderTest.debugFillProperties called', // debug only
        'toTimelineArguments used in non-debug build', // entire function should get dropped by tree shaker
      },
    ));
    results.addAll(await verifyTracingAppBuild(
      modeArgument: 'release',
      sourceFile: 'test.dart',
      allowed: <String>{
        'BUILT IN RELEASE MODE', 'RenderTest.performResize called', // controls
      },
      disallowed: <String>{
        'BUILT IN DEBUG MODE', 'BUILT IN PROFILE MODE',
        'BUILD', 'LAYOUT', 'PAINT', // these are only used in Timeline.startSync calls that should not appear in release builds
        'TestWidget.debugFillProperties called', 'RenderTest.debugFillProperties called', // debug only
        'toTimelineArguments used in non-debug build', // not included in release builds
      },
    ));
    if (results.isNotEmpty) {
      foundError(results);
    }
  }

  Future<void> runFixTests(String package) async {
    final List<String> args = <String>[
      'fix',
      '--compare-to-golden',
    ];
    await runCommand(
      dart,
      args,
      workingDirectory: path.join(flutterRoot, 'packages', package, 'test_fixes'),
    );
  }

  Future<void> runPrivateTests() async {
    final List<String> args = <String>[
      'run',
      'bin/test_private.dart',
    ];
    final Map<String, String> environment = <String, String>{
      'FLUTTER_ROOT': flutterRoot,
      if (Directory(pubCache).existsSync())
        'PUB_CACHE': pubCache,
    };
    adjustEnvironmentToEnableFlutterAsserts(environment);
    await runCommand(
      dart,
      args,
      workingDirectory: path.join(flutterRoot, 'packages', 'flutter', 'test_private'),
      environment: environment,
    );
  }

  // Tests that take longer than average to run. This is usually because they
  // need to compile something large or make use of the analyzer for the test.
  // These tests need to be platform agnostic as they are only run on a linux
  // machine to save on execution time and cost.
  Future<void> runSlow() async {
    printProgress('${green}Running slow package tests$reset for directories other than packages/flutter');
    await runTracingTests();
    await runFixTests('flutter');
    await runFixTests('flutter_test');
    await runFixTests('integration_test');
    await runFixTests('flutter_driver');
    await runPrivateTests();
  }

  Future<void> runMisc() async {
    printProgress('${green}Running package tests$reset for directories other than packages/flutter');
    await _runTestHarnessTests();
    await runExampleTests();
    await runFlutterTest(
      path.join(flutterRoot, 'dev', 'a11y_assessments'),
      tests: <String>[ 'test' ],
    );
    await runDartTest(path.join(flutterRoot, 'dev', 'bots'));
    await runDartTest(path.join(flutterRoot, 'dev', 'devicelab'), ensurePrecompiledTool: false); // See https://github.com/flutter/flutter/issues/86209
    await runDartTest(path.join(flutterRoot, 'dev', 'conductor', 'core'), forceSingleCore: true);
    // TODO(gspencergoog): Remove the exception for fatalWarnings once https://github.com/flutter/flutter/issues/113782 has landed.
    await runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'android_semantics_testing'), fatalWarnings: false);
    await runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'ui'));
    await runFlutterTest(path.join(flutterRoot, 'dev', 'manual_tests'));
    await runFlutterTest(path.join(flutterRoot, 'dev', 'tools'));
    await runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'vitool'));
    await runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'gen_defaults'));
    await runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'gen_keycodes'));
    await runFlutterTest(path.join(flutterRoot, 'dev', 'benchmarks', 'test_apps', 'stocks'));
    await runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_driver'), tests: <String>[path.join('test', 'src', 'real_tests')]);
    await runFlutterTest(path.join(flutterRoot, 'packages', 'integration_test'), options: <String>[
      '--enable-vmservice',
      // Web-specific tests depend on Chromium, so they run as part of the web_long_running_tests shard.
      '--exclude-tags=web',
    ]);
    // Run java unit tests for integration_test
    //
    // Generate Gradle wrapper if it doesn't exist.
    Process.runSync(
      flutter,
      <String>['build', 'apk', '--config-only'],
      workingDirectory: path.join(flutterRoot, 'packages', 'integration_test', 'example', 'android'),
    );
    await runCommand(
      path.join(flutterRoot, 'packages', 'integration_test', 'example', 'android', 'gradlew$bat'),
      <String>[
        ':integration_test:testDebugUnitTest',
        '--tests',
        'dev.flutter.plugins.integration_test.FlutterDeviceScreenshotTest',
      ],
      workingDirectory: path.join(flutterRoot, 'packages', 'integration_test', 'example', 'android'),
    );
    await runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_goldens'));
    await runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_localizations'));
    await runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_test'));
    await runFlutterTest(path.join(flutterRoot, 'packages', 'fuchsia_remote_debug_protocol'));
    await runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'non_nullable'));
    const String httpClientWarning =
      'Warning: At least one test in this suite creates an HttpClient. When running a test suite that uses\n'
      'TestWidgetsFlutterBinding, all HTTP requests will return status code 400, and no network request\n'
      'will actually be made. Any test expecting a real network connection and status code will fail.\n'
      'To test code that needs an HttpClient, provide your own HttpClient implementation to the code under\n'
      'test, so that your test can consistently provide a testable response to the code under test.';
    await runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter_test'),
      script: path.join('test', 'bindings_test_failure.dart'),
      expectFailure: true,
      printOutput: false,
      outputChecker: (CommandResult result) {
        final Iterable<Match> matches = httpClientWarning.allMatches(result.flattenedStdout!);
        if (matches.isEmpty || matches.length > 1) {
          return 'Failed to print warning about HttpClientUsage, or printed it too many times.\n\n'
                 'stdout:\n${result.flattenedStdout}\n\n'
                 'stderr:\n${result.flattenedStderr}';
        }
        return null;
      },
    );
  }

  await selectSubshard(<String, ShardRunner>{
    'widgets': runWidgets,
    'libraries': runLibraries,
    'slow': runSlow,
    'misc': runMisc,
    'impeller': runImpeller,
  });
}

/// This will force the next run of the Flutter tool (if it uses the provided
/// environment) to have asserts enabled, by setting an environment variable.
void adjustEnvironmentToEnableFlutterAsserts(Map<String, String> environment) {
  // If an existing env variable exists append to it, but only if
  // it doesn't appear to already include enable-asserts.
  String toolsArgs = Platform.environment['FLUTTER_TOOL_ARGS'] ?? '';
  if (!toolsArgs.contains('--enable-asserts')) {
    toolsArgs += ' --enable-asserts';
  }
  environment['FLUTTER_TOOL_ARGS'] = toolsArgs.trim();
}

/// Checks the given file's contents to determine if they match the allowed
/// pattern for version strings.
///
/// Returns null if the contents are good. Returns a string if they are bad.
/// The string is an error message.
Future<String?> verifyVersion(File file) async {
  final RegExp pattern = RegExp(
    r'^(\d+)\.(\d+)\.(\d+)((-\d+\.\d+)?\.pre(\.\d+)?)?$');
  if (!file.existsSync()) {
    return 'The version logic failed to create the Flutter version file.';
  }
  final String version = await file.readAsString();
  if (version == '0.0.0-unknown') {
    return 'The version logic failed to determine the Flutter version.';
  }
  if (!version.contains(pattern)) {
    return 'The version logic generated an invalid version string: "$version".';
  }
  return null;
}
