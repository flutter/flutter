import 'dart:convert';
import 'dart:io';

import 'package:process_run/src/lines_utils.dart';

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
  Iterable<String> get outLines => _outStringToLines(this.stdout.toString());

  /// Line lists
  Iterable<String> get errLines => _outStringToLines(this.stderr.toString());
}

/// Process helper.
extension ProcessRunProcessExt on Process {
  /// Out lines stream
  Stream<String> get outLines => shellStreamLines(this.stdout);

  /// Err lines stream
  Stream<String> get errLines => shellStreamLines(this.stderr);
}
