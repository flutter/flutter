// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

final Stopwatch _stopwatch = Stopwatch();

/// A wrapper around package:test's JSON reporter.
///
/// This class behaves similarly to the compact reporter, but suppresses all
/// output except for progress until the end of testing. In other words, errors,
/// [print] calls, and skipped test messages will not be printed during the run
/// of the suite.
///
/// It also processes the JSON data into a collection of [TestResult]s for any
/// other post processing needs, e.g. sending data to analytics.
class FlutterCompactFormatter {
  FlutterCompactFormatter() {
    _stopwatch.start();
  }

  /// Whether to use color escape codes in writing to stdout.
  final bool useColor = stdout.supportsAnsiEscapes;

  /// The terminal escape for green text, or the empty string if this is Windows
  /// or not outputting to a terminal.
  String get _green => useColor ? '\u001b[32m' : '';

  /// The terminal escape for red text, or the empty string if this is Windows
  /// or not outputting to a terminal.
  String get _red => useColor ? '\u001b[31m' : '';

  /// The terminal escape for yellow text, or the empty string if this is
  /// Windows or not outputting to a terminal.
  String get _yellow => useColor ? '\u001b[33m' : '';

  /// The terminal escape for gray text, or the empty string if this is
  /// Windows or not outputting to a terminal.
  String get _gray => useColor ? '\u001b[1;30m' : '';

  /// The terminal escape for bold text, or the empty string if this is
  /// Windows or not outputting to a terminal.
  String get _bold => useColor ? '\u001b[1m' : '';

  /// The terminal escape for removing test coloring, or the empty string if
  /// this is Windows or not outputting to a terminal.
  String get _noColor => useColor ? '\u001b[0m' : '';

  /// The terminal escape for clearing the line, or a carriage return if
  /// this is Windows or not outputting to a terminal.
  String get _clearLine => useColor ? '\x1b[2K\r' : '\r';

  final Map<int, TestResult> _tests = <int, TestResult>{};

  /// The test results from this run.
  Iterable<TestResult> get tests => _tests.values;

  /// The number of tests that were started.
  int started = 0;

  /// The number of test failures.
  int failures = 0;

  /// The number of skipped tests.
  int skips = 0;

  /// The number of successful tests.
  int successes = 0;

  /// Process a single line of JSON output from the JSON test reporter.
  ///
  /// Callers are responsible for splitting multiple lines before calling this
  /// method.
  TestResult processRawOutput(String raw) {
    assert(raw != null);
    // We might be getting messages from Flutter Tool about updating/building.
    if (!raw.startsWith('{')) {
      print(raw);
      return null;
    }
    final Map<String, dynamic> decoded = json.decode(raw) as Map<String, dynamic>;
    final TestResult originalResult = _tests[decoded['testID']];
    switch (decoded['type'] as String) {
      case 'done':
        stdout.write(_clearLine);
        stdout.write('$_bold${_stopwatch.elapsed}$_noColor ');
        stdout.writeln(
            '$_green+$successes $_yellow~$skips $_red-$failures:$_bold$_gray Done.$_noColor');
        break;
      case 'testStart':
        final Map<String, dynamic> testData = decoded['test'] as Map<String, dynamic>;
        if (testData['url'] == null) {
          started += 1;
          stdout.write(_clearLine);
          stdout.write('$_bold${_stopwatch.elapsed}$_noColor ');
          stdout.write(
              '$_green+$successes $_yellow~$skips $_red-$failures: $_gray${testData['name']}$_noColor');
          break;
        }
        _tests[testData['id'] as int] = TestResult(
          id: testData['id'] as int,
          name: testData['name'] as String,
          line: testData['root_line'] as int ?? testData['line'] as int,
          column: testData['root_column'] as int ?? testData['column'] as int,
          path: testData['root_url'] as String ?? testData['url'] as String,
          startTime: decoded['time'] as int,
        );
        break;
      case 'testDone':
        if (originalResult == null) {
          break;
        }
        originalResult.endTime = decoded['time'] as int;
        if (decoded['skipped'] == true) {
          skips += 1;
          originalResult.status = TestStatus.skipped;
        } else {
          if (decoded['result'] == 'success') {
            originalResult.status =TestStatus.succeeded;
            successes += 1;
          } else {
            originalResult.status = TestStatus.failed;
            failures += 1;
          }
        }
        break;
      case 'error':
        final String error = decoded['error'] as String;
        final String stackTrace = decoded['stackTrace'] as String;
        if (originalResult != null) {
          originalResult.errorMessage = error;
          originalResult.stackTrace = stackTrace;
        } else {
          if (error != null)
            stderr.writeln(error);
          if (stackTrace != null)
            stderr.writeln(stackTrace);
        }
        break;
      case 'print':
        if (originalResult != null) {
          originalResult.messages.add(decoded['message'] as String);
        }
        break;
      case 'group':
      case 'allSuites':
      case 'start':
      case 'suite':
      default:
        break;
    }
    return originalResult;
  }

  /// Print summary of test results.
  void finish() {
    final List<String> skipped = <String>[];
    final List<String> failed = <String>[];
    for (final TestResult result in _tests.values) {
      switch (result.status) {
        case TestStatus.started:
          failed.add('${_red}Unexpectedly failed to complete a test!');
          failed.add(result.toString() + _noColor);
          break;
        case TestStatus.skipped:
          skipped.add(
              '${_yellow}Skipped ${result.name} (${result.pathLineColumn}).$_noColor');
          break;
        case TestStatus.failed:
          failed.addAll(<String>[
            '$_bold${_red}Failed ${result.name} (${result.pathLineColumn}):',
            result.errorMessage,
            _noColor + _red,
            result.stackTrace,
          ]);
          failed.addAll(result.messages);
          failed.add(_noColor);
          break;
        case TestStatus.succeeded:
          break;
      }
    }
    skipped.forEach(print);
    failed.forEach(print);
    if (failed.isEmpty) {
      print('${_green}Completed, $successes test(s) passing ($skips skipped).$_noColor');
    } else {
      print('$_gray$failures test(s) failed.$_noColor');
    }
  }
}

/// The state of a test received from the JSON reporter.
enum TestStatus {
  /// Test execution has started.
  started,
  /// Test completed successfully.
  succeeded,
  /// Test failed.
  failed,
  /// Test was skipped.
  skipped,
}

/// The detailed status of a test run.
class TestResult {
  TestResult({
    @required this.id,
    @required this.name,
    @required this.line,
    @required this.column,
    @required this.path,
    @required this.startTime,
    this.status = TestStatus.started,
  })  : assert(id != null),
        assert(name != null),
        assert(line != null),
        assert(column != null),
        assert(path != null),
        assert(startTime != null),
        assert(status != null),
        messages = <String>[];

  /// The state of the test.
  TestStatus status;

  /// The internal ID of the test used by the JSON reporter.
  final int id;

  /// The name of the test, specified via the `test` method.
  final String name;

  /// The line number from the original file.
  final int line;

  /// The column from the original file.
  final int column;

  /// The path of the original test file.
  final String path;

  /// A friendly print out of the [path], [line], and [column] of the test.
  String get pathLineColumn => '$path:$line:$column';

  /// The start time of the test, in milliseconds relative to suite startup.
  final int startTime;

  /// The stdout of the test.
  final List<String> messages;

  /// The error message from the test, from an `expect`, an [Exception] or
  /// [Error].
  String errorMessage;

  /// The stacktrace from a test failure.
  String stackTrace;

  /// The time, in milliseconds relative to suite startup, that the test ended.
  int endTime;

  /// The total time, in milliseconds, that the test took.
  int get totalTime => (endTime ?? _stopwatch.elapsedMilliseconds) - startTime;

  @override
  String toString() => '{$runtimeType: {$id, $name, ${totalTime}ms, $pathLineColumn}}';
}
