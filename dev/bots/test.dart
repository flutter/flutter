// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:googleapis/bigquery/v2.dart' as bq;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'flutter_compact_formatter.dart';
import 'run_command.dart';
import 'utils.dart';

typedef ShardRunner = Future<void> Function();

/// A function used to validate the output of a test.
///
/// If the output matches expectations, the function shall return null.
///
/// If the output does not match expectations, the function shall return an
/// appropriate error message.
typedef OutputChecker = String Function(CapturedOutput);

final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
final String dart = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'dart.exe' : 'dart');
final String pub = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'pub.bat' : 'pub');
final String pubCache = path.join(flutterRoot, '.pub-cache');
final String toolRoot = path.join(flutterRoot, 'packages', 'flutter_tools');

/// The arguments to pass to `flutter test` (typically the local engine
/// configuration) -- prefilled with the arguments passed to test.dart.
final List<String> flutterTestArgs = <String>[];

final bool useFlutterTestFormatter = Platform.environment['FLUTTER_TEST_FORMATTER'] == 'true';

final bool canUseBuildRunner = Platform.environment['FLUTTER_TEST_NO_BUILD_RUNNER'] != 'true';

/// The number of Cirrus jobs that run host-only devicelab tests in parallel.
///
/// WARNING: if you change this number, also change .cirrus.yml
/// and make sure it runs _all_ shards.
const int kDeviceLabShardCount = 4;

/// The number of Cirrus jobs that run Web tests in parallel.
///
/// WARNING: if you change this number, also change .cirrus.yml
/// and make sure it runs _all_ shards.
///
/// The last shard also runs the Web plugin tests.
const int kWebShardCount = 8;

/// Maximum number of Web tests to run in a single `flutter test`. We found that
/// large batches can get flaky, possibly because we reuse a single instance of
/// the browser, and after many tests the browser's state gets corrupted.
const int kWebBatchSize = 20;

/// Tests that we don't run on Web for various reasons.
//
// TODO(yjbanov): we're getting rid of this blacklist as part of https://github.com/flutter/flutter/projects/60
const List<String> kWebTestFileBlacklist = <String>[
  // This test doesn't compile because it depends on code outside the flutter package.
  'test/examples/sector_layout_test.dart',
  'test/widgets/selectable_text_test.dart',
  'test/widgets/color_filter_test.dart',
  'test/widgets/editable_text_cursor_test.dart',
  'test/widgets/raw_keyboard_listener_test.dart',
  'test/widgets/editable_text_test.dart',
  'test/widgets/widget_inspector_test.dart',
  'test/widgets/shortcuts_test.dart',
  'test/material/text_form_field_test.dart',
  'test/material/data_table_test.dart',
  'test/cupertino/dialog_test.dart',
  'test/cupertino/nav_bar_test.dart',
  'test/cupertino/nav_bar_transition_test.dart',
  'test/cupertino/refresh_test.dart',
  'test/cupertino/switch_test.dart',
  'test/cupertino/text_field_test.dart',
  'test/cupertino/date_picker_test.dart',
  'test/cupertino/slider_test.dart',
  'test/cupertino/text_field_test.dart',
  'test/cupertino/segmented_control_test.dart',
  'test/cupertino/route_test.dart',
  'test/cupertino/activity_indicator_test.dart',
];

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
    await selectShard(const <String, ShardRunner>{
      'add_to_app_tests': _runAddToAppTests,
      'add_to_app_life_cycle_tests': _runAddToAppLifeCycleTests,
      'build_tests': _runBuildTests,
      'framework_coverage': _runFrameworkCoverage,
      'framework_tests': _runFrameworkTests,
      'hostonly_devicelab_tests': _runHostOnlyDeviceLabTests,
      'tool_coverage': _runToolCoverage,
      'tool_tests': _runToolTests,
      'web_tests': _runWebTests,
    });
  } on ExitException catch (error) {
    error.apply();
  }
  print('$clock ${bold}Test successful.$reset');
}

Future<void> _runSmokeTests() async {
  print('${green}Running smoketests...$reset');
  // Verify that the tests actually return failure on failure and success on
  // success.
  final String automatedTests = path.join(flutterRoot, 'dev', 'automated_tests');
  // We run the "pass" and "fail" smoke tests first, and alone, because those
  // are particularly critical and sensitive. If one of these fails, there's no
  // point even trying the others.
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'pass_test.dart'),
    printOutput: false,
  );
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'fail_test.dart'),
    expectFailure: true,
    printOutput: false,
  );
  // We run the timeout tests individually because they are timing-sensitive.
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'timeout_pass_test.dart'),
    expectFailure: false,
    printOutput: false,
  );
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'timeout_fail_test.dart'),
    expectFailure: true,
    printOutput: false,
  );
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'pending_timer_fail_test.dart'),
    expectFailure: true,
    printOutput: false,
    outputChecker: (CapturedOutput output) {
      return output.stdout.contains('failingPendingTimerTest')
        ? null
        : 'Failed to find the stack trace for the pending Timer.';
    }
  );
  // We run the remaining smoketests in parallel, because they each take some
  // time to run (e.g. compiling), so we don't want to run them in series,
  // especially on 20-core machines...
  await Future.wait<void>(
    <Future<void>>[
      _runFlutterTest(automatedTests,
        script: path.join('test_smoke_test', 'crash1_test.dart'),
        expectFailure: true,
        printOutput: false,
      ),
      _runFlutterTest(automatedTests,
        script: path.join('test_smoke_test', 'crash2_test.dart'),
        expectFailure: true,
        printOutput: false,
      ),
      _runFlutterTest(automatedTests,
        script: path.join('test_smoke_test', 'syntax_error_test.broken_dart'),
        expectFailure: true,
        printOutput: false,
      ),
      _runFlutterTest(automatedTests,
        script: path.join('test_smoke_test', 'missing_import_test.broken_dart'),
        expectFailure: true,
        printOutput: false,
      ),
      _runFlutterTest(automatedTests,
        script: path.join('test_smoke_test', 'disallow_error_reporter_modification_test.dart'),
        expectFailure: true,
        printOutput: false,
      ),
      runCommand(flutter,
        <String>['drive', '--use-existing-app', '-t', path.join('test_driver', 'failure.dart')],
        workingDirectory: path.join(flutterRoot, 'packages', 'flutter_driver'),
        expectNonZeroExit: true,
        outputMode: OutputMode.discard,
      ),
    ],
  );

  // Verify that we correctly generated the version file.
  final String versionError = await verifyVersion(File(path.join(flutterRoot, 'version')));
  if (versionError != null)
    exitWithError(<String>[versionError]);
}

Future<bq.BigqueryApi> _getBigqueryApi() async {
  if (!useFlutterTestFormatter) {
    return null;
  }
  // TODO(dnfield): How will we do this on LUCI?
  final String privateKey = Platform.environment['GCLOUD_SERVICE_ACCOUNT_KEY'];
  // If we're on Cirrus and a non-collaborator is doing this, we can't get the key.
  if (privateKey == null || privateKey.isEmpty || privateKey.startsWith('ENCRYPTED[')) {
    return null;
  }
  try {
    final auth.ServiceAccountCredentials accountCredentials = auth.ServiceAccountCredentials(
      'flutter-ci-test-reporter@flutter-infra.iam.gserviceaccount.com',
      auth.ClientId.serviceAccount('114390419920880060881.apps.googleusercontent.com'),
      '-----BEGIN PRIVATE KEY-----\n$privateKey\n-----END PRIVATE KEY-----\n',
    );
    final List<String> scopes = <String>[bq.BigqueryApi.BigqueryInsertdataScope];
    final http.Client client = await auth.clientViaServiceAccount(accountCredentials, scopes);
    return bq.BigqueryApi(client);
  } catch (e) {
    print('${red}Failed to get BigQuery API client.$reset');
    print(e);
    return null;
  }
}

Future<void> _runToolCoverage() async {
  await runCommand( // Precompile tests to speed up subsequent runs.
    pub,
    <String>['run', 'build_runner', 'build'],
    workingDirectory: toolRoot,
  );
  await runCommand(
    dart,
    <String>[path.join('tool', 'tool_coverage.dart')],
    workingDirectory: toolRoot,
    environment: <String, String>{
      'FLUTTER_ROOT': flutterRoot,
    }
  );
}

Future<void> _runToolTests() async {
  final bq.BigqueryApi bigqueryApi = await _getBigqueryApi();

  const String kDotShard = '.shard';
  const String kTest = 'test';
  final String toolsPath = path.join(flutterRoot, 'packages', 'flutter_tools');

  final Map<String, ShardRunner> subshards = Map<String, ShardRunner>.fromIterable(
    Directory(path.join(toolsPath, kTest))
      .listSync()
      .map<String>((FileSystemEntity entry) => entry.path)
      .where((String name) => name.endsWith(kDotShard))
      .map<String>((String name) => path.basenameWithoutExtension(name)),
    // The `dynamic` on the next line is because Map.fromIterable isn't generic.
    value: (dynamic subshard) => () async {
      // Due to https://github.com/flutter/flutter/issues/46180, skip the hermetic directory
      // on Windows.
      final String suffix = Platform.isWindows && subshard == 'commands'
        ? 'permeable'
        : '';
      await _pubRunTest(
        toolsPath,
        testPath: path.join(kTest, '$subshard$kDotShard', suffix),
        useBuildRunner: canUseBuildRunner,
        tableData: bigqueryApi?.tabledata,
        enableFlutterToolAsserts: true,
      );
    },
  );

  await selectSubshard(subshards);
}

// Example apps that should not be built by _runBuildTests`
const List<String> _excludedExampleApplications = <String>[
  // This application contains no platform code and cannot be built, except for
  // as a part of a '--fast-start' Android application.
  'splash',
];

/// Verifies that AOT, APK, and IPA (if on macOS) builds the examples apps
/// without crashing. It does not actually launch the apps. That happens later
/// in the devicelab. This is just a smoke-test. In particular, this will verify
/// we can build when there are spaces in the path name for the Flutter SDK and
/// target app.
Future<void> _runBuildTests() async {
  final Stream<FileSystemEntity> exampleDirectories = Directory(path.join(flutterRoot, 'examples')).list();
  await for (final FileSystemEntity fileEntity in exampleDirectories) {
    if (fileEntity is! Directory) {
      continue;
    }
    if (_excludedExampleApplications.any(fileEntity.path.endsWith)) {
      continue;
    }
    final String examplePath = fileEntity.path;
    await _flutterBuildAot(examplePath);
    await _flutterBuildApk(examplePath);
    if (Platform.isMacOS) {
      await _flutterBuildIpa(examplePath);
    }
  }

  final String branch = Platform.environment['CIRRUS_BRANCH'];
  if (branch != 'beta' && branch != 'stable') {
    // Web compilation tests.
    await _flutterBuildDart2js(
      path.join('dev', 'integration_tests', 'web'),
      path.join('lib', 'main.dart'),
    );
    // Should not fail to compile with dart:io.
    await _flutterBuildDart2js(
      path.join('dev', 'integration_tests', 'web_compile_tests'),
      path.join('lib', 'dart_io_import.dart'),
    );
  }
}

Future<void> _flutterBuildAot(String relativePathToApplication) async {
  print('${green}Testing AOT build$reset for $cyan$relativePathToApplication$reset...');
  final String absoluteTarget = path.join(path.absolute(relativePathToApplication), 'lib', 'main.dart');
  await runCommand(flutter,
    <String>[
      'assemble',
      '-dTargetFile=$absoluteTarget',
      '-dTargetPlatform=android',
      '-dBuildMode=release',
      '--output=build/aot',
      'android_aot_bundle_release_android-arm64',
      'android_aot_bundle_release_android-arm',
    ],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
  );
}

Future<void> _flutterBuildApk(String relativePathToApplication) async {
  print('${green}Testing APK --debug build$reset for $cyan$relativePathToApplication$reset...');
  await runCommand(flutter,
    <String>['build', 'apk', '--debug', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
  );
}

Future<void> _flutterBuildIpa(String relativePathToApplication) async {
  assert(Platform.isMacOS);
  print('${green}Testing IPA build$reset for $cyan$relativePathToApplication$reset...');
  // Install Cocoapods.  We don't have these checked in for the examples,
  // and build ios doesn't take care of it automatically.
  final File podfile = File(path.join(flutterRoot, relativePathToApplication, 'ios', 'Podfile'));
  if (podfile.existsSync()) {
    await runCommand('pod',
      <String>['install'],
      workingDirectory: podfile.parent.path,
      environment: <String, String>{
        'LANG': 'en_US.UTF-8',
      },
    );
  }
  await runCommand(flutter,
    <String>['build', 'ios', '--no-codesign', '--debug', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
  );
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

Future<void> _runAddToAppTests() async {
  if (Platform.isMacOS) {
    print('${green}Running add-to-app iOS integration tests$reset...');
    final String addToAppDir = path.join(flutterRoot, 'dev', 'integration_tests', 'ios_add2app');
    await runCommand('./build_and_test.sh',
      <String>[],
      workingDirectory: addToAppDir,
    );
  }
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
  final bq.BigqueryApi bigqueryApi = await _getBigqueryApi();

  Future<void> runWidgets() async {
    print('${green}Running packages/flutter tests for$reset: ${cyan}test/widgets/$reset');
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--track-widget-creation'],
      tableData: bigqueryApi?.tabledata,
      tests: <String>[ path.join('test', 'widgets') + path.separator ],
    );
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--no-track-widget-creation'],
      tableData: bigqueryApi?.tabledata,
      tests: <String>[ path.join('test', 'widgets') + path.separator ],
    );
    // Try compiling code outside of the packages/flutter directory with and without --track-widget-creation
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'flutter_gallery'), options: <String>['--track-widget-creation'], tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'flutter_gallery'), options: <String>['--no-track-widget-creation'], tableData: bigqueryApi?.tabledata);
  }

  Future<void> runLibraries() async {
    final List<String> tests = Directory(path.join(flutterRoot, 'packages', 'flutter', 'test'))
      .listSync(followLinks: false, recursive: false)
      .whereType<Directory>()
      .where((Directory dir) => dir.path.endsWith('widgets') == false)
      .map<String>((Directory dir) => path.join('test', path.basename(dir.path)) + path.separator)
      .toList();
    print('${green}Running packages/flutter tests$reset for: $cyan${tests.join(", ")}$reset');
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--track-widget-creation'],
      tableData: bigqueryApi?.tabledata,
      tests: tests,
    );
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--no-track-widget-creation'],
      tableData: bigqueryApi?.tabledata,
      tests: tests,
    );
  }

  Future<void> runMisc() async {
    print('${green}Running package tests$reset for directories other than packages/flutter');
    await _pubRunTest(path.join(flutterRoot, 'dev', 'bots'), tableData: bigqueryApi?.tabledata);
    await _pubRunTest(path.join(flutterRoot, 'dev', 'devicelab'), tableData: bigqueryApi?.tabledata);
    await _pubRunTest(path.join(flutterRoot, 'dev', 'snippets'), tableData: bigqueryApi?.tabledata);
    await _pubRunTest(path.join(flutterRoot, 'dev', 'tools'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'android_semantics_testing'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'manual_tests'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'vitool'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'catalog'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'hello_world'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'layers'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'stocks'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_driver'), tableData: bigqueryApi?.tabledata, tests: <String>[path.join('test', 'src', 'real_tests')]);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_goldens'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_localizations'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_test'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'fuchsia_remote_debug_protocol'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(
      path.join(flutterRoot, 'dev', 'integration_tests', 'codegen'),
      tableData: bigqueryApi?.tabledata,
      environment: <String, String>{
        'FLUTTER_EXPERIMENTAL_BUILD': 'true',
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

Future<void> _runWebTests() async {
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
    .where((String filePath) => !kWebTestFileBlacklist.contains(filePath))
    .toList()
    // Finally we shuffle the list because we want the average cost per file to be uniformly
    // distributed. If the list is not sorted then different shards and batches may have
    // very different characteristics.
    // We use a constant seed for repeatability.
    ..shuffle(math.Random(0));

  assert(kWebShardCount >= 1);
  final int testsPerShard = (allTests.length / kWebShardCount).ceil();
  assert(testsPerShard * kWebShardCount >= allTests.length);

  // This for loop computes all but the last shard.
  for (int index = 0; index < kWebShardCount - 1; index += 1) {
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
  subshards['${kWebShardCount - 1}_last'] = () async {
    await _runFlutterWebTest(
      flutterPackageDirectory.path,
      allTests.sublist(
        (kWebShardCount - 1) * testsPerShard,
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

Future<void> _runFlutterWebTest(String workingDirectory, List<String> tests) async {
  final List<String> batch = <String>[];
  for (int i = 0; i < tests.length; i += 1) {
    final String testFilePath = tests[i];
    batch.add(testFilePath);
    if (batch.length == kWebBatchSize || i == tests.length - 1) {
      await runCommand(
        flutter,
        <String>[
          'test',
          if (ciProvider == CiProviders.cirrus)
            '--concurrency=1',  // do not parallelize on Cirrus, to reduce flakiness
          '-v',
          '--platform=chrome',
          ...?flutterTestArgs,
          ...batch,
        ],
        workingDirectory: workingDirectory,
        environment: <String, String>{
          'FLUTTER_WEB': 'true',
          'FLUTTER_LOW_RESOURCE_MODE': 'true',
        },
      );
      batch.clear();
    }
  }
}

Future<void> _pubRunTest(String workingDirectory, {
  String testPath,
  bool enableFlutterToolAsserts = true,
  bool useBuildRunner = false,
  bq.TabledataResourceApi tableData,
}) async {
  final List<String> args = <String>['run'];
  if (useBuildRunner) {
    final String posixTestPath = path.posix.joinAll(path.split(testPath));
    args.addAll(<String>[
      'build_runner',
      'test',
      '--build-filter=$posixTestPath/*.dill',
      '--build-filter=$posixTestPath/**/*.dill',
      '--',
    ]);
  } else {
    args.add('test');
  }
  args.add(useFlutterTestFormatter ? '-rjson' : '-rcompact');
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
  args.add('-j$cpus');
  if (!hasColor)
    args.add('--no-color');
  if (testPath != null)
    args.add(testPath);
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
    await _processTestOutput(formatter, testOutput, tableData);
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
  bq.TabledataResourceApi tableData,
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
    OutputMode outputMode = OutputMode.discard;
    CapturedOutput output;

    if (outputChecker != null) {
      outputMode = OutputMode.capture;
      output = CapturedOutput();
    } else if (printOutput) {
      outputMode = OutputMode.print;
    }

    await runCommand(
      flutter,
      args,
      workingDirectory: workingDirectory,
      expectNonZeroExit: expectFailure,
      outputMode: outputMode,
      output: output,
      skip: skip,
      environment: environment,
    );

    if (outputChecker != null) {
      final String message = outputChecker(output);
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
    await _processTestOutput(formatter, testOutput, tableData);
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
    print('${red}Could not find Android SDK; set ANDROID_SDK_ROOT (or ANDROID_HOME).$reset');
    exit(1);
  }
  return <String, String>{
    'ANDROID_HOME': androidSdkRoot,
    'ANDROID_SDK_ROOT': androidSdkRoot,
  };
}

final Map<String, String> gradleEnvironment = _initGradleEnvironment();

Future<void> _runHostOnlyDeviceLabTests() async {
  // Please don't add more tests here. We should not be using the devicelab
  // logic to run tests outside devicelab, that's just confusing.
  // Instead, create tests that are not devicelab tests, and run those.

  // TODO(ianh): Move the tests that are not running on devicelab any more out
  // of the device lab directory.

  // List the tests to run.
  // We split these into subshards. The tests are randomly distributed into
  // those subshards so as to get a uniform distribution of costs, but the
  // seed is fixed so that issues are reproducible.
  final List<ShardRunner> tests = <ShardRunner>[
    // Keep this in alphabetical order.
    () => _runDevicelabTest('build_aar_module_test', environment: gradleEnvironment),
    if (Platform.isMacOS) () => _runDevicelabTest('flutter_create_offline_test_mac'),
    if (Platform.isLinux) () => _runDevicelabTest('flutter_create_offline_test_linux'),
    if (Platform.isWindows) () => _runDevicelabTest('flutter_create_offline_test_windows'),
    () => _runDevicelabTest('gradle_fast_start_test', environment: gradleEnvironment),
    // TODO(ianh): Fails on macOS looking for "dexdump", https://github.com/flutter/flutter/issues/42494
    if (!Platform.isMacOS) () => _runDevicelabTest('gradle_jetifier_test', environment: gradleEnvironment),
    () => _runDevicelabTest('gradle_non_android_plugin_test', environment: gradleEnvironment),
    () => _runDevicelabTest('gradle_plugin_bundle_test', environment: gradleEnvironment),
    () => _runDevicelabTest('gradle_plugin_fat_apk_test', environment: gradleEnvironment),
    () => _runDevicelabTest('gradle_plugin_light_apk_test', environment: gradleEnvironment),
    () => _runDevicelabTest('gradle_r8_test', environment: gradleEnvironment),

    () => _runDevicelabTest('module_host_with_custom_build_test', environment: gradleEnvironment, testEmbeddingV2: true),
    () => _runDevicelabTest('module_test', environment: gradleEnvironment, testEmbeddingV2: true),
    () => _runDevicelabTest('plugin_dependencies_test', environment: gradleEnvironment),

    if (Platform.isMacOS) () => _runDevicelabTest('module_test_ios'),
    if (Platform.isMacOS) () => _runDevicelabTest('build_ios_framework_module_test'),
    if (Platform.isMacOS) () => _runDevicelabTest('plugin_lint_mac'),
    () => _runDevicelabTest('plugin_test', environment: gradleEnvironment),
  ]..shuffle(math.Random(0));

  final int testsPerShard = tests.length ~/ kDeviceLabShardCount;
  final Map<String, ShardRunner> subshards = <String, ShardRunner>{};

  for (int subshard = 0; subshard < kDeviceLabShardCount; subshard += 1) {
    String last = '';
    List<ShardRunner> sublist;
    if (subshard < kDeviceLabShardCount - 1) {
      sublist = tests.sublist(subshard * testsPerShard, (subshard + 1) * testsPerShard);
    } else {
      sublist = tests.sublist(subshard * testsPerShard, tests.length);
      // We make sure the last shard ends in _last so it's easier to catch mismatches
      // between `.cirrus.yml` and `test.dart`.
      last = '_last';
    }
    subshards['$subshard$last'] = () async {
      for (final ShardRunner test in sublist)
        await test();
    };
  }

  await selectSubshard(subshards);
}

Future<void> _runDevicelabTest(String testName, {
  Map<String, String> environment,
  // testEmbeddingV2 is only supported by certain specific devicelab tests.
  // Don't use it unless you're sure the test actually supports it.
  // You can check by looking to see if the test examines the environment
  // for the ENABLE_ANDROID_EMBEDDING_V2 variable.
  bool testEmbeddingV2 = false,
}) async {
  await runCommand(
    dart,
    <String>['bin/run.dart', '-t', testName],
    workingDirectory: path.join(flutterRoot, 'dev', 'devicelab'),
    environment: <String, String>{
      ...?environment,
      if (testEmbeddingV2)
        'ENABLE_ANDROID_EMBEDDING_V2': 'true',
    },
  );
}

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
  bq.TabledataResourceApi tableData,
) async {
  final Timer heartbeat = Timer.periodic(const Duration(seconds: 30), (Timer timer) {
    print('Processing...');
  });

  await testOutput.forEach(formatter.processRawOutput);
  heartbeat.cancel();
  formatter.finish();
  if (tableData == null || formatter.tests.isEmpty) {
    return;
  }
  final bq.TableDataInsertAllRequest request = bq.TableDataInsertAllRequest();
  final String authors = await _getAuthors();
  request.rows = List<bq.TableDataInsertAllRequestRows>.from(
    formatter.tests.map<bq.TableDataInsertAllRequestRows>((TestResult result) =>
      bq.TableDataInsertAllRequestRows.fromJson(<String, dynamic> {
        'json': <String, dynamic>{
          'source': <String, dynamic>{
            'provider': ciProviderName,
            'url': ciUrl,
            'platform': <String, dynamic>{
              'os': Platform.operatingSystem,
              'version': Platform.operatingSystemVersion,
            },
          },
          'test': <String, dynamic>{
            'name': result.name,
            'result': result.status.toString(),
            'file': result.path,
            'line': result.line,
            'column': result.column,
            'time': result.totalTime,
          },
          'git': <String, dynamic>{
            'author': authors,
            'pull_request': prNumber,
            'commit': gitHash,
            'organization': 'flutter',
            'repository': 'flutter',
          },
          'error': result.status != TestStatus.failed ? null : <String, dynamic>{
            'message': result.errorMessage,
            'stack_trace': result.stackTrace,
          },
          'information': result.messages,
        },
      }),
    ),
    growable: false,
  );
  final bq.TableDataInsertAllResponse response = await tableData.insertAll(request, 'flutter-infra', 'tests', 'ci');
  if (response.insertErrors != null && response.insertErrors.isNotEmpty) {
    print('${red}BigQuery insert errors:');
    print(response.toJson());
    print(reset);
  }
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

String get ciProviderName {
  switch (ciProvider) {
    case CiProviders.cirrus:
      return 'cirrusci';
    case CiProviders.luci:
      return 'luci';
  }
  return 'unknown';
}

int get prNumber {
  switch (ciProvider) {
    case CiProviders.cirrus:
      return Platform.environment['CIRRUS_PR'] == null
          ? -1
          : int.tryParse(Platform.environment['CIRRUS_PR']);
    case CiProviders.luci:
      return -1; // LUCI doesn't know about this.
  }
  return -1;
}

Future<String> _getAuthors() async {
  final String exe = Platform.isWindows ? '.exe' : '';
  final String author = await runAndGetStdout(
    'git$exe', <String>['-c', 'log.showSignature=false', 'log', gitHash, '--pretty="%an <%ae>"'],
    workingDirectory: flutterRoot,
  ).first;
  return author;
}

String get ciUrl {
  switch (ciProvider) {
    case CiProviders.cirrus:
      return 'https://cirrus-ci.com/task/${Platform.environment['CIRRUS_TASK_ID']}';
    case CiProviders.luci:
      return 'https://ci.chromium.org/p/flutter/g/framework/console'; // TODO(dnfield): can we get a direct link to the actual build?
  }
  return '';
}

String get gitHash {
  switch(ciProvider) {
    case CiProviders.cirrus:
      return Platform.environment['CIRRUS_CHANGE_IN_REPO'];
    case CiProviders.luci:
      return 'HEAD'; // TODO(dnfield): Set this in the env for LUCI.
  }
  return '';
}

/// Checks the given file's contents to determine if they match the allowed
/// pattern for version strings.
///
/// Returns null if the contents are good. Returns a string if they are bad.
/// The string is an error message.
Future<String> verifyVersion(File file) async {
  final RegExp pattern = RegExp(r'^\d+\.\d+\.\d+(\+hotfix\.\d+)?(-pre\.\d+)?$');
  final String version = await file.readAsString();
  if (!file.existsSync())
    return 'The version logic failed to create the Flutter version file.';
  if (version == '0.0.0-unknown')
    return 'The version logic failed to determine the Flutter version.';
  if (!version.contains(pattern))
    return 'The version logic generated an invalid version string: "$version".';
  return null;
}

/// If the CIRRUS_TASK_NAME environment variable exists, we use that to determine
/// the shard and sub-shard (parsing it in the form shard-subshard-platform, ignoring
/// the platform).
///
/// However, for local testing you can just set the SHARD and SUBSHARD
/// environment variables. For example, to run all the framework tests you can
/// just set SHARD=framework_tests. To run specifically the third subshard of
/// the Web tests you can set SHARD=web_tests SUBSHARD=2 (it's zero-based).
Future<void> selectShard(Map<String, ShardRunner> shards) => _runFromList(shards, 'SHARD', 'shard', 0);
Future<void> selectSubshard(Map<String, ShardRunner> subshards) => _runFromList(subshards, 'SUBSHARD', 'subshard', 1);

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
