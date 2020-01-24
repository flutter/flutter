// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;

import 'package:meta/meta.dart';

/// This class knows how to format benchmark results for machine and human
/// consumption.
///

/// Example:
///
///     BenchmarkResultPrinter printer = new BenchmarkResultPrinter();
///     printer.add(
///       description: 'Average frame time',
///       value: averageFrameTime,
///       unit: 'ms',
///       name: 'average_frame_time',
///     );
///     printer.printToStdout();
///
class BenchmarkResultPrinter {

  final List<_BenchmarkResult> _results = <_BenchmarkResult>[];

  /// Adds a benchmark result to the list of results.
  ///
  /// [description] is a human-readable description of the result. [value] is a
  /// result value. [unit] is the unit of measurement, such as "ms", "km", "h".
  /// [name] is a computer-readable name of the result used as a key in the JSON
  /// serialization of the results.
  void addResult({ @required String description, @required double value, @required String unit, @required String name }) {
    _results.add(_BenchmarkResult(description, value, unit, name));
  }

  /// Prints the results added via [addResult] to standard output, once as JSON
  /// for computer consumption and once formatted as plain text for humans.
  void printToStdout() {
    // IMPORTANT: keep these values in sync with dev/devicelab/bin/tasks/microbenchmarks.dart
    const String jsonStart = '================ RESULTS ================';
    const String jsonEnd = '================ FORMATTED ==============';
    const String jsonPrefix = ':::JSON:::';

    print(jsonStart);
    print('$jsonPrefix ${_printJson()}');
    print(jsonEnd);
    print(_printPlainText());
  }

  String _printJson() {
    final Map<String, double> results = <String, double>{};
    for (final _BenchmarkResult result in _results) {
      results[result.name] = result.value;
    }
    return json.encode(results);
  }

  String _printPlainText() {
    final StringBuffer buf = StringBuffer();
    for (final _BenchmarkResult result in _results) {
      buf.writeln('${result.description}: ${result.value.toStringAsFixed(1)} ${result.unit}');
    }
    return buf.toString();
  }
}

class _BenchmarkResult {
  _BenchmarkResult(this.description, this.value, this.unit, this.name);

  /// Human-readable description of the result, e.g. "Average frame time".
  final String description;

  /// Result value that in agreement with [unit].
  final double value;

  /// Unit of measurement that is in agreement with [value].
  final String unit;

  /// Computer-readable name of the result.
  final String name;
}
