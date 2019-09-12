// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:googleapis/bigquery/v2.dart' as bq;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'flutter_compact_formatter.dart';
import 'run_command.dart';

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
final List<String> flutterTestArgs = <String>[];

final bool useFlutterTestFormatter = Platform.environment['FLUTTER_TEST_FORMATTER'] == 'true';

final bool noUseBuildRunner = Platform.environment['FLUTTER_TEST_NO_BUILD_RUNNER'] == 'true';

const Map<String, ShardRunner> _kShards = <String, ShardRunner>{
  'tests': _runTests,
  'web_tests': _runWebTests,
  'tool_tests': _runToolTests,
  'tool_coverage': _runToolCoverage,
  'build_tests': _runBuildTests,
  'coverage': _runCoverage,
  'integration_tests': _runIntegrationTests,
  'add2app_test': _runAdd2AppTest,
};

/// When you call this, you can pass additional arguments to pass custom
/// arguments to flutter test. For example, you might want to call this
/// script with the parameter --local-engine=host_debug_unopt to
/// use your own build of the engine.
///
/// To run the tool_tests part, run it with SHARD=tool_tests
///
/// For example:
/// SHARD=tool_tests bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// bin/cache/dart-sdk/bin/dart dev/bots/test.dart --local-engine=host_debug_unopt
Future<void> main(List<String> args) async {
  flutterTestArgs.addAll(args);

  final String shard = Platform.environment['SHARD'];
  if (shard != null) {
    if (!_kShards.containsKey(shard)) {
      print('Invalid shard: $shard');
      print('The available shards are: ${_kShards.keys.join(", ")}');
      exit(1);
    }
    print('${bold}SHARD=$shard$reset');
    await _kShards[shard]();
  } else {
    for (String currentShard in _kShards.keys) {
      print('${bold}SHARD=$currentShard$reset');
      await _kShards[currentShard]();
      print('');
    }
  }
}

Future<void> _runSmokeTests() async {
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
    outputChecker: (CapturedOutput output) =>
      output.stdout.contains('failingPendingTimerTest')
      ? null
      : 'Failed to find the stack trace for the pending Timer.',
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
  await _verifyVersion(path.join(flutterRoot, 'version'));
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
    print('Failed to get BigQuery API client.');
    print(e);
    return null;
  }
}

// Partition tool tests into two groups, see explanation on `_runToolCoverage`.
List<List<String>> _partitionToolTests() {
  final List<String> pending = <String>[];
  final String toolTestDir = path.join(toolRoot, 'test');
  for (FileSystemEntity entity in Directory(toolTestDir).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('_test.dart')) {
      final String relativePath = path.relative(entity.path, from: toolRoot);
      pending.add(relativePath);
    }
  }
  // Shuffle the tests to avoid giving an expensive test directory like
  // integration to a single run of tests.
  pending..shuffle();
  final int aboutHalf = pending.length ~/ 2;
  final List<String> groupA = pending.take(aboutHalf).toList();
  final List<String> groupB = pending.skip(aboutHalf).toList();
  return <List<String>>[groupA, groupB];
}

// Tools tests run with coverage enabled have much higher memory usage than
// our current CI infrastructure can support. We partition the tests into
// two sets and run them in separate invocations of dart to reduce peak memory
// usage. codecov.io automatically handles merging different coverage files
// together, so producing separate files is OK.
//
// See: https://github.com/flutter/flutter/issues/35025
Future<void> _runToolCoverage() async {
  final List<List<String>> tests = _partitionToolTests();
  // Precompile tests to speed up subsequent runs.
  await runCommand(
    pub,
    <String>['run', 'build_runner', 'build'],
    workingDirectory: toolRoot,
  );

  // The name of this subshard has to match the --file path provided at
  // the end of this test script in `.cirrus.yml`.
  const List<String> subshards = <String>['A', 'B'];
  for (int i = 0; i < tests.length; i++) {
    final List<String> testGroup = tests[i];
    await runCommand(
      dart,
      <String>[path.join('tool', 'tool_coverage.dart'), '--', ...testGroup],
      workingDirectory: toolRoot,
      environment: <String, String>{
        'FLUTTER_ROOT': flutterRoot,
        'SUBSHARD': subshards[i],
      }
    );
  }
}

Future<void> _runToolTests() async {
  final bq.BigqueryApi bigqueryApi = await _getBigqueryApi();
  await _runSmokeTests();

  // The flutter_tool will currently be snapshotted without asserts. We need
  // to force it to be regenerated with them enabled.
  if (!Platform.isWindows) {
    File(path.join(flutterRoot, 'bin', 'cache', 'flutter_tools.snapshot')).deleteSync();
    File(path.join(flutterRoot, 'bin', 'cache', 'flutter_tools.stamp')).deleteSync();
  }
  // reduce overhead of build_runner in the create case.
  if (noUseBuildRunner || Platform.environment['SUBSHARD'] == 'create') {
    await _pubRunTest(
      path.join(flutterRoot, 'packages', 'flutter_tools'),
      tableData: bigqueryApi?.tabledata,
      enableFlutterToolAsserts: !Platform.isWindows,
    );
  } else {
    await _buildRunnerTest(
      path.join(flutterRoot, 'packages', 'flutter_tools'),
      flutterRoot,
      tableData: bigqueryApi?.tabledata,
      enableFlutterToolAsserts: !Platform.isWindows,
    );
  }

  print('${bold}DONE: All tests successful.$reset');
}

/// Verifies that AOT, APK, and IPA (if on macOS) builds the
/// examples apps without crashing. It does not actually
/// launch the apps. That happens later in the devicelab. This is
/// just a smoke-test. In particular, this will verify we can build
/// when there are spaces in the path name for the Flutter SDK and
/// target app.
Future<void> _runBuildTests() async {
  final Stream<FileSystemEntity> exampleDirectories = Directory(path.join(flutterRoot, 'examples')).list();
  await for (FileSystemEntity fileEntity in exampleDirectories) {
    if (fileEntity is! Directory) {
      continue;
    }
    final String examplePath = fileEntity.path;

    await _flutterBuildAot(examplePath);
    await _flutterBuildApk(examplePath);
    await _flutterBuildIpa(examplePath);
  }
  await _flutterBuildDart2js(path.join('dev', 'integration_tests', 'web'));

  print('${bold}DONE: All build tests successful.$reset');
}

Future<void> _flutterBuildDart2js(String relativePathToApplication) async {
  print('Running Dart2JS build tests...');
  await runCommand(flutter,
    <String>['build', 'web', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
    expectNonZeroExit: false,
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    }
  );
  print('Done.');
}

Future<void> _flutterBuildAot(String relativePathToApplication) async {
  print('Running AOT build tests...');
  await runCommand(flutter,
    <String>['build', 'aot', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
    expectNonZeroExit: false,
  );
  print('Done.');
}

Future<void> _flutterBuildApk(String relativePathToApplication) async {
  if (
        (Platform.environment['ANDROID_HOME']?.isEmpty ?? true) &&
        (Platform.environment['ANDROID_SDK_ROOT']?.isEmpty ?? true)) {
    return;
  }
  print('Running APK build tests...');
  await runCommand(flutter,
    <String>['build', 'apk', '--debug', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
    expectNonZeroExit: false,
  );
  print('Done.');
}

Future<void> _flutterBuildIpa(String relativePathToApplication) async {
  if (!Platform.isMacOS) {
    return;
  }
  print('Running IPA build tests...');
  // Install Cocoapods.  We don't have these checked in for the examples,
  // and build ios doesn't take care of it automatically.
  final File podfile = File(path.join(flutterRoot, relativePathToApplication, 'ios', 'Podfile'));
  if (podfile.existsSync()) {
    await runCommand('pod',
      <String>['install'],
      workingDirectory: podfile.parent.path,
      expectNonZeroExit: false,
    );
  }
  await runCommand(flutter,
    <String>['build', 'ios', '--no-codesign', '--debug', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
    expectNonZeroExit: false,
  );
  print('Done.');
}

Future<void> _runAdd2AppTest() async {
  if (!Platform.isMacOS) {
    return;
  }
  print('Running Add2App iOS integration tests...');
  final String add2AppDir = path.join(flutterRoot, 'dev', 'integration_tests', 'ios_add2app');
  await runCommand('./build_and_test.sh',
    <String>[],
    workingDirectory: add2AppDir,
    expectNonZeroExit: false,
  );
  print('Done.');
}

Future<void> _runTests() async {
  final bq.BigqueryApi bigqueryApi = await _getBigqueryApi();
  await _runSmokeTests();
  final String subShard = Platform.environment['SUBSHARD'];

  Future<void> runWidgets() async {
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      tableData: bigqueryApi?.tabledata,
      tests: <String>[
        path.join('test', 'widgets') + path.separator,
      ],
    );
    // Only packages/flutter/test/widgets/widget_inspector_test.dart really
    // needs to be run with --track-widget-creation but it is nice to run
    // all of the tests in package:flutter with the flag to ensure that
    // the Dart kernel transformer triggered by the flag does not break anything.
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--track-widget-creation'],
      tableData: bigqueryApi?.tabledata,
      tests: <String>[
        path.join('test', 'widgets') + path.separator,
      ],
    );
  }

  Future<void> runFrameworkOthers() async {
    final List<String> tests = Directory(path.join(flutterRoot, 'packages', 'flutter', 'test'))
      .listSync(followLinks: false, recursive: false)
      .whereType<Directory>()
      .where((Directory dir) => dir.path.endsWith('widgets') == false)
      .map((Directory dir) => path.join('test', path.basename(dir.path)) + path.separator)
      .toList();

    print('Running tests for: ${tests.join(';')}');

    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      tableData: bigqueryApi?.tabledata,
      tests: tests,
    );
    // Only packages/flutter/test/widgets/widget_inspector_test.dart really
    // needs to be run with --track-widget-creation but it is nice to run
    // all of the tests in package:flutter with the flag to ensure that
    // the Dart kernel transformer triggered by the flag does not break anything.
    await _runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter'),
      options: <String>['--track-widget-creation'],
      tableData: bigqueryApi?.tabledata,
      tests: tests,
    );
  }

  Future<void> runExtras() async {
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_localizations'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_driver'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_test'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'fuchsia_remote_debug_protocol'), tableData: bigqueryApi?.tabledata);
    await _pubRunTest(path.join(flutterRoot, 'dev', 'bots'), tableData: bigqueryApi?.tabledata);
    await _pubRunTest(path.join(flutterRoot, 'dev', 'devicelab'), tableData: bigqueryApi?.tabledata);
    await _pubRunTest(path.join(flutterRoot, 'dev', 'snippets'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'android_semantics_testing'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'manual_tests'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'vitool'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'hello_world'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'layers'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'stocks'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'flutter_gallery'), tableData: bigqueryApi?.tabledata);
    // Regression test to ensure that code outside of package:flutter can run
    // with --track-widget-creation.
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'flutter_gallery'), options: <String>['--track-widget-creation'], tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'catalog'), tableData: bigqueryApi?.tabledata);
    // Smoke test for code generation.
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'codegen'), tableData: bigqueryApi?.tabledata, environment: <String, String>{
      'FLUTTER_EXPERIMENTAL_BUILD': 'true',
    });
  }
  switch (subShard) {
    case 'widgets':
      await runWidgets();
      break;
    case 'framework_other':
      await runFrameworkOthers();
      break;
    case 'extras':
      runExtras();
      break;
    default:
      print('Unknown sub-shard $subShard, running all tests!');
      await runWidgets();
      await runFrameworkOthers();
      await runExtras();

  }

  print('${bold}DONE: All tests successful.$reset');
}

Future<void> _runWebTests() async {
  // TODO(yjbanov): re-enable when web test cirrus flakiness is resolved
  await _runFlutterWebTest(path.join(flutterRoot, 'packages', 'flutter'), tests: <String>[
    // TODO(yjbanov): re-enable when flakiness is resolved
    // 'test/foundation/',
    // 'test/physics/',
    // 'test/rendering/',
    // 'test/services/',
    // 'test/painting/',
    // 'test/scheduler/',
    // 'test/semantics/',
    // 'test/widgets/',
    // 'test/material/',
  ]);
  await _runFlutterWebTest(path.join(flutterRoot, 'packages', 'flutter_web_plugins'), tests: <String>['test']);
}

Future<void> _runCoverage() async {
  final File coverageFile = File(path.join(flutterRoot, 'packages', 'flutter', 'coverage', 'lcov.info'));
  if (!coverageFile.existsSync()) {
    print('${red}Coverage file not found.$reset');
    print('Expected to find: ${coverageFile.absolute}');
    print('This file is normally obtained by running `flutter update-packages`.');
    exit(1);
  }
  coverageFile.deleteSync();
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter'),
    options: const <String>['--coverage'],
  );
  if (!coverageFile.existsSync()) {
    print('${red}Coverage file not found.$reset');
    print('Expected to find: ${coverageFile.absolute}');
    print('This file should have been generated by the `flutter test --coverage` script, but was not.');
    exit(1);
  }

  print('${bold}DONE: Coverage collection successful.$reset');
}

Future<void> _buildRunnerTest(
  String workingDirectory,
  String flutterRoot, {
  String testPath,
  bool enableFlutterToolAsserts = false,
  bq.TabledataResourceApi tableData,
}) async {
  final List<String> args = <String>['run', 'build_runner', 'test', '--', useFlutterTestFormatter ? '-rjson' : '-rcompact', '-j1'];
  if (!hasColor) {
    args.add('--no-color');
  }
  if (testPath != null) {
    args.add(testPath);
  }
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
  }

  final String subShard = Platform.environment['SUBSHARD'];
  switch (subShard) {
    case 'integration':
      args.addAll(<String>['--tags', 'integration']);
      break;
    case 'create':
      args.addAll(<String>['--tags', 'create']);
      break;
    case 'tool':
      args.addAll(<String>['-x', 'integration', '-x', 'create']);
      break;
  }

  if (useFlutterTestFormatter) {
    final FlutterCompactFormatter formatter = FlutterCompactFormatter();
    final Stream<String> testOutput = runAndGetStdout(
      pub,
      args,
      workingDirectory: workingDirectory,
      environment: pubEnvironment,
      beforeExit: formatter.finish
    );
    await _processTestOutput(formatter, testOutput, tableData);
  } else {
    await runCommand(
      pub,
      args,
      workingDirectory:workingDirectory,
      environment:pubEnvironment,
      removeLine: (String line) => line.contains('[INFO]')
    );
  }
}

Future<void> _pubRunTest(
  String workingDirectory, {
  String testPath,
  bool enableFlutterToolAsserts = false,
  bq.TabledataResourceApi tableData,
}) async {
  final List<String> args = <String>['run', 'test', useFlutterTestFormatter ? '-rjson' : '-rcompact', '-j1'];
  if (!hasColor)
    args.add('--no-color');
  if (testPath != null)
    args.add(testPath);
  final Map<String, String> pubEnvironment = <String, String>{};
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
  }

  final String subShard = Platform.environment['SUBSHARD'];
  switch (subShard) {
    case 'integration':
      args.addAll(<String>['--tags', 'integration']);
      break;
    case 'tool':
      args.addAll(<String>['--exclude-tags', 'integration']);
      break;
    case 'create':
      args.addAll(<String>[path.join('test', 'general.shard', 'commands', 'create_test.dart')]);
      break;
  }

  if (useFlutterTestFormatter) {
    final FlutterCompactFormatter formatter = FlutterCompactFormatter();
    final Stream<String> testOutput = runAndGetStdout(
      pub,
      args,
      workingDirectory: workingDirectory,
      beforeExit: formatter.finish,
    );
    await _processTestOutput(formatter, testOutput, tableData);
  } else {
    await runCommand(
      pub,
      args,
      workingDirectory: workingDirectory,
    );
  }
}

enum CiProviders {
  cirrus,
  luci,
}

CiProviders _getCiProvider() {
  if (Platform.environment['CIRRUS_CI'] == 'true') {
    return CiProviders.cirrus;
  }
  if (Platform.environment['LUCI_CONTEXT'] != null) {
    return CiProviders.luci;
  }
  return null;
}

String _getCiProviderName() {
  switch(_getCiProvider()) {
    case CiProviders.cirrus:
      return 'cirrusci';
    case CiProviders.luci:
      return 'luci';
  }
  return 'unknown';
}

int _getPrNumber() {
  switch(_getCiProvider()) {
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
    'git$exe', <String>['-c', 'log.showSignature=false', 'log', _getGitHash(), '--pretty="%an <%ae>"'],
    workingDirectory: flutterRoot,
  ).first;
  return author;
}

String _getCiUrl() {
  switch(_getCiProvider()) {
    case CiProviders.cirrus:
      return 'https://cirrus-ci.com/task/${Platform.environment['CIRRUS_TASK_ID']}';
    case CiProviders.luci:
      return 'https://ci.chromium.org/p/flutter/g/framework/console'; // TODO(dnfield): can we get a direct link to the actual build?
  }
  return '';
}

String _getGitHash() {
  switch(_getCiProvider()) {
    case CiProviders.cirrus:
      return Platform.environment['CIRRUS_CHANGE_IN_REPO'];
    case CiProviders.luci:
      return 'HEAD'; // TODO(dnfield): Set this in the env for LUCI.
  }
  return '';
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
            'provider': _getCiProviderName(),
            'url': _getCiUrl(),
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
            'pull_request': _getPrNumber(),
            'commit': _getGitHash(),
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

class EvalResult {
  EvalResult({
    this.stdout,
    this.stderr,
    this.exitCode = 0,
  });

  final String stdout;
  final String stderr;
  final int exitCode;
}

Future<void> _runFlutterWebTest(String workingDirectory, {
  List<String> tests,
}) async {
  final List<String> allTests = <String>[];
  for (String testDirPath in tests) {
    final Directory testDir = Directory(path.join(workingDirectory, testDirPath));
    allTests.addAll(
      testDir.listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('_test.dart'))
        .map((File file) => path.relative(file.path, from: workingDirectory))
    );
  }
  print(allTests.join('\n'));
  print('${allTests.length} tests total');

  // Maximum number of tests to run in a single `flutter test`. We found that
  // large batches can get flaky, possibly because we reuse a single instance
  // of the browser, and after many tests the browser's state gets corrupted.
  const int kBatchSize = 20;
  List<String> batch = <String>[];
  for (int i = 0; i < allTests.length; i += 1) {
    final String testFilePath = allTests[i];
    batch.add(testFilePath);
    if (batch.length == kBatchSize || i == allTests.length - 1) {
      await _runFlutterWebTestBatch(workingDirectory, batch: batch);
      batch = <String>[];
    }
  }
}

Future<void> _runFlutterWebTestBatch(String workingDirectory, {
  List<String> batch,
}) async {
  final List<String> args = <String>[
    'test',
    '-v',
    '--platform=chrome',
    ...?flutterTestArgs,
    ...batch,
  ];

  // TODO(jonahwilliams): fix relative path issues to make this unecessary.
  final Directory oldCurrent = Directory.current;
  Directory.current = Directory(path.join(flutterRoot, 'packages', 'flutter'));
  try {
    await runCommand(
      flutter,
      args,
      workingDirectory: workingDirectory,
      expectFlaky: false,
      environment: <String, String>{
        'FLUTTER_WEB': 'true',
        'FLUTTER_LOW_RESOURCE_MODE': 'true',
      },
    );
  } finally {
    Directory.current = oldCurrent;
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
  assert(!printOutput || outputChecker == null,
      'Output either can be printed or checked but not both');

  final List<String> args = <String>[
    'test',
    ...options,
    ...?flutterTestArgs,
  ];

  final bool shouldProcessOutput = useFlutterTestFormatter && !expectFailure && !options.contains('--coverage');
  if (shouldProcessOutput) {
    args.add('--machine');
  }

  if (script != null) {
    final String fullScriptPath = path.join(workingDirectory, script);
    if (!FileSystemEntity.isFileSync(fullScriptPath)) {
      print('Could not find test: $fullScriptPath');
      print('Working directory: $workingDirectory');
      print('Script: $script');
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
      if (message != null) {
        print('$redLine');
        print(message);
        print('$redLine');
        exit(1);
      }
    }
    return;
  }

  if (useFlutterTestFormatter) {
    final FlutterCompactFormatter formatter = FlutterCompactFormatter();
    final Stream<String> testOutput = runAndGetStdout(
      flutter,
      args,
      workingDirectory: workingDirectory,
      expectNonZeroExit: expectFailure,
      beforeExit: formatter.finish,
      environment: environment,
    );
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

Future<void> _verifyVersion(String filename) async {
  if (!File(filename).existsSync()) {
    print('$redLine');
    print('The version logic failed to create the Flutter version file.');
    print('$redLine');
    exit(1);
  }
  final String version = await File(filename).readAsString();
  if (version == '0.0.0-unknown') {
    print('$redLine');
    print('The version logic failed to determine the Flutter version.');
    print('$redLine');
    exit(1);
  }
  final RegExp pattern = RegExp(r'^\d+\.\d+\.\d+(?:|-pre\.\d+|\+hotfix\.\d+)$');
  if (!version.contains(pattern)) {
    print('$redLine');
    print('The version logic generated an invalid version string.');
    print('$redLine');
    exit(1);
  }
}

Future<void> _runIntegrationTests() async {
  final String subShard = Platform.environment['SUBSHARD'];

  switch (subShard) {
    case 'gradle1':
    case 'gradle2':
      // This runs some gradle integration tests if the subshard is Android.
      await _androidGradleTests(subShard);
      break;
    default:
      await _runDevicelabTest('dartdocs');

      if (Platform.isLinux) {
        await _runDevicelabTest('flutter_create_offline_test_linux');
      } else if (Platform.isWindows) {
        await _runDevicelabTest('flutter_create_offline_test_windows');
      } else if (Platform.isMacOS) {
        await _runDevicelabTest('flutter_create_offline_test_mac');
// TODO(jmagman): Re-enable once flakiness is resolved.
//        await _runDevicelabTest('module_test_ios');
      }
      // This does less work if the subshard isn't Android.
      await _androidPluginTest();
  }
}

Future<void> _runDevicelabTest(String testName, {Map<String, String> env}) async {
  await runCommand(
    dart,
    <String>['bin/run.dart', '-t', testName],
    workingDirectory: path.join(flutterRoot, 'dev', 'devicelab'),
    environment: env,
  );
}

String get androidSdkRoot {
  final String androidSdkRoot = (Platform.environment['ANDROID_HOME']?.isEmpty ?? true)
      ? Platform.environment['ANDROID_SDK_ROOT']
      : Platform.environment['ANDROID_HOME'];
  if (androidSdkRoot == null || androidSdkRoot.isEmpty) {
    return null;
  }
  return androidSdkRoot;
}

Future<void> _androidPluginTest() async {
  if (androidSdkRoot == null) {
    print('No Android SDK detected, skipping Android Plugin test.');
    return;
  }

  final Map<String, String> env = <String, String> {
    'ANDROID_HOME': androidSdkRoot,
    'ANDROID_SDK_ROOT': androidSdkRoot,
  };

  await _runDevicelabTest('plugin_test', env: env);
}

Future<void> _androidGradleTests(String subShard) async {
  // TODO(dnfield): gradlew is crashing on the cirrus image and it's not clear why.
  if (androidSdkRoot == null || Platform.isWindows) {
    print('No Android SDK detected or on Windows, skipping Android gradle test.');
    return;
  }

  final Map<String, String> env = <String, String> {
    'ANDROID_HOME': androidSdkRoot,
    'ANDROID_SDK_ROOT': androidSdkRoot,
  };

  if (subShard == 'gradle1') {
    await _runDevicelabTest('gradle_plugin_light_apk_test', env: env);
    await _runDevicelabTest('gradle_plugin_fat_apk_test', env: env);
  }
  if (subShard == 'gradle2') {
    await _runDevicelabTest('gradle_plugin_bundle_test', env: env);
    await _runDevicelabTest('module_test', env: env);
    await _runDevicelabTest('module_host_with_custom_build_test', env: env);
  }
}
