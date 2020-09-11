// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

// This test depends on some files in ///dev/automated_tests/flutter_test/*

Future<void> _testExclusionLock;

void main() {
  final String automatedTestsDirectory = globals.fs.path.join('..', '..', 'dev', 'automated_tests');
  final String flutterTestDirectory = globals.fs.path.join(automatedTestsDirectory, 'flutter_test');

  testUsingContext('flutter test should not have extraneous error messages', () async {
    Cache.flutterRoot = '../..';
    return _testFile('trivial_widget', automatedTestsDirectory, flutterTestDirectory, exitCode: isZero);
  });

  testUsingContext('flutter test should report nice errors for exceptions thrown within testWidgets()', () async {
    Cache.flutterRoot = '../..';
    return _testFile('exception_handling', automatedTestsDirectory, flutterTestDirectory);
  });

  testUsingContext('flutter test should report a nice error when a guarded function was called without await', () async {
    Cache.flutterRoot = '../..';
    return _testFile('test_async_utils_guarded', automatedTestsDirectory, flutterTestDirectory);
  });

  testUsingContext('flutter test should report a nice error when an async function was called without await', () async {
    Cache.flutterRoot = '../..';
    return _testFile('test_async_utils_unguarded', automatedTestsDirectory, flutterTestDirectory);
  });

  testUsingContext('flutter test should report a nice error when a Ticker is left running', () async {
    Cache.flutterRoot = '../..';
    return _testFile('ticker', automatedTestsDirectory, flutterTestDirectory);
  });

  testUsingContext('flutter test should report a nice error when a pubspec.yaml is missing a flutter_test dependency', () async {
    final String missingDependencyTests = globals.fs.path.join('..', '..', 'dev', 'missing_dependency_tests');
    Cache.flutterRoot = '../..';
    return _testFile('trivial', missingDependencyTests, missingDependencyTests);
  });

  testUsingContext('flutter test should report which user-created widget caused the error', () async {
    Cache.flutterRoot = '../..';
    return _testFile('print_user_created_ancestor', automatedTestsDirectory, flutterTestDirectory,
        extraArguments: const <String>['--track-widget-creation']);
  });

  testUsingContext('flutter test should report which user-created widget caused the error - no flag', () async {
    Cache.flutterRoot = '../..';
    return _testFile('print_user_created_ancestor_no_flag', automatedTestsDirectory, flutterTestDirectory,
       extraArguments: const <String>['--no-track-widget-creation']);
  });

  testUsingContext('flutter test should report the correct user-created widget that caused the error', () async {
    Cache.flutterRoot = '../..';
    return _testFile('print_correct_local_widget', automatedTestsDirectory, flutterTestDirectory,
      extraArguments: const <String>['--track-widget-creation']);
  });

  testUsingContext('flutter test should can load assets within its own package', () async {
    Cache.flutterRoot = '../..';
    return _testFile('package_assets', automatedTestsDirectory, flutterTestDirectory, exitCode: isZero);
  });

  testUsingContext('flutter test should run a test when its name matches a regexp', () async {
    Cache.flutterRoot = '../..';
    final ProcessResult result = await _runFlutterTest('filtering', automatedTestsDirectory, flutterTestDirectory,
      extraArguments: const <String>['--name', 'inc.*de']);
    if (!(result.stdout as String).contains('+1: All tests passed')) {
      fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
    }
    expect(result.exitCode, 0);
  });

  testUsingContext('flutter test should run a test when its name contains a string', () async {
    Cache.flutterRoot = '../..';
    final ProcessResult result = await _runFlutterTest('filtering', automatedTestsDirectory, flutterTestDirectory,
      extraArguments: const <String>['--plain-name', 'include']);
    if (!(result.stdout as String).contains('+1: All tests passed')) {
      fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
    }
    expect(result.exitCode, 0);
  });

  testUsingContext('flutter test should run a test with a given tag', () async {
    Cache.flutterRoot = '../..';
    final ProcessResult result = await _runFlutterTest('filtering_tag', automatedTestsDirectory, flutterTestDirectory,
        extraArguments: const <String>['--tags', 'include-tag']);
    if (!(result.stdout as String).contains('+1: All tests passed')) {
      fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
    }
    expect(result.exitCode, 0);
  });

  testUsingContext('flutter test should not run a test with excluded tag', () async {
    Cache.flutterRoot = '../..';
    final ProcessResult result = await _runFlutterTest('filtering_tag', automatedTestsDirectory, flutterTestDirectory,
        extraArguments: const <String>['--exclude-tags', 'exclude-tag']);
    if (!(result.stdout as String).contains('+1: All tests passed')) {
      fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
    }
    expect(result.exitCode, 0);
  });

  testUsingContext('flutter test should run all tests when tags are unspecified', () async {
    Cache.flutterRoot = '../..';
    final ProcessResult result = await _runFlutterTest('filtering_tag', automatedTestsDirectory, flutterTestDirectory);
    if (!(result.stdout as String).contains('+1 -1: Some tests failed')) {
      fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
    }
    expect(result.exitCode, 1);
  });

  testUsingContext('flutter test should run a widgetTest with a given tag', () async {
    Cache.flutterRoot = '../..';
    final ProcessResult result = await _runFlutterTest('filtering_tag_widget', automatedTestsDirectory, flutterTestDirectory,
        extraArguments: const <String>['--tags', 'include-tag']);
    if (!(result.stdout as String).contains('+1: All tests passed')) {
      fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
    }
    expect(result.exitCode, 0);
  });

  testUsingContext('flutter test should not run a widgetTest with excluded tag', () async {
    Cache.flutterRoot = '../..';
    final ProcessResult result = await _runFlutterTest('filtering_tag_widget', automatedTestsDirectory, flutterTestDirectory,
        extraArguments: const <String>['--exclude-tags', 'exclude-tag']);
    if (!(result.stdout as String).contains('+1: All tests passed')) {
      fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
    }
    expect(result.exitCode, 0);
  });

  testUsingContext('flutter test should run all widgetTest when tags are unspecified', () async {
    Cache.flutterRoot = '../..';
    final ProcessResult result = await _runFlutterTest('filtering_tag_widget', automatedTestsDirectory, flutterTestDirectory);
    if (!(result.stdout as String).contains('+1 -1: Some tests failed')) {
      fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
    }
    expect(result.exitCode, 1);
  });

  testUsingContext('flutter test should test runs to completion', () async {
    Cache.flutterRoot = '../..';
    final ProcessResult result = await _runFlutterTest('trivial', automatedTestsDirectory, flutterTestDirectory,
      extraArguments: const <String>['--verbose']);
    final String stdout = result.stdout as String;
    if ((!stdout.contains('+1: All tests passed')) ||
        (!stdout.contains('test 0: starting shell process')) ||
        (!stdout.contains('test 0: deleting temporary directory')) ||
        (!stdout.contains('test 0: finished')) ||
        (!stdout.contains('test package returned with exit code 0'))) {
      fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
    }
    if ((result.stderr as String).isNotEmpty) {
      fail('unexpected error output from test:\n\n${result.stderr}\n-- end stderr --\n\n');
    }
    expect(result.exitCode, 0);
  });

  testUsingContext('flutter test should run all tests inside of a directory with no trailing slash', () async {
    Cache.flutterRoot = '../..';
    final ProcessResult result = await _runFlutterTest(null, automatedTestsDirectory, flutterTestDirectory + '/child_directory',
      extraArguments: const <String>['--verbose']);
    final String stdout = result.stdout as String;
    if ((!stdout.contains('+2: All tests passed')) ||
        (!stdout.contains('test 0: starting shell process')) ||
        (!stdout.contains('test 0: deleting temporary directory')) ||
        (!stdout.contains('test 0: finished')) ||
        (!stdout.contains('test package returned with exit code 0'))) {
      fail('unexpected output from test:\n\n${result.stdout}\n-- end stdout --\n\n');
    }
    if ((result.stderr as String).isNotEmpty) {
      fail('unexpected error output from test:\n\n${result.stderr}\n-- end stderr --\n\n');
    }
    expect(result.exitCode, 0);
  });
}

Future<void> _testFile(
  String testName,
  String workingDirectory,
  String testDirectory, {
  Matcher exitCode,
  List<String> extraArguments = const <String>[],
}) async {
  exitCode ??= isNonZero;
  final String fullTestExpectation = globals.fs.path.join(testDirectory, '${testName}_expectation.txt');
  final File expectationFile = globals.fs.file(fullTestExpectation);
  if (!expectationFile.existsSync()) {
    fail('missing expectation file: $expectationFile');
  }

  while (_testExclusionLock != null) {
    await _testExclusionLock;
  }

  final ProcessResult exec = await _runFlutterTest(
    testName,
    workingDirectory,
    testDirectory,
    extraArguments: extraArguments,
  );

  expect(exec.exitCode, exitCode);
  final List<String> output = (exec.stdout as String).split('\n');
  if (output.first.startsWith('Waiting for another flutter command to release the startup lock...')) {
    output.removeAt(0);
  }
  if (output.first.startsWith('Running "flutter pub get" in')) {
    output.removeAt(0);
  }
  output.add('<<stderr>>');
  output.addAll((exec.stderr as String).split('\n'));
  final List<String> expectations = globals.fs.file(fullTestExpectation).readAsLinesSync();
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
    String outputLine = output[outputLineNumber];
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
    if (!RegExp(expectationLine).hasMatch(outputLine) && outputLineNumber + 1 < output.length) {
      // Check if the RegExp can match the next two lines in the output so
      // that it is possible to write expectations that still hold even if a
      // line is wrapped slightly differently due to for example a file name
      // being longer on one platform than another.
      final String mergedLines = '$outputLine\n${output[outputLineNumber+1]}';
      if (RegExp(expectationLine).hasMatch(mergedLines)) {
        outputLineNumber += 1;
        outputLine = mergedLines;
      }
    }

    expect(outputLine, matches(expectationLine), reason: 'Full output:\n- - - -----8<----- - - -\n${output.join("\n")}\n- - - -----8<----- - - -');
    expectationLineNumber += 1;
    outputLineNumber += 1;
  }
  expect(allowSkip, isFalse);
  if (!haveSeenStdErrMarker) {
    expect(exec.stderr, '');
  }
}

Future<ProcessResult> _runFlutterTest(
  String testName,
  String workingDirectory,
  String testDirectory, {
  List<String> extraArguments = const <String>[],
}) async {

  String testPath;
  if (testName == null) {
    // Test everything in the directory.
    testPath = testDirectory;
    final Directory directoryToTest = globals.fs.directory(testPath);
    if (!directoryToTest.existsSync()) {
      fail('missing test directory: $directoryToTest');
    }
  } else {
    // Test just a specific test file.
    testPath = globals.fs.path.join(testDirectory, '${testName}_test.dart');
    final File testFile = globals.fs.file(testPath);
    if (!testFile.existsSync()) {
      fail('missing test file: $testFile');
    }
  }

  final List<String> args = <String>[
    globals.fs.path.absolute(globals.fs.path.join('bin', 'flutter_tools.dart')),
    'test',
    '--no-color',
    '--no-version-check',
    ...extraArguments,
    testPath,
  ];

  while (_testExclusionLock != null) {
    await _testExclusionLock;
  }

  final Completer<void> testExclusionCompleter = Completer<void>();
  _testExclusionLock = testExclusionCompleter.future;
  try {
    return await Process.run(
      globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
      args,
      workingDirectory: workingDirectory,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  } finally {
    _testExclusionLock = null;
    testExclusionCompleter.complete();
  }
}
