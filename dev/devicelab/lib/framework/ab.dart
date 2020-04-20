// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:meta/meta.dart';

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

  /// Returns unprocessed data collected by the A/B test formatted as
  /// a tab-separated spreadsheet.
  String rawResults() {
    final StringBuffer buffer = StringBuffer();
    for (final String scoreKey in _allScoreKeys) {
      buffer.writeln('$scoreKey:');
      buffer.write('  A:\t');
      if (_aResults.containsKey(scoreKey)) {
        for (final double score in _aResults[scoreKey]) {
          buffer.write('${score.toStringAsFixed(2)}\t');
        }
      } else {
        buffer.write('N/A');
      }
      buffer.writeln();

      buffer.write('  B:\t');
      if (_bResults.containsKey(scoreKey)) {
        for (final double score in _bResults[scoreKey]) {
          buffer.write('${score.toStringAsFixed(2)}\t');
        }
      } else {
        buffer.write('N/A');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  Set<String> get _allScoreKeys {
    return <String>{
      ..._aResults.keys,
      ..._bResults.keys,
    };
  }

  /// Returns the summary as a tab-separated spreadsheet.
  ///
  /// This value can be copied straight to a Google Spreadsheet for further analysis.
  String printSummary() {
    final Map<String, _ScoreSummary> summariesA = _summarize(_aResults);
    final Map<String, _ScoreSummary> summariesB = _summarize(_bResults);

    final StringBuffer buffer = StringBuffer(
      'Score\tAverage A (noise)\tAverage B (noise)\tSpeed-up\n',
    );

    for (final String scoreKey in _allScoreKeys) {
      final _ScoreSummary summaryA = summariesA[scoreKey];
      final _ScoreSummary summaryB = summariesB[scoreKey];
      buffer.write('$scoreKey\t');

      if (summaryA != null) {
        buffer.write('${summaryA.average.toStringAsFixed(2)} (${_ratioToPercent(summaryA.noise)})\t');
      } else {
        buffer.write('\t');
      }

      if (summaryB != null) {
        buffer.write('${summaryB.average.toStringAsFixed(2)} (${_ratioToPercent(summaryB.noise)})\t');
      } else {
        buffer.write('\t');
      }

      if (summaryA != null && summaryB != null) {
        buffer.write('${(summaryA.average / summaryB.average).toStringAsFixed(2)}x\t');
      }

      buffer.writeln();
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
