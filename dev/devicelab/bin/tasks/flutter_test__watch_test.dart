// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test runs `flutter test --watch` on the `trivial_widget_test.dart`
// three times.
//
// The intial run should pass.
//
// We then modify the source file, and the second time the test should fail.
//
// Before the third time, a change is made to test file, which should cause the
// third run to again pass.
//
// We then reset the files to their initial state.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

const String rerunLine = "Press 'r' to rerun your tests, 'q' to quit";

class TestRunnerProcess {
  TestRunnerProcess(this._process) {
    _waitingForLine = rerunLine;
    _completer = Completer<List<String>>();
    _process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
      _stdout.add(line);
      if (_waitingForLine != null && line.contains(_waitingForLine)) {
        print('Found line "$_waitingForLine", returning ${_stdout.length} lines');
        _completer.complete(_stdout.map((String a) => a).toList());
        _stdout.clear();
        _waitingForLine = null;
      }
    });
  }

  final List<String> _stdout = <String>[]; // Collected lines
  String _waitingForLine; // Substring of line currently waiting for
  final Process _process; // Underlying system process
  Completer<List<String>> _completer; // Used to control execution flow

  Future<List<String>> sendChar(String char) {
    _waitingForLine = rerunLine;
    _completer = Completer<List<String>>();
    _process.stdin.write(char[0]);
    return _completer.future;
  }

  Future<List<String>> waitForLine(String line) {
    _waitingForLine = line;
    _completer = Completer<List<String>>();
    return _completer.future;
  }
}

Future<TestRunnerProcess> startTestRunner() async {
  final Process process = await startProcess(
    path.join(flutterDirectory.path, 'bin', 'flutter'),
    <String>[
      'test',
      '-v',
      '--watch',
      path.join('flutter_test', 'trivial_widget_test.dart')
    ],
    workingDirectory: path.join(flutterDirectory.path, 'dev', 'automated_tests'),
  );

  final TestRunnerProcess testRunner = TestRunnerProcess(process);
  await testRunner.waitForLine(rerunLine);
  return testRunner;
}

// This will go through the `actual` list in order, looking for matches to the
// `first` element of the expected list(contains), removing that element if found.
// If at the end of the actual list, expected has any elements left, it is an
// error.
TaskResult expectMatchesInOrder(List<String> actual, List<String> expected) {
  if (expected.isEmpty) {
    return TaskResult.success(<String, dynamic>{});
  }
  for (String line in actual) {
    if (line.contains(expected.first)) {
      expected.removeAt(0);
      if (expected.isEmpty) {
        break;
      }
    }
  }

  if (expected.isNotEmpty) {
    return TaskResult.failure(
      "Could not find '${expected.first}' in:\n${actual.join('\n')}"
    );
  }

  return TaskResult.success(<String, dynamic>{});
}

Future<TaskResult> runTest(TestRunnerProcess testRunner, {
  String description = 'A test',
  List<String> stdoutExpected = const <String>[],
}) async {
  print((description + ' ').padRight(80, '='));
  final List<String> testRunOutput = await testRunner.sendChar('r');
  return expectMatchesInOrder(testRunOutput, stdoutExpected);
}

void main() {
  task(() async {
    final File nodeSourceFile = File(path.join(
      flutterDirectory.path, 'packages', 'flutter', 'lib', 'src', 'foundation', 'node.dart',
    ));
    final File testSourceFile = File(path.join(
      flutterDirectory.path, 'dev', 'automated_tests', 'flutter_test', 'trivial_widget_test.dart',
    ));

    final String originalSource = await nodeSourceFile.readAsString();
    final String testOriginalSource = await testSourceFile.readAsString();

    try {
      final TestRunnerProcess testRunner = await startTestRunner();
      TaskResult result;

      result = await runTest(testRunner,
        description: 'Rerun with no change',
        stdoutExpected: <String>[
          'A trivial widget test',
          'All tests passed!',
          "Press 'r' to rerun",
        ]
      );

      if (!result.succeeded) {
        return result;
      }

      await nodeSourceFile.writeAsString( // only change implementation
        originalSource
          .replaceAll('_owner', '_xyzzy')
      );
      result = await runTest(testRunner,
        description: 'Rerun with implementation change to source',
        stdoutExpected: <String>[
          'Recompiling test files...',
          'A trivial widget test',
          'All tests passed!',
          "Press 'r' to rerun",
        ],
      );

      if (!result.succeeded) {
        return result;
      }

      await nodeSourceFile.writeAsString( // change interface as well
        originalSource
          .replaceAll('_owner', '_xyzzy')
          .replaceAll('owner', '_owner')
          .replaceAll('_xyzzy', 'owner')
      );
      result = await runTest(testRunner,
        description: 'Rerun with interface changed in source',
        stdoutExpected: <String>[
          'Recompiling test files...',
          'A trivial widget test',
          'All tests passed!',
          "Press 'r' to rerun",
        ],
      );

      if (!result.succeeded) {
        return result;
      }

      // Test that introducing an error to the test source, creates a failure.
      final String patchedTestSource =
          testOriginalSource
          .replaceAll(
            '(WidgetTester tester) async {}',
            '''
(WidgetTester tester) async {
  expect(true, false);
}''');
      final Future<List<String>> invalidateFuture = testRunner.waitForLine('Will invalidate');
      await testSourceFile.writeAsString(patchedTestSource);
      final List<String> invalidateOutput = await invalidateFuture;
      final TaskResult invalidateResult = expectMatchesInOrder(invalidateOutput, <String>['Will invalidate']);

      if (!invalidateResult.succeeded) {
        return invalidateResult;
      }

      result = await runTest(testRunner,
        description: 'Rerun with error in test file ',
        stdoutExpected: <String>[
          'Recompiling test files...',
          'Expected: <false>',
          'Actual: <true>',
          'Some tests failed.',
        ],
      );

      return result;
    } finally {
      await nodeSourceFile.writeAsString(originalSource);
      await testSourceFile.writeAsString(testOriginalSource);
    }
  });
}