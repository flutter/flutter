// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import '../convert.dart';
import '../globals.dart' as globals;

/// A test reporter that displays compact progress and prints a summary of
/// failed tests at the end.
///
/// This reporter processes JSON output from package:test's JSON reporter,
/// displays test progress in a compact format (similar to the default compact
/// reporter), and collects failed test names to print a summary at the end.
///
/// Usage:
///   flutter test --reporter=summary
class SummaryReporter {
  SummaryReporter({
    required this.supportsColor,
    required this.stdout,
  });

  final bool supportsColor;
  final io.Stdout stdout;

  final Map<int, _TestInfo> _tests = <int, _TestInfo>{};
  final Map<int, String> _suites = <int, String>{};
  final List<_FailedTest> _failedTests = <_FailedTest>[];
  final Stopwatch _stopwatch = Stopwatch();

  int _passed = 0;
  int _skipped = 0;
  int _failed = 0;
  String _currentTestName = '';
  bool _lastLineWasProgress = false;

  /// Process a single line of JSON output from the test runner.
  void handleLine(String line) {
    if (line.trim().isEmpty) {
      return;
    }

    try {
      final dynamic event = json.decode(line);
      if (event is! Map<String, dynamic>) {
        _printLine(line);
        return;
      }
      _handleEvent(event);
    } on FormatException {
      _printLine(line);
    }
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;

    switch (type) {
      case 'start':
        _stopwatch.start();
      case 'suite':
        _handleSuite(event);
      case 'testStart':
        _handleTestStart(event);
      case 'testDone':
        _handleTestDone(event);
      case 'error':
        _handleError(event);
      case 'print':
        _handlePrint(event);
      case 'done':
        _handleDone(event);
    }
  }

  void _handleSuite(Map<String, dynamic> event) {
    final dynamic suite = event['suite'];
    if (suite is! Map<String, dynamic>) {
      return;
    }

    final id = suite['id'] as int?;
    final path = suite['path'] as String?;

    if (id != null && path != null) {
      _suites[id] = path;
    }
  }

  void _handleTestStart(Map<String, dynamic> event) {
    final dynamic test = event['test'];
    if (test is! Map<String, dynamic>) {
      return;
    }

    final id = test['id'] as int?;
    final name = test['name'] as String?;
    final suiteId = test['suiteID'] as int?;

    if (id != null && name != null) {
      _tests[id] = _TestInfo(name: name, suiteId: suiteId);
      _currentTestName = name;
      _printProgress();
    }
  }

  void _handleTestDone(Map<String, dynamic> event) {
    final testId = event['testID'] as int?;
    final result = event['result'] as String?;
    final bool skipped = event['skipped'] as bool? ?? false;
    final bool hidden = event['hidden'] as bool? ?? false;

    if (testId == null) {
      return;
    }

    final _TestInfo? testInfo = _tests[testId];
    if (testInfo == null) {
      return;
    }

    // Don't count hidden tests (like setUpAll/tearDownAll)
    if (hidden) {
      return;
    }

    if (skipped) {
      _skipped++;
    } else if (result == 'success') {
      _passed++;
    } else if (result == 'failure' || result == 'error') {
      _failed++;
      final String? suitePath = testInfo.suiteId != null ? _suites[testInfo.suiteId] : null;
      _failedTests.add(_FailedTest(name: testInfo.name, suitePath: suitePath));
    }

    _printProgress();
  }

  void _handleError(Map<String, dynamic> event) {
    final error = event['error'] as String?;
    final stackTrace = event['stackTrace'] as String?;

    if (error != null) {
      if (_lastLineWasProgress) {
        _clearLine();
      }
      _printLine('');
      _printLine(error);
      if (stackTrace != null) {
        _printLine(stackTrace);
      }
      _lastLineWasProgress = false;
    }
  }

  void _handlePrint(Map<String, dynamic> event) {
    final message = event['message'] as String?;
    if (message != null) {
      if (_lastLineWasProgress) {
        _clearLine();
      }
      _printLine(message);
      _lastLineWasProgress = false;
    }
  }

  void _handleDone(Map<String, dynamic> event) {
    _stopwatch.stop();

    final bool success = event['success'] as bool? ?? false;

    if (_lastLineWasProgress) {
      _clearLine();
    }

    if (success) {
      _printFinalStatus('All tests passed!');
    } else {
      _printFinalStatus('Some tests failed.', isFailure: true);
      _printFailureSummary();
    }
  }

  void _printProgress() {
    final buffer = StringBuffer();
    final Duration elapsed = _stopwatch.elapsed;
    final String minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final String seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    buffer.write('$minutes:$seconds ');
    buffer.write('$_green+$_passed$_reset');

    if (_skipped > 0) {
      buffer.write(' $_yellow~$_skipped$_reset');
    }

    if (_failed > 0) {
      buffer.write(' $_red-$_failed$_reset');
    }

    buffer.write(': ');
    buffer.write(_currentTestName);

    final line = buffer.toString();
    final String paddedLine = line.padRight(_terminalWidth);
    stdout.write('\r$paddedLine');
    _lastLineWasProgress = true;
  }

  void _printFinalStatus(String message, {bool isFailure = false}) {
    final buffer = StringBuffer();
    final Duration elapsed = _stopwatch.elapsed;
    final String minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final String seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    buffer.write('$minutes:$seconds ');
    buffer.write('$_green+$_passed$_reset');

    if (_skipped > 0) {
      buffer.write(' $_yellow~$_skipped$_reset');
    }

    if (_failed > 0) {
      buffer.write(' $_red-$_failed$_reset');
    }

    buffer.write(': ');

    if (isFailure) {
      buffer.write('$_red$message$_reset');
    } else {
      buffer.write(message);
    }

    _printLine(buffer.toString());
  }

  void _printFailureSummary() {
    if (_failedTests.isEmpty) {
      return;
    }

    _printLine('');
    _printLine('${_red}Failing tests:$_reset');
    for (final _FailedTest test in _failedTests) {
      if (test.suitePath != null) {
        _printLine('  ${test.suitePath}: ${test.name}');
      } else {
        _printLine('  ${test.name}');
      }
    }
  }

  void _printLine(String message) {
    globals.printStatus(message);
    _lastLineWasProgress = false;
  }

  void _clearLine() {
    stdout.write('\r${' ' * _terminalWidth}\r');
  }

  int get _terminalWidth {
    try {
      return stdout.terminalColumns;
    } on io.StdoutException {
      return 80;
    }
  }

  String get _green => supportsColor ? '\x1B[32m' : '';
  String get _red => supportsColor ? '\x1B[31m' : '';
  String get _yellow => supportsColor ? '\x1B[33m' : '';
  String get _reset => supportsColor ? '\x1B[0m' : '';
}

class _TestInfo {
  _TestInfo({required this.name, this.suiteId});

  final String name;
  final int? suiteId;
}

class _FailedTest {
  _FailedTest({required this.name, this.suitePath});

  final String name;
  final String? suitePath;
}
