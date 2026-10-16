// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

/// The comparison of a single metric between a baseline run and the current run.
class MetricComparison {
  /// Creates a comparison of [metricKey] between [baseline] and [current].
  const MetricComparison({
    required this.metricKey,
    required this.baseline,
    required this.current,
    required this.deltaPercent,
    required this.isRegression,
  });

  /// The flattened metric key, such as `draw_rect.canvaskit.totalUiFrame.average`.
  final String metricKey;

  /// The value of the metric in the baseline run.
  final double baseline;

  /// The value of the metric in the current run.
  final double current;

  /// The change from [baseline] to [current], as a percentage of [baseline].
  ///
  /// Positive values are slowdowns. This is [double.infinity] when [baseline]
  /// is zero and [current] is not.
  final double deltaPercent;

  /// Whether [deltaPercent] exceeds the regression threshold.
  final bool isRegression;
}

/// The result of [compareResults].
class BenchmarkComparison {
  /// Creates a comparison of [metrics].
  const BenchmarkComparison(this.metrics);

  /// The compared metrics, which [compareResults] sorts by
  /// [MetricComparison.metricKey].
  final List<MetricComparison> metrics;

  /// Whether any of the [metrics] is a regression.
  bool get hasRegressions => metrics.any((MetricComparison m) => m.isRegression);
}

/// Compares the `.average` metrics in [current] against those in [baseline].
///
/// Both maps are flattened `TaskResult.data` maps, such as
/// `{'draw_rect.canvaskit.totalUiFrame.average': 123.4}`. Only keys that end
/// in `.average` and appear in both maps are compared; all other keys are
/// ignored. The resulting metrics are sorted by key.
///
/// All metrics are durations or counts, so higher is worse. A metric is a
/// regression if [regressionThreshold] is non-null and the metric's
/// [MetricComparison.deltaPercent] is greater than it, so speedups are never
/// regressions.
///
/// Throws an [ArgumentError] if [regressionThreshold] is negative or not
/// finite, and a [FormatException] if a compared value is not a finite,
/// non-negative number.
BenchmarkComparison compareResults({
  required Map<String, dynamic> current,
  required Map<String, dynamic> baseline,
  double? regressionThreshold,
}) {
  if (regressionThreshold != null && (regressionThreshold < 0 || !regressionThreshold.isFinite)) {
    throw ArgumentError.value(
      regressionThreshold,
      'regressionThreshold',
      'must be a finite, non-negative number',
    );
  }

  double read(Map<String, dynamic> values, String key) {
    final Object? value = values[key];
    if (value is! num || !value.isFinite || value < 0) {
      throw FormatException('Expected a finite, non-negative number for $key, but got $value.');
    }
    return value.toDouble();
  }

  final List<String> keys =
      baseline.keys
          .where((String key) => key.endsWith('.average') && current.containsKey(key))
          .toList()
        ..sort();
  return BenchmarkComparison(<MetricComparison>[
    for (final key in keys)
      _compareMetric(key, read(baseline, key), read(current, key), regressionThreshold),
  ]);
}

MetricComparison _compareMetric(
  String key,
  double baseline,
  double current,
  double? regressionThreshold,
) {
  final double deltaPercent = baseline == 0
      ? (current == 0 ? 0.0 : double.infinity)
      : (current - baseline) / baseline * 100;
  return MetricComparison(
    metricKey: key,
    baseline: baseline,
    current: current,
    deltaPercent: deltaPercent,
    isRegression: regressionThreshold != null && deltaPercent > regressionThreshold,
  );
}

/// Formats [comparison] as a table for terminal output.
///
/// The table has a header row, a separator row, and one row per metric, with
/// the columns `Metric`, `Baseline`, `Current`, `Delta` and `Status` two spaces
/// apart and the numeric columns right-aligned. An infinite delta renders as
/// `N/A`. The status is `FAIL` for regressions and `PASS` otherwise.
///
/// If [enableAnsi] is true, the status is colored red or green; pass false
/// when the output is not a terminal.
///
/// Returns an empty string if [comparison] has no metrics.
String formatAnsiSummaryTable(BenchmarkComparison comparison, {bool enableAnsi = true}) {
  if (comparison.metrics.isEmpty) {
    return '';
  }
  final rows = <List<String>>[
    <String>['Metric', 'Baseline', 'Current', 'Delta', 'Status'],
    for (final MetricComparison m in comparison.metrics)
      <String>[
        m.metricKey,
        m.baseline.toStringAsFixed(1),
        m.current.toStringAsFixed(1),
        if (m.deltaPercent.isFinite) '${m.deltaPercent.toStringAsFixed(1)}%' else 'N/A',
        if (m.isRegression) 'FAIL' else 'PASS',
      ],
  ];
  final widths = <int>[
    for (var column = 0; column < rows.first.length; column++)
      rows.map((List<String> row) => row[column].length).reduce(math.max),
  ];

  final buffer = StringBuffer();
  for (var i = 0; i < rows.length; i++) {
    final List<String> row = rows[i];
    // The status column is last, so it is left unpadded to avoid trailing
    // whitespace, and colors do not affect the alignment.
    String status = row[4];
    if (enableAnsi && i > 0) {
      status = '${comparison.metrics[i - 1].isRegression ? '\x1B[31m' : '\x1B[32m'}$status\x1B[0m';
    }
    buffer.writeln(
      <String>[
        row[0].padRight(widths[0]),
        for (var column = 1; column < 4; column++) row[column].padLeft(widths[column]),
        status,
      ].join('  '),
    );
    if (i == 0) {
      buffer.writeln(widths.map((int width) => '-' * width).join('  '));
    }
  }
  return buffer.toString();
}
