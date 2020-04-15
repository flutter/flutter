// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:meta/meta.dart';

enum FieldJustification { LEFT, RIGHT, CENTER }

/// Collects data from an A/B test and produces a summary for human evaluation.
///
/// See [printSummary] for more.
class ABTest {
  final Map<String, List<double>> _aResults = <String, List<double>>{};
  final Map<String, List<double>> _bResults = <String, List<double>>{};

  /// Adds the result of a single A run of the benchmark.
  ///
  /// The result may contain multiple score keys.
  ///
  /// [result] is expected to be a serialization of [TaskResult].
  void addAResult(Map<String, dynamic> result) {
    _addResult(result, _aResults);
  }

  /// Adds the result of a single B run of the benchmark.
  ///
  /// The result may contain multiple score keys.
  ///
  /// [result] is expected to be a serialization of [TaskResult].
  void addBResult(Map<String, dynamic> result) {
    _addResult(result, _bResults);
  }

  static void updateColumnLengths(List<int> lengths, List<String> results) {
    for (int column = 0; column < lengths.length; column++) {
      if (results[column] != null) {
        lengths[column] = math.max(lengths[column], results[column].length);
      }
    }
  }

  static void formatResult(StringBuffer buffer,
                           List<int> lengths,
                           List<FieldJustification> aligns,
                           List<String> values) {
    for (int column = 0; column < lengths.length; column++) {
      final int len = lengths[column];
      String value = values[column];
      if (value == null) {
        value = ''.padRight(len);
      } else {
        switch (aligns[column]) {
          case FieldJustification.LEFT:
            value = value.padRight(len);
            break;
          case FieldJustification.RIGHT:
            value = value.padLeft(len);
            break;
          case FieldJustification.CENTER:
            value = value.padLeft((len + value.length) ~/2);
            value = value.padRight(len);
            break;
        }
      }
      if (column > 0) {
        value = value.padLeft(len+1);
      }
      buffer.write(value);
    }
    buffer.writeln();
  }

  /// Returns the summary as a tab-separated spreadsheet.
  ///
  /// This value can be copied straight to a Google Spreadsheet for further analysis.
  String printSummary() {
    final Map<String, _ScoreSummary> summariesA = _summarize(_aResults);
    final Map<String, _ScoreSummary> summariesB = _summarize(_bResults);

    final List<List<String>> tableRows = <List<String>>[
      for (final String scoreKey in <String>{...summariesA.keys, ...summariesB.keys})
        <String>[
          scoreKey,
          summariesA[scoreKey]?.averageString, summariesA[scoreKey]?.noiseString,
          summariesB[scoreKey]?.averageString, summariesB[scoreKey]?.noiseString,
          summariesA[scoreKey]?.improvementOver(summariesB[scoreKey]),
        ],
    ];

    final List<String> titles = <String>[
      'Score',
      'Average A', '(noise)',
      'Average B', '(noise)',
      'Speed-up'
    ];
    final List<FieldJustification> alignments = <FieldJustification>[
      FieldJustification.LEFT,
      FieldJustification.RIGHT, FieldJustification.LEFT,
      FieldJustification.RIGHT, FieldJustification.LEFT,
      FieldJustification.CENTER
    ];

    final List<int> lengths = List<int>.filled(6, 0);
    updateColumnLengths(lengths, titles);
    for (final List<String> row in tableRows) {
      updateColumnLengths(lengths, row);
    }

    final StringBuffer buffer = StringBuffer();
    formatResult(buffer, lengths, <FieldJustification>[FieldJustification.CENTER, ...alignments.skip(1)], titles);
    for (final List<String> row in tableRows) {
      formatResult(buffer, lengths, alignments, row);
    }

    return buffer.toString();
  }
}

class _ScoreSummary {
  _ScoreSummary({
    @required this.average,
    @required this.noise,
  });

  /// Average (arithmetic mean) of a series of values collected by a benchmark.
  final double average;

  /// The noise (standard deviation divided by [average]) in the collected
  /// values.
  final double noise;

  String get averageString => average.toStringAsFixed(2);
  String get noiseString => '(${_ratioToPercent(noise)})';

  String improvementOver(_ScoreSummary other) {
    return other == null ? '' : '${(average / other.average).toStringAsFixed(2)}x';
  }
}

void _addResult(Map<String, dynamic> result, Map<String, List<double>> results) {
  final List<String> scoreKeys = (result['benchmarkScoreKeys'] as List<dynamic>).cast<String>();
  final Map<String, dynamic> data = result['data'] as Map<String, dynamic>;
  for (final String scoreKey in scoreKeys) {
    final double score = (data[scoreKey] as num).toDouble();
    results.putIfAbsent(scoreKey, () => <double>[]).add(score);
  }
}

Map<String, _ScoreSummary> _summarize(Map<String, List<double>> results) {
  return results.map<String, _ScoreSummary>((String scoreKey, List<double> values) {
    final double average = _computeAverage(values);
    return MapEntry<String, _ScoreSummary>(scoreKey, _ScoreSummary(
      average: average,
      // If the average is zero, the benchmark got the perfect score with no noise.
      noise: average > 0
        ? _computeStandardDeviationForPopulation(values) / average
        : 0.0,
    ));
  });
}

/// Computes the arithmetic mean (or average) of given [values].
double _computeAverage(Iterable<double> values) {
  final double sum = values.reduce((double a, double b) => a + b);
  return sum / values.length;
}

/// Computes population standard deviation.
///
/// Unlike sample standard deviation, which divides by N - 1, this divides by N.
///
/// See also:
///
/// * https://en.wikipedia.org/wiki/Standard_deviation
double _computeStandardDeviationForPopulation(Iterable<double> population) {
  final double mean = _computeAverage(population);
  final double sumOfSquaredDeltas = population.fold<double>(
    0.0,
    (double previous, num value) => previous += math.pow(value - mean, 2),
  );
  return math.sqrt(sumOfSquaredDeltas / population.length);
}

String _ratioToPercent(double value) {
  return '${(value * 100).toStringAsFixed(2)}%';
}
