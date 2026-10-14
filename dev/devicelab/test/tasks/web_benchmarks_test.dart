// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/tasks/web_benchmarks.dart';
import 'package:flutter_devicelab/tasks/web_benchmarks_comparison.dart';

import '../common.dart';

void main() {
  group('BenchmarkFilter', () {
    final allBenchmarks = <String>[
      'draw_rect',
      'bench_card',
      'foo_bar',
      'bench_card_infinite_scroll',
    ];

    test('exact matching of single and multiple target benchmarks', () {
      final filter = BenchmarkFilter(targetBenchmarks: <String>['draw_rect', 'bench_card']);
      final List<String> result = filter.filter(allBenchmarks);
      expect(result, <String>['draw_rect', 'bench_card']);
    });

    test(
      'treats empty target list or only-whitespace targets as if no targetBenchmarks were provided',
      () {
        final filter = BenchmarkFilter(targetBenchmarks: <String>['  ', '']);
        final List<String> result = filter.filter(allBenchmarks);
        expect(result, allBenchmarks);
      },
    );

    test('rejects targetBenchmarks combined with compiledFilter', () {
      expect(
        () => BenchmarkFilter(
          targetBenchmarks: <String>['draw_rect', 'bench_card'],
          compiledFilter: RegExp(r'^bench_'),
        ),
        throwsA(isTargetsAndFilterConflict),
      );
    });

    test('rejects targetBenchmarks combined with filterPattern arguments', () {
      expect(
        () => BenchmarkFilter.parse(
          targetBenchmarks: <String>['draw_rect', 'bench_card'],
          filterPattern: r'^bench_',
        ),
        throwsA(isTargetsAndFilterConflict),
      );
    });

    test('allows compiledFilter when targetBenchmarks are only whitespace', () {
      final filter = BenchmarkFilter(
        targetBenchmarks: <String>['  ', ''],
        compiledFilter: RegExp(r'^bench_'),
      );
      final List<String> result = filter.filter(allBenchmarks);
      expect(result, <String>['bench_card', 'bench_card_infinite_scroll']);
    });

    test('allows targetBenchmarks with an empty filterPattern', () {
      final filter = BenchmarkFilter.parse(
        targetBenchmarks: <String>['draw_rect'],
        filterPattern: '',
      );
      final List<String> result = filter.filter(allBenchmarks);
      expect(result, <String>['draw_rect']);
    });

    test('trimming whitespace in target benchmarks', () {
      final filter = BenchmarkFilter(targetBenchmarks: <String>[' draw_rect ', 'bench_card ']);
      final List<String> result = filter.filter(allBenchmarks);
      expect(result, <String>['draw_rect', 'bench_card']);
    });

    test('regex pattern filtering', () {
      final filter = BenchmarkFilter.parse(filterPattern: r'^draw_');
      final List<String> result = filter.filter(allBenchmarks);
      expect(result, <String>['draw_rect']);
    });

    test('strict fail-fast error when target benchmark is missing/misspelled', () {
      final filter = BenchmarkFilter(targetBenchmarks: <String>['draw_rect', 'draw_rext']);
      expect(
        () => filter.filter(allBenchmarks),
        throwsA(
          isA<Exception>().having(
            (Exception e) => e.toString(),
            'message',
            contains('Unrecognized target benchmark(s): [draw_rext]'),
          ),
        ),
      );
    });

    test('error when regex matches zero benchmarks', () {
      final filter = BenchmarkFilter.parse(filterPattern: r'^non_existent_');
      expect(
        () => filter.filter(allBenchmarks),
        throwsA(
          isA<Exception>().having(
            (Exception e) => e.toString(),
            'message',
            contains('No benchmarks matched the requested filter.'),
          ),
        ),
      );
    });

    test('eager validation error when filterPattern is an invalid regex', () {
      expect(() => BenchmarkFilter.parse(filterPattern: '['), throwsA(isA<Exception>()));
    });

    test('filters to kSmokeTestBenchmarks when used as targetBenchmarks', () {
      final filter = BenchmarkFilter(targetBenchmarks: kSmokeTestBenchmarks);
      expect(filter.filter(allBenchmarks), kSmokeTestBenchmarks);
    });
  });

  group('BenchmarkFilter.parse (environment overrides)', () {
    test('uses BENCHMARK_TARGETS when targetBenchmarks is null', () {
      final filter = BenchmarkFilter.parse(
        environment: <String, String>{'BENCHMARK_TARGETS': 'draw_rect, bench_card'},
      );
      expect(filter.targetBenchmarks, <String>['draw_rect', 'bench_card']);
    });

    test('ignores BENCHMARK_TARGETS when targetBenchmarks is provided', () {
      final filter = BenchmarkFilter.parse(
        targetBenchmarks: <String>['foo_bar'],
        environment: <String, String>{'BENCHMARK_TARGETS': 'draw_rect, bench_card'},
      );
      expect(filter.targetBenchmarks, <String>['foo_bar']);
    });

    test('uses BENCHMARK_FILTER when filterPattern is null', () {
      final filter = BenchmarkFilter.parse(
        environment: <String, String>{'BENCHMARK_FILTER': r'^draw_'},
      );
      expect(filter.compiledFilter?.pattern, r'^draw_');
    });

    test('ignores BENCHMARK_FILTER when filterPattern is provided', () {
      final filter = BenchmarkFilter.parse(
        filterPattern: 'skwasm',
        environment: <String, String>{'BENCHMARK_FILTER': r'^draw_'},
      );
      expect(filter.compiledFilter?.pattern, 'skwasm');
    });

    test('fails fast on invalid regex in BENCHMARK_FILTER', () {
      expect(
        () => BenchmarkFilter.parse(environment: <String, String>{'BENCHMARK_FILTER': '['}),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects BENCHMARK_TARGETS combined with BENCHMARK_FILTER', () {
      expect(
        () => BenchmarkFilter.parse(
          environment: <String, String>{
            'BENCHMARK_TARGETS': 'draw_rect,bench_card',
            'BENCHMARK_FILTER': r'^bench_',
          },
        ),
        throwsA(isTargetsAndFilterConflict),
      );
    });

    test('rejects targetBenchmarks argument combined with BENCHMARK_FILTER', () {
      expect(
        () => BenchmarkFilter.parse(
          targetBenchmarks: <String>['draw_rect'],
          environment: <String, String>{'BENCHMARK_FILTER': r'^bench_'},
        ),
        throwsA(isTargetsAndFilterConflict),
      );
    });

    test('rejects filterPattern argument combined with BENCHMARK_TARGETS', () {
      expect(
        () => BenchmarkFilter.parse(
          filterPattern: r'^bench_',
          environment: <String, String>{'BENCHMARK_TARGETS': 'draw_rect'},
        ),
        throwsA(isTargetsAndFilterConflict),
      );
    });

    test('rejects the conflict before validating the filter regex', () {
      expect(
        () => BenchmarkFilter.parse(
          environment: <String, String>{'BENCHMARK_TARGETS': 'draw_rect', 'BENCHMARK_FILTER': '['},
        ),
        throwsA(isTargetsAndFilterConflict),
      );
    });

    test('treats empty BENCHMARK_TARGETS as unset when a filter is provided', () {
      final filter = BenchmarkFilter.parse(
        filterPattern: r'^draw_',
        environment: <String, String>{'BENCHMARK_TARGETS': ''},
      );
      expect(filter.targetBenchmarks, isNull);
      expect(filter.compiledFilter?.pattern, r'^draw_');
    });
  });

  group('processBenchmarkProfiles', () {
    const WebBenchmarkOptions options = (
      useWasm: false,
      forceSingleThreadedSkwasm: false,
      useDdc: false,
      withHotReload: false,
      buildMode: 'profile',
    );

    test('empty profiles list returns TaskResult.failure', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, Object?>>[], options);
      expect(result.succeeded, isFalse);
      expect(result.message, 'No benchmark profiles were collected.');
    });

    test('missing or empty benchmark name returns TaskResult.failure', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, Object?>>[
        <String, Object?>{
          'name': '',
          'scoreKeys': <String>['frame_build_times'],
        },
      ], options);
      expect(result.succeeded, isFalse);
      expect(result.message, 'Benchmark name is empty');
    });

    test('empty scoreKeys returns TaskResult.failure', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, Object?>>[
        <String, Object?>{'name': 'draw_rect', 'scoreKeys': <String>[]},
      ], options);
      expect(result.succeeded, isFalse);
      expect(result.message, 'No metrics in benchmark "draw_rect"');
    });

    test('successful profile transformation into TaskResult.success', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, Object?>>[
        <String, Object?>{
          'name': 'draw_rect',
          'scoreKeys': <String>['frame_build_times'],
          'frame_build_times': 123.4,
        },
      ], options);
      expect(result.succeeded, isTrue);
      expect(result.benchmarkScoreKeys, <String>['draw_rect.canvaskit.frame_build_times']);
      expect(result.data, <String, Object?>{'draw_rect.canvaskit.frame_build_times': 123.4});
    });

    test('successful profile transformation into TaskResult.success (Skwasm)', () {
      final TaskResult result = processBenchmarkProfiles(
        <Map<String, Object?>>[
          <String, Object?>{
            'name': 'draw_rect',
            'scoreKeys': <String>['frame_build_times'],
            'frame_build_times': 123.4,
          },
        ],
        (
          useWasm: true,
          forceSingleThreadedSkwasm: false,
          useDdc: false,
          withHotReload: false,
          buildMode: 'profile',
        ),
      );
      expect(result.succeeded, isTrue);
      expect(result.benchmarkScoreKeys, <String>['draw_rect.skwasm.frame_build_times']);
      expect(result.data, <String, Object?>{'draw_rect.skwasm.frame_build_times': 123.4});
    });

    test('fails if scoreKeys contains empty string', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, Object?>>[
        <String, Object?>{
          'name': 'draw_rect',
          'scoreKeys': <String>['frame_build_times', ''],
          'frame_build_times': 123.4,
        },
      ], options);
      expect(result.succeeded, isFalse);
      expect(result.message, 'Received an empty metric name in benchmark "draw_rect".');
    });

    test('ignores data keys that match internal keys like "name" or "scoreKeys"', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, Object?>>[
        <String, Object?>{
          'name': 'draw_rect',
          'scoreKeys': <String>['frame_build_times'],
          'frame_build_times': 123.4,
        },
      ], options);
      expect(result.succeeded, isTrue);
      expect(result.data!.containsKey('draw_rect.canvaskit.name'), isFalse);
      expect(result.data!.containsKey('draw_rect.canvaskit.scoreKeys'), isFalse);
      expect(result.data!['draw_rect.canvaskit.frame_build_times'], 123.4);
    });
  });

  group('runWebBenchmarkFromArgs', () {
    const WebBenchmarkOptions options = (
      useWasm: false,
      forceSingleThreadedSkwasm: false,
      useDdc: false,
      withHotReload: false,
      buildMode: 'profile',
    );

    test('fails on unrecognized arguments', () async {
      final TaskResult result = await runWebBenchmarkFromArgs(options, <String>['--invalid-flag']);
      expect(result.succeeded, isFalse);
      expect(result.message, contains('Could not find an option named "--invalid-flag".'));
    });

    test('fails without building when target benchmarks and a filter are both given', () async {
      final TaskResult result = await runWebBenchmark(
        options,
        targetBenchmarks: <String>['draw_rect'],
        environment: <String, String>{'BENCHMARK_FILTER': r'^draw_'},
      );
      expect(result.succeeded, isFalse);
      expect(result.message, contains('Cannot combine'));
      expect(result.message, contains('BENCHMARK_TARGETS'));
      expect(result.message, contains('BENCHMARK_FILTER'));
    });
  });

  group('compareResults', () {
    test('Regression detected: delta exceeds regressionThreshold=10.0', () {
      final BenchmarkComparison result = compareResults(
        baseline: {'a.average': 100.0},
        current: {'a.average': 115.0},
        regressionThreshold: 10.0,
      );
      expect(result.hasRegressions, true);
      expect(result.metrics.first.deltaPercent, 15.0);
      expect(result.metrics.first.isRegression, true);
    });

    test('Acceptable change: delta within threshold, flags isRegression: false', () {
      final BenchmarkComparison result = compareResults(
        baseline: {'a.average': 100.0},
        current: {'a.average': 105.0},
        regressionThreshold: 10.0,
      );
      expect(result.hasRegressions, false);
      expect(result.metrics.first.deltaPercent, 5.0);
      expect(result.metrics.first.isRegression, false);
    });

    test('Speedup: negative delta (e.g. -25%), flags isRegression: false even if magnitude exceeds threshold', () {
      final BenchmarkComparison result = compareResults(
        baseline: {'a.average': 100.0},
        current: {'a.average': 75.0},
        regressionThreshold: 10.0,
      );
      expect(result.hasRegressions, false);
      expect(result.metrics.first.deltaPercent, -25.0);
      expect(result.metrics.first.isRegression, false);
    });

    test('Negative or non-finite threshold: passing regressionThreshold: -5.0 or double.nan throws ArgumentError', () {
      expect(
        () => compareResults(baseline: {'a': 1}, current: {'a': 1}, regressionThreshold: -5.0),
        throwsArgumentError,
      );
      expect(
        () =>
            compareResults(baseline: {'a': 1}, current: {'a': 1}, regressionThreshold: double.nan),
        throwsArgumentError,
      );
    });

    test('Missing baseline metrics (strict): with failOnMissingBaseline: true', () {
      final BenchmarkComparison result = compareResults(
        baseline: {'a.average': 100.0},
        current: {},
        regressionThreshold: 10.0,
      );
      expect(result.hasRegressions, true);
      expect(result.missingMetrics.length, 1);
      final MetricComparison missingMetric = result.metrics.firstWhere(
        (m) => m.metricKey == 'a.average',
      );
      expect(result.missingMetrics.first, 'a.average');
      expect(missingMetric.current, isNull);
      expect(missingMetric.deltaPercent, double.infinity);
      expect(missingMetric.isRegression, true);
    });

    test('Missing baseline metrics (partial run): with failOnMissingBaseline: false', () {
      final BenchmarkComparison result = compareResults(
        baseline: {'a.average': 100.0},
        current: {},
        regressionThreshold: 10.0,
        failOnMissingBaseline: false,
      );
      expect(result.hasRegressions, false);
      expect(result.missingMetrics.length, 1);
      final MetricComparison missingMetric = result.metrics.firstWhere(
        (m) => m.metricKey == 'a.average',
      );
      expect(missingMetric.current, isNull);
      expect(missingMetric.deltaPercent, double.infinity);
      expect(missingMetric.isRegression, false);
    });

    test('New metrics (current only): metric present in current but absent in baseline', () {
      final BenchmarkComparison result = compareResults(
        baseline: {},
        current: {'a.average': 100.0},
        regressionThreshold: 10.0,
      );
      expect(result.metrics.first.baseline, isNull);
      expect(result.metrics.first.deltaPercent, 0.0);
      expect(result.metrics.first.isRegression, false);
    });

    test('Metric eligibility: evaluates all numeric metrics ending in .average and ignores non-average metrics or non-numeric keys', () {
      final BenchmarkComparison result = compareResults(
        baseline: {'a.average': 100.0, 'a.median': 50.0, 'a.string': 'foo'},
        current: {'a.average': 100.0, 'a.median': 50.0, 'a.string': 'foo'},
        regressionThreshold: 10.0,
      );
      expect(result.metrics.length, 1);
      expect(result.metrics.first.metricKey, 'a.average');
    });

    test('Deterministic metric ordering: metrics in BenchmarkComparison.metrics are sorted alphabetically by metricKey', () {
      final BenchmarkComparison result = compareResults(
        baseline: {'b.average': 100.0, 'a.average': 100.0, 'c.average': 100.0},
        current: {'b.average': 100.0, 'a.average': 100.0, 'c.average': 100.0},
        regressionThreshold: 10.0,
      );
      expect(result.metrics.map((m) => m.metricKey).toList(), [
        'a.average',
        'b.average',
        'c.average',
      ]);
    });

    test('BenchmarkComparison sorts metrics by metricKey without mutating the input', () {
      MetricComparison metric(String key) => MetricComparison(
        metricKey: key,
        baseline: 100.0,
        current: 100.0,
        deltaPercent: 0.0,
        isRegression: false,
      );
      final input = <MetricComparison>[
        metric('c.average'),
        metric('a.average'),
        metric('b.average'),
      ];
      final comp = BenchmarkComparison(regressionThreshold: 10.0, metrics: input);
      expect(comp.metrics.map((MetricComparison m) => m.metricKey).toList(), <String>[
        'a.average',
        'b.average',
        'c.average',
      ]);
      expect(input.map((MetricComparison m) => m.metricKey).toList(), <String>[
        'c.average',
        'a.average',
        'b.average',
      ]);
      expect(() => comp.metrics.add(metric('d.average')), throwsUnsupportedError);
    });

    test('Zero baseline jump: baseline is 0.0 and current is positive', () {
      final BenchmarkComparison result = compareResults(
        baseline: {'a.average': 0.0},
        current: {'a.average': 150.0},
        regressionThreshold: 10.0,
      );
      expect(result.metrics.first.deltaPercent, double.infinity);
      expect(result.metrics.first.isRegression, true);
      expect(result.hasRegressions, true);
    });

    test('Zero baseline unchanged: baseline is 0.0 and current is 0.0', () {
      final BenchmarkComparison result = compareResults(
        baseline: {'a.average': 0.0},
        current: {'a.average': 0.0},
        regressionThreshold: 10.0,
      );
      expect(result.metrics.first.deltaPercent, 0.0);
      expect(result.metrics.first.isRegression, false);
      expect(result.hasRegressions, false);
    });

    test(
      'Type safety & integer metrics: successfully parses both Dart int and double durations',
      () {
        final BenchmarkComparison result = compareResults(
          baseline: {'a.average': 100},
          current: {'a.average': 150.0},
          regressionThreshold: 10.0,
        );
        expect(result.metrics.first.deltaPercent, 50.0);
      },
    );

    test('Non-finite or negative values: throws FormatException on double.nan, double.infinity, negative numbers, or non-num/null values for keys ending in .average', () {
      expect(
        () => compareResults(baseline: {'a.average': -100.0}, current: {'a.average': 100.0}),
        throwsFormatException,
      );
      expect(
        () => compareResults(baseline: {'a.average': 100.0}, current: {'a.average': double.nan}),
        throwsFormatException,
      );
      expect(
        () =>
            compareResults(baseline: {'a.average': double.infinity}, current: {'a.average': 100.0}),
        throwsFormatException,
      );
      expect(
        () =>
            compareResults(baseline: {'a.average': 'string_value'}, current: {'a.average': 100.0}),
        throwsFormatException,
      );
      final BenchmarkComparison result = compareResults(
        baseline: {'a.average': 100.0, 'a.something_else': double.nan},
        current: {'a.average': 100.0},
        regressionThreshold: 10.0,
      );
      expect(result.metrics.length, 1);
    });

    test('Flattened input schema: accepts flattened TaskResult.data maps and ignores non-numeric keys / metadata', () {
      final BenchmarkComparison result = compareResults(
        baseline: {'draw_rect.canvaskit.totalUiFrame.average': 123.4, 'metadata': 'ignored'},
        current: {'draw_rect.canvaskit.totalUiFrame.average': 130.0},
        regressionThreshold: 10.0,
      );
      expect(result.metrics.length, 1);
      expect(result.metrics.first.metricKey, 'draw_rect.canvaskit.totalUiFrame.average');
    });

    test('regressionThreshold of 0.0 correctly flags strictly positive deltas as regressions', () {
      final BenchmarkComparison comp = compareResults(
        baseline: {'a.average': 100.0, 'b.average': 100.0},
        current: {'a.average': 100.0001, 'b.average': 100.0},
        regressionThreshold: 0.0,
      );
      expect(comp.hasRegressions, true);
      final MetricComparison metricA = comp.metrics.firstWhere((m) => m.metricKey == 'a.average');
      final MetricComparison metricB = comp.metrics.firstWhere((m) => m.metricKey == 'b.average');
      expect(metricA.isRegression, true);
      expect(metricB.isRegression, false);
    });

    test('compareResults with completely empty baseline and current maps', () {
      final BenchmarkComparison comp = compareResults(baseline: {}, current: {});
      expect(comp.hasRegressions, false);
      expect(comp.metrics.isEmpty, true);
      expect(comp.missingMetrics.isEmpty, true);
    });
  });

  group('formatAnsiSummaryTable', () {
    test('Table contains metric names, baseline values, current values, formatted deltas, and status labels', () {
      final comp = BenchmarkComparison(
        regressionThreshold: 10.0,
        metrics: [
          MetricComparison(
            metricKey: 'a.average',
            baseline: 100.0,
            current: 150.0,
            deltaPercent: 50.0,
            isRegression: true,
          ),
          MetricComparison(
            metricKey: 'b.average',
            baseline: 100.0,
            current: 100.0,
            deltaPercent: 0.0,
            isRegression: false,
          ),
        ],
        missingMetrics: [],
      );
      final String table = formatAnsiSummaryTable(comp, enableAnsi: false);
      expect(table, contains('a.average'));
      expect(table, contains('100.0'));
      expect(table, contains('150.0'));
      expect(table, contains('50.0%'));
      expect(table, contains('FAIL'));
      expect(table, contains('b.average'));
      expect(table, contains('PASS'));
    });

    test('Null and infinite formatting: renders null baseline, null current, and infinite delta as N/A', () {
      final comp = BenchmarkComparison(
        regressionThreshold: 10.0,
        metrics: [
          MetricComparison(
            metricKey: 'missing.average',
            baseline: 100.0,
            current: null,
            deltaPercent: double.infinity,
            isRegression: true,
          ),
          MetricComparison(
            metricKey: 'new.average',
            baseline: null,
            current: 150.0,
            deltaPercent: 0.0,
            isRegression: false,
          ),
        ],
        missingMetrics: ['missing.average'],
      );
      final String table = formatAnsiSummaryTable(comp, enableAnsi: false);
      expect(table, contains('new.average'));
      expect(table, contains('N/A'));
      expect(table, contains('missing.average'));
      expect(table, contains('N/A'));
    });

    test(
      'Status column: displays FAIL when isRegression: true, and PASS when isRegression: false',
      () {
        final comp = BenchmarkComparison(
          regressionThreshold: 10.0,
          metrics: [
            MetricComparison(
              metricKey: 'missing.average',
              baseline: 100.0,
              current: null,
              deltaPercent: double.infinity,
              isRegression: false,
            ),
          ],
          missingMetrics: ['missing.average'],
        );
        final String table = formatAnsiSummaryTable(comp, enableAnsi: false);
        expect(table, contains('missing.average'));
        expect(table, contains('PASS'));
      },
    );

    test('Row ordering: rows are printed alphabetically by metricKey', () {
      final BenchmarkComparison comp = compareResults(
        baseline: <String, dynamic>{'z.average': 100.0, 'a.average': 100.0, 'm.average': 100.0},
        current: <String, dynamic>{'z.average': 100.0, 'a.average': 100.0},
        regressionThreshold: 10.0,
        failOnMissingBaseline: false,
      );
      final String table = formatAnsiSummaryTable(comp, enableAnsi: false);
      final int indexOfA = table.indexOf('a.average');
      final int indexOfM = table.indexOf('m.average');
      final int indexOfZ = table.indexOf('z.average');
      expect(indexOfA < indexOfM, true);
      expect(indexOfM < indexOfZ, true);
    });

    test('ANSI control: With enableAnsi: true, emits ANSI color formatting', () {
      final comp = BenchmarkComparison(
        regressionThreshold: 10.0,
        metrics: [
          MetricComparison(
            metricKey: 'a.average',
            baseline: 100.0,
            current: 150.0,
            deltaPercent: 50.0,
            isRegression: true,
          ),
        ],
        missingMetrics: [],
      );
      final String tableAnsi = formatAnsiSummaryTable(comp);
      expect(tableAnsi, contains('\x1B['));

      final String tablePlain = formatAnsiSummaryTable(comp, enableAnsi: false);
      expect(tablePlain, isNot(contains('\x1B[')));
    });

    test('empty metrics list generates empty table output', () {
      final comp = BenchmarkComparison(regressionThreshold: 10.0, metrics: [], missingMetrics: []);
      final String table = formatAnsiSummaryTable(comp);
      expect(table.trim(), isEmpty);
    });

    // Metric keys and values of differing widths, so that joining the cells
    // with single spaces cannot line the columns up.
    final mixedWidthComparison = BenchmarkComparison(
      regressionThreshold: 10.0,
      metrics: [
        MetricComparison(
          metricKey: 'a.average',
          baseline: 4915.7,
          current: 4596.2,
          deltaPercent: -6.5,
          isRegression: false,
        ),
        MetricComparison(
          metricKey: 'bench_card_infinite_scroll.canvaskit.apply_frame.average',
          baseline: 67.2,
          current: 75.6,
          deltaPercent: 12.5,
          isRegression: true,
        ),
        MetricComparison(
          metricKey: 'new.average',
          baseline: null,
          current: 2.2,
          deltaPercent: double.infinity,
          isRegression: false,
        ),
      ],
      missingMetrics: [],
    );
    const columnTitles = <String>['Metric', 'Baseline', 'Current', 'Delta', 'Status'];
    // Expected cells per metric key, in column order.
    const expectedCells = <String, List<String>>{
      'a.average': <String>['a.average', '4915.7', '4596.2', '-6.5%', 'PASS'],
      'bench_card_infinite_scroll.canvaskit.apply_frame.average': <String>[
        'bench_card_infinite_scroll.canvaskit.apply_frame.average',
        '67.2',
        '75.6',
        '12.5%',
        'FAIL',
      ],
      'new.average': <String>['new.average', 'N/A', '2.2', 'N/A', 'PASS'],
    };

    // Returns the non-blank lines of [table], dropping an optional separator
    // line made only of `-` characters.
    List<String> tableLines(String table) => table
        .split('\n')
        .where((String line) => line.trim().isNotEmpty && !RegExp(r'^[\s-]+$').hasMatch(line))
        .toList();

    // Asserts that [lines] form a table whose first line is the header and
    // whose columns line up: Metric and Status start at the header's offset,
    // and Baseline, Current and Delta end at the header's offset.
    void expectAlignedTable(List<String> lines) {
      expect(lines.first.trim().split(RegExp(r'\s{2,}')), columnTitles);
      final List<RegExpMatch> header = RegExp(r'\S+').allMatches(lines.first).toList();
      expect(header.map((RegExpMatch m) => m.group(0)), columnTitles);

      final List<String> rows = lines.skip(1).toList();
      expect(rows, hasLength(expectedCells.length));
      for (final MapEntry<String, List<String>> entry in expectedCells.entries) {
        final String row = rows.singleWhere(
          (String line) => RegExp(r'\S+').firstMatch(line)?.group(0) == entry.key,
        );
        final List<RegExpMatch> cells = RegExp(r'\S+').allMatches(row).toList();
        expect(cells.map((RegExpMatch m) => m.group(0)), entry.value, reason: row);
        expect(cells[0].start, header[0].start, reason: 'Metric is left-aligned in: $row');
        for (final column in <int>[1, 2, 3]) {
          expect(
            cells[column].end,
            header[column].end,
            reason: '${columnTitles[column]} is right-aligned in: $row',
          );
        }
        expect(cells[4].start, header[4].start, reason: 'Status is left-aligned in: $row');
        for (var i = 0; i < cells.length - 1; i++) {
          expect(
            cells[i + 1].start - cells[i].end,
            greaterThanOrEqualTo(2),
            reason: 'columns separated by at least two spaces in: $row',
          );
        }
      }
      // Rows keep the order of the comparison's metrics.
      expect(
        rows.map((String row) => RegExp(r'\S+').firstMatch(row)!.group(0)),
        mixedWidthComparison.metrics.map((MetricComparison m) => m.metricKey),
      );
    }

    test('first line is a header row naming the columns', () {
      final List<String> lines = tableLines(
        formatAnsiSummaryTable(mixedWidthComparison, enableAnsi: false),
      );
      expect(lines.first.trim().split(RegExp(r'\s{2,}')), columnTitles);
      expect(lines.skip(1).where((String line) => line.contains('Metric')), isEmpty);
    });

    test('columns are aligned, with numeric columns right-aligned', () {
      expectAlignedTable(
        tableLines(formatAnsiSummaryTable(mixedWidthComparison, enableAnsi: false)),
      );
    });

    test('ANSI colors wrap only the status and do not affect alignment', () {
      final String plain = formatAnsiSummaryTable(mixedWidthComparison, enableAnsi: false);
      final String ansi = formatAnsiSummaryTable(mixedWidthComparison);
      expect(ansi, contains('\x1B[31mFAIL\x1B[0m'));
      expect(ansi, contains('\x1B[32mPASS\x1B[0m'));
      final String stripped = ansi.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
      expect(stripped, plain);
      expectAlignedTable(tableLines(stripped));
    });
  });

  group('formatStructuredJson', () {
    test('Emits valid JSON map matching the standardized schema with timestamp, metadata, and benchmarks', () {
      final Map<String, dynamic> metadata = {'foo': 'bar'};
      final Map<String, dynamic> result = formatStructuredJson(
        profiles: <Map<String, dynamic>>[
          {'a.average': 100.0},
        ],
        metadata: metadata,
      );
      expect(result.containsKey('timestamp'), true);
      expect(result['metadata'], metadata);
      expect(result.containsKey('benchmarks'), true);
      expect((result['benchmarks'] as Map<String, dynamic>)['a.average'], isNotNull);
    });

    test('Deterministic timestamp: when timestamp parameter is provided, outputs the formatted ISO-8601 UTC string', () {
      final dt = DateTime(2023, 10, 5, 12);
      final Map<String, dynamic> result = formatStructuredJson(
        profiles: <Map<String, dynamic>>[],
        metadata: {},
        timestamp: dt,
      );
      expect(result['timestamp'], dt.toUtc().toIso8601String());
    });

    test('empty profiles and metadata', () {
      final Map<String, dynamic> result = formatStructuredJson(
        profiles: <Map<String, dynamic>>[],
        metadata: {},
      );
      expect(result['metadata'], isEmpty);
      expect((result['benchmarks'] as Map).isEmpty, true);
    });
  });
}

/// Matches the exception thrown when target benchmarks and a filter pattern are
/// both specified, and checks that the message names both options.
final Matcher isTargetsAndFilterConflict = isA<Exception>().having(
  (Exception e) => e.toString(),
  'message',
  allOf(
    contains('Cannot combine'),
    contains('--benchmark'),
    contains('BENCHMARK_TARGETS'),
    contains('--filter'),
    contains('BENCHMARK_FILTER'),
  ),
);
