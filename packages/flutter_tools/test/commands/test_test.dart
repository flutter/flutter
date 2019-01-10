// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/sdk.dart';

import '../src/common.dart';
import '../src/context.dart';

// This test depends on some files in ///dev/automated_tests/flutter_test/*

Future<void> _testExclusionLock;

void main() {
  group('flutter test should', () {

    final String automatedTestsDirectory = fs.path.join('..', '..', 'dev', 'automated_tests');
    final String flutterTestDirectory = fs.path.join(automatedTestsDirectory, 'flutter_test');

    testUsingContext('not have extraneous error messages', () async {
      Cache.flutterRoot = '../..';
      return _testFile('trivial_widget', automatedTestsDirectory, flutterTestDirectory, exitCode: isZero);
    }, skip: io.Platform.isLinux); // Flutter on Linux sometimes has problems with font resolution (#7224)

    testUsingContext('report nice errors for exceptions thrown within testWidgets()', () async {
      Cache.flutterRoot = '../..';
      return _testFile('exception_handling', automatedTestsDirectory, flutterTestDirectory);
    }, skip: io.Platform.isWindows); // Dart on Windows has trouble with unicode characters in output

    testUsingContext('report a nice error when a guarded function was called without await', () async {
      Cache.flutterRoot = '../..';
      return _testFile('test_async_utils_guarded', automatedTestsDirectory, flutterTestDirectory);
    }, skip: io.Platform.isWindows); // Dart on Windows has trouble with unicode characters in output

    testUsingContext('report a nice error when an async function was called without await', () async {
      Cache.flutterRoot = '../..';
      return _testFile('test_async_utils_unguarded', automatedTestsDirectory, flutterTestDirectory);
    }, skip: io.Platform.isWindows); // Dart on Windows has trouble with unicode characters in output

    testUsingContext('report a nice error when a Ticker is left running', () async {
      Cache.flutterRoot = '../..';
      return _testFile('ticker', automatedTestsDirectory, flutterTestDirectory);
    }, skip: io.Platform.isWindows); // Dart on Windows has trouble with unicode characters in output

    testUsingContext('report a nice error when a pubspec.yaml is missing a flutter_test dependency', () async {
      final String missingDependencyTests = fs.path.join('..', '..', 'dev', 'missing_dependency_tests');
      Cache.flutterRoot = '../..';
      return _testFile('trivial', missingDependencyTests, missingDependencyTests);
    }, skip: io.Platform.isWindows); // Dart on Windows has trouble with unicode characters in output

    testUsingContext('run a test when its name matches a regexp', () async {
      Cache.flutterRoot = '../..';
      final ProcessResult result = await _runFlutterTest('filtering', automatedTestsDirectory, flutterTestDirectory,
        extraArgs: const <String>['--name', 'inc.*de']);
      if (!result.stdout.contains('+1: All tests passed'))
        fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
      expect(result.exitCode, 0);
    });

    testUsingContext('run a test when its name contains a string', () async {
      Cache.flutterRoot = '../..';
      final ProcessResult result = await _runFlutterTest('filtering', automatedTestsDirectory, flutterTestDirectory,
        extraArgs: const <String>['--plain-name', 'include']);
      if (!result.stdout.contains('+1: All tests passed'))
        fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
      expect(result.exitCode, 0);
    });

    testUsingContext('test runs to completion', () async {
      Cache.flutterRoot = '../..';
      final ProcessResult result = await _runFlutterTest('trivial', automatedTestsDirectory, flutterTestDirectory,
        extraArgs: const <String>['--verbose']);
      if ((!result.stdout.contains('+1: All tests passed')) ||
          (!result.stdout.contains('test 0: starting shell process')) ||
          (!result.stdout.contains('test 0: deleting temporary directory')) ||
          (!result.stdout.contains('test 0: finished')) ||
          (!result.stdout.contains('test package returned with exit code 0')))
        fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
      if (result.stderr.isNotEmpty)
        fail('unexpected error output from test:\n\n${result.stderr}\n-- end stderr --\n\n');
      expect(result.exitCode, 0);
    });

  });
}

Future<void> _testFile(String testName, String workingDirectory, String testDirectory, {Matcher exitCode}) async {
  exitCode ??= isNonZero;
  final String fullTestExpectation = fs.path.join(testDirectory, '${testName}_expectation.txt');
  final File expectationFile = fs.file(fullTestExpectation);
  if (!expectationFile.existsSync())
    fail('missing expectation file: $expectationFile');

  while (_testExclusionLock != null)
    await _testExclusionLock;

  final ProcessResult exec = await _runFlutterTest(testName, workingDirectory, testDirectory);

  expect(exec.exitCode, exitCode);
  final List<String> output = exec.stdout.split('\n');
  if (output.first == 'Waiting for another flutter command to release the startup lock...')
    output.removeAt(0);
  if (output.first.startsWith('Running "flutter packages get" in'))
    output.removeAt(0);
  output.add('<<stderr>>');
  output.addAll(exec.stderr.split('\n'));
  final List<String> expectations = fs.file(fullTestExpectation).readAsLinesSync();
  bool allowSkip = false;
  int expectationLineNumber = 0;
  int outputLineNumber = 0;
  bool haveSeenStdErrMarker = false;
  while (expectationLineNumber < expectations.length) {
    expect(
      output,
      hasLength(greaterThan(outputLineNumber)),
      reason: 'Failure in $testName to compare to $fullTestExpectation',
    );
    final String expectationLine = expectations[expectationLineNumber];
    final String outputLine = output[outputLineNumber];
    if (expectationLine == '<<skip until matching line>>') {
      allowSkip = true;
      expectationLineNumber += 1;
      continue;
    }
    if (allowSkip) {
      if (!RegExp(expectationLine).hasMatch(outputLine)) {
        outputLineNumber += 1;
        continue;
      }
      allowSkip = false;
    }
    if (expectationLine == '<<stderr>>') {
      expect(haveSeenStdErrMarker, isFalse);
      haveSeenStdErrMarker = true;
    }
    expect(outputLine, matches(expectationLine), reason: 'Full output:\n- - - -----8<----- - - -\n${output.join("\n")}\n- - - -----8<----- - - -');
    expectationLineNumber += 1;
    outputLineNumber += 1;
  }
  expect(allowSkip, isFalse);
  if (!haveSeenStdErrMarker)
    expect(exec.stderr, '');
}

Future<ProcessResult> _runFlutterTest(
  String testName,
  String workingDirectory,
  String testDirectory, {
  List<String> extraArgs = const <String>[],
}) async {

  final String testFilePath = fs.path.join(testDirectory, '${testName}_test.dart');
  final File testFile = fs.file(testFilePath);
  if (!testFile.existsSync())
    fail('missing test file: $testFile');

  final List<String> args = <String>[]
    ..addAll(dartVmFlags)
    ..add(fs.path.absolute(fs.path.join('bin', 'flutter_tools.dart')))
    ..add('test')
    ..add('--no-color')
    ..addAll(extraArgs)
    ..add(testFilePath);

  while (_testExclusionLock != null)
    await _testExclusionLock;

  final Completer<void> testExclusionCompleter = Completer<void>();
  _testExclusionLock = testExclusionCompleter.future;
  try {
    return await Process.run(
      fs.path.join(dartSdkPath, 'bin', 'dart'),
      args,
      workingDirectory: workingDirectory,
    );
  } finally {
    _testExclusionLock = null;
    testExclusionCompleter.complete();
  }
}
