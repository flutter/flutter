import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

final Stopwatch _stopwatch = Stopwatch();

class FlutterCompactFormatter {
  FlutterCompactFormatter() {
    _stopwatch.start();
  }

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

  /// The termianl escape for clearing the line, or a carriage return if
  /// this is Windows or not outputting to a termianl.
  String get _clearLine => useColor ? '\x1b[2K\r' : '\r';

  final Map<int, TestResult> tests = <int, TestResult>{};
  int started = 0;
  int failures = 0;
  int skips = 0;
  int successes = 0;

  TestResult processRawOutput(String raw) {
    // We might be getting messages from Flutter Tool about updating/building.
    if (!raw.startsWith('{')) {
      print(raw);
      return null;
    }
    final Map<String, dynamic> decoded = json.decode(raw);
    final TestResult originalResult = tests[decoded['testID']];
    switch (decoded['type']) {
      case 'done':
        stdout.write(_clearLine);
        stdout.write('$_bold${_stopwatch.elapsed}$_noColor ');
        stdout.writeln(
            '$_green+$successes $_yellow~$skips $_red-$failures:$_bold$_gray Done.$_noColor');
        break;
      case 'testStart':
        final Map<String, dynamic> testData = decoded['test'];
        if (testData['url'] == null) {
          started += 1;
          stdout.write(_clearLine);
          stdout.write('$_bold${_stopwatch.elapsed}$_noColor ');
          stdout.write(
              '$_green+$successes $_yellow~$skips $_red-$failures: $_gray${testData['name']}$_noColor');
          break;
        }
        tests[testData['id']] = TestResult(
          id: testData['id'],
          name: testData['name'],
          line: testData['root_line'] ?? testData['line'],
          column: testData['root_column'] ?? testData['column'],
          path: testData['root_url'] ?? testData['url'],
          startTime: decoded['time'],
        );
        break;
      case 'testDone':
        if (originalResult == null) {
          break;
        }
        originalResult.endTime = decoded['time'];
        if (decoded['skipped'] == true) {
          skips += 1;
          originalResult.status = TestStatus.skipped;
        } else {
          if (decoded['result'] == 'success') {
            tests.remove(originalResult.id);
            // originalResult.status = TestStatus.succeeded;
            successes += 1;
          } else {
            originalResult.status = TestStatus.failed;
            failures += 1;
          }
        }
        break;
      case 'error':
        if (originalResult != null) {
          originalResult.errorMessage = decoded['error'];
          originalResult.stackTrace = decoded['stackTrace'];
        }
        break;
      case 'print':
        if (originalResult != null) {
          originalResult.messages.add(decoded['message']);
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

  void finish() {
    final List<String> skipped = <String>[];
    final List<String> failed = <String>[];
    for (TestResult result in tests.values) {
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
      print(
          '${_green}Completed, $successes test(s) passing ($skips skipped).$_noColor');
    } else {
      print('$_gray$failures test(s) failed.$_noColor');
    }
  }
}

enum TestStatus {
  started,
  succeeded,
  failed,
  skipped,
}

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

  TestStatus status;
  final int id;
  final String name;
  final int line;
  final int column;
  final String path;
  String get pathLineColumn => '$path:$line:$column';
  final int startTime;
  final List<String> messages;
  String errorMessage;
  String stackTrace;

  int endTime;
  int get totalTime => (endTime ?? _stopwatch.elapsedMilliseconds) - startTime;

  @override
  String toString() =>
      '{$runtimeType: {$id, $name, ${totalTime}ms, $pathLineColumn}}';
}
