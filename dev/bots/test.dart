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
import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file/file.dart' as fs;
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import 'browser.dart';
import 'run_command.dart';
import 'service_worker_test.dart';
import 'tool_subsharding.dart';
import 'utils.dart';

typedef ShardRunner = Future<void> Function();

/// A function used to validate the output of a test.
///
/// If the output matches expectations, the function shall return null.
///
/// If the output does not match expectations, the function shall return an
/// appropriate error message.
typedef OutputChecker = String? Function(CommandResult);

final String exe = Platform.isWindows ? '.exe' : '';
final String bat = Platform.isWindows ? '.bat' : '';
final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', 'flutter$bat');
final String dart = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dart$exe');
final String pubCache = path.join(flutterRoot, '.pub-cache');
final String engineVersionFile = path.join(flutterRoot, 'bin', 'internal', 'engine.version');
final String engineRealmFile = path.join(flutterRoot, 'bin', 'internal', 'engine.realm');
final String flutterPackagesVersionFile = path.join(flutterRoot, 'bin', 'internal', 'flutter_packages.version');

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

/// The arguments to pass to `flutter test` (typically the local engine
/// configuration) -- prefilled with the arguments passed to test.dart.
final List<String> flutterTestArgs = <String>[];

/// Environment variables to override the local engine when running `pub test`,
/// if such flags are provided to `test.dart`.
final Map<String,String> localEngineEnv = <String, String>{};

const String kShardKey = 'SHARD';
const String kSubshardKey = 'SUBSHARD';

/// The number of Cirrus jobs that run Web tests in parallel.
///
/// The default is 8 shards. Typically .cirrus.yml would define the
/// WEB_SHARD_COUNT environment variable rather than relying on the default.
///
/// WARNING: if you change this number, also change .cirrus.yml
/// and make sure it runs _all_ shards.
///
/// The last shard also runs the Web plugin tests.
int get webShardCount => Platform.environment.containsKey('WEB_SHARD_COUNT')
  ? int.parse(Platform.environment['WEB_SHARD_COUNT']!)
  : 8;

/// Tests that we don't run on Web.
///
/// In general avoid adding new tests here. If a test cannot run on the web
/// because it fails at runtime, such as when a piece of functionality is not
/// implemented or not implementable on the web, prefer using `skip` in the
/// test code. Only add tests here that cannot be skipped using `skip`. For
/// example:
///
///  * Test code cannot be compiled because it uses Dart VM-specific
///    functionality. In this case `skip` doesn't help because the code cannot
///    reach the point where it can even run the skipping logic.
///  * Migrations. It is OK to put tests here that need to be temporarily
///    disabled in certain modes because of some migration or initial bringup.
///
/// The key in the map is the renderer type that the list applies to. The value
/// is the list of tests known to fail for that renderer.
//
// TODO(yjbanov): we're getting rid of this as part of https://github.com/flutter/flutter/projects/60
const Map<String, List<String>> kWebTestFileKnownFailures = <String, List<String>>{
  'html': <String>[
    // These tests are not compilable on the web due to dependencies on
    // VM-specific functionality.
    'test/services/message_codecs_vm_test.dart',
    'test/examples/sector_layout_test.dart',
  ],
  'canvaskit': <String>[
    // These tests are not compilable on the web due to dependencies on
    // VM-specific functionality.
    'test/services/message_codecs_vm_test.dart',
    'test/examples/sector_layout_test.dart',

    // These tests are broken and need to be fixed.
    // TODO(yjbanov): https://github.com/flutter/flutter/issues/71604
    'test/material/text_field_test.dart',
    'test/widgets/performance_overlay_test.dart',
    'test/widgets/html_element_view_test.dart',
    'test/cupertino/scaffold_test.dart',
    'test/rendering/platform_view_test.dart',
  ],
};

const String kTestHarnessShardName = 'test_harness_tests';
const List<String> _kAllBuildModes = <String>['debug', 'profile', 'release'];

// The seed used to shuffle tests. If not passed with
// --test-randomize-ordering-seed=<seed> on the command line, it will be set the
// first time it is accessed. Pass zero to turn off shuffling.
String? _shuffleSeed;
String get shuffleSeed {
  if (_shuffleSeed == null) {
    // Change the seed at 7am, UTC.
    final DateTime seedTime = DateTime.now().toUtc().subtract(const Duration(hours: 7));
    // Generates YYYYMMDD as the seed, so that testing continues to fail for a
    // day after the seed changes, and on other days the seed can be used to
    // replicate failures.
    _shuffleSeed = '${seedTime.year * 10000 + seedTime.month * 100 + seedTime.day}';
  }
  return _shuffleSeed!;
}

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
        _shuffleSeed = arg.substring('--test-randomize-ordering-seed='.length);
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
    await selectShard(<String, ShardRunner>{
      'add_to_app_life_cycle_tests': _runAddToAppLifeCycleTests,
      'build_tests': _runBuildTests,
      'framework_coverage': _runFrameworkCoverage,
      'framework_tests': _runFrameworkTests,
      'tool_tests': _runToolTests,
      // web_tool_tests is also used by HHH: https://dart.googlesource.com/recipes/+/refs/heads/master/recipes/dart/flutter_engine.py
      'web_tool_tests': _runWebToolTests,
      'tool_integration_tests': _runIntegrationToolTests,
      'android_preview_tool_integration_tests': _runAndroidPreviewIntegrationToolTests,
      'tool_host_cross_arch_tests': _runToolHostCrossArchTests,
      // All the unit/widget tests run using `flutter test --platform=chrome --web-renderer=html`
      'web_tests': _runWebHtmlUnitTests,
      // All the unit/widget tests run using `flutter test --platform=chrome --web-renderer=canvaskit`
      'web_canvaskit_tests': _runWebCanvasKitUnitTests,
      // All web integration tests
      'web_long_running_tests': _runWebLongRunningTests,
      'flutter_plugins': _runFlutterPackagesTests,
      'skp_generator': _runSkpGeneratorTests,
      'realm_checker': _runRealmCheckerTest,
      'customer_testing': _runCustomerTesting,
      'analyze': _runAnalyze,
      'fuchsia_precache': _runFuchsiaPrecache,
      'docs': _runDocs,
      'verify_binaries_codesigned': _runVerifyCodesigned,
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

final String _luciBotId = Platform.environment['SWARMING_BOT_ID'] ?? '';
final bool _runningInDartHHHBot =
    _luciBotId.startsWith('luci-dart-') || _luciBotId.startsWith('dart-tests-');

/// Verify the Flutter Engine is the revision in
/// bin/cache/internal/engine.version.
Future<void> _validateEngineHash() async {
  if (_runningInDartHHHBot) {
    // The Dart HHH bots intentionally modify the local artifact cache
    // and then use this script to run Flutter's test suites.
    // Because the artifacts have been changed, this particular test will return
    // a false positive and should be skipped.
    print('${yellow}Skipping Flutter Engine Version Validation for swarming bot $_luciBotId.');
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
    () => _runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'pass_test.dart'),
      printOutput: false,
    ),
    () => _runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'fail_test.dart'),
      expectFailure: true,
      printOutput: false,
    ),
    () => _runFlutterTest(
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
    () => _runFlutterTest(
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
    () => _runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'crash1_test.dart'),
      expectFailure: true,
      printOutput: false,
    ),
    () => _runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'crash2_test.dart'),
      expectFailure: true,
      printOutput: false,
    ),
    () => _runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'syntax_error_test.broken_dart'),
      expectFailure: true,
      printOutput: false,
    ),
    () => _runFlutterTest(
      automatedTests,
      script: path.join('test_smoke_test', 'missing_import_test.broken_dart'),
      expectFailure: true,
      printOutput: false,
    ),
    () => _runFlutterTest(
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
    testsToRun = _selectIndexOfTotalSubshard<ShardRunner>(tests);
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
  await _runDartTest(
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
  await _runDartTest(
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
  await _runDartTest(
    _toolsPath,
    forceSingleCore: true,
    testPaths: _selectIndexOfTotalSubshard<String>(allTests),
    includeLocalEngineEnv: true,
  );
}

Future<void> _runToolHostCrossArchTests() {
  return _runDartTest(
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

  await _runDartTest(
    _toolsPath,
    forceSingleCore: true,
    testPaths: _selectIndexOfTotalSubshard<String>(allTests),
    collectMetrics: true,
  );
}

Future<void> _runAndroidPreviewIntegrationToolTests() async {
  final List<String> allTests = Directory(path.join(_toolsPath, 'test', 'android_preview_integration.shard'))
      .listSync(recursive: true).whereType<File>()
      .map<String>((FileSystemEntity entry) => path.relative(entry.path, from: _toolsPath))
      .where((String testPath) => path.basename(testPath).endsWith('_test.dart')).toList();

  await _runDartTest(
    _toolsPath,
    forceSingleCore: true,
    testPaths: _selectIndexOfTotalSubshard<String>(allTests),
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
    ],
    runForbiddenFromReleaseTests,
  ]..shuffle(math.Random(0));

  await _runShardRunnerIndexOfTotalSubshard(tests);
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

Future<void> _runAddToAppLifeCycleTests() async {
  if (Platform.isMacOS) {
    printProgress('${green}Running add-to-app life cycle iOS integration tests$reset...');
    final String addToAppDir = path.join(flutterRoot, 'dev', 'integration_tests', 'ios_add2app_life_cycle');
    await runCommand('./build_and_test.sh',
      <String>[],
      workingDirectory: addToAppDir,
    );
  } else {
    printProgress('${yellow}Skipped on this platform (only iOS has add-to-add lifecycle tests at this time).$reset');
  }
}

Future<void> _runFrameworkTests() async {
  final List<String> trackWidgetCreationAlternatives = <String>['--track-widget-creation', '--no-track-widget-creation'];

  Future<void> runWidgets() async {
    printProgress('${green}Running packages/flutter tests $reset for ${cyan}test/widgets/$reset');
    for (final String trackWidgetCreationOption in trackWidgetCreationAlternatives) {
      await _runFlutterTest(
        path.join(flutterRoot, 'packages', 'flutter'),
        options: <String>[trackWidgetCreationOption],
        tests: <String>[ path.join('test', 'widgets') + path.separator ],
      );
    }
    // Try compiling code outside of the packages/flutter directory with and without --track-widget-creation
    for (final String trackWidgetCreationOption in trackWidgetCreationAlternatives) {
      await _runFlutterTest(
        path.join(flutterRoot, 'dev', 'integration_tests', 'flutter_gallery'),
        options: <String>[trackWidgetCreationOption],
        fatalWarnings: false, // until we've migrated video_player
      );
    }
    // Run release mode tests (see packages/flutter/test_release/README.md)
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--dart-define=dart.vm.product=true'],
      tests: <String>['test_release${path.separator}'],
    );
    // Run profile mode tests (see packages/flutter/test_profile/README.md)
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--dart-define=dart.vm.product=false', '--dart-define=dart.vm.profile=true'],
      tests: <String>['test_profile${path.separator}'],
    );
  }

  Future<void> runImpeller() async {
    printProgress('${green}Running packages/flutter tests $reset in Impeller$reset');
    await _runFlutterTest(
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
      await _runFlutterTest(
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
      await _runFlutterTest(entity.path);
    }
  }

  Future<void> runTracingTests() async {
    final String tracingDirectory = path.join(flutterRoot, 'dev', 'tracing_tests');

    // run the tests for debug mode
    await _runFlutterTest(tracingDirectory, options: <String>['--enable-vmservice']);

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
        final List<String> results = <String>[];
        for (final String pattern in allowed) {
          if (!libappStrings.contains(pattern)) {
            results.add('When building with --$modeArgument, expected to find "$pattern" in libapp.so but could not find it.');
          }
        }
        for (final String pattern in disallowed) {
          if (libappStrings.contains(pattern)) {
            results.add('When building with --$modeArgument, expected to not find "$pattern" in libapp.so but did find it.');
          }
        }
        return results;
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
    await _runFlutterTest(
      path.join(flutterRoot, 'dev', 'a11y_assessments'),
      tests: <String>[ 'test' ],
    );
    await _runDartTest(path.join(flutterRoot, 'dev', 'bots'));
    await _runDartTest(path.join(flutterRoot, 'dev', 'devicelab'), ensurePrecompiledTool: false); // See https://github.com/flutter/flutter/issues/86209
    await _runDartTest(path.join(flutterRoot, 'dev', 'conductor', 'core'), forceSingleCore: true);
    // TODO(gspencergoog): Remove the exception for fatalWarnings once https://github.com/flutter/flutter/issues/113782 has landed.
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'android_semantics_testing'), fatalWarnings: false);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'ui'));
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'manual_tests'));
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'tools'));
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'vitool'));
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'gen_defaults'));
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'gen_keycodes'));
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'benchmarks', 'test_apps', 'stocks'));
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_driver'), tests: <String>[path.join('test', 'src', 'real_tests')]);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'integration_test'), options: <String>[
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
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_goldens'));
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_localizations'));
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_test'));
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'fuchsia_remote_debug_protocol'));
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'non_nullable'));
    const String httpClientWarning =
      'Warning: At least one test in this suite creates an HttpClient. When running a test suite that uses\n'
      'TestWidgetsFlutterBinding, all HTTP requests will return status code 400, and no network request\n'
      'will actually be made. Any test expecting a real network connection and status code will fail.\n'
      'To test code that needs an HttpClient, provide your own HttpClient implementation to the code under\n'
      'test, so that your test can consistently provide a testable response to the code under test.';
    await _runFlutterTest(
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

Future<void> _runFrameworkCoverage() async {
  final File coverageFile = File(path.join(flutterRoot, 'packages', 'flutter', 'coverage', 'lcov.info'));
  if (!coverageFile.existsSync()) {
    foundError(<String>[
      '${red}Coverage file not found.$reset',
      'Expected to find: $cyan${coverageFile.absolute.path}$reset',
      'This file is normally obtained by running `${green}flutter update-packages$reset`.',
    ]);
    return;
  }
  coverageFile.deleteSync();
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter'),
    options: const <String>['--coverage'],
  );
  if (!coverageFile.existsSync()) {
    foundError(<String>[
      '${red}Coverage file not found.$reset',
      'Expected to find: $cyan${coverageFile.absolute.path}$reset',
      'This file should have been generated by the `${green}flutter test --coverage$reset` script, but was not.',
    ]);
    return;
  }
}

Future<void> _runWebHtmlUnitTests() {
  return _runWebUnitTests('html');
}

Future<void> _runWebCanvasKitUnitTests() {
  return _runWebUnitTests('canvaskit');
}

Future<void> _runWebUnitTests(String webRenderer) async {
  final Map<String, ShardRunner> subshards = <String, ShardRunner>{};

  final Directory flutterPackageDirectory = Directory(path.join(flutterRoot, 'packages', 'flutter'));
  final Directory flutterPackageTestDirectory = Directory(path.join(flutterPackageDirectory.path, 'test'));

  final List<String> allTests = flutterPackageTestDirectory
    .listSync()
    .whereType<Directory>()
    .expand((Directory directory) => directory
      .listSync(recursive: true)
      .where((FileSystemEntity entity) => entity.path.endsWith('_test.dart'))
    )
    .whereType<File>()
    .map<String>((File file) => path.relative(file.path, from: flutterPackageDirectory.path))
    .where((String filePath) => !kWebTestFileKnownFailures[webRenderer]!.contains(path.split(filePath).join('/')))
    .toList()
    // Finally we shuffle the list because we want the average cost per file to be uniformly
    // distributed. If the list is not sorted then different shards and batches may have
    // very different characteristics.
    // We use a constant seed for repeatability.
    ..shuffle(math.Random(0));

  assert(webShardCount >= 1);
  final int testsPerShard = (allTests.length / webShardCount).ceil();
  assert(testsPerShard * webShardCount >= allTests.length);

  // This for loop computes all but the last shard.
  for (int index = 0; index < webShardCount - 1; index += 1) {
    subshards['$index'] = () => _runFlutterWebTest(
      webRenderer,
      flutterPackageDirectory.path,
      allTests.sublist(
        index * testsPerShard,
        (index + 1) * testsPerShard,
      ),
    );
  }

  // The last shard also runs the flutter_web_plugins tests.
  //
  // We make sure the last shard ends in _last so it's easier to catch mismatches
  // between `.cirrus.yml` and `test.dart`.
  subshards['${webShardCount - 1}_last'] = () async {
    await _runFlutterWebTest(
      webRenderer,
      flutterPackageDirectory.path,
      allTests.sublist(
        (webShardCount - 1) * testsPerShard,
        allTests.length,
      ),
    );
    await _runFlutterWebTest(
      webRenderer,
      path.join(flutterRoot, 'packages', 'flutter_web_plugins'),
      <String>['test'],
    );
    await _runFlutterWebTest(
      webRenderer,
      path.join(flutterRoot, 'packages', 'flutter_driver'),
      <String>[path.join('test', 'src', 'web_tests', 'web_extension_test.dart')],
    );
  };

  await selectSubshard(subshards);
}

/// Coarse-grained integration tests running on the Web.
Future<void> _runWebLongRunningTests() async {
  final String engineVersion = File(engineVersionFile).readAsStringSync().trim();
  final String engineRealm = File(engineRealmFile).readAsStringSync().trim();
  if (engineRealm.isNotEmpty) {
    return;
  }
  final List<ShardRunner> tests = <ShardRunner>[
    for (final String buildMode in _kAllBuildModes) ...<ShardRunner>[
      () => _runFlutterDriverWebTest(
        testAppDirectory: path.join('packages', 'integration_test', 'example'),
        target: path.join('test_driver', 'failure.dart'),
        buildMode: buildMode,
        renderer: 'canvaskit',
        // This test intentionally fails and prints stack traces in the browser
        // logs. To avoid confusion, silence browser output.
        silenceBrowserOutput: true,
      ),
      () => _runFlutterDriverWebTest(
        testAppDirectory: path.join('packages', 'integration_test', 'example'),
        target: path.join('integration_test', 'example_test.dart'),
        driver: path.join('test_driver', 'integration_test.dart'),
        buildMode: buildMode,
        renderer: 'canvaskit',
        expectWriteResponseFile: true,
        expectResponseFileContent: 'null',
      ),
      () => _runFlutterDriverWebTest(
        testAppDirectory: path.join('packages', 'integration_test', 'example'),
        target: path.join('integration_test', 'extended_test.dart'),
        driver: path.join('test_driver', 'extended_integration_test.dart'),
        buildMode: buildMode,
        renderer: 'canvaskit',
        expectWriteResponseFile: true,
        expectResponseFileContent: '''
{
  "screenshots": [
    {
      "screenshotName": "platform_name",
      "bytes": []
    },
    {
      "screenshotName": "platform_name_2",
      "bytes": []
    }
  ]
}''',
      ),
    ],

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    () => _runWebE2eTest('platform_messages_integration', buildMode: 'debug', renderer: 'canvaskit'),
    () => _runWebE2eTest('platform_messages_integration', buildMode: 'profile', renderer: 'html'),
    () => _runWebE2eTest('platform_messages_integration', buildMode: 'release', renderer: 'html'),

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    () => _runWebE2eTest('profile_diagnostics_integration', buildMode: 'debug', renderer: 'html'),
    () => _runWebE2eTest('profile_diagnostics_integration', buildMode: 'profile', renderer: 'canvaskit'),
    () => _runWebE2eTest('profile_diagnostics_integration', buildMode: 'release', renderer: 'html'),

    // This test is only known to work in debug mode.
    () => _runWebE2eTest('scroll_wheel_integration', buildMode: 'debug', renderer: 'html'),

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    () => _runWebE2eTest('text_editing_integration', buildMode: 'debug', renderer: 'canvaskit'),
    () => _runWebE2eTest('text_editing_integration', buildMode: 'profile', renderer: 'html'),
    () => _runWebE2eTest('text_editing_integration', buildMode: 'release', renderer: 'html'),

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    () => _runWebE2eTest('url_strategy_integration', buildMode: 'debug', renderer: 'html'),
    () => _runWebE2eTest('url_strategy_integration', buildMode: 'profile', renderer: 'canvaskit'),
    () => _runWebE2eTest('url_strategy_integration', buildMode: 'release', renderer: 'html'),

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    () => _runWebE2eTest('capabilities_integration_canvaskit', buildMode: 'debug', renderer: 'auto'),
    () => _runWebE2eTest('capabilities_integration_canvaskit', buildMode: 'profile', renderer: 'canvaskit'),
    () => _runWebE2eTest('capabilities_integration_html', buildMode: 'release', renderer: 'html'),

    // This test doesn't do anything interesting w.r.t. rendering, so we don't run the full build mode x renderer matrix.
    // CacheWidth and CacheHeight are only currently supported in CanvasKit mode, so we don't run the test in HTML mode.
    () => _runWebE2eTest('cache_width_cache_height_integration', buildMode: 'debug', renderer: 'auto'),
    () => _runWebE2eTest('cache_width_cache_height_integration', buildMode: 'profile', renderer: 'canvaskit'),

    () => _runWebTreeshakeTest(),

    () => _runFlutterDriverWebTest(
      testAppDirectory: path.join(flutterRoot, 'examples', 'hello_world'),
      target: 'test_driver/smoke_web_engine.dart',
      buildMode: 'profile',
      renderer: 'auto',
    ),
    () => _runGalleryE2eWebTest('debug'),
    () => _runGalleryE2eWebTest('debug', canvasKit: true),
    () => _runGalleryE2eWebTest('profile'),
    () => _runGalleryE2eWebTest('profile', canvasKit: true),
    () => _runGalleryE2eWebTest('release'),
    () => _runGalleryE2eWebTest('release', canvasKit: true),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withoutFlutterJs),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withFlutterJs),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withFlutterJsShort),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withFlutterJsEntrypointLoadedEvent),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withFlutterJsTrustedTypesOn),
    () => runWebServiceWorkerTest(headless: true, testType: ServiceWorkerTestType.withFlutterJsNonceOn),
    () => runWebServiceWorkerTestWithCachingResources(headless: true, testType: ServiceWorkerTestType.withoutFlutterJs),
    () => runWebServiceWorkerTestWithCachingResources(headless: true, testType: ServiceWorkerTestType.withFlutterJs),
    () => runWebServiceWorkerTestWithCachingResources(headless: true, testType: ServiceWorkerTestType.withFlutterJsShort),
    () => runWebServiceWorkerTestWithCachingResources(headless: true, testType: ServiceWorkerTestType.withFlutterJsEntrypointLoadedEvent),
    () => runWebServiceWorkerTestWithCachingResources(headless: true, testType: ServiceWorkerTestType.withFlutterJsTrustedTypesOn),
    () => runWebServiceWorkerTestWithGeneratedEntrypoint(headless: true),
    () => runWebServiceWorkerTestWithBlockedServiceWorkers(headless: true),
    () => runWebServiceWorkerTestWithCustomServiceWorkerVersion(headless: true),
    () => _runWebStackTraceTest('profile', 'lib/stack_trace.dart'),
    () => _runWebStackTraceTest('release', 'lib/stack_trace.dart'),
    () => _runWebStackTraceTest('profile', 'lib/framework_stack_trace.dart'),
    () => _runWebStackTraceTest('release', 'lib/framework_stack_trace.dart'),
    () => _runWebDebugTest('lib/stack_trace.dart'),
    () => _runWebDebugTest('lib/framework_stack_trace.dart'),
    () => _runWebDebugTest('lib/web_directory_loading.dart'),
    () => _runWebDebugTest('lib/web_resources_cdn_test.dart',
      additionalArguments: <String>[
        '--dart-define=TEST_FLUTTER_ENGINE_VERSION=$engineVersion',
      ]),
    () => _runWebDebugTest('test/test.dart'),
    () => _runWebDebugTest('lib/null_safe_main.dart'),
    () => _runWebDebugTest('lib/web_define_loading.dart',
      additionalArguments: <String>[
        '--dart-define=test.valueA=Example,A',
        '--dart-define=test.valueB=Value',
      ]
    ),
    () => _runWebReleaseTest('lib/web_define_loading.dart',
      additionalArguments: <String>[
        '--dart-define=test.valueA=Example,A',
        '--dart-define=test.valueB=Value',
      ]
    ),
    () => _runWebDebugTest('lib/sound_mode.dart'),
    () => _runWebReleaseTest('lib/sound_mode.dart'),
    () => _runFlutterWebTest(
      'html',
      path.join(flutterRoot, 'packages', 'integration_test'),
      <String>['test/web_extension_test.dart'],
    ),
    () => _runFlutterWebTest(
      'canvaskit',
      path.join(flutterRoot, 'packages', 'integration_test'),
      <String>['test/web_extension_test.dart'],
    ),
  ];

  // Shuffling mixes fast tests with slow tests so shards take roughly the same
  // amount of time to run.
  tests.shuffle(math.Random(0));

  await _ensureChromeDriverIsRunning();
  await _runShardRunnerIndexOfTotalSubshard(tests);
  await _stopChromeDriver();
}

/// Runs one of the `dev/integration_tests/web_e2e_tests` tests.
Future<void> _runWebE2eTest(
  String name, {
  required String buildMode,
  required String renderer,
}) async {
  await _runFlutterDriverWebTest(
    target: path.join('test_driver', '$name.dart'),
    buildMode: buildMode,
    renderer: renderer,
    testAppDirectory: path.join(flutterRoot, 'dev', 'integration_tests', 'web_e2e_tests'),
  );
}

Future<void> _runFlutterDriverWebTest({
  required String target,
  required String buildMode,
  required String renderer,
  required String testAppDirectory,
  String? driver,
  bool expectFailure = false,
  bool silenceBrowserOutput = false,
  bool expectWriteResponseFile = false,
  String expectResponseFileContent = '',
}) async {
  printProgress('${green}Running integration tests $target in $buildMode mode.$reset');
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  final String responseFile =
      path.join(testAppDirectory, 'build', 'integration_response_data.json');
  if (File(responseFile).existsSync()) {
    File(responseFile).deleteSync();
  }
  await runCommand(
    flutter,
    <String>[
      ...flutterTestArgs,
      'drive',
      if (driver != null) '--driver=$driver',
      '--target=$target',
      '--browser-name=chrome',
      '-d',
      'web-server',
      '--$buildMode',
      '--web-renderer=$renderer',
    ],
    expectNonZeroExit: expectFailure,
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
    removeLine: (String line) {
      if (!silenceBrowserOutput) {
        return false;
      }
      if (line.trim().startsWith('[INFO]')) {
        return true;
      }
      return false;
    },
  );
  if (expectWriteResponseFile) {
    if (!File(responseFile).existsSync()) {
      foundError(<String>[
        '$bold${red}Command did not write the response file but expected response file written.$reset',
      ]);
    } else {
      final String response = File(responseFile).readAsStringSync();
      if (response != expectResponseFileContent) {
        foundError(<String>[
          '$bold${red}Command write the response file with $response but expected response file with $expectResponseFileContent.$reset',
        ]);
      }
    }
  }
}

// Compiles a sample web app and checks that its JS doesn't contain certain
// debug code that we expect to be tree shaken out.
//
// The app is compiled in `--profile` mode to prevent the compiler from
// minifying the symbols.
Future<void> _runWebTreeshakeTest() async {
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'web_e2e_tests');
  final String target = path.join('lib', 'treeshaking_main.dart');
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  await runCommand(
    flutter,
    <String>[
      'build',
      'web',
      '--target=$target',
      '--profile',
    ],
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );

  final File mainDartJs = File(path.join(testAppDirectory, 'build', 'web', 'main.dart.js'));
  final String javaScript = mainDartJs.readAsStringSync();

  // Check that we're not looking at minified JS. Otherwise this test would result in false positive.
  expect(javaScript.contains('RootElement'), true);

  const String word = 'debugFillProperties';
  int count = 0;
  int pos = javaScript.indexOf(word);
  final int contentLength = javaScript.length;
  while (pos != -1) {
    count += 1;
    pos += word.length;
    if (pos >= contentLength || count > 100) {
      break;
    }
    pos = javaScript.indexOf(word, pos);
  }

  // The following are classes from `timeline.dart` that should be treeshaken
  // off unless the app (typically a benchmark) uses methods that need them.
  expect(javaScript.contains('AggregatedTimedBlock'), false);
  expect(javaScript.contains('AggregatedTimings'), false);
  expect(javaScript.contains('_BlockBuffer'), false);
  expect(javaScript.contains('_StringListChain'), false);
  expect(javaScript.contains('_Float64ListChain'), false);

  const int kMaxExpectedDebugFillProperties = 11;
  if (count > kMaxExpectedDebugFillProperties) {
    throw Exception(
      'Too many occurrences of "$word" in compiled JavaScript.\n'
      'Expected no more than $kMaxExpectedDebugFillProperties, but found $count.'
    );
  }
}

/// Returns the commit hash of the flutter/packages repository that's rolled in.
///
/// The flutter/packages repository is a downstream dependency, it is only used
/// by flutter/flutter for testing purposes, to assure stable tests for a given
/// flutter commit the flutter/packages commit hash to test against is coded in
/// the bin/internal/flutter_packages.version file.
///
/// The `filesystem` parameter specified filesystem to read the packages version file from.
/// The `packagesVersionFile` parameter allows specifying an alternative path for the
/// packages version file, when null [flutterPackagesVersionFile] is used.
Future<String> getFlutterPackagesVersion({
  fs.FileSystem fileSystem = const LocalFileSystem(),
  String? packagesVersionFile,
}) async {
  final File versionFile = fileSystem.file(packagesVersionFile ?? flutterPackagesVersionFile);
  final String versionFileContents = await versionFile.readAsString();
  return versionFileContents.trim();
}

/// Executes the test suite for the flutter/packages repo.
Future<void> _runFlutterPackagesTests() async {
  Future<void> runAnalyze() async {
    printProgress('${green}Running analysis for flutter/packages$reset');
    final Directory checkout = Directory.systemTemp.createTempSync('flutter_packages.');
    await runCommand(
      'git',
      <String>[
        '-c',
        'core.longPaths=true',
        'clone',
        'https://github.com/flutter/packages.git',
        '.',
      ],
      workingDirectory: checkout.path,
    );
    final String packagesCommit = await getFlutterPackagesVersion();
    await runCommand(
      'git',
      <String>[
        '-c',
        'core.longPaths=true',
        'checkout',
        packagesCommit,
      ],
      workingDirectory: checkout.path,
    );
    // Prep the repository tooling.
    // This test does not use tool_runner.sh because in this context the test
    // should always run on the entire packages repo, while tool_runner.sh
    // is designed for flutter/packages CI and only analyzes changed repository
    // files when run for anything but master.
    final String toolDir = path.join(checkout.path, 'script', 'tool');
    await runCommand(
      'dart',
      <String>[
        'pub',
        'get',
      ],
      workingDirectory: toolDir,
    );
    final String toolScript = path.join(toolDir, 'bin', 'flutter_plugin_tools.dart');
    await runCommand(
      'dart',
      <String>[
        'run',
        toolScript,
        'analyze',
        // Fetch the oldest possible dependencies, rather than the newest, to
        // insulate flutter/flutter from out-of-band failures when new versions
        // of dependencies are published. This compensates for the fact that
        // flutter/packages doesn't use pinned dependencies, and for the
        // purposes of this test using old dependencies is fine. See
        // https://github.com/flutter/flutter/issues/129633
        '--downgrade',
        '--custom-analysis=script/configs/custom_analysis.yaml',
      ],
      workingDirectory: checkout.path,
    );
  }
  await selectSubshard(<String, ShardRunner>{
    'analyze': runAnalyze,
  });
}

// Runs customer_testing.
Future<void> _runCustomerTesting() async {
  printProgress('${green}Running customer testing$reset');
  await runCommand(
    'git',
    <String>[
      'fetch',
      'origin',
      'master',
    ],
    workingDirectory: flutterRoot,
  );
  await runCommand(
    'git',
    <String>[
      'branch',
      '-f',
      'master',
      'origin/master',
    ],
    workingDirectory: flutterRoot,
  );
  final Map<String, String> env = Platform.environment;
  final String? revision = env['REVISION'];
  if (revision != null) {
    await runCommand(
      'git',
      <String>[
        'checkout',
        revision,
      ],
      workingDirectory: flutterRoot,
    );
  }
  final String winScript = path.join(flutterRoot, 'dev', 'customer_testing', 'ci.bat');
  await runCommand(
    Platform.isWindows? winScript: './ci.sh',
    <String>[],
    workingDirectory: path.join(flutterRoot, 'dev', 'customer_testing'),
  );
}

// Runs analysis tests.
Future<void> _runAnalyze() async {
  printProgress('${green}Running analysis testing$reset');
  await runCommand(
    'dart',
    <String>[
      '--enable-asserts',
      path.join(flutterRoot, 'dev', 'bots', 'analyze.dart'),
    ],
    workingDirectory: flutterRoot,
  );
}

// Runs flutter_precache.
Future<void> _runFuchsiaPrecache() async {
  printProgress('${green}Running flutter precache tests$reset');
  await runCommand(
    'flutter',
    <String>[
      'config',
      '--enable-fuchsia',
    ],
    workingDirectory: flutterRoot,
  );
  await runCommand(
    'flutter',
    <String>[
      'precache',
      '--flutter_runner',
      '--fuchsia',
      '--no-android',
      '--no-ios',
      '--force',
    ],
    workingDirectory: flutterRoot,
  );
}

// Runs docs.
Future<void> _runDocs() async {
  printProgress('${green}Running flutter doc tests$reset');
  await runCommand(
    './dev/bots/docs.sh',
    <String>[
      '--output',
      'dev/docs/api_docs.zip',
      '--keep-staging',
      '--staging-dir',
      'dev/docs',
    ],
    workingDirectory: flutterRoot,
  );
}

// Verifies binaries are codesigned.
Future<void> _runVerifyCodesigned() async {
  printProgress('${green}Running binaries codesign verification$reset');
  await runCommand(
    'flutter',
    <String>[
      'precache',
      '--android',
      '--ios',
      '--macos'
    ],
    workingDirectory: flutterRoot,
  );

  await verifyExist(flutterRoot);
  await verifySignatures(flutterRoot);
}

const List<String> expectedEntitlements = <String>[
  'com.apple.security.cs.allow-jit',
  'com.apple.security.cs.allow-unsigned-executable-memory',
  'com.apple.security.cs.allow-dyld-environment-variables',
  'com.apple.security.network.client',
  'com.apple.security.network.server',
  'com.apple.security.cs.disable-library-validation',
];

/// Binaries that are expected to be codesigned and have entitlements.
///
/// This list should be kept in sync with the actual contents of Flutter's
/// cache.
List<String> binariesWithEntitlements(String flutterRoot) {
  return <String> [
    'artifacts/engine/android-arm-profile/darwin-x64/gen_snapshot',
    'artifacts/engine/android-arm-release/darwin-x64/gen_snapshot',
    'artifacts/engine/android-arm64-profile/darwin-x64/gen_snapshot',
    'artifacts/engine/android-arm64-release/darwin-x64/gen_snapshot',
    'artifacts/engine/android-x64-profile/darwin-x64/gen_snapshot',
    'artifacts/engine/android-x64-release/darwin-x64/gen_snapshot',
    'artifacts/engine/darwin-x64-profile/gen_snapshot',
    'artifacts/engine/darwin-x64-profile/gen_snapshot_arm64',
    'artifacts/engine/darwin-x64-profile/gen_snapshot_x64',
    'artifacts/engine/darwin-x64-release/gen_snapshot',
    'artifacts/engine/darwin-x64-release/gen_snapshot_arm64',
    'artifacts/engine/darwin-x64-release/gen_snapshot_x64',
    'artifacts/engine/darwin-x64/flutter_tester',
    'artifacts/engine/darwin-x64/gen_snapshot',
    'artifacts/engine/darwin-x64/gen_snapshot_arm64',
    'artifacts/engine/darwin-x64/gen_snapshot_x64',
    'artifacts/engine/ios-profile/gen_snapshot_arm64',
    'artifacts/engine/ios-release/gen_snapshot_arm64',
    'artifacts/engine/ios/gen_snapshot_arm64',
    'artifacts/libimobiledevice/idevicescreenshot',
    'artifacts/libimobiledevice/idevicesyslog',
    'artifacts/libimobiledevice/libimobiledevice-1.0.6.dylib',
    'artifacts/libplist/libplist-2.0.3.dylib',
    'artifacts/openssl/libcrypto.1.1.dylib',
    'artifacts/openssl/libssl.1.1.dylib',
    'artifacts/usbmuxd/iproxy',
    'artifacts/usbmuxd/libusbmuxd-2.0.6.dylib',
    'dart-sdk/bin/dart',
    'dart-sdk/bin/dartaotruntime',
    'dart-sdk/bin/utils/gen_snapshot',
    'dart-sdk/bin/utils/wasm-opt',
  ]
  .map((String relativePath) => path.join(flutterRoot, 'bin', 'cache', relativePath)).toList();
}

/// Binaries that are only expected to be codesigned.
///
/// This list should be kept in sync with the actual contents of Flutter's
/// cache.
List<String> binariesWithoutEntitlements(String flutterRoot) {
  return <String>[
    'artifacts/engine/darwin-x64-profile/FlutterMacOS.xcframework/macos-arm64_x86_64/FlutterMacOS.framework/Versions/A/FlutterMacOS',
    'artifacts/engine/darwin-x64-release/FlutterMacOS.xcframework/macos-arm64_x86_64/FlutterMacOS.framework/Versions/A/FlutterMacOS',
    'artifacts/engine/darwin-x64/FlutterMacOS.xcframework/macos-arm64_x86_64/FlutterMacOS.framework/Versions/A/FlutterMacOS',
    'artifacts/engine/darwin-x64/font-subset',
    'artifacts/engine/darwin-x64/impellerc',
    'artifacts/engine/darwin-x64/libpath_ops.dylib',
    'artifacts/engine/darwin-x64/libtessellator.dylib',
    'artifacts/engine/ios-profile/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
    'artifacts/engine/ios-profile/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
    'artifacts/engine/ios-profile/extension_safe/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
    'artifacts/engine/ios-profile/extension_safe/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
    'artifacts/engine/ios-release/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
    'artifacts/engine/ios-release/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
    'artifacts/engine/ios-release/extension_safe/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
    'artifacts/engine/ios-release/extension_safe/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
    'artifacts/engine/ios/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
    'artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
    'artifacts/engine/ios/extension_safe/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
    'artifacts/engine/ios/extension_safe/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
    'artifacts/ios-deploy/ios-deploy',
  ]
  .map((String relativePath) => path.join(flutterRoot, 'bin', 'cache', relativePath)).toList();
}

/// xcframeworks that are expected to be codesigned.
///
/// This list should be kept in sync with the actual contents of Flutter's
/// cache.
List<String> signedXcframeworks(String flutterRoot) {
  return <String>[
    'artifacts/engine/ios-profile/Flutter.xcframework',
    'artifacts/engine/ios-profile/extension_safe/Flutter.xcframework',
    'artifacts/engine/ios-release/Flutter.xcframework',
    'artifacts/engine/ios-release/extension_safe/Flutter.xcframework',
    'artifacts/engine/ios/Flutter.xcframework',
    'artifacts/engine/ios/extension_safe/Flutter.xcframework',
    'artifacts/engine/darwin-x64-profile/FlutterMacOS.xcframework',
    'artifacts/engine/darwin-x64-release/FlutterMacOS.xcframework',
    'artifacts/engine/darwin-x64/FlutterMacOS.xcframework',
  ]
  .map((String relativePath) => path.join(flutterRoot, 'bin', 'cache', relativePath)).toList();
}

/// Verify the existence of all expected binaries in cache.
///
/// This function ignores code signatures and entitlements, and is intended to
/// be run on every commit. It should throw if either new binaries are added
/// to the cache or expected binaries removed. In either case, this class'
/// [binariesWithEntitlements] or [binariesWithoutEntitlements] lists should
/// be updated accordingly.
Future<void> verifyExist(
  String flutterRoot,
  {@visibleForTesting ProcessManager processManager = const LocalProcessManager()
}) async {
  final Set<String> foundFiles = <String>{};
  final String cacheDirectory =  path.join(flutterRoot, 'bin', 'cache');

  for (final String binaryPath
      in await findBinaryPaths(cacheDirectory, processManager: processManager)) {
    if (binariesWithEntitlements(flutterRoot).contains(binaryPath)) {
      foundFiles.add(binaryPath);
    } else if (binariesWithoutEntitlements(flutterRoot).contains(binaryPath)) {
      foundFiles.add(binaryPath);
    } else {
      throw Exception(
          'Found unexpected binary in cache: $binaryPath');
    }
  }

  final List<String> allExpectedFiles = binariesWithEntitlements(flutterRoot) + binariesWithoutEntitlements(flutterRoot);
  if (foundFiles.length < allExpectedFiles.length) {
    final List<String> unfoundFiles = allExpectedFiles
        .where(
          (String file) => !foundFiles.contains(file),
        )
        .toList();
    print(
      'Expected binaries not found in cache:\n\n${unfoundFiles.join('\n')}\n\n'
      'If this commit is removing binaries from the cache, this test should be fixed by\n'
      'removing the relevant entry from either the "binariesWithEntitlements" or\n'
      '"binariesWithoutEntitlements" getters in dev/tools/lib/codesign.dart.',
    );
    throw Exception('Did not find all expected binaries!');
  }

  print('All expected binaries present.');
}

/// Verify code signatures and entitlements of all binaries in the cache.
Future<void> verifySignatures(
  String flutterRoot,
  {@visibleForTesting ProcessManager processManager = const LocalProcessManager()}
) async {
  final List<String> unsignedFiles = <String>[];
  final List<String> wrongEntitlementBinaries = <String>[];
  final List<String> unexpectedFiles = <String>[];
  final String cacheDirectory =  path.join(flutterRoot, 'bin', 'cache');

  final List<String> binariesAndXcframeworks =
      (await findBinaryPaths(cacheDirectory, processManager: processManager)) + (await findXcframeworksPaths(cacheDirectory, processManager: processManager));

  for (final String pathToCheck in binariesAndXcframeworks) {
    bool verifySignature = false;
    bool verifyEntitlements = false;
    if (binariesWithEntitlements(flutterRoot).contains(pathToCheck)) {
      verifySignature = true;
      verifyEntitlements = true;
    }
    if (binariesWithoutEntitlements(flutterRoot).contains(pathToCheck)) {
      verifySignature = true;
    }
    if (signedXcframeworks(flutterRoot).contains(pathToCheck)) {
      verifySignature = true;
    }
    if (!verifySignature && !verifyEntitlements) {
      unexpectedFiles.add(pathToCheck);
      print('Unexpected binary or xcframework $pathToCheck found in cache!');
      continue;
    }
    print('Verifying the code signature of $pathToCheck');
    final io.ProcessResult codeSignResult = await processManager.run(
      <String>[
        'codesign',
        '-vvv',
        pathToCheck,
      ],
    );
    if (codeSignResult.exitCode != 0) {
      unsignedFiles.add(pathToCheck);
      print(
        'File "$pathToCheck" does not appear to be codesigned.\n'
        'The `codesign` command failed with exit code ${codeSignResult.exitCode}:\n'
        '${codeSignResult.stderr}\n',
      );
      continue;
    }
    if (verifyEntitlements) {
      print('Verifying entitlements of $pathToCheck');
      if (!(await hasExpectedEntitlements(pathToCheck, flutterRoot, processManager: processManager))) {
        wrongEntitlementBinaries.add(pathToCheck);
      }
    }
  }

  // First print all deviations from expectations
  if (unsignedFiles.isNotEmpty) {
    print('Found ${unsignedFiles.length} unsigned files:');
    unsignedFiles.forEach(print);
  }

  if (wrongEntitlementBinaries.isNotEmpty) {
    print('Found ${wrongEntitlementBinaries.length} files with unexpected entitlements:');
    wrongEntitlementBinaries.forEach(print);
  }

  if (unexpectedFiles.isNotEmpty) {
    print('Found ${unexpectedFiles.length} unexpected files in the cache:');
    unexpectedFiles.forEach(print);
  }

  // Finally, exit on any invalid state
  if (unsignedFiles.isNotEmpty) {
    throw Exception('Test failed because unsigned files detected.');
  }

  if (wrongEntitlementBinaries.isNotEmpty) {
    throw Exception(
      'Test failed because files found with the wrong entitlements:\n'
      '${wrongEntitlementBinaries.join('\n')}',
    );
  }

  if (unexpectedFiles.isNotEmpty) {
    throw Exception('Test failed because unexpected files found in the cache.');
  }
  print('Verified that files are codesigned and have expected entitlements.');
}

/// Find every binary file in the given [rootDirectory].
Future<List<String>> findBinaryPaths(
  String rootDirectory,
  {@visibleForTesting ProcessManager processManager = const LocalProcessManager()
}) async {
  final List<String> allBinaryPaths = <String>[];
  final io.ProcessResult result = await processManager.run(
    <String>[
      'find',
      rootDirectory,
      '-type',
      'f',
    ],
  );
  final List<String> allFiles = (result.stdout as String)
      .split('\n')
      .where((String s) => s.isNotEmpty)
      .toList();

  await Future.forEach(allFiles, (String filePath) async {
    if (await isBinary(filePath, processManager: processManager)) {
      allBinaryPaths.add(filePath);
      print('Found: $filePath\n');
    }
  });
  return allBinaryPaths;
}

/// Find every xcframework in the given [rootDirectory].
Future<List<String>> findXcframeworksPaths(
    String rootDirectory,
    {@visibleForTesting ProcessManager processManager = const LocalProcessManager()
    }) async {
  final io.ProcessResult result = await processManager.run(
    <String>[
      'find',
      rootDirectory,
      '-type',
      'd',
      '-name',
      '*xcframework',
    ],
  );
  final List<String> allXcframeworkPaths = LineSplitter.split(result.stdout as String)
      .where((String s) => s.isNotEmpty)
      .toList();
  for (final String path in allXcframeworkPaths) {
    print('Found: $path\n');
  }
  return allXcframeworkPaths;
}

/// Check mime-type of file at [filePath] to determine if it is binary.
Future<bool> isBinary(
  String filePath,
  {@visibleForTesting ProcessManager processManager = const LocalProcessManager()}
) async {
  final io.ProcessResult result = await processManager.run(
    <String>[
      'file',
      '--mime-type',
      '-b', // is binary
      filePath,
    ],
  );
  return (result.stdout as String).contains('application/x-mach-binary');
}

/// Check if the binary has the expected entitlements.
Future<bool> hasExpectedEntitlements(
  String binaryPath,
  String flutterRoot,
  {@visibleForTesting ProcessManager processManager = const LocalProcessManager()}
) async {
  final io.ProcessResult entitlementResult = await processManager.run(
    <String>[
      'codesign',
      '--display',
      '--entitlements',
      ':-',
      binaryPath,
    ],
  );

  if (entitlementResult.exitCode != 0) {
    print(
      'The `codesign --entitlements` command failed with exit code ${entitlementResult.exitCode}:\n'
      '${entitlementResult.stderr}\n',
    );
    return false;
  }

  bool passes = true;
  final String output = entitlementResult.stdout as String;
  for (final String entitlement in expectedEntitlements) {
    final bool entitlementExpected =
        binariesWithEntitlements(flutterRoot).contains(binaryPath);
    if (output.contains(entitlement) != entitlementExpected) {
      print(
        'File "$binaryPath" ${entitlementExpected ? 'does not have expected' : 'has unexpected'} '
        'entitlement $entitlement.',
      );
      passes = false;
    }
  }
  return passes;
}

/// Runs the skp_generator from the flutter/tests repo.
///
/// See also the customer_tests shard.
///
/// Generated SKPs are ditched, this just verifies that it can run without failure.
Future<void> _runSkpGeneratorTests() async {
  printProgress('${green}Running skp_generator from flutter/tests$reset');
  final Directory checkout = Directory.systemTemp.createTempSync('flutter_skp_generator.');
  await runCommand(
    'git',
    <String>[
      '-c',
      'core.longPaths=true',
      'clone',
      'https://github.com/flutter/tests.git',
      '.',
    ],
    workingDirectory: checkout.path,
  );
  await runCommand(
    './build.sh',
    <String>[ ],
    workingDirectory: path.join(checkout.path, 'skp_generator'),
  );
}

Future<void> _runRealmCheckerTest() async {
  final String engineRealm = File(engineRealmFile).readAsStringSync().trim();
  if (engineRealm.isNotEmpty) {
    foundError(<String>['The checked-in engine.realm file must be empty.']);
  }
}

// The `chromedriver` process created by this test.
//
// If an existing chromedriver is already available on port 4444, the existing
// process is reused and this variable remains null.
Command? _chromeDriver;

Future<bool> _isChromeDriverRunning() async {
  try {
    final RawSocket socket = await RawSocket.connect('localhost', 4444);
    socket.shutdown(SocketDirection.both);
    await socket.close();
    return true;
  } on SocketException {
    return false;
  }
}

Future<void> _ensureChromeDriverIsRunning() async {
  // If we cannot connect to ChromeDriver, assume it is not running. Launch it.
  if (!await _isChromeDriverRunning()) {
    printProgress('Starting chromedriver');
    // Assume chromedriver is in the PATH.
    _chromeDriver = await startCommand(
      // TODO(ianh): this is the only remaining consumer of startCommand other than runCommand
      // and it doesn't use most of startCommand's features; we could simplify this a lot by
      // inlining the relevant parts of startCommand here.
      'chromedriver',
      <String>['--port=4444'],
    );
    while (!await _isChromeDriverRunning()) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      print('Waiting for chromedriver to start up.');
    }
  }

  final HttpClient client = HttpClient();
  final Uri chromeDriverUrl = Uri.parse('http://localhost:4444/status');
  final HttpClientRequest request = await client.getUrl(chromeDriverUrl);
  final HttpClientResponse response = await request.close();
  final Map<String, dynamic> webDriverStatus = json.decode(await response.transform(utf8.decoder).join()) as Map<String, dynamic>;
  client.close();
  final bool webDriverReady = (webDriverStatus['value'] as Map<String, dynamic>)['ready'] as bool;
  if (!webDriverReady) {
    throw Exception('WebDriver not available.');
  }
}

Future<void> _stopChromeDriver() async {
  if (_chromeDriver == null) {
    return;
  }
  print('Stopping chromedriver');
  _chromeDriver!.process.kill();
}

/// Exercises the old gallery in a browser for a long period of time, looking
/// for memory leaks and dangling pointers.
///
/// This is not a performance test.
///
/// If [canvasKit] is set to true, runs the test in CanvasKit mode.
///
/// The test is written using `package:integration_test` (despite the "e2e" in
/// the name, which is there for historic reasons).
Future<void> _runGalleryE2eWebTest(String buildMode, { bool canvasKit = false }) async {
  printProgress('${green}Running flutter_gallery integration test in --$buildMode using ${canvasKit ? 'CanvasKit' : 'HTML'} renderer.$reset');
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'flutter_gallery');
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  await runCommand(
    flutter,
    <String>[
      ...flutterTestArgs,
      'drive',
      if (canvasKit)
        '--dart-define=FLUTTER_WEB_USE_SKIA=true',
      if (!canvasKit)
        '--dart-define=FLUTTER_WEB_USE_SKIA=false',
      if (!canvasKit)
        '--dart-define=FLUTTER_WEB_AUTO_DETECT=false',
      '--driver=test_driver/transitions_perf_e2e_test.dart',
      '--target=test_driver/transitions_perf_e2e.dart',
      '--browser-name=chrome',
      '-d',
      'web-server',
      '--$buildMode',
    ],
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );
}

Future<void> _runWebStackTraceTest(String buildMode, String entrypoint) async {
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'web');
  final String appBuildDirectory = path.join(testAppDirectory, 'build', 'web');

  // Build the app.
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  await runCommand(
    flutter,
    <String>[
      'build',
      'web',
      '--$buildMode',
      '-t',
      entrypoint,
    ],
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );

  // Run the app.
  final int serverPort = await findAvailablePortAndPossiblyCauseFlakyTests();
  final int browserDebugPort = await findAvailablePortAndPossiblyCauseFlakyTests();
  final String result = await evalTestAppInChrome(
    appUrl: 'http://localhost:$serverPort/index.html',
    appDirectory: appBuildDirectory,
    serverPort: serverPort,
    browserDebugPort: browserDebugPort,
  );

  if (!result.contains('--- TEST SUCCEEDED ---')) {
    foundError(<String>[
      result,
      '${red}Web stack trace integration test failed.$reset',
    ]);
  }
}

/// Run a web integration test in release mode.
Future<void> _runWebReleaseTest(String target, {
  List<String> additionalArguments = const<String>[],
}) async {
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'web');
  final String appBuildDirectory = path.join(testAppDirectory, 'build', 'web');

  // Build the app.
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  await runCommand(
    flutter,
    <String>[
      ...flutterTestArgs,
      'build',
      'web',
      '--release',
      ...additionalArguments,
      '-t',
      target,
    ],
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );

  // Run the app.
  final int serverPort = await findAvailablePortAndPossiblyCauseFlakyTests();
  final int browserDebugPort = await findAvailablePortAndPossiblyCauseFlakyTests();
  final String result = await evalTestAppInChrome(
    appUrl: 'http://localhost:$serverPort/index.html',
    appDirectory: appBuildDirectory,
    serverPort: serverPort,
    browserDebugPort: browserDebugPort,
  );

  if (!result.contains('--- TEST SUCCEEDED ---')) {
    foundError(<String>[
      result,
      '${red}Web release mode test failed.$reset',
    ]);
  }
}

/// Debug mode is special because `flutter build web` doesn't build in debug mode.
///
/// Instead, we use `flutter run --debug` and sniff out the standard output.
Future<void> _runWebDebugTest(String target, {
  List<String> additionalArguments = const<String>[],
}) async {
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'web');
  bool success = false;
  final Map<String, String> environment = <String, String>{
    'FLUTTER_WEB': 'true',
  };
  adjustEnvironmentToEnableFlutterAsserts(environment);
  final CommandResult result = await runCommand(
    flutter,
    <String>[
      'run',
      '--debug',
      '-d',
      'chrome',
      '--web-run-headless',
      '--dart-define=FLUTTER_WEB_USE_SKIA=false',
      '--dart-define=FLUTTER_WEB_AUTO_DETECT=false',
      ...additionalArguments,
      '-t',
      target,
    ],
    outputMode: OutputMode.capture,
    outputListener: (String line, Process process) {
      if (line.contains('--- TEST SUCCEEDED ---')) {
        success = true;
      }
      if (success || line.contains('--- TEST FAILED ---')) {
        process.stdin.add('q'.codeUnits);
      }
    },
    workingDirectory: testAppDirectory,
    environment: environment,
  );

  if (!success) {
    foundError(<String>[
      result.flattenedStdout!,
      result.flattenedStderr!,
      '${red}Web stack trace integration test failed.$reset',
    ]);
  }
}

Future<void> _runFlutterWebTest(String webRenderer, String workingDirectory, List<String> tests) async {
  await runCommand(
    flutter,
    <String>[
      'test',
      '-v',
      '--platform=chrome',
      '--web-renderer=$webRenderer',
      '--dart-define=DART_HHH_BOT=$_runningInDartHHHBot',
      ...flutterTestArgs,
      ...tests,
    ],
    workingDirectory: workingDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );
}

// TODO(sigmund): includeLocalEngineEnv should default to true. Currently we
// only enable it on flutter-web test because some test suites do not work
// properly when overriding the local engine (for example, because some platform
// dependent targets are only built on some engines).
// See https://github.com/flutter/flutter/issues/72368
Future<void> _runDartTest(String workingDirectory, {
  List<String>? testPaths,
  bool enableFlutterToolAsserts = true,
  bool useBuildRunner = false,
  String? coverage,
  bool forceSingleCore = false,
  Duration? perTestTimeout,
  bool includeLocalEngineEnv = false,
  bool ensurePrecompiledTool = true,
  bool shuffleTests = true,
  bool collectMetrics = false,
}) async {
  int? cpus;
  final String? cpuVariable = Platform.environment['CPU']; // CPU is set in cirrus.yml
  if (cpuVariable != null) {
    cpus = int.tryParse(cpuVariable, radix: 10);
    if (cpus == null) {
      foundError(<String>[
        '${red}The CPU environment variable, if set, must be set to the integer number of available cores.$reset',
        'Actual value: "$cpuVariable"',
      ]);
      return;
    }
  } else {
    cpus = 2; // Don't default to 1, otherwise we won't catch race conditions.
  }
  // Integration tests that depend on external processes like chrome
  // can get stuck if there are multiple instances running at once.
  if (forceSingleCore) {
    cpus = 1;
  }

  const LocalFileSystem fileSystem = LocalFileSystem();
  final File metricFile = fileSystem.file(path.join(flutterRoot, 'metrics.json'));
  final List<String> args = <String>[
    'run',
    'test',
    '--file-reporter=json:${metricFile.path}',
    if (shuffleTests) '--test-randomize-ordering-seed=$shuffleSeed',
    '-j$cpus',
    if (!hasColor)
      '--no-color',
    if (coverage != null)
      '--coverage=$coverage',
    if (perTestTimeout != null)
      '--timeout=${perTestTimeout.inMilliseconds}ms',
    if (testPaths != null)
      for (final String testPath in testPaths)
        testPath,
  ];
  final Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': flutterRoot,
    if (includeLocalEngineEnv)
      ...localEngineEnv,
    if (Directory(pubCache).existsSync())
      'PUB_CACHE': pubCache,
  };
  if (enableFlutterToolAsserts) {
    adjustEnvironmentToEnableFlutterAsserts(environment);
  }
  if (ensurePrecompiledTool) {
    // We rerun the `flutter` tool here just to make sure that it is compiled
    // before tests run, because the tests might time out if they have to rebuild
    // the tool themselves.
    await runCommand(flutter, <String>['--version'], environment: environment);
  }
  await runCommand(
    dart,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
    removeLine: useBuildRunner ? (String line) => line.startsWith('[INFO]') : null,
  );

  final TestFileReporterResults test = TestFileReporterResults.fromFile(metricFile); // --file-reporter name
  final File info = fileSystem.file(path.join(flutterRoot, 'error.log'));
  info.writeAsStringSync(json.encode(test.errors));

  if (collectMetrics) {
    try {
      final List<String> testList = <String>[];
      final Map<int, TestSpecs> allTestSpecs = test.allTestSpecs;
      for (final TestSpecs testSpecs in allTestSpecs.values) {
        testList.add(testSpecs.toJson());
      }
      if (testList.isNotEmpty) {
        final String testJson = json.encode(testList);
        final File testResults = fileSystem.file(
            path.join(flutterRoot, 'test_results.json'));
        testResults.writeAsStringSync(testJson);
      }
    } on fs.FileSystemException catch (e) {
      print('Failed to generate metrics: $e');
    }
  }
}

Future<void> _runFlutterTest(String workingDirectory, {
  String? script,
  bool expectFailure = false,
  bool printOutput = true,
  OutputChecker? outputChecker,
  List<String> options = const <String>[],
  Map<String, String>? environment,
  List<String> tests = const <String>[],
  bool shuffleTests = true,
  bool fatalWarnings = true,
}) async {
  assert(!printOutput || outputChecker == null, 'Output either can be printed or checked but not both');

  final List<String> tags = <String>[];
  // Recipe-configured reduced test shards will only execute tests with the
  // appropriate tag.
  if (Platform.environment['REDUCED_TEST_SET'] == 'True') {
    tags.addAll(<String>['-t', 'reduced-test-set']);
  }

  final List<String> args = <String>[
    'test',
    if (shuffleTests) '--test-randomize-ordering-seed=$shuffleSeed',
    if (fatalWarnings) '--fatal-warnings',
    ...options,
    ...tags,
    ...flutterTestArgs,
  ];

  if (script != null) {
    final String fullScriptPath = path.join(workingDirectory, script);
    if (!FileSystemEntity.isFileSync(fullScriptPath)) {
      foundError(<String>[
        '${red}Could not find test$reset: $green$fullScriptPath$reset',
        'Working directory: $cyan$workingDirectory$reset',
        'Script: $green$script$reset',
        if (!printOutput)
          'This is one of the tests that does not normally print output.',
      ]);
      return;
    }
    args.add(script);
  }

  args.addAll(tests);

  final OutputMode outputMode = outputChecker == null && printOutput
    ? OutputMode.print
    : OutputMode.capture;

  final CommandResult result = await runCommand(
    flutter,
    args,
    workingDirectory: workingDirectory,
    expectNonZeroExit: expectFailure,
    outputMode: outputMode,
    environment: environment,
  );

  if (outputChecker != null) {
    final String? message = outputChecker(result);
    if (message != null) {
      foundError(<String>[message]);
    }
  }
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

/// Parse (one-)index/total-named subshards from environment variable SUBSHARD
/// and equally distribute [tests] between them.
/// Subshard format is "{index}_{total number of shards}".
/// The scheduler can change the number of total shards without needing an additional
/// commit in this repository.
///
/// Examples:
/// 1_3
/// 2_3
/// 3_3
List<T> _selectIndexOfTotalSubshard<T>(List<T> tests, {String subshardKey = kSubshardKey}) {
  // Example: "1_3" means the first (one-indexed) shard of three total shards.
  final String? subshardName = Platform.environment[subshardKey];
  if (subshardName == null) {
    print('$kSubshardKey environment variable is missing, skipping sharding');
    return tests;
  }
  printProgress('$bold$subshardKey=$subshardName$reset');

  final RegExp pattern = RegExp(r'^(\d+)_(\d+)$');
  final Match? match = pattern.firstMatch(subshardName);
  if (match == null || match.groupCount != 2) {
    foundError(<String>[
      '${red}Invalid subshard name "$subshardName". Expected format "[int]_[int]" ex. "1_3"',
    ]);
    throw Exception('Invalid subshard name: $subshardName');
  }
  // One-indexed.
  final int index = int.parse(match.group(1)!);
  final int total = int.parse(match.group(2)!);
  if (index > total) {
    foundError(<String>[
      '${red}Invalid subshard name "$subshardName". Index number must be greater or equal to total.',
    ]);
    return <T>[];
  }

  final int testsPerShard = (tests.length / total).ceil();
  final int start = (index - 1) * testsPerShard;
  final int end = math.min(index * testsPerShard, tests.length);

  print('Selecting subshard $index of $total (tests ${start + 1}-$end of ${tests.length})');
  return tests.sublist(start, end);
}

Future<void> _runShardRunnerIndexOfTotalSubshard(List<ShardRunner> tests) async {
  final List<ShardRunner> sublist = _selectIndexOfTotalSubshard<ShardRunner>(tests);
  for (final ShardRunner test in sublist) {
    await test();
  }
}

Future<void> selectShard(Map<String, ShardRunner> shards) => _runFromList(shards, kShardKey, 'shard', 0);
Future<void> selectSubshard(Map<String, ShardRunner> subshards) => _runFromList(subshards, kSubshardKey, 'subshard', 1);

const String CIRRUS_TASK_NAME = 'CIRRUS_TASK_NAME';

Future<void> _runFromList(Map<String, ShardRunner> items, String key, String name, int positionInTaskName) async {
  String? item = Platform.environment[key];
  if (item == null && Platform.environment.containsKey(CIRRUS_TASK_NAME)) {
    final List<String> parts = Platform.environment[CIRRUS_TASK_NAME]!.split('-');
    assert(positionInTaskName < parts.length);
    item = parts[positionInTaskName];
  }
  if (item == null) {
    for (final String currentItem in items.keys) {
      printProgress('$bold$key=$currentItem$reset');
      await items[currentItem]!();
    }
  } else {
    printProgress('$bold$key=$item$reset');
    if (!items.containsKey(item)) {
      foundError(<String>[
        '${red}Invalid $name: $item$reset',
        'The available ${name}s are: ${items.keys.join(", ")}',
      ]);
      return;
    }
    await items[item]!();
  }
}
