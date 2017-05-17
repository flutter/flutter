// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/sdk.dart';
import 'package:test/test.dart';

import '../src/context.dart';

// This test depends on some files in ///dev/automated_tests/flutter_test/*

Future<Null> _testExclusionLock;

void main() {
  group('test', () {

    final String automatedTestsDirectory = fs.path.join('..', '..', 'dev', 'automated_tests');
    final String flutterTestDirectory = fs.path.join(automatedTestsDirectory, 'flutter_test');

    testUsingContext('Exception handling in test harness', () async {
      Cache.flutterRoot = '../..';
      return _testFile('exception_handling', automatedTestsDirectory, flutterTestDirectory);
    });

    testUsingContext('TestAsyncUtils guarded function test', () async {
      Cache.flutterRoot = '../..';
      return _testFile('test_async_utils_guarded', automatedTestsDirectory, flutterTestDirectory);
    });

    testUsingContext('TestAsyncUtils unguarded function test', () async {
      Cache.flutterRoot = '../..';
      return _testFile('test_async_utils_unguarded', automatedTestsDirectory, flutterTestDirectory);
    });

    testUsingContext('Missing flutter_test dependency', () async {
      final String missingDependencyTests = fs.path.join('..', '..', 'dev', 'missing_dependency_tests');
      Cache.flutterRoot = '../..';
      return _testFile('trivial', missingDependencyTests, missingDependencyTests);
    });
  }, skip: io.Platform.isWindows); // TODO(goderbauer): enable when sky_shell is available
}

Future<Null> _testFile(String testName, String workingDirectory, String testDirectory) async {
  final String fullTestName = fs.path.join(testDirectory, '${testName}_test.dart');
  final File testFile = fs.file(fullTestName);
  expect(testFile.existsSync(), true);
  final String fullTestExpectation = fs.path.join(testDirectory, '${testName}_expectation.txt');
  final File expectationFile = fs.file(fullTestExpectation);
  expect(expectationFile.existsSync(), true);

  while (_testExclusionLock != null)
    await _testExclusionLock;

  ProcessResult exec;
  final Completer<Null> testExclusionCompleter = new Completer<Null>();
  _testExclusionLock = testExclusionCompleter.future;
  try {
    exec = await Process.run(
      fs.path.join(dartSdkPath, 'bin', 'dart'),
      <String>[
        fs.path.absolute(fs.path.join('bin', 'flutter_tools.dart')),
        'test',
        '--no-color',
        fullTestName,
      ],
      workingDirectory: workingDirectory,
    );
  } finally {
    _testExclusionLock = null;
    testExclusionCompleter.complete();
  }

  expect(exec.exitCode, isNonZero);
  final List<String> output = exec.stdout.split('\n');
  if (output.first == 'Waiting for another flutter command to release the startup lock...')
    output.removeAt(0);
  output.add('<<stderr>>');
  output.addAll(exec.stderr.split('\n'));
  final List<String> expectations = fs.file(fullTestExpectation).readAsLinesSync();
  bool allowSkip = false;
  int expectationLineNumber = 0;
  int outputLineNumber = 0;
  bool haveSeenStdErrMarker = false;
  while (expectationLineNumber < expectations.length) {
    expect(output, hasLength(greaterThan(outputLineNumber)));
    final String expectationLine = expectations[expectationLineNumber];
    final String outputLine = output[outputLineNumber];
    if (expectationLine == '<<skip until matching line>>') {
      allowSkip = true;
      expectationLineNumber += 1;
      continue;
    }
    if (allowSkip) {
      if (!new RegExp(expectationLine).hasMatch(outputLine)) {
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
