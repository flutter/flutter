import 'dart:convert';

import 'package:process_run/src/shell_common.dart';

import 'lines_utils.dart';

/// run response helper.
extension ProcessRunProcessResultsExt on List<ProcessResult> {
  Iterable<String> _outLinesToLines(Iterable<Iterable<String>> out) =>
      out.expand((lines) => lines);

  /// Join the out lines for a quick string access.
  String get outText => outLines.join('\n');

  /// Join the out lines for a quick string access.
  String get errText => errLines.join('\n');

  /// Out line lists
  Iterable<String> get outLines =>
      _outLinesToLines(map((result) => result.outLines));

  /// Line lists
  Iterable<String> get errLines =>
      _outLinesToLines(map((result) => result.errLines));
}

/// run response helper.
extension ProcessRunProcessResultExt on ProcessResult {
  Iterable<String> _outStringToLines(String out) => LineSplitter.split(out);

  /// Join the out lines for a quick string access.
  String get outText => outLines.join('\n');

  /// Join the out lines for a quick string access.
  String get errText => errLines.join('\n');

  /// Out line lists
  Iterable<String> get outLines => _outStringToLines(stdout.toString());

  /// Line lists
  Iterable<String> get errLines => _outStringToLines(stderr.toString());
}

/// Process helper.
extension ProcessRunProcessExt on Process {
  /// Out lines stream
  Stream<String> get outLines => shellStreamLines(stdout);

  /// Err lines stream
  Stream<String> get errLines => shellStreamLines(stderr);
}
