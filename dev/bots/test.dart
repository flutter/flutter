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
final List<String> flutterTestArgs = <String>[]; // arguments to pass to `flutter test` (typically the local engine configuration)

final bool useFlutterTestFormatter = Platform.environment['FLUTTER_TEST_FORMATTER'] == 'true';
final bool canUseBuildRunner = Platform.environment['FLUTTER_TEST_NO_BUILD_RUNNER'] != 'true';

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
  flutterTestArgs.addAll(args);
  await _runSmokeTests();
  await selectShard(const <String, ShardRunner>{
    'add_to_app_tests': _runAddToAppTests,
    'build_tests': _runBuildTests,
    'framework_coverage': _runFrameworkCoverage,
    'framework_tests': _runFrameworkTests,
    'integration_tests': _runIntegrationTests,
    'tool_coverage': _runToolCoverage,
    'tool_tests': _runToolTests,
    'web_tests': _runWebTests,
  });
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
  await _verifyVersion(path.join(flutterRoot, 'version'));
  print('');
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
    value: (dynamic subshard) => () async {
      await _pubRunTest(
        toolsPath,
        testPath: path.join(kTest, '$subshard$kDotShard'),
        useBuildRunner: canUseBuildRunner,
        tableData: bigqueryApi?.tabledata,
      );
    },
  );

  await selectSubshard(subshards);
}

/// Verifies that AOT, APK, and IPA (if on macOS) builds the examples apps
/// without crashing. It does not actually launch the apps. That happens later
/// in the devicelab. This is just a smoke-test. In particular, this will verify
/// we can build when there are spaces in the path name for the Flutter SDK and
/// target app.
Future<void> _runBuildTests() async {
  final Stream<FileSystemEntity> exampleDirectories = Directory(path.join(flutterRoot, 'examples')).list();
  await for (FileSystemEntity fileEntity in exampleDirectories) {
    if (fileEntity is! Directory)
      continue;
    final String examplePath = fileEntity.path;
    await _flutterBuildAot(examplePath);
    await _flutterBuildApk(examplePath);
    if (Platform.isMacOS)
      await _flutterBuildIpa(examplePath);
  }
  await _flutterBuildDart2js(path.join('dev', 'integration_tests', 'web'));
}

Future<void> _flutterBuildDart2js(String relativePathToApplication) async {
  print('${green}Testing Dart2JS build$reset for $cyan$relativePathToApplication$reset...');
  await runCommand(flutter,
    <String>['build', 'web', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
    environment: <String, String>{
      'FLUTTER_WEB': 'true',
    }
  );
}

Future<void> _flutterBuildAot(String relativePathToApplication) async {
  print('${green}Testing AOT build$reset for $cyan$relativePathToApplication$reset...');
  await runCommand(flutter,
    <String>['build', 'aot', '-v'],
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
    );
  }
  await runCommand(flutter,
    <String>['build', 'ios', '--no-codesign', '--debug', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
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
      options: <String>['--track-widget-creation'],
      tableData: bigqueryApi?.tabledata,
      tests: <String>[ 'test/widgets/' ],
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
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'android_semantics_testing'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'manual_tests'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'vitool'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'catalog'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'hello_world'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'layers'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'stocks'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_driver'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_localizations'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_test'), tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'packages', 'fuchsia_remote_debug_protocol'), tableData: bigqueryApi?.tabledata);

    // Try compiling code outside of the packages/flutter directory with and without --track-widget-creation
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'flutter_gallery'), options: <String>['--track-widget-creation'], tableData: bigqueryApi?.tabledata);
    await _runFlutterTest(path.join(flutterRoot, 'examples', 'flutter_gallery'), options: <String>['--no-track-widget-creation'], tableData: bigqueryApi?.tabledata);

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

Future<void> _runWebTests() async {
  // Run a small subset of web tests to smoke-test the Web test infrastructure.
  await _runFlutterWebTest(path.join(flutterRoot, 'packages', 'flutter'), tests: <String>[
    'test/foundation/assertions_test.dart',
    // TODO(yjbanov): re-enable when web test cirrus flakiness is resolved
    // 'test/foundation/',
    // 'test/material/',
    // 'test/painting/',
    // 'test/physics/',
    // 'test/rendering/',
    // 'test/scheduler/',
    // 'test/semantics/',
    // 'test/services/',
    // 'test/widgets/',
  ]);
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

Future<void> _pubRunTest(String workingDirectory, {
  String testPath,
  bool enableFlutterToolAsserts = true,
  bool useBuildRunner = false,
  bq.TabledataResourceApi tableData,
}) async {
  final List<String> args = <String>['run'];
  if (useBuildRunner) {
    args.addAll(<String>['build_runner', 'test', '--']);
  } else {
    args.add('test');
  }
  args.add(useFlutterTestFormatter ? '-rjson' : '-rcompact');
  args.add('-j1'); // TODO(ianh): Scale based on CPUs.
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
    final Stream<String> testOutput = runAndGetStdout(
      pub,
      args,
      workingDirectory: workingDirectory,
      environment: pubEnvironment,
      beforeExit: formatter.finish,
    );
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

void deleteFile(String path) {
  // There's a race condition here but in theory we're not racing anyone
  // while this script runs, so should be ok.
  final File file = File(path);
  if (file.existsSync())
    file.deleteSync();
}

enum CiProviders {
  cirrus,
  luci,
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
  bool printOutput = true,
  bool skip = false,
  List<String> tests,
}) async {
  final List<String> args = <String>[
    'test',
    '-v',
    '--platform=chrome',
    ...?flutterTestArgs,
    ...tests,
  ];

  // TODO(jonahwilliams): fix relative path issues to make this unecessary.
  final Directory oldCurrent = Directory.current;
  Directory.current = Directory(path.join(flutterRoot, 'packages', 'flutter'));
  try {
    await runCommand(
      flutter,
      args,
      workingDirectory: workingDirectory,
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

Future<void> _runIntegrationTests() async {

  Future<void> runGradle1() async {
    await _runDevicelabTest('gradle_plugin_light_apk_test', environment: gradleEnvironment);
    await _runDevicelabTest('gradle_plugin_fat_apk_test', environment: gradleEnvironment);
  }

  Future<void> runGradle2() async {
    await _runDevicelabTest('gradle_plugin_bundle_test', environment: gradleEnvironment);
    await _runDevicelabTest('module_test', environment: gradleEnvironment);
    await _runDevicelabTest('module_host_with_custom_build_test', environment: gradleEnvironment);
  }

  Future<void> runMisc() async {
    await _runDevicelabTest('dartdocs');
    if (Platform.isLinux) {
      await _runDevicelabTest('flutter_create_offline_test_linux');
    } else if (Platform.isWindows) {
      await _runDevicelabTest('flutter_create_offline_test_windows');
    } else if (Platform.isMacOS) {
      await _runDevicelabTest('flutter_create_offline_test_mac');
      // TODO(jmagman): Re-enable once flakiness is resolved:
      // await _runDevicelabTest('module_test_ios');
    }
    await _runDevicelabTest('plugin_test', environment: gradleEnvironment);
  }

  await selectSubshard(<String, ShardRunner>{
    'gradle1': runGradle1,
    'gradle2': runGradle2,
    'misc': runMisc,
  });
}

Future<void> _runDevicelabTest(String testName, {Map<String, String> environment}) async {
  // TODO(ianh): Move the tests that are not running on devicelab any more out of the device lab directory.
  await runCommand(
    dart,
    <String>['bin/run.dart', '-t', testName],
    workingDirectory: path.join(flutterRoot, 'dev', 'devicelab'),
    environment: environment,
  );
}

Future<void> selectShard(Map<String, ShardRunner> shards) => _runFromList(shards, 'SHARD', 'shard');
Future<void> selectSubshard(Map<String, ShardRunner> subshards) => _runFromList(subshards, 'SUBSHARD', 'subshard');

Future<void> _runFromList(Map<String, ShardRunner> items, String key, String name) async {
  final String item = Platform.environment[key];
  if (item != null) {
    if (!items.containsKey(item)) {
      print('${red}Invalid $name: $item$reset');
      print('The available ${name}s are: ${items.keys.join(", ")}');
      exit(1);
    }
    print('$bold$key=$item$reset');
    await items[item]();
  } else {
    for (String currentItem in items.keys) {
      print('$bold$key=$currentItem$reset');
      await items[currentItem]();
      print('');
    }
  }
}
