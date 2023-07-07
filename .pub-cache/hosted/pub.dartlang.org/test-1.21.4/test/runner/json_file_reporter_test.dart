// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_core/src/util/exit_codes.dart' as exit_codes;
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';
import 'json_reporter_utils.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('runs successful tests with a stdout reporter and file reporter', () {
    return _expectReports('''
      test('success 1', () {});
      test('success 2', () {});
      test('success 3', () {});
    ''', '''
      +0: success 1
      +1: success 2
      +2: success 3
      +3: All tests passed!''', [
      [
        suiteJson(0),
        testStartJson(1, 'loading test.dart', groupIDs: []),
        testDoneJson(1, hidden: true),
      ],
      [
        groupJson(2, testCount: 3),
        testStartJson(3, 'success 1', line: 6, column: 7),
        testDoneJson(3),
        testStartJson(4, 'success 2', line: 7, column: 7),
        testDoneJson(4),
        testStartJson(5, 'success 3', line: 8, column: 7),
        testDoneJson(5),
      ]
    ], doneJson());
  });

  test('runs failing tests with a stdout reporter and file reporter', () {
    return _expectReports('''
      test('failure 1', () => throw new TestFailure('oh no'));
      test('failure 2', () => throw new TestFailure('oh no'));
      test('failure 3', () => throw new TestFailure('oh no'));
    ''', '''
      +0: failure 1
      +0 -1: failure 1 [E]
        oh no
        test.dart 6:31  main.<fn>

      +0 -1: failure 2
      +0 -2: failure 2 [E]
        oh no
        test.dart 7:31  main.<fn>

      +0 -2: failure 3
      +0 -3: failure 3 [E]
        oh no
        test.dart 8:31  main.<fn>

      +0 -3: Some tests failed.''', [
      [
        suiteJson(0),
        testStartJson(1, 'loading test.dart', groupIDs: []),
        testDoneJson(1, hidden: true),
      ],
      [
        groupJson(2, testCount: 3),
        testStartJson(3, 'failure 1', line: 6, column: 7),
        errorJson(3, 'oh no', isFailure: true),
        testDoneJson(3, result: 'failure'),
        testStartJson(4, 'failure 2', line: 7, column: 7),
        errorJson(4, 'oh no', isFailure: true),
        testDoneJson(4, result: 'failure'),
        testStartJson(5, 'failure 3', line: 8, column: 7),
        errorJson(5, 'oh no', isFailure: true),
        testDoneJson(5, result: 'failure'),
      ]
    ], doneJson(success: false));
  });

  group('reports an error if --file-reporter', () {
    test('is not in the form <reporter>:<filepath>', () async {
      var test = await runTest(['--file-reporter=json']);
      expect(test.stderr,
          emits(contains('option must be in the form <reporter>:<filepath>')));
      await test.shouldExit(exit_codes.usage);
    });

    test('targets a non-existent reporter', () async {
      var test = await runTest(['--file-reporter=nope:output.txt']);
      expect(
          test.stderr, emits(contains('"nope" is not a supported reporter')));
      await test.shouldExit(exit_codes.usage);
    });
  });
}

Future<void> _expectReports(
    String tests,
    String stdoutExpected,
    List<List<Object /*Map|Matcher*/ >> jsonFileExpected,
    Map<Object, Object> jsonFileDone,
    {List<String> args = const []}) async {
  await d.file('test.dart', '''
    import 'dart:async';

    import 'package:test/test.dart';

    void main() {
$tests
    }
  ''').create();

  var test = await runTest(['test.dart', '--chain-stack-traces', ...args],
      // Write to a file within a dir that doesn't yet exist to verify that the
      // file is created recursively.
      fileReporter: 'json:reports/tests.json');
  await test.shouldExit();

  // ---- stdout reporter verification ----
  var stdoutLines = await test.stdoutStream().toList();

  // Remove excess trailing whitespace and trim off timestamps.
  var actual = stdoutLines.map((line) {
    if (line.startsWith('  ') || line.isEmpty) return line.trimRight();
    return line.trim().replaceFirst(RegExp('^[0-9]{2}:[0-9]{2} '), '');
  }).join('\n');

  // Un-indent the expected string.
  var indentation = stdoutExpected.indexOf(RegExp('[^ ]'));
  stdoutExpected = stdoutExpected.split('\n').map((line) {
    if (line.isEmpty) return line;
    return line.substring(indentation);
  }).join('\n');

  expect(actual, equals(stdoutExpected));

  // ---- file reporter verification ----
  var fileOutputLines =
      File(p.join(d.sandbox, 'reports', 'tests.json')).readAsLinesSync();
  await expectJsonReport(
      fileOutputLines, test.pid, jsonFileExpected, jsonFileDone);
}
