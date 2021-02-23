// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file/file.dart' as fs;
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'browser.dart';
import 'flutter_compact_formatter.dart';
import 'run_command.dart';
import 'service_worker_test.dart';
import 'utils.dart';

typedef ShardRunner = Future<void> Function();

/// A function used to validate the output of a test.
///
/// If the output matches expectations, the function shall return null.
///
/// If the output does not match expectations, the function shall return an
/// appropriate error message.
typedef OutputChecker = String Function(CommandResult);

final String exe = Platform.isWindows ? '.exe' : '';
final String bat = Platform.isWindows ? '.bat' : '';
final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', 'flutter$bat');
final String dart = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dart$exe');
final String pub = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'pub$bat');
final String pubCache = path.join(flutterRoot, '.pub-cache');
final String toolRoot = path.join(flutterRoot, 'packages', 'flutter_tools');
final String engineVersionFile = path.join(flutterRoot, 'bin', 'internal', 'engine.version');
final String flutterPluginsVersionFile = path.join(flutterRoot, 'bin', 'internal', 'flutter_plugins.version');

String get platformFolderName {
  if (Platform.isWindows)
    return 'windows-x64';
  if (Platform.isMacOS)
    return 'darwin-x64';
  if (Platform.isLinux)
    return 'linux-x64';
  throw UnsupportedError('The platform ${Platform.operatingSystem} is not supported by this script.');
}
final String flutterTester = path.join(flutterRoot, 'bin', 'cache', 'artifacts', 'engine', platformFolderName, 'flutter_tester$exe');

/// The arguments to pass to `flutter test` (typically the local engine
/// configuration) -- prefilled with the arguments passed to test.dart.
final List<String> flutterTestArgs = <String>[];

final bool useFlutterTestFormatter = Platform.environment['FLUTTER_TEST_FORMATTER'] == 'true';

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
  ? int.parse(Platform.environment['WEB_SHARD_COUNT'])
  : 8;
/// Tests that we don't run on Web for compilation reasons.
//
// TODO(yjbanov): we're getting rid of this as part of https://github.com/flutter/flutter/projects/60
const List<String> kWebTestFileKnownFailures = <String>[
  'test/services/message_codecs_vm_test.dart',
  'test/examples/sector_layout_test.dart',
];

const String kSmokeTestShardName = 'smoke_tests';

/// When you call this, you can pass additional arguments to pass custom
/// arguments to flutter test. For example, you might want to call this
/// script with the parameter --local-engine=host_debug_unopt to
/// use your own build of the engine.
///
/// To run the tool_tests part, run it with SHARD=tool_tests
///
/// Examples:
/// SHARD=tool_tests bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// bin/cache/dart-sdk/bin/dart dev/bots/test.dart --local-engine=host_debug_unopt
Future<void> main(List<String> args) async {
  print('$clock STARTING ANALYSIS');
  try {
    flutterTestArgs.addAll(args);
    if (Platform.environment.containsKey(CIRRUS_TASK_NAME))
      print('Running task: ${Platform.environment[CIRRUS_TASK_NAME]}');
    print('═' * 80);
    await _runSmokeTests();
    print('═' * 80);
    await selectShard(<String, ShardRunner>{
      'add_to_app_life_cycle_tests': _runAddToAppLifeCycleTests,
      'build_tests': _runBuildTests,
      'framework_coverage': _runFrameworkCoverage,
      'framework_tests': _runFrameworkTests,
      'tool_tests': _runToolTests,
      'tool_integration_tests': _runIntegrationToolTests,
      'web_tool_tests': _runWebToolTests,
      'web_tests': _runWebUnitTests,
      'web_integration_tests': _runWebIntegrationTests,
      'web_long_running_tests': _runWebLongRunningTests,
      'flutter_plugins': _runFlutterPluginsTests,
      kSmokeTestShardName: () async {}, // No-op, the smoke tests already ran. Used for testing this script.
    });
  } on ExitException catch (error) {
    error.apply();
  }
  print('$clock ${bold}Test successful.$reset');
}

/// Verify the Flutter Engine is the revision in
/// bin/cache/internal/engine.version.
Future<void> _validateEngineHash() async {
  final String luciBotId = Platform.environment['SWARMING_BOT_ID'] ?? '';
  if (luciBotId.startsWith('luci-dart-')) {
    // The Dart HHH bots intentionally modify the local artifact cache
    // and then use this script to run Flutter's test suites.
    // Because the artifacts have been changed, this particular test will return
    // a false positive and should be skipped.
    print('${yellow}Skipping Flutter Engine Version Validation for swarming '
          'bot $luciBotId.');
    return;
  }
  final String expectedVersion = File(engineVersionFile).readAsStringSync().trim();
  final CommandResult result = await runCommand(flutterTester, <String>['--help'], outputMode: OutputMode.capture);
  final String actualVersion = result.flattenedStderr.split('\n').firstWhere((final String line) {
    return line.startsWith('Flutter Engine Version:');
  });
  if (!actualVersion.contains(expectedVersion)) {
    print('${red}Expected "Flutter Engine Version: $expectedVersion", '
          'but found "$actualVersion".');
    exit(1);
  }
}

Future<void> _runSmokeTests() async {
  print('${green}Running smoketests...$reset');

  await _validateEngineHash();

  // Verify that the tests actually return failure on failure and success on
  // success.
  final String automatedTests = path.join(flutterRoot, 'dev', 'automated_tests');
  // We run the "pass" and "fail" smoke tests first, and alone, because those
  // are particularly critical and sensitive. If one of these fails, there's no
  // point even trying the others.
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
    // We run the timeout tests individually because they are timing-sensitive.
    () => _runFlutterTest(
          automatedTests,
          script: path.join('test_smoke_test', 'timeout_pass_test.dart'),
          expectFailure: false,
          printOutput: false,
        ),
    () => _runFlutterTest(
          automatedTests,
          script: path.join('test_smoke_test', 'timeout_fail_test.dart'),
          expectFailure: true,
          printOutput: false,
        ),
    () => _runFlutterTest(automatedTests,
            script:
                path.join('test_smoke_test', 'pending_timer_fail_test.dart'),
            expectFailure: true,
            printOutput: false, outputChecker: (CommandResult result) {
          return result.flattenedStdout.contains('failingPendingTimerTest')
              ? null
              : 'Failed to find the stack trace for the pending Timer.';
        }),
    // We run the remaining smoketests in parallel, because they each take some
    // time to run (e.g. compiling), so we don't want to run them in series,
    // especially on 20-core machines...
    () => Future.wait<void>(
          <Future<void>>[
            _runFlutterTest(
              automatedTests,
              script: path.join('test_smoke_test', 'crash1_test.dart'),
              expectFailure: true,
              printOutput: false,
            ),
            _runFlutterTest(
              automatedTests,
              script: path.join('test_smoke_test', 'crash2_test.dart'),
              expectFailure: true,
              printOutput: false,
            ),
            _runFlutterTest(
              automatedTests,
              script:
                  path.join('test_smoke_test', 'syntax_error_test.broken_dart'),
              expectFailure: true,
              printOutput: false,
            ),
            _runFlutterTest(
              automatedTests,
              script: path.join(
                  'test_smoke_test', 'missing_import_test.broken_dart'),
              expectFailure: true,
              printOutput: false,
            ),
            _runFlutterTest(
              automatedTests,
              script: path.join('test_smoke_test',
                  'disallow_error_reporter_modification_test.dart'),
              expectFailure: true,
              printOutput: false,
            ),
          ],
        ),
  ];

  List<ShardRunner> testsToRun;

  // Smoke tests are special and run first for all test shards.
  // Run all smoke tests for other shards.
  // Only shard smoke tests when explicitly specified.
  final String shardName = Platform.environment[kShardKey];
  if (shardName == kSmokeTestShardName) {
    testsToRun = _selectIndexOfTotalSubshard<ShardRunner>(tests);
  } else {
    testsToRun = tests;
  }
  for (final ShardRunner test in testsToRun) {
    await test();
  }

  // Verify that we correctly generated the version file.
  final String versionError = await verifyVersion(File(path.join(flutterRoot, 'version')));
  if (versionError != null)
    exitWithError(<String>[versionError]);
}

Future<void> _runGeneralToolTests() async {
  await _pubRunTest(
    path.join(flutterRoot, 'packages', 'flutter_tools'),
    testPaths: <String>[path.join('test', 'general.shard')],
    enableFlutterToolAsserts: false,
    // Detect unit test time regressions (poor time delay handling, etc).
    perTestTimeout: const Duration(seconds: 2),
  );
}

Future<void> _runCommandsToolTests() async {
  // Due to https://github.com/flutter/flutter/issues/46180, skip the hermetic directory
  // on Windows.
  final String suffix = Platform.isWindows ? 'permeable' : '';
  await _pubRunTest(
    path.join(flutterRoot, 'packages', 'flutter_tools'),
    forceSingleCore: true,
    testPaths: <String>[path.join('test', 'commands.shard', suffix)],
  );
}

Future<void> _runIntegrationToolTests() async {
  final String toolsPath = path.join(flutterRoot, 'packages', 'flutter_tools');
  final List<String> allTests = Directory(path.join(toolsPath, 'test', 'integration.shard'))
      .listSync(recursive: true).whereType<File>()
      .map<String>((FileSystemEntity entry) => path.relative(entry.path, from: toolsPath))
      .where((String testPath) => path.basename(testPath).endsWith('_test.dart')).toList();

  await _pubRunTest(
    toolsPath,
    forceSingleCore: true,
    testPaths: _selectIndexOfTotalSubshard<String>(allTests),
  );
}

Future<void> _runToolTests() async {
  await selectSubshard(<String, ShardRunner>{
    'general': _runGeneralToolTests,
    'commands': _runCommandsToolTests,
  });
}

Future<void> _runWebToolTests() async {
  const String kDotShard = '.shard';
  const String kWeb = 'web';
  const String kTest = 'test';
  final String toolsPath = path.join(flutterRoot, 'packages', 'flutter_tools');

  final Map<String, ShardRunner> subshards = <String, ShardRunner>{
      kWeb:
      () async {
        await _pubRunTest(
          toolsPath,
          forceSingleCore: true,
          testPaths: <String>[path.join(kTest, '$kWeb$kDotShard', '')],
          enableFlutterToolAsserts: true,
        );
      }
  };

  await selectSubshard(subshards);
}

/// Verifies that APK, and IPA (if on macOS) builds the examples apps
/// without crashing. It does not actually launch the apps. That happens later
/// in the devicelab. This is just a smoke-test. In particular, this will verify
/// we can build when there are spaces in the path name for the Flutter SDK and
/// target app.
Future<void> _runBuildTests() async {
  final List<FileSystemEntity> exampleDirectories = Directory(path.join(flutterRoot, 'examples')).listSync()
    ..add(Directory(path.join(flutterRoot, 'packages', 'integration_test', 'example')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'android_semantics_testing')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'android_views')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'channels')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'hybrid_android_views')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'flutter_gallery')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'ios_platform_view_tests')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'non_nullable')))
    ..add(Directory(path.join(flutterRoot, 'dev', 'integration_tests', 'ui')));

  // The tests are randomly distributed into subshards so as to get a uniform
  // distribution of costs, but the seed is fixed so that issues are reproducible.
  final List<ShardRunner> tests = <ShardRunner>[
    for (final FileSystemEntity exampleDirectory in exampleDirectories)
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
  ]..shuffle(math.Random(0));

  await _runShardRunnerIndexOfTotalSubshard(tests);
}

Future<void> _runExampleProjectBuildTests(FileSystemEntity exampleDirectory) async {
  // Only verify caching with flutter gallery.
  final bool verifyCaching = exampleDirectory.path.contains('flutter_gallery');
  if (exampleDirectory is! Directory) {
    return;
  }
  final String examplePath = exampleDirectory.path;
  final bool hasNullSafety = File(path.join(examplePath, 'null_safety')).existsSync();
  final List<String> additionalArgs = hasNullSafety
    ? <String>['--no-sound-null-safety']
    : <String>[];
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
  @required bool release,
  bool verifyCaching = false,
  List<String> additionalArgs = const <String>[],
}) async {
  print('${green}Testing APK build$reset for $cyan$relativePathToApplication$reset...');
  await _flutterBuild(relativePathToApplication, 'APK', 'apk',
    release: release,
    verifyCaching: verifyCaching,
    additionalArgs: additionalArgs
  );
}

Future<void> _flutterBuildIpa(String relativePathToApplication, {
  @required bool release,
  List<String> additionalArgs = const <String>[],
  bool verifyCaching = false,
}) async {
  assert(Platform.isMacOS);
  print('${green}Testing IPA build$reset for $cyan$relativePathToApplication$reset...');
  await _flutterBuild(relativePathToApplication, 'IPA', 'ios',
    release: release,
    verifyCaching: verifyCaching,
    additionalArgs: <String>[...additionalArgs, '--no-codesign'],
  );
}

Future<void> _flutterBuildLinux(String relativePathToApplication, {
  @required bool release,
  bool verifyCaching = false,
  List<String> additionalArgs = const <String>[],
}) async {
  assert(Platform.isLinux);
  await runCommand(flutter, <String>['config', '--enable-linux-desktop']);
  print('${green}Testing Linux build$reset for $cyan$relativePathToApplication$reset...');
  await _flutterBuild(relativePathToApplication, 'Linux', 'linux',
    release: release,
    verifyCaching: verifyCaching,
    additionalArgs: additionalArgs
  );
}

Future<void> _flutterBuildMacOS(String relativePathToApplication, {
  @required bool release,
  bool verifyCaching = false,
  List<String> additionalArgs = const <String>[],
}) async {
  assert(Platform.isMacOS);
  await runCommand(flutter, <String>['config', '--enable-macos-desktop']);
  print('${green}Testing macOS build$reset for $cyan$relativePathToApplication$reset...');
  await _flutterBuild(relativePathToApplication, 'macOS', 'macos',
    release: release,
    verifyCaching: verifyCaching,
    additionalArgs: additionalArgs
  );
}

Future<void> _flutterBuildWin32(String relativePathToApplication, {
  @required bool release,
  bool verifyCaching = false,
  List<String> additionalArgs = const <String>[],
}) async {
  assert(Platform.isWindows);
  await runCommand(flutter, <String>['config', '--enable-windows-desktop']);
  print('${green}Testing Windows build$reset for $cyan$relativePathToApplication$reset...');
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
  @required bool release,
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
    print('${green}Testing $platformLabel cache$reset for $cyan$relativePathToApplication$reset...');
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
      print('${red}Not all build targets cached after second run.$reset');
      print('The target performance data was: ${file.readAsStringSync()}');
      exit(1);
    }
  }
}

bool _allTargetsCached(File performanceFile) {
  final Map<String, Object> data = json.decode(performanceFile.readAsStringSync())
    as Map<String, Object>;
  final List<Map<String, Object>> targets = (data['targets'] as List<Object>)
    .cast<Map<String, Object>>();
  return targets.every((Map<String, Object> element) => element['skipped'] == true);
}

Future<void> _flutterBuildDart2js(String relativePathToApplication, String target, { bool expectNonZeroExit = false }) async {
  print('${green}Testing Dart2JS build$reset for $cyan$relativePathToApplication$reset...');
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
    print('${green}Running add-to-app life cycle iOS integration tests$reset...');
    final String addToAppDir = path.join(flutterRoot, 'dev', 'integration_tests', 'ios_add2app_life_cycle');
    await runCommand('./build_and_test.sh',
      <String>[],
      workingDirectory: addToAppDir,
    );
  }
}

Future<void> _runFrameworkTests() async {
  final List<String> soundNullSafetyOptions     = <String>['--null-assertions', '--sound-null-safety'];
  final List<String> mixedModeNullSafetyOptions = <String>['--null-assertions', '--no-sound-null-safety'];
  final List<String> trackWidgetCreationAlternatives = <String>['--track-widget-creation', '--no-track-widget-creation'];

  Future<void> runWidgets() async {
    print('${green}Running packages/flutter tests for$reset: ${cyan}test/widgets/$reset');
    for (final String trackWidgetCreationOption in trackWidgetCreationAlternatives) {
      await _runFlutterTest(
        path.join(flutterRoot, 'packages', 'flutter'),
        options: <String>[trackWidgetCreationOption, ...soundNullSafetyOptions],
        tests: <String>[ path.join('test', 'widgets') + path.separator ],
      );
    }
    // Try compiling code outside of the packages/flutter directory with and without --track-widget-creation
    for (final String trackWidgetCreationOption in trackWidgetCreationAlternatives) {
      await _runFlutterTest(
        path.join(flutterRoot, 'dev', 'integration_tests', 'flutter_gallery'),
        options: <String>[trackWidgetCreationOption],
      );
    }
    // Run release mode tests (see packages/flutter/test_release/README.md)
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--dart-define=dart.vm.product=true', ...soundNullSafetyOptions],
      tests: <String>[ 'test_release' + path.separator ],
    );
  }

  Future<void> runLibraries() async {
    final List<String> tests = Directory(path.join(flutterRoot, 'packages', 'flutter', 'test'))
      .listSync(followLinks: false, recursive: false)
      .whereType<Directory>()
      .where((Directory dir) => dir.path.endsWith('widgets') == false)
      .map<String>((Directory dir) => path.join('test', path.basename(dir.path)) + path.separator)
      .toList();
    print('${green}Running packages/flutter tests$reset for: $cyan${tests.join(", ")}$reset');
    for (final String trackWidgetCreationOption in trackWidgetCreationAlternatives) {
      await _runFlutterTest(
        path.join(flutterRoot, 'packages', 'flutter'),
        options: <String>[trackWidgetCreationOption, ...soundNullSafetyOptions],
        tests: tests,
      );
    }
  }

  Future<void> runFixTests() async {
    final List<String> args = <String>[
      'fix',
      '--compare-to-golden',
    ];
    await runCommand(
      dart,
      args,
      workingDirectory: path.join(flutterRoot, 'packages', 'flutter', 'test_fixes'),
    );
  }

  Future<void> runPrivateTests() async {
    final List<String> args = <String>[
      'run',
      '--sound-null-safety',
      'test_private.dart',
    ];
    final Map<String, String> pubEnvironment = <String, String>{
      'FLUTTER_ROOT': flutterRoot,
    };
    if (Directory(pubCache).existsSync()) {
      pubEnvironment['PUB_CACHE'] = pubCache;
    }

    // If an existing env variable exists append to it, but only if
    // it doesn't appear to already include enable-asserts.
    String toolsArgs = Platform.environment['FLUTTER_TOOL_ARGS'] ?? '';
    if (!toolsArgs.contains('--enable-asserts')) {
      toolsArgs += ' --enable-asserts';
    }
    pubEnvironment['FLUTTER_TOOL_ARGS'] = toolsArgs.trim();
    // The flutter_tool will originally have been snapshotted without asserts.
    // We need to force it to be regenerated with them enabled.
    deleteFile(path.join(flutterRoot, 'bin', 'cache', 'flutter_tools.snapshot'));
    deleteFile(path.join(flutterRoot, 'bin', 'cache', 'flutter_tools.stamp'));

    await runCommand(
      pub,
      args,
      workingDirectory: path.join(flutterRoot, 'packages', 'flutter', 'test_private'),
      environment: pubEnvironment,
    );
  }

  Future<void> runMisc() async {
    print('${green}Running package tests$reset for directories other than packages/flutter');
    await _pubRunTest(path.join(flutterRoot, 'dev', 'bots'));
    await _pubRunTest(path.join(flutterRoot, 'dev', 'devicelab'));
    await _pubRunTest(path.join(flutterRoot, 'dev', 'snippets'));
    await _pubRunTest(path.join(flutterRoot, 'dev', 'tools'), forceSingleCore: true);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'android_semantics_testing'));
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'manual_tests'));
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'vitool'));
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'hello_world'), options: soundNullSafetyOptions);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'layers'), options: soundNullSafetyOptions);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'benchmarks', 'test_apps', 'stocks'));
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_driver'), tests: <String>[path.join('test', 'src', 'real_tests')], options: soundNullSafetyOptions);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'integration_test'));
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_goldens'), options: soundNullSafetyOptions);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_localizations'), options: soundNullSafetyOptions);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_test'), options: soundNullSafetyOptions);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'fuchsia_remote_debug_protocol'), options: soundNullSafetyOptions);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'non_nullable'), options: mixedModeNullSafetyOptions);
    await _runFlutterTest(
      path.join(flutterRoot, 'dev', 'tracing_tests'),
      options: <String>['--enable-vmservice'],
    );
    await runFixTests();
    await runPrivateTests();
    const String httpClientWarning =
      'Warning: At least one test in this suite creates an HttpClient. When\n'
      'running a test suite that uses TestWidgetsFlutterBinding, all HTTP\n'
      'requests will return status code 400, and no network request will\n'
      'actually be made. Any test expecting a real network connection and\n'
      'status code will fail.\n'
      'To test code that needs an HttpClient, provide your own HttpClient\n'
      'implementation to the code under test, so that your test can\n'
      'consistently provide a testable response to the code under test.';
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter_test'),
      script: path.join('test', 'bindings_test_failure.dart'),
      expectFailure: true,
      printOutput: false,
      outputChecker: (CommandResult result) {
        final Iterable<Match> matches = httpClientWarning.allMatches(result.flattenedStdout);
        if (matches == null || matches.isEmpty || matches.length > 1) {
          return 'Failed to print warning about HttpClientUsage, or printed it too many times.\n'
                 'stdout:\n${result.flattenedStdout}';
        }
        return null;
      },
    );
  }

  await selectSubshard(<String, ShardRunner>{
    'widgets': runWidgets,
    'libraries': runLibraries,
    'misc': runMisc,
  });
}

Future<void> _runFrameworkCoverage() async {
  final File coverageFile = File(path.join(flutterRoot, 'packages', 'flutter', 'coverage', 'lcov.info'));
  if (!coverageFile.existsSync()) {
    print('${red}Coverage file not found.$reset');
    print('Expected to find: $cyan${coverageFile.absolute}$reset');
    print('This file is normally obtained by running `${green}flutter update-packages$reset`.');
    exit(1);
  }
  coverageFile.deleteSync();
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter'),
    options: const <String>['--coverage'],
  );
  if (!coverageFile.existsSync()) {
    print('${red}Coverage file not found.$reset');
    print('Expected to find: $cyan${coverageFile.absolute}$reset');
    print('This file should have been generated by the `${green}flutter test --coverage$reset` script, but was not.');
    exit(1);
  }
}

Future<void> _runWebUnitTests() async {
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
    .where((String filePath) => !kWebTestFileKnownFailures.contains(path.split(filePath).join('/')))
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
      flutterPackageDirectory.path,
      allTests.sublist(
        (webShardCount - 1) * testsPerShard,
        allTests.length,
      ),
    );
    await _runFlutterWebTest(
      path.join(flutterRoot, 'packages', 'flutter_web_plugins'),
      <String>['test'],
    );
    await _runFlutterWebTest(
        path.join(flutterRoot, 'packages', 'flutter_driver'),
        <String>[path.join('test', 'src', 'web_tests', 'web_extension_test.dart')],
    );
  };

  await selectSubshard(subshards);
}

/// Coarse-grained integration tests running on the Web.
Future<void> _runWebLongRunningTests() async {
  final List<ShardRunner> tests = <ShardRunner>[
    () => _runGalleryE2eWebTest('debug'),
    () => _runGalleryE2eWebTest('debug', canvasKit: true),
    () => _runGalleryE2eWebTest('profile'),
    () => _runGalleryE2eWebTest('profile', canvasKit: true),
    () => _runGalleryE2eWebTest('release'),
    () => _runGalleryE2eWebTest('release', canvasKit: true),
    () => runWebServiceWorkerTest(headless: true),
  ];
  await _ensureChromeDriverIsRunning();
  await _runShardRunnerIndexOfTotalSubshard(tests);
  await _stopChromeDriver();
}

/// Returns the commit hash of the flutter/plugins repository that's rolled in.
///
/// The flutter/plugins repository is a downstream dependency, it is only used
/// by flutter/flutter for testing purposes, to assure stable tests for a given
/// flutter commit the flutter/plugins commit hash to test against is coded in
/// the bin/internal/flutter_plugins.version file.
///
/// The `filesystem` parameter specified filesystem to read the plugins version file from.
/// The `pluginsVersionFile` parameter allows specifying an alternative path for the
/// plugins version file, when null [flutterPluginsVersionFile] is used.
Future<String> getFlutterPluginsVersion({
  fs.FileSystem fileSystem = const LocalFileSystem(),
  String pluginsVersionFile,
}) async {
  final File versionFile = fileSystem.file(pluginsVersionFile ?? flutterPluginsVersionFile);
  final String versionFileContents = await versionFile.readAsString();
  return versionFileContents.trim();
}

/// Executes the test suite for the flutter/plugins repo.
Future<void> _runFlutterPluginsTests() async {
  Future<void> runAnalyze() async {
    print('${green}Running analysis for flutter/plugins$reset');
    final Directory checkout = Directory.systemTemp.createTempSync('plugins');
    await runCommand(
      'git',
      <String>[
        '-c',
        'core.longPaths=true',
        'clone',
        'https://github.com/flutter/plugins.git',
        '.'
      ],
      workingDirectory: checkout.path,
    );
    final String pluginsCommit = await getFlutterPluginsVersion();
    await runCommand(
      'git',
      <String>[
        '-c',
        'core.longPaths=true',
        'checkout',
        pluginsCommit,
      ],
      workingDirectory: checkout.path,
    );
    await runCommand(
      pub,
      <String>[
        'global',
        'activate',
        'flutter_plugin_tools',
      ],
      workingDirectory: checkout.path,
    );
    await runCommand(
      pub,
      <String>[
        'global',
        'run',
        'flutter_plugin_tools',
        'analyze',
      ],
      workingDirectory: checkout.path,
    );
  }
  await selectSubshard(<String, ShardRunner>{
    'analyze': runAnalyze,
  });
}

// The `chromedriver` process created by this test.
//
// If an existing chromedriver is already available on port 4444, the existing
// process is reused and this variable remains null.
Command _chromeDriver;

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
    print('Starting chromedriver');
    // Assume chromedriver is in the PATH.
    _chromeDriver = await startCommand(
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
  final Map<String, dynamic> webDriverStatus = json.decode(await response.transform(utf8.decoder).join('')) as Map<String, dynamic>;
  client.close();
  final bool webDriverReady = webDriverStatus['value']['ready'] as bool;
  if (!webDriverReady) {
    throw Exception('WebDriver not available.');
  }
}

Future<void> _stopChromeDriver() async {
  if (_chromeDriver == null) {
    return;
  }
  print('Stopping chromedriver');
  _chromeDriver.process.kill();
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
  print('${green}Running flutter_gallery integration test in --$buildMode using ${canvasKit ? 'CanvasKit' : 'HTML'} renderer.$reset');
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'flutter_gallery');
  await runCommand(
    flutter,
    <String>[ 'clean' ],
    workingDirectory: testAppDirectory,
  );
  await runCommand(
    flutter,
    <String>[
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
      '--no-sound-null-safety',
      '-d',
      'web-server',
      '--$buildMode',
    ],
    workingDirectory: testAppDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );
  print('${green}Integration test passed.$reset');
}

Future<void> _runWebIntegrationTests() async {
  await _runWebStackTraceTest('profile', 'lib/stack_trace.dart');
  await _runWebStackTraceTest('release', 'lib/stack_trace.dart');
  await _runWebStackTraceTest('profile', 'lib/framework_stack_trace.dart');
  await _runWebStackTraceTest('release', 'lib/framework_stack_trace.dart');
  await _runWebDebugTest('lib/stack_trace.dart');
  await _runWebDebugTest('lib/framework_stack_trace.dart');
  await _runWebDebugTest('lib/web_directory_loading.dart');
  await _runWebDebugTest('test/test.dart');
  await _runWebDebugTest('lib/null_assert_main.dart', enableNullSafety: true);
  await _runWebDebugTest('lib/null_safe_main.dart', enableNullSafety: true);
  await _runWebDebugTest('lib/web_define_loading.dart',
    additionalArguments: <String>[
      '--dart-define=test.valueA=Example,A',
      '--dart-define=test.valueB=Value',
    ]
  );
  await _runWebReleaseTest('lib/web_define_loading.dart',
    additionalArguments: <String>[
      '--dart-define=test.valueA=Example,A',
      '--dart-define=test.valueB=Value',
    ]
  );
  await _runWebDebugTest('lib/sound_mode.dart', additionalArguments: <String>[
    '--sound-null-safety',
  ]);
  await _runWebReleaseTest('lib/sound_mode.dart', additionalArguments: <String>[
    '--sound-null-safety',
  ]);
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
  final String result = await evalTestAppInChrome(
    appUrl: 'http://localhost:8080/index.html',
    appDirectory: appBuildDirectory,
  );

  if (result.contains('--- TEST SUCCEEDED ---')) {
    print('${green}Web stack trace integration test passed.$reset');
  } else {
    print(result);
    print('${red}Web stack trace integration test failed.$reset');
    exit(1);
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
  final String result = await evalTestAppInChrome(
    appUrl: 'http://localhost:8080/index.html',
    appDirectory: appBuildDirectory,
  );

  if (result.contains('--- TEST SUCCEEDED ---')) {
    print('${green}Web release mode test passed.$reset');
  } else {
    print(result);
    print('${red}Web release mode test failed.$reset');
    exit(1);
  }
}

/// Debug mode is special because `flutter build web` doesn't build in debug mode.
///
/// Instead, we use `flutter run --debug` and sniff out the standard output.
Future<void> _runWebDebugTest(String target, {
  bool enableNullSafety = false,
  List<String> additionalArguments = const<String>[],
}) async {
  final String testAppDirectory = path.join(flutterRoot, 'dev', 'integration_tests', 'web');
  bool success = false;
  final CommandResult result = await runCommand(
    flutter,
    <String>[
      'run',
      '--debug',
      if (enableNullSafety)
        ...<String>[
          '--no-sound-null-safety',
          '--null-assertions',
        ],
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
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );

  if (success) {
    print('${green}Web stack trace integration test passed.$reset');
  } else {
    print(result.flattenedStdout);
    print(result.flattenedStderr);
    print('${red}Web stack trace integration test failed.$reset');
    exit(1);
  }
}

Future<void> _runFlutterWebTest(String workingDirectory, List<String> tests) async {
  await runCommand(
    flutter,
    <String>[
      'test',
      if (ciProvider == CiProviders.cirrus)
        '--concurrency=1',  // do not parallelize on Cirrus, to reduce flakiness
      '-v',
      '--platform=chrome',
      // TODO(ferhatb): Run web tests with both rendering backends.
      '--web-renderer=html', // use html backend for web tests.
      '--sound-null-safety', // web tests do not autodetect yet.
      ...?flutterTestArgs,
      ...tests,
    ],
    workingDirectory: workingDirectory,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    },
  );
}

Future<void> _pubRunTest(String workingDirectory, {
  List<String> testPaths,
  bool enableFlutterToolAsserts = true,
  bool useBuildRunner = false,
  String coverage,
  bool forceSingleCore = false,
  Duration perTestTimeout,
}) async {
  int cpus;
  final String cpuVariable = Platform.environment['CPU']; // CPU is set in cirrus.yml
  if (cpuVariable != null) {
    cpus = int.tryParse(cpuVariable, radix: 10);
    if (cpus == null) {
      print('${red}The CPU environment variable, if set, must be set to the integer number of available cores.$reset');
      print('Actual value: "$cpuVariable"');
      exit(1);
    }
  } else {
    cpus = 2; // Don't default to 1, otherwise we won't catch race conditions.
  }
  // Integration tests that depend on external processes like chrome
  // can get stuck if there are multiple instances running at once.
  if (forceSingleCore) {
    cpus = 1;
  }

  final List<String> args = <String>[
    'run',
    'test',
    if (useFlutterTestFormatter)
      '-rjson'
    else
      '-rcompact',
    '-j$cpus',
    if (!hasColor)
      '--no-color',
    if (coverage != null)
      '--coverage=$coverage',
    if (perTestTimeout != null)
      '--timeout=${perTestTimeout.inMilliseconds.toString()}ms',
    if (testPaths != null)
      for (final String testPath in testPaths)
        testPath,
  ];
  final Map<String, String> pubEnvironment = <String, String>{
    'FLUTTER_ROOT': flutterRoot,
  };
  if (Directory(pubCache).existsSync()) {
    pubEnvironment['PUB_CACHE'] = pubCache;
  }
  if (enableFlutterToolAsserts) {
    // If an existing env variable exists append to it, but only if
    // it doesn't appear to already include enable-asserts.
    String toolsArgs = Platform.environment['FLUTTER_TOOL_ARGS'] ?? '';
    if (!toolsArgs.contains('--enable-asserts'))
      toolsArgs += ' --enable-asserts';
    pubEnvironment['FLUTTER_TOOL_ARGS'] = toolsArgs.trim();
    // The flutter_tool will originally have been snapshotted without asserts.
    // We need to force it to be regenerated with them enabled.
    deleteFile(path.join(flutterRoot, 'bin', 'cache', 'flutter_tools.snapshot'));
    deleteFile(path.join(flutterRoot, 'bin', 'cache', 'flutter_tools.stamp'));
  }
  if (useFlutterTestFormatter) {
    final FlutterCompactFormatter formatter = FlutterCompactFormatter();
    Stream<String> testOutput;
    try {
      testOutput = runAndGetStdout(
        pub,
        args,
        workingDirectory: workingDirectory,
        environment: pubEnvironment,
      );
    } finally {
      formatter.finish();
    }
    await _processTestOutput(formatter, testOutput);
  } else {
    await runCommand(
      pub,
      args,
      workingDirectory: workingDirectory,
      environment: pubEnvironment,
      removeLine: useBuildRunner ? (String line) => line.startsWith('[INFO]') : null,
    );
  }
}

Future<void> _runFlutterTest(String workingDirectory, {
  String script,
  bool expectFailure = false,
  bool printOutput = true,
  OutputChecker outputChecker,
  List<String> options = const <String>[],
  bool skip = false,
  Map<String, String> environment,
  List<String> tests = const <String>[],
}) async {
  assert(!printOutput || outputChecker == null, 'Output either can be printed or checked but not both');

  final List<String> args = <String>[
    'test',
    ...options,
    ...?flutterTestArgs,
  ];

  final bool shouldProcessOutput = useFlutterTestFormatter && !expectFailure && !options.contains('--coverage');
  if (shouldProcessOutput)
    args.add('--machine');

  if (script != null) {
    final String fullScriptPath = path.join(workingDirectory, script);
    if (!FileSystemEntity.isFileSync(fullScriptPath)) {
      print('${red}Could not find test$reset: $green$fullScriptPath$reset');
      print('Working directory: $cyan$workingDirectory$reset');
      print('Script: $green$script$reset');
      if (!printOutput)
        print('This is one of the tests that does not normally print output.');
      if (skip)
        print('This is one of the tests that is normally skipped in this configuration.');
      exit(1);
    }
    args.add(script);
  }

  args.addAll(tests);

  if (!shouldProcessOutput) {
    final OutputMode outputMode = outputChecker == null && printOutput
      ? OutputMode.print
      : OutputMode.capture;

    final CommandResult result = await runCommand(
      flutter,
      args,
      workingDirectory: workingDirectory,
      expectNonZeroExit: expectFailure,
      outputMode: outputMode,
      skip: skip,
      environment: environment,
    );

    if (outputChecker != null) {
      final String message = outputChecker(result);
      if (message != null)
        exitWithError(<String>[message]);
    }
    return;
  }

  if (useFlutterTestFormatter) {
    final FlutterCompactFormatter formatter = FlutterCompactFormatter();
    Stream<String> testOutput;
    try {
      testOutput = runAndGetStdout(
        flutter,
        args,
        workingDirectory: workingDirectory,
        expectNonZeroExit: expectFailure,
        environment: environment,
      );
    } finally {
      formatter.finish();
    }
    await _processTestOutput(formatter, testOutput);
  } else {
    await runCommand(
      flutter,
      args,
      workingDirectory: workingDirectory,
      expectNonZeroExit: expectFailure,
    );
  }
}

Map<String, String> _initGradleEnvironment() {
  final String androidSdkRoot = (Platform.environment['ANDROID_HOME']?.isEmpty ?? true)
      ? Platform.environment['ANDROID_SDK_ROOT']
      : Platform.environment['ANDROID_HOME'];
  if (androidSdkRoot == null || androidSdkRoot.isEmpty) {
    print('${red}Could not find Android SDK; set ANDROID_SDK_ROOT.$reset');
    exit(1);
  }
  return <String, String>{
    'ANDROID_HOME': androidSdkRoot,
    'ANDROID_SDK_ROOT': androidSdkRoot,
  };
}

final Map<String, String> gradleEnvironment = _initGradleEnvironment();

void deleteFile(String path) {
  // This is technically a race condition but nobody else should be running
  // while this script runs, so we should be ok. (Sadly recursive:true does not
  // obviate the need for existsSync, at least on Windows.)
  final File file = File(path);
  if (file.existsSync())
    file.deleteSync();
}

enum CiProviders {
  cirrus,
  luci,
}

Future<void> _processTestOutput(
  FlutterCompactFormatter formatter,
  Stream<String> testOutput,
) async {
  final Timer heartbeat = Timer.periodic(const Duration(seconds: 30), (Timer timer) {
    print('Processing...');
  });

  await testOutput.forEach(formatter.processRawOutput);
  heartbeat.cancel();
  formatter.finish();
}

CiProviders get ciProvider {
  if (Platform.environment['CIRRUS_CI'] == 'true') {
    return CiProviders.cirrus;
  }
  if (Platform.environment['LUCI_CONTEXT'] != null) {
    return CiProviders.luci;
  }
  return null;
}

/// Returns the name of the branch being tested.
String get branchName {
  switch(ciProvider) {
    case CiProviders.cirrus:
      return Platform.environment['CIRRUS_BRANCH'];
    case CiProviders.luci:
      return Platform.environment['LUCI_BRANCH'];
  }
  return '';
}

/// Checks the given file's contents to determine if they match the allowed
/// pattern for version strings.
///
/// Returns null if the contents are good. Returns a string if they are bad.
/// The string is an error message.
Future<String> verifyVersion(File file) async {
  final RegExp pattern = RegExp(
    r'^(\d+)\.(\d+)\.(\d+)((-\d+\.\d+)?\.pre(\.\d+)?)?$');
  final String version = await file.readAsString();
  if (!file.existsSync())
    return 'The version logic failed to create the Flutter version file.';
  if (version == '0.0.0-unknown')
    return 'The version logic failed to determine the Flutter version.';
  if (!version.contains(pattern))
    return 'The version logic generated an invalid version string: "$version".';
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
  final String subshardName = Platform.environment[subshardKey];
  if (subshardName == null) {
    print('$kSubshardKey environment variable is missing, skipping sharding');
    return tests;
  }
  print('$bold$subshardKey=$subshardName$reset');

  final RegExp pattern = RegExp(r'^(\d+)_(\d+)$');
  final Match match = pattern.firstMatch(subshardName);
  if (match == null || match.groupCount != 2) {
    print('${red}Invalid subshard name "$subshardName". Expected format "[int]_[int]" ex. "1_3"');
    exit(1);
  }
  // One-indexed.
  final int index = int.parse(match.group(1));
  final int total = int.parse(match.group(2));
  if (index > total) {
    print('${red}Invalid subshard name "$subshardName". Index number must be greater or equal to total.');
    exit(1);
  }

  final int testsPerShard = tests.length ~/ total;
  final int start = (index - 1) * testsPerShard;
  final int end = index * testsPerShard;

  print('Selecting subshard $index of $total (range ${start + 1}-$end of ${tests.length})');
  return tests.sublist(start, end);
}

Future<void> _runShardRunnerIndexOfTotalSubshard(List<ShardRunner> tests) async {
  final List<ShardRunner> sublist = _selectIndexOfTotalSubshard<ShardRunner>(tests);
  for (final ShardRunner test in sublist) {
    await test();
  }
}

/// If the CIRRUS_TASK_NAME environment variable exists, we use that to determine
/// the shard and sub-shard (parsing it in the form shard-subshard-platform, ignoring
/// the platform).
///
/// For local testing you can just set the SHARD and SUBSHARD
/// environment variables. For example, to run all the framework tests you can
/// just set SHARD=framework_tests. Some shards support named subshards, like
/// SHARD=framework_tests SUBSHARD=widgets. Others support arbitrary numbered
/// subsharding, like SHARD=build_tests SUBSHARD=1_2 (where 1_2 means "one of two"
/// as in run the first half of the tests).
///
/// To run specifically the third subshard of
/// the Web tests you can set SHARD=web_tests SUBSHARD=2 (it's zero-based).
Future<void> selectShard(Map<String, ShardRunner> shards) => _runFromList(shards, kShardKey, 'shard', 0);
Future<void> selectSubshard(Map<String, ShardRunner> subshards) => _runFromList(subshards, kSubshardKey, 'subshard', 1);

const String CIRRUS_TASK_NAME = 'CIRRUS_TASK_NAME';

Future<void> _runFromList(Map<String, ShardRunner> items, String key, String name, int positionInTaskName) async {
  String item = Platform.environment[key];
  if (item == null && Platform.environment.containsKey(CIRRUS_TASK_NAME)) {
    final List<String> parts = Platform.environment[CIRRUS_TASK_NAME].split('-');
    assert(positionInTaskName < parts.length);
    item = parts[positionInTaskName];
  }
  if (item == null) {
    for (final String currentItem in items.keys) {
      print('$bold$key=$currentItem$reset');
      await items[currentItem]();
      print('');
    }
  } else {
    if (!items.containsKey(item)) {
      print('${red}Invalid $name: $item$reset');
      print('The available ${name}s are: ${items.keys.join(", ")}');
      exit(1);
    }
    print('$bold$key=$item$reset');
    await items[item]();
  }
}
