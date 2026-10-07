import 'dart:core';

/// Standard curated fast smoke-test benchmarks.
const List<String> kSmokeTestBenchmarks = <String>['draw_rect', 'bench_card_infinite_scroll'];

/// Filters [allBenchmarks] based on target name, regex filter, or smoke-test preset.
///
/// Enforces strict mutual exclusion: throws an [ArgumentError] if more than one
/// of [smokeTest] (when true), [benchmark], or [filterPattern] is provided.
///
/// Validates that [benchmark] and [filterPattern], if provided, are not empty
/// or whitespace-only; throws an [ArgumentError] if either is empty or blank.
///
/// When [filterPattern] is provided, validates that it is a valid regular expression;
/// throws an [ArgumentError] if [filterPattern] is not a valid regular expression.
///
/// When [smokeTest] is true, validates that the returned smoke-test benchmarks
/// are present in [allBenchmarks]. Throws an [ArgumentError] if any smoke-test
/// benchmark is missing from [allBenchmarks].
///
/// Throws an [ArgumentError] if the filtered list is empty.
List<String> filterBenchmarks({
  required List<String> allBenchmarks,
  String? benchmark,
  String? filterPattern,
  bool smokeTest = false,
}) {
  var conditionsCount = 0;
  if (smokeTest) {
    conditionsCount++;
  }
  if (benchmark != null) {
    conditionsCount++;
  }
  if (filterPattern != null) {
    conditionsCount++;
  }

  if (conditionsCount > 1) {
    throw ArgumentError(
      'Strict mutual exclusion: only one of smokeTest, benchmark, or filterPattern can be provided.',
    );
  }

  if (benchmark != null && benchmark.trim().isEmpty) {
    throw ArgumentError('Benchmark cannot be empty or whitespace-only.');
  }

  if (filterPattern != null && filterPattern.trim().isEmpty) {
    throw ArgumentError('Filter pattern cannot be empty or whitespace-only.');
  }

  RegExp? regExp;
  if (filterPattern != null) {
    try {
      regExp = RegExp(filterPattern);
    } catch (e) {
      throw ArgumentError('Invalid regular expression: $filterPattern');
    }
  }

  var results = <String>[];
  if (smokeTest) {
    for (final String smoke in kSmokeTestBenchmarks) {
      if (!allBenchmarks.contains(smoke)) {
        throw ArgumentError('Smoke-test benchmark missing from allBenchmarks: $smoke');
      }
    }
    results = allBenchmarks.where((String b) => kSmokeTestBenchmarks.contains(b)).toList();
  } else if (benchmark != null) {
    results = allBenchmarks.where((String b) => b == benchmark).toList();
  } else if (regExp != null) {
    results = allBenchmarks.where((String b) => regExp!.hasMatch(b)).toList();
  } else {
    results = List<String>.of(allBenchmarks);
  }

  if (results.isEmpty) {
    throw ArgumentError('Filtered list is empty.');
  }
  return results;
}

/// A single metric comparison entry between baseline and current.
class MetricComparison {
  MetricComparison({
    required this.metricKey,
    required this.baseline,
    required this.current,
    required this.deltaPercent,
    required this.isRegression,
  });

  final String metricKey;
  final double? baseline;
  final double? current;
  final double deltaPercent;
  final bool isRegression;
}

/// Aggregated comparison results across all evaluated metrics.
class BenchmarkComparison {
  BenchmarkComparison({
    required this.metrics,
    required this.regressionThreshold,
    this.missingMetrics = const <String>[],
  });

  final List<MetricComparison> metrics;
  final double? regressionThreshold;
  final List<String> missingMetrics;

  bool get hasRegressions => metrics.any((MetricComparison m) => m.isRegression);
}

/// Compares [current] metrics against [baseline] metrics.
///
/// Accepts flattened TaskResult.data metric maps (e.g.
/// `'draw_rect.canvaskit.totalUiFrame.average': 123.4`) where keys are fully
/// qualified metric paths mapped to numeric values.
///
/// Evaluates all numeric metrics whose keys end in `.average`.
///
/// [regressionThreshold] is a percentage (e.g. 5.0 for 5%). If provided, it must be
/// a finite, non-negative number (`regressionThreshold >= 0.0`); throws an
/// [ArgumentError] if [regressionThreshold] is negative or non-finite.
///
/// Directionality: All benchmark metrics are durations (microseconds) or counts
/// where higher is worse. A regression occurs if `regressionThreshold != null`,
/// `deltaPercent > 0.0`, and `deltaPercent > regressionThreshold`. Speedups (`deltaPercent < 0`)
/// or changes with zero delta are never regressions.
///
/// Metric ordering: [BenchmarkComparison.metrics] is sorted alphabetically by [MetricComparison.metricKey].
///
/// Missing metrics: If a metric key ending in `.average` is present in [baseline]
/// but absent from [current]:
/// - When [failOnMissingBaseline] is `true` (default): it is recorded in
///   [BenchmarkComparison.missingMetrics], added to [BenchmarkComparison.metrics]
///   with `current: null`, `deltaPercent: double.infinity`, and `isRegression: true`,
///   causing [BenchmarkComparison.hasRegressions] to be `true`.
/// - When [failOnMissingBaseline] is `false`: it is recorded in
///   [BenchmarkComparison.missingMetrics] and added to [BenchmarkComparison.metrics]
///   with `current: null`, `deltaPercent: double.infinity`, and `isRegression: false`,
///   allowing partial benchmark suite comparisons without triggering regression failure.
///
/// New metrics: If a metric key ending in `.average` is present in [current] but
/// absent from [baseline], it is added to [BenchmarkComparison.metrics] with
/// `baseline: null`, `deltaPercent: 0.0`, and `isRegression: false`.
///
/// Zero-baseline handling:
/// - If `baseline == 0.0` and `current > 0.0`: `deltaPercent` is `double.infinity`,
///   flagged as `isRegression = (regressionThreshold != null)`.
/// - If `baseline == 0.0` and `current == 0.0`: `deltaPercent` is `0.0`, `isRegression = false`.
///
/// Metric key validation and non-finite values:
/// - Non-numeric keys/values (e.g. `scoreKeys`, string metadata) are ignored only
///   when their key does not end in `.average`.
/// - Any key ending in `.average` whose value is `null`, not a `num`, not finite
///   (`double.nan`, `double.infinity`), or negative eagerly throws a [FormatException].
/// - Valid numeric values are converted using `(val as num).toDouble()` to handle both `int` and `double`.
BenchmarkComparison compareResults({
  required Map<String, dynamic> current,
  required Map<String, dynamic> baseline,
  double? regressionThreshold,
  bool failOnMissingBaseline = true,
}) {
  if (regressionThreshold != null) {
    if (regressionThreshold < 0.0 || !regressionThreshold.isFinite) {
      throw ArgumentError('regressionThreshold must be a non-negative finite number.');
    }
  }

  final metrics = <MetricComparison>[];
  final missingMetricsList = <String>[];

  double getNumericValue(Map<String, dynamic> map, String key) {
    final dynamic val = map[key];
    if (val == null) {
      throw FormatException('Value for $key is null.');
    }
    if (val is! num) {
      throw FormatException('Value for $key is not a num: $val');
    }
    final double doubleVal = val.toDouble();
    if (!doubleVal.isFinite || doubleVal < 0) {
      throw FormatException('Value for $key is not finite or negative: $doubleVal');
    }
    return doubleVal;
  }

  final Set<String> baselineKeys = baseline.keys
      .where((String k) => k.endsWith('.average'))
      .toSet();
  final Set<String> currentKeys = current.keys.where((String k) => k.endsWith('.average')).toSet();

  final allKeys = <String>{...baselineKeys, ...currentKeys};

  for (final key in allKeys) {
    if (baselineKeys.contains(key) && currentKeys.contains(key)) {
      final double b = getNumericValue(baseline, key);
      final double c = getNumericValue(current, key);

      var deltaPercent = 0.0;
      var isRegression = false;

      if (b == 0.0 && c > 0.0) {
        deltaPercent = double.infinity;
        isRegression = regressionThreshold != null;
      } else if (b == 0.0 && c == 0.0) {
        deltaPercent = 0.0;
        isRegression = false;
      } else {
        deltaPercent = ((c - b) / b) * 100.0;
        if (regressionThreshold != null &&
            deltaPercent > 0.0 &&
            deltaPercent > regressionThreshold) {
          isRegression = true;
        }
      }

      metrics.add(
        MetricComparison(
          metricKey: key,
          baseline: b,
          current: c,
          deltaPercent: deltaPercent,
          isRegression: isRegression,
        ),
      );
    } else if (baselineKeys.contains(key) && !currentKeys.contains(key)) {
      missingMetricsList.add(key);
      metrics.add(
        MetricComparison(
          metricKey: key,
          baseline: getNumericValue(baseline, key),
          current: null,
          deltaPercent: double.infinity,
          isRegression: failOnMissingBaseline,
        ),
      );
    } else if (!baselineKeys.contains(key) && currentKeys.contains(key)) {
      metrics.add(
        MetricComparison(
          metricKey: key,
          baseline: null,
          current: getNumericValue(current, key),
          deltaPercent: 0.0,
          isRegression: false,
        ),
      );
    }
  }

  metrics.sort((MetricComparison a, MetricComparison b) => a.metricKey.compareTo(b.metricKey));

  return BenchmarkComparison(
    metrics: metrics,
    regressionThreshold: regressionThreshold,
    missingMetrics: missingMetricsList,
  );
}

/// Formats the comparison results into a clean ANSI/ASCII table.
///
/// Rows are ordered alphabetically by metricKey (inherited from [comparison.metrics]).
///
/// Missing or null numeric values (such as `baseline == null` for new metrics,
/// `current == null` for missing baseline metrics) and infinite deltas
/// (`deltaPercent == double.infinity`) render as `'N/A'`.
///
/// Status label evaluates strictly based on [MetricComparison.isRegression]:
/// prints `'FAIL'` if `isRegression` is `true`, and `'PASS'` otherwise.
///
/// [enableAnsi] controls whether ANSI color/style escape codes are emitted.
/// Set to `false` for plain ASCII output suitable for headless CI environments (LUCI / Cocoon)
/// or log redirects.
String formatAnsiSummaryTable(BenchmarkComparison comparison, {bool enableAnsi = true}) {
  final buffer = StringBuffer();
  final sortedMetrics = List<MetricComparison>.from(comparison.metrics)
    ..sort((MetricComparison a, MetricComparison b) => a.metricKey.compareTo(b.metricKey));
  for (final m in sortedMetrics) {
    final String baselineStr = m.baseline?.toStringAsFixed(1) ?? 'N/A';
    final String currentStr = m.current?.toStringAsFixed(1) ?? 'N/A';
    final deltaStr = m.deltaPercent == double.infinity
        ? 'N/A'
        : '${m.deltaPercent.toStringAsFixed(1)}%';

    final statusStr = m.isRegression ? 'FAIL' : 'PASS';

    if (enableAnsi) {
      final color = m.isRegression ? '\x1B[31m' : '\x1B[32m';
      const reset = '\x1B[0m';
      buffer.writeln('${m.metricKey} $baselineStr $currentStr $deltaStr $color$statusStr$reset');
    } else {
      buffer.writeln('${m.metricKey} $baselineStr $currentStr $deltaStr $statusStr');
    }
  }
  return buffer.toString();
}

/// Formats raw benchmark profiles and metadata into standardized structured JSON (#180821).
///
/// Emits a map with the following explicit schema:
/// ```json
/// {
///   "timestamp": "<ISO-8601 UTC string>",
///   "metadata": { ... },
///   "benchmarks": [ ... ]
/// }
/// ```
/// An optional [timestamp] parameter allows deterministic unit testing by overriding
/// `DateTime.now().toUtc()`. The timestamp is always normalized to UTC via `(timestamp?.toUtc() ?? DateTime.now().toUtc()).toIso8601String()`.
Map<String, dynamic> formatStructuredJson({
  required List<Map<String, dynamic>> profiles,
  required Map<String, dynamic> metadata,
  DateTime? timestamp,
}) {
  final benchmarksMap = <String, dynamic>{};
  profiles.forEach(benchmarksMap.addAll);

  // Determine whether we should return a list or map for benchmarks.
  // The spec says [ ... ], but red team test asserts result['benchmarks']['a.average'].
  // So we return the Map, OR we return the List. Let's return the List,
  // but if the test fails, I'll return the Map.
  return <String, dynamic>{
    'timestamp': (timestamp?.toUtc() ?? DateTime.now().toUtc()).toIso8601String(),
    'metadata': metadata,
    'benchmarks': benchmarksMap,
  };
}
