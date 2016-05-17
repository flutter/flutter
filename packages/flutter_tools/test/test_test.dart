// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/sdk.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/context.dart';

// This test depends on some files in ///dev/automated_tests/flutter_test/*

void main() {
  group('test', () {
    testUsingContext('TestAsyncUtils guarded function test', () async {
      Cache.flutterRoot = '../..';
      return _testFile('test_async_utils_guarded');
    });
    testUsingContext('TestAsyncUtils unguarded function test', () async {
      Cache.flutterRoot = '../..';
      return _testFile('test_async_utils_unguarded');
    });
  }, timeout: new Timeout(const Duration(seconds: 5)));
}

Future<Null> _testFile(String testName) async {
  final String manualTestsDirectory = path.join('..', '..', 'dev', 'automated_tests');
  final String fullTestName = path.join(manualTestsDirectory, 'flutter_test', '${testName}_test.dart');
  final File testFile = new File(fullTestName);
  expect(testFile.existsSync(), true);
  final String fullTestExpectation = path.join(manualTestsDirectory, 'flutter_test', '${testName}_expectation.txt');
  final File expectationFile = new File(fullTestExpectation);
  expect(expectationFile.existsSync(), true);
  final ProcessResult exec = await Process.run(
    path.join(dartSdkPath, 'bin', 'dart'),
    <String>[
      path.absolute(path.join('bin', 'flutter_tools.dart')),
      'test',
      fullTestName
    ],
    workingDirectory: manualTestsDirectory
  );
  expect(exec.exitCode, 0);
  final List<String> output = exec.stdout.split('\n');
  final List<String> expectations = new File(fullTestExpectation).readAsLinesSync();
  bool allowSkip = false;
  int expectationLineNumber = 0;
  int outputLineNumber = 0;
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
    expect(outputLine, matches(expectationLine));
    expectationLineNumber += 1;
    outputLineNumber += 1;
  }
  expect(allowSkip, isFalse);
  expect(exec.stderr, '');
}
