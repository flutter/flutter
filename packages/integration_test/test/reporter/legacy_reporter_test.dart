// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

// Assumes that the flutter command is in `$PATH`.
const String _flutterBin = 'flutter';
const String _integrationResultsPrefix =
    'IntegrationTestWidgetsFlutterBinding test results:';

Future<void> main() async {
  test('When multiple tests pass', () async {
    final Map<String, dynamic> results =
        await _runTest('test/reporter/data/pass_test_script.dart');

    expect(results, hasLength(2));
    expect(results, containsPair('Passing test 1', isSuccess));
    expect(results, containsPair('Passing test 2', isSuccess));
  });

  test('When multiple tests fail', () async {
    final Map<String, dynamic> results =
        await _runTest('test/reporter/data/fail_test_script.dart');

    expect(results, hasLength(2));
    expect(results, containsPair('Failing test 1', isSerializedFailure));
    expect(results, containsPair('Failing test 2', isSerializedFailure));
  });

  test('When one test passes, then another fails', () async {
    final Map<String, dynamic> results =
        await _runTest('test/reporter/data/pass_then_fail_test_script.dart');

    expect(results, hasLength(2));
    expect(results, containsPair('Passing test', isSuccess));
    expect(results, containsPair('Failing test', isSerializedFailure));
  });
}

/// Runs a test script and returns the [IntegrationTestWidgetsFlutterBinding.result].
///
/// [scriptPath] is relative to the package root.
Future<Map<String, dynamic>> _runTest(String scriptPath) async {
  final Process process =
      await Process.start(_flutterBin, <String>['test', '--machine', scriptPath]);

  /// In the test [tearDownAll] block, the test results are encoded into JSON and
  /// are printed with the [_integrationResultsPrefix] prefix.
  ///
  /// See the following for the test event spec which we parse the printed lines
  /// out of: https://github.com/dart-lang/test/blob/master/pkgs/test/doc/json_reporter.md
  final String testResults = (await process.stdout
          .transform(utf8.decoder)
          .expand((String text) => text.split('\n'))
          .map<dynamic>((String line) {
            try {
              return jsonDecode(line);
            } on FormatException {
              // Only interested in test events which are JSON.
            }
          })
          .where((dynamic testEvent) =>
              testEvent != null && testEvent['type'] == 'print')
          .map((dynamic printEvent) => printEvent['message'] as String)
          .firstWhere((String message) =>
              message.startsWith(_integrationResultsPrefix)))
      .replaceAll(_integrationResultsPrefix, '');

  return jsonDecode(testResults) as Map<String, dynamic>;
}
