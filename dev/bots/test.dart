// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'run_command.dart';

typedef ShardRunner = Future<void> Function();

final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
final String dart = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'dart.exe' : 'dart');
final String pub = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', Platform.isWindows ? 'pub.bat' : 'pub');
final String pubCache = path.join(flutterRoot, '.pub-cache');
final List<String> flutterTestArgs = <String>[];

const Map<String, ShardRunner> _kShards = <String, ShardRunner>{
  'tests': _runTests,
  'tool_tests': _runToolTests,
  'build_tests': _runBuildTests,
  'coverage': _runCoverage,
};

const Duration _kLongTimeout = Duration(minutes: 45);
const Duration _kShortTimeout = Duration(minutes: 5);

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
    timeout: _kShortTimeout,
  );
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'fail_test.dart'),
    expectFailure: true,
    printOutput: false,
    timeout: _kShortTimeout,
  );
  // We run the timeout tests individually because they are timing-sensitive.
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'timeout_pass_test.dart'),
    expectFailure: false,
    printOutput: false,
    timeout: _kShortTimeout,
  );
  await _runFlutterTest(automatedTests,
    script: path.join('test_smoke_test', 'timeout_fail_test.dart'),
    expectFailure: true,
    printOutput: false,
    timeout: _kShortTimeout,
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
        timeout: _kShortTimeout,
      ),
      _runFlutterTest(automatedTests,
        script: path.join('test_smoke_test', 'crash2_test.dart'),
        expectFailure: true,
        printOutput: false,
        timeout: _kShortTimeout,
      ),
      _runFlutterTest(automatedTests,
        script: path.join('test_smoke_test', 'syntax_error_test.broken_dart'),
        expectFailure: true,
        printOutput: false,
        timeout: _kShortTimeout,
      ),
      _runFlutterTest(automatedTests,
        script: path.join('test_smoke_test', 'missing_import_test.broken_dart'),
        expectFailure: true,
        printOutput: false,
        timeout: _kShortTimeout,
      ),
      _runFlutterTest(automatedTests,
        script: path.join('test_smoke_test', 'disallow_error_reporter_modification_test.dart'),
        expectFailure: true,
        printOutput: false,
        timeout: _kShortTimeout,
      ),
      runCommand(flutter,
        <String>['drive', '--use-existing-app', '-t', path.join('test_driver', 'failure.dart')],
        workingDirectory: path.join(flutterRoot, 'packages', 'flutter_driver'),
        expectNonZeroExit: true,
        printOutput: false,
        timeout: _kShortTimeout,
      ),
    ],
  );

  // Verify that we correctly generated the version file.
  await _verifyVersion(path.join(flutterRoot, 'version'));
}

Future<void> _runToolTests() async {
  await _runSmokeTests();

  await _pubRunTest(
    path.join(flutterRoot, 'packages', 'flutter_tools'),
    enableFlutterToolAsserts: true,
  );

  print('${bold}DONE: All tests successful.$reset');
}

/// Verifies that AOT, APK, and IPA (if on macOS) builds of some
/// examples apps finish without crashing. It does not actually
/// launch the apps. That happens later in the devicelab. This is
/// just a smoke-test. In particular, this will verify we can build
/// when there are spaces in the path name for the Flutter SDK and
/// target app.
Future<void> _runBuildTests() async {
  final List<String> paths = <String>[
    path.join('examples', 'hello_world'),
    path.join('examples', 'flutter_gallery'),
    path.join('examples', 'flutter_view'),
  ];
  for (String path in paths) {
    await _flutterBuildAot(path);
    await _flutterBuildApk(path);
    await _flutterBuildIpa(path);
  }

  print('${bold}DONE: All build tests successful.$reset');
}

Future<void> _flutterBuildAot(String relativePathToApplication) async {
  print('Running AOT build tests...');
  await runCommand(flutter,
    <String>['build', 'aot', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
    expectNonZeroExit: false,
    timeout: _kShortTimeout,
  );
  print('Done.');
}

Future<void> _flutterBuildApk(String relativePathToApplication) async {
  // TODO(dnfield): See if we can get Android SDK on all Cirrus platforms.
  if (Platform.environment['ANDROID_HOME']?.isEmpty ?? true) {
    return;
  }
  print('Running APK build tests...');
  await runCommand(flutter,
    <String>['build', 'apk', '--debug', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
    expectNonZeroExit: false,
    timeout: _kShortTimeout,
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
      timeout: _kShortTimeout,
    );
  }
  await runCommand(flutter,
    <String>['build', 'ios', '--no-codesign', '--debug', '-v'],
    workingDirectory: path.join(flutterRoot, relativePathToApplication),
    expectNonZeroExit: false,
    timeout: _kShortTimeout,
  );
  print('Done.');
}

Future<void> _runTests() async {
  await _runSmokeTests();

  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter'));
  // Only packages/flutter/test/widgets/widget_inspector_test.dart really
  // needs to be run with --track-widget-creation but it is nice to run
  // all of the tests in package:flutter with the flag to ensure that
  // the Dart kernel transformer triggered by the flag does not break anything.
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter'), options: <String>['--track-widget-creation']);
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_localizations'));
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_driver'));
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'flutter_test'));
  await _runFlutterTest(path.join(flutterRoot, 'packages', 'fuchsia_remote_debug_protocol'));
  await _pubRunTest(path.join(flutterRoot, 'dev', 'bots'));
  await _pubRunTest(path.join(flutterRoot, 'dev', 'devicelab'));
  await _pubRunTest(path.join(flutterRoot, 'dev', 'snippets'));
  await _runFlutterTest(path.join(flutterRoot, 'dev', 'integration_tests', 'android_semantics_testing'));
  await _runFlutterTest(path.join(flutterRoot, 'dev', 'manual_tests'));
  await _runFlutterTest(path.join(flutterRoot, 'dev', 'tools', 'vitool'));
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'hello_world'));
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'layers'));
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'stocks'));
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'flutter_gallery'));
  // Regression test to ensure that code outside of package:flutter can run
  // with --track-widget-creation.
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'flutter_gallery'), options: <String>['--track-widget-creation']);
  await _runFlutterTest(path.join(flutterRoot, 'examples', 'catalog'));

  print('${bold}DONE: All tests successful.$reset');
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

Future<void> _pubRunTest(
  String workingDirectory, {
  String testPath,
  bool enableFlutterToolAsserts = false
}) {
  final List<String> args = <String>['run', 'test', '-rcompact', '-j1'];
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
  return runCommand(
    pub, args,
    workingDirectory: workingDirectory,
    environment: pubEnvironment,
  );
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

Future<void> _runFlutterTest(String workingDirectory, {
  String script,
  bool expectFailure = false,
  bool printOutput = true,
  List<String> options = const <String>[],
  bool skip = false,
  Duration timeout = _kLongTimeout,
}) {
  final List<String> args = <String>['test']..addAll(options);
  if (flutterTestArgs != null && flutterTestArgs.isNotEmpty)
    args.addAll(flutterTestArgs);
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
  return runCommand(flutter, args,
    workingDirectory: workingDirectory,
    expectNonZeroExit: expectFailure,
    printOutput: printOutput,
    skip: skip,
    timeout: timeout,
  );
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
  final RegExp pattern = RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+(-pre\.[0-9]+)?$');
  if (!version.contains(pattern)) {
    print('$redLine');
    print('The version logic generated an invalid version string.');
    print('$redLine');
    exit(1);
  }
}
