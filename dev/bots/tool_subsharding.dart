// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

class TestSpecs {
  TestSpecs({required this.path, required this.startTime});

  final String path;
  int startTime;
  int? _endTime;

  int get milliseconds => endTime - startTime;

  set endTime(int value) {
    _endTime = value;
  }

  int get endTime => _endTime ?? 0;

  String toJson() {
    return json.encode(<String, String>{'path': path, 'runtime': milliseconds.toString()});
  }
}

/// The parsed result of a single test case as reported by the `dart test`
/// JSON file reporter.
class TestResult {
  TestResult({required this.name, required this.suiteID, required this.startTime});

  /// The full name of the test (including any group prefixes).
  final String name;

  /// The id of the suite (test file) that this test belongs to.
  final int suiteID;

  /// The time (in milliseconds, relative to the start of the run) at which the
  /// test started.
  final int startTime;

  /// The time (in milliseconds, relative to the start of the run) at which the
  /// test finished, or null if it never finished.
  int? endTime;

  /// The raw result reported by `dart test`: one of `success`, `failure`, or
  /// `error`.
  String result = 'success';

  /// Whether the test was skipped.
  bool skipped = false;

  /// Whether the test is a "hidden" bookkeeping test (for example, the
  /// synthetic "loading <suite>" test that `dart test` emits for each suite).
  ///
  /// Hidden tests are excluded from the reported results.
  bool hidden = false;

  /// The duration of the test, in seconds.
  double get seconds => ((endTime ?? startTime) - startTime) / 1000.0;

  /// Maps the `dart test` [result]/[skipped] to a `PASS`/`FAIL`/`SKIP` result
  /// type.
  String get actual => switch (this) {
    TestResult(skipped: true) => 'SKIP',
    TestResult(result: 'success') => 'PASS',
    _ => 'FAIL',
  };

  /// The expected result type for this test.
  ///
  /// `dart test` has no concept of expected failures, so every non-skipped
  /// test is expected to pass.
  String get expected => skipped ? 'SKIP' : 'PASS';
}

class TestFileReporterResults {
  TestFileReporterResults._({
    required this.allTestSpecs,
    required this.testResults,
    required this.hasFailedTests,
    required this.errors,
  });

  /// Intended to parse the output file of `dart test --file-reporter json:file_name
  factory TestFileReporterResults.fromFile(File metrics) {
    if (!metrics.existsSync()) {
      throw Exception('${metrics.path} does not exist');
    }

    final testSpecs = <int, TestSpecs>{};
    final testResults = <int, TestResult>{};
    var hasFailedTests = true;
    final errors = <String>[];

    for (final String metric in metrics.readAsLinesSync()) {
      /// Using print within a test adds the printed content to the json file report
      /// as \u0000 making the file parsing step fail. The content of the json file
      /// is expected to be a json dictionary per line and the following line removes
      /// all the additional content at the beginning of the line until it finds the
      /// first opening curly bracket.
      // TODO(godofredoc): remove when https://github.com/flutter/flutter/issues/145553 is fixed.
      final String sanitizedMetric = metric.replaceAll(RegExp(r'$.*{'), '{');
      final entry = json.decode(sanitizedMetric) as Map<String, Object?>;
      switch (entry) {
        case {'suite': final Map<String, Object?> suite, 'time': final int time}:
          addTestSpec(suite, time, testSpecs);
        case {'type': 'group', 'group': {'suiteID': final int suiteID}, 'time': final int time}
            when testSpecs.containsKey(suiteID):
          addMetricDone(suiteID, time, testSpecs);
        case {'type': 'testStart', 'test': final Map<String, Object?> test, 'time': final int time}:
          addTestStart(test, time, testResults);
        case {'type': 'testDone'}:
          addTestDone(entry, testResults);
        case {'error': final Object? error}:
          final String stackTrace = entry['stackTrace'] as String? ?? '';
          errors.add('$error\n $stackTrace');
        case {'success': true}:
          hasFailedTests = false;
      }
    }

    return TestFileReporterResults._(
      allTestSpecs: testSpecs,
      testResults: testResults,
      hasFailedTests: hasFailedTests,
      errors: errors,
    );
  }

  final Map<int, TestSpecs> allTestSpecs;
  final Map<int, TestResult> testResults;
  final bool hasFailedTests;
  final List<String> errors;

  static void addTestSpec(Map<String, Object?> suite, int time, Map<int, TestSpecs> allTestSpecs) {
    if (suite case {'id': final int id, 'path': final String path}) {
      allTestSpecs[id] = TestSpecs(path: path, startTime: time);
    }
  }

  static void addMetricDone(int suiteID, int time, Map<int, TestSpecs> allTestSpecs) {
    allTestSpecs[suiteID]?.endTime = time;
  }

  static bool isMetricDone(Map<String, Object?> entry, Map<int, TestSpecs> allTestSpecs) =>
      switch (entry) {
        {'type': 'group', 'group': {'suiteID': final int suiteID}} => allTestSpecs.containsKey(
          suiteID,
        ),
        _ => false,
      };

  static void addTestStart(Map<String, Object?> test, int time, Map<int, TestResult> testResults) {
    if (test case {'id': final int id, 'name': final String name, 'suiteID': final int suiteID}) {
      testResults[id] = TestResult(name: name, suiteID: suiteID, startTime: time);
    }
  }

  static void addTestDone(Map<String, Object?> entry, Map<int, TestResult> testResults) {
    if (entry case {'testID': final int testID, 'time': final int time}) {
      if (testResults[testID] case final testResult?) {
        testResult
          ..endTime = time
          ..result = entry['result'] as String? ?? testResult.result
          ..skipped = entry['skipped'] as bool? ?? false
          ..hidden = entry['hidden'] as bool? ?? false;
      }
    }
  }
}
