import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

// Assumes that the flutter command is in `$PATH`.
const String _flutterBin = 'flutter';
const String _integrationResultsPrefix =
    'IntegrationTestWidgetsFlutterBinding test results:';
const String _failureExcerpt = 'Expected: <false>\\n  Actual: <true>';

void main() async {
  group('Integration binding result', () {
    test('when multiple tests pass', () async {
      final Map<String, dynamic> results =
          await _runTest('test/data/pass_test_script.dart');

      expect(
          results,
          equals({
            'passing test 1': 'success',
            'passing test 2': 'success',
          }));
    });

    test('when multiple tests fail', () async {
      final Map<String, dynamic> results =
          await _runTest('test/data/fail_test_script.dart');

      expect(results, hasLength(2));
      expect(
          results, containsPair('failing test 1', contains(_failureExcerpt)));
      expect(
          results, containsPair('failing test 2', contains(_failureExcerpt)));
    });

    test('when one test passes, then another fails', () async {
      final Map<String, dynamic> results =
          await _runTest('test/data/pass_then_fail_test_script.dart');

      expect(results, hasLength(2));
      expect(results, containsPair('passing test', equals('success')));
      expect(results, containsPair('failing test', contains(_failureExcerpt)));
    });
  });
}

/// Runs a test script and returns the [IntegrationTestWidgetsFlutterBinding.result].
///
/// [scriptPath] is relative to the package root.
Future<Map<String, dynamic>> _runTest(String scriptPath) async {
  final Process process =
      await Process.start(_flutterBin, ['test', '--machine', scriptPath]);

  /// In the test [tearDownAll] block, the test results are encoded into JSON and
  /// are printed with the [_integrationResultsPrefix] prefix.
  ///
  /// See the following for the test event spec which we parse the printed lines
  /// out of: https://github.com/dart-lang/test/blob/master/pkgs/test/doc/json_reporter.md
  final String testResults = (await process.stdout
          .transform(utf8.decoder)
          .expand((String text) => text.split('\n'))
          .map((String line) {
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

  return jsonDecode(testResults);
}
