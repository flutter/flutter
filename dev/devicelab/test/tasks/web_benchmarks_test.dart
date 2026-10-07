// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
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
    for (final (
          String description,
          num baseline,
          num current,
          double? threshold,
          double delta,
          bool regression,
        )
        in <(String, num, num, double?, double, bool)>[
          ('slowdown above the threshold is a regression', 100.0, 115.0, 10.0, 15.0, true),
          ('slowdown within the threshold is not a regression', 100.0, 105.0, 10.0, 5.0, false),
          ('slowdown equal to the threshold is not a regression', 100.0, 110.0, 10.0, 10.0, false),
          ('speedup beyond the threshold is not a regression', 100.0, 75.0, 10.0, -25.0, false),
          ('slowdown without a threshold is not a regression', 100.0, 150.0, null, 50.0, false),
          ('any slowdown is a regression at threshold 0', 100.0, 101.0, 0.0, 1.0, true),
          ('no change is not a regression at threshold 0', 100.0, 100.0, 0.0, 0.0, false),
          ('rise from zero is an infinite regression', 0.0, 150.0, 10.0, double.infinity, true),
          (
            'rise from zero without a threshold is not a regression',
            0.0,
            150.0,
            null,
            double.infinity,
            false,
          ),
          ('zero to zero is unchanged', 0.0, 0.0, 10.0, 0.0, false),
          ('integer values are accepted', 100, 150, 10.0, 50.0, true),
        ]) {
      test(description, () {
        final BenchmarkComparison result = compareResults(
          baseline: <String, dynamic>{'a.average': baseline},
          current: <String, dynamic>{'a.average': current},
          regressionThreshold: threshold,
        );
        final MetricComparison metric = result.metrics.single;
        expect(metric.metricKey, 'a.average');
        expect(metric.baseline, baseline);
        expect(metric.current, current);
        expect(metric.deltaPercent, delta);
        expect(metric.isRegression, regression);
        expect(result.hasRegressions, regression);
      });
    }

    test('compares only .average keys present in both maps, sorted by key', () {
      final BenchmarkComparison result = compareResults(
        baseline: <String, dynamic>{
          'c.average': 1,
          'a.average': 1,
          'a.median': double.nan,
          'baseline_only.average': -1,
          'name': 'draw_rect',
        },
        current: <String, dynamic>{
          'a.average': 1,
          'c.average': 1,
          'a.median': double.nan,
          'current_only.average': null,
        },
      );
      expect(result.metrics.map((MetricComparison m) => m.metricKey), <String>[
        'a.average',
        'c.average',
      ]);
      expect(
        compareResults(
          baseline: <String, dynamic>{'a.average': 1},
          current: <String, dynamic>{'b.average': 1},
        ).metrics,
        isEmpty,
      );
    });

    test('rejects negative and non-finite thresholds', () {
      for (final threshold in <double>[-5.0, double.nan, double.infinity]) {
        expect(
          () => compareResults(
            baseline: <String, dynamic>{'a.average': 1},
            current: <String, dynamic>{'a.average': 1},
            regressionThreshold: threshold,
          ),
          throwsArgumentError,
          reason: '$threshold',
        );
      }
    });

    test('rejects compared values that are not finite, non-negative numbers', () {
      for (final value in <Object?>[-1.0, double.nan, double.infinity, 'fast', null]) {
        expect(
          () => compareResults(
            baseline: <String, dynamic>{'a.average': value},
            current: <String, dynamic>{'a.average': 1},
          ),
          throwsFormatException,
          reason: 'baseline $value',
        );
        expect(
          () => compareResults(
            baseline: <String, dynamic>{'a.average': 1},
            current: <String, dynamic>{'a.average': value},
          ),
          throwsFormatException,
          reason: 'current $value',
        );
      }
    });
  });

  group('formatAnsiSummaryTable', () {
    final BenchmarkComparison comparison = compareResults(
      baseline: <String, dynamic>{
        'zero.average': 0,
        'a.average': 4915.7,
        'bench_card_infinite_scroll.canvaskit.apply_frame.average': 67.2,
        'huge.average': 123456789,
      },
      current: <String, dynamic>{
        'zero.average': 2.2,
        'a.average': 4596.2,
        'bench_card_infinite_scroll.canvaskit.apply_frame.average': 75.6,
        'huge.average': 123457,
      },
      regressionThreshold: 10.0,
    );

    test('renders an aligned table with a header and separator', () {
      expect(formatAnsiSummaryTable(comparison, enableAnsi: false), '''
Metric                                                       Baseline   Current   Delta  Status
--------------------------------------------------------  -----------  --------  ------  ------
a.average                                                      4915.7    4596.2   -6.5%  PASS
bench_card_infinite_scroll.canvaskit.apply_frame.average         67.2      75.6   12.5%  FAIL
huge.average                                              123456789.0  123457.0  -99.9%  PASS
zero.average                                                      0.0       2.2     N/A  FAIL
''');
    });

    test('colors only the status when ANSI is enabled', () {
      final String ansi = formatAnsiSummaryTable(comparison, enableAnsi: true);
      expect(ansi, contains('\x1B[31mFAIL\x1B[0m'));
      expect(ansi, contains('\x1B[32mPASS\x1B[0m'));
      expect(
        ansi.replaceAll(RegExp(r'\x1B\[\d+m'), ''),
        formatAnsiSummaryTable(comparison, enableAnsi: false),
      );
    });

    test('returns an empty string when there are no metrics', () {
      expect(
        formatAnsiSummaryTable(const BenchmarkComparison(<MetricComparison>[]), enableAnsi: true),
        isEmpty,
      );
    });
  });


  group('CLI Argument and Runner Tests', () {
    test('Argument parsing includes all flags and --help', () {
      final ArgParser parser = buildBenchmarkArgParser();
      expect(parser.options.containsKey('help'), isTrue);
      expect(parser.options.containsKey('benchmark'), isTrue);
      expect(parser.options.containsKey('smoke-test'), isTrue);
      expect(parser.options.containsKey('filter'), isTrue);
      expect(parser.options.containsKey('baseline'), isTrue);
      expect(parser.options.containsKey('results-file'), isTrue);
      expect(parser.options.containsKey('renderer'), isTrue);
      expect(parser.options.containsKey('regression-threshold'), isTrue);
      expect(parser.options.containsKey('clean'), isTrue);
      expect(parser.options.containsKey('no-build'), isTrue);
      expect(parser.options.containsKey('local-engine-src-path'), isTrue);
      expect(parser.options.containsKey('local-web-sdk'), isTrue);
    });

    test('runBenchmarkCli handles ArgParserException, prints usage and exits with code 2', () async {
      final List<String> outLines = <String>[];
      final List<String> errLines = <String>[];
      final int exitCode = await runBenchmarkCli(
        <String>['--invalid-flag'],
        out: outLines.add,
        err: errLines.add,
      );
      expect(exitCode, 2);
      expect(errLines.any((String line) => line.contains('Could not find an option named "invalid-flag"')), isTrue);
      expect(outLines.any((String line) => line.contains('Usage:')), isTrue);
    });

    test('Rejection of conflicting selectors', () async {
      final List<List<String>> conflicts = <List<String>>[
        <String>['--benchmark=foo', '--smoke-test'],
        <String>['--filter=foo', '--smoke-test'],
        <String>['--benchmark=foo', '--filter=foo'],
      ];
      for (final List<String> args in conflicts) {
        final List<String> errLines = <String>[];
        final int exitCode = await runBenchmarkCli(args, err: errLines.add);
        expect(exitCode, 2);
        expect(errLines.any((String line) => line.contains('Cannot use')), isTrue);
      }
    });

    test('Default execution of all benchmarks when no selector flag is passed', () async {
      bool runnerCalled = false;
      final int exitCode = await runBenchmarkCli(
        <String>[],
        runner: ({
          required List<String>? benchmark,
          required bool smokeTest,
          required String? filter,
          required String renderer,
          required bool clean,
          required bool noBuild,
          required String? localEngineSrcPath,
          required String? localWebSdk,
        }) async {
          runnerCalled = true;
          expect(benchmark, isEmpty);
          expect(smokeTest, isFalse);
          expect(filter, isNull);
          return <String, dynamic>{
             'timestamp': '2023',
             'metadata': {},
             'benchmarks': {}
          };
        },
      );
      expect(runnerCalled, isTrue);
      expect(exitCode, 0);
    });

    test('runBenchmarkCli parses arguments correctly and delegates to runner', () async {
      bool runnerCalled = false;
      final int exitCode = await runBenchmarkCli(
        <String>[
          '--benchmark=draw_rect',
          '--renderer=skwasm',
          '--no-build',
        ],
        runner: ({
          required List<String>? benchmark,
          required bool smokeTest,
          required String? filter,
          required String renderer,
          required bool clean,
          required bool noBuild,
          required String? localEngineSrcPath,
          required String? localWebSdk,
        }) async {
          runnerCalled = true;
          expect(benchmark, <String>['draw_rect']);
          expect(smokeTest, isFalse);
          expect(filter, isNull);
          expect(renderer, 'skwasm');
          expect(clean, isFalse); // noBuild disarms clean
          expect(noBuild, isTrue);
          expect(localEngineSrcPath, isNull);
          expect(localWebSdk, isNull);
          return <String, dynamic>{
             'timestamp': '2023',
             'metadata': {},
             'benchmarks': {
               'draw_rect.skwasm': {'a.average': 100}
             }
          };
        },
      );
      expect(runnerCalled, isTrue);
      expect(exitCode, 0);
    });

    test('Rejection of identical canonical paths for --baseline and --results-file', () async {
      final List<String> errLines = <String>[];
      final int exitCode = await runBenchmarkCli(
        <String>[
          '--baseline=./path/to/file.json',
          '--results-file=path/to/file.json',
        ],
        err: errLines.add,
      );
      expect(exitCode, 2);
      expect(errLines.any((String line) => line.contains('baseline and results-file cannot be the same')), isTrue);
    });

    test('Validation of --renderer allowed choices', () async {
      final List<String> errLines = <String>[];
      final int exitCode = await runBenchmarkCli(
        <String>['--renderer=invalid_renderer'],
        err: errLines.add,
      );
      expect(exitCode, 2);
      expect(errLines.any((String line) => line.contains('invalid_renderer is not an allowed value')), isTrue);
    });

    test('Rejection of negative, NaN, or infinite regression-threshold', () async {
      for (final String val in <String>['-0.1', 'NaN', 'Infinity']) {
        final List<String> errLines = <String>[];
        final int exitCode = await runBenchmarkCli(
          <String>['--regression-threshold=$val', '--baseline=b.json'],
          err: errLines.add,
        );
        expect(exitCode, 2);
        expect(errLines.any((String line) => line.contains('must be a positive number')), isTrue);
      }
    });

    test('Rejection of --regression-threshold when --baseline is omitted', () async {
      final List<String> errLines = <String>[];
      final int exitCode = await runBenchmarkCli(
        <String>['--regression-threshold=0.1'],
        err: errLines.add,
      );
      expect(exitCode, 2);
      expect(errLines.any((String line) => line.contains('regression-threshold requires a baseline')), isTrue);
    });

    test('Validation of mutual exclusion between --clean and --no-build', () async {
      final List<String> errLines = <String>[];
      final int exitCode = await runBenchmarkCli(
        <String>['--clean', '--no-build'],
        err: errLines.add,
      );
      expect(exitCode, 2);
      expect(errLines.any((String line) => line.contains('Cannot use --clean and --no-build together')), isTrue);
    });

    test('Validation that --local-engine-src-path requires --local-web-sdk', () async {
      final List<String> errLines = <String>[];
      final int exitCode = await runBenchmarkCli(
        <String>['--local-engine-src-path=/some/path'],
        err: errLines.add,
      );
      expect(exitCode, 2);
      expect(errLines.any((String line) => line.contains('local-engine-src-path requires local-web-sdk')), isTrue);
    });

    test('Upfront validation of --baseline file existence and JSON parsing', () async {
      final List<String> errLines = <String>[];
      // File doesn't exist
      int exitCode = await runBenchmarkCli(
        <String>['--baseline=non_existent_file.json'],
        err: errLines.add,
      );
      expect(exitCode, 2);
      expect(errLines.any((String line) => line.contains('Baseline file not found')), isTrue);
    });

    test('Detection of empty metric intersection or lack of .average metrics between baseline and current results, exiting with code 2', () async {
      final List<String> errLines = <String>[];
      final int exitCode = await runBenchmarkCli(
        <String>['--baseline=baseline.json'],
        runner: ({
          required List<String>? benchmark,
          required bool smokeTest,
          required String? filter,
          required String renderer,
          required bool clean,
          required bool noBuild,
          required String? localEngineSrcPath,
          required String? localWebSdk,
        }) async => <String, dynamic>{
          'timestamp': '2023',
          'metadata': {},
          'benchmarks': {
            'draw_rect.canvaskit': {'b.average': 100}
          }
        },
        readBaseline: (String path) => <String, dynamic>{
          'benchmarks': {
            'draw_rect.canvaskit': {'a.average': 100} // disjoint metrics
          }
        },
        err: errLines.add,
      );
      expect(exitCode, 2);
      expect(errLines.any((String line) => line.contains('No overlapping metrics')), isTrue);
    });

    test('Validation of renderer-specific artifact existence under --no-build anchored to flutterRootDir', () async {
      final List<String> errLines = <String>[];
      final int exitCode = await runBenchmarkCli(
        <String>['--no-build', '--renderer=skwasm'],
        flutterRootDir: '/fake/flutter/root',
        checkArtifacts: (String root, String renderer) => false,
        err: errLines.add,
      );
      expect(exitCode, 2);
      expect(errLines.any((String line) => line.contains('Artifacts for renderer skwasm not found')), isTrue);
    });

    test('Graceful handling of file system errors for --results-file', () async {
      final List<String> errLines = <String>[];
      final int exitCode = await runBenchmarkCli(
        <String>['--results-file=/nonexistent_dir/results.json'],
        runner: ({
          required List<String>? benchmark,
          required bool smokeTest,
          required String? filter,
          required String renderer,
          required bool clean,
          required bool noBuild,
          required String? localEngineSrcPath,
          required String? localWebSdk,
        }) async => <String, dynamic>{},
        writeResults: (String path, String content) => throw Exception('Cannot write file'),
        err: errLines.add,
      );
      expect(exitCode, 2);
      expect(errLines.any((String line) => line.contains('Failed to write results')), isTrue);
    });
  });
    test('Execution through runBenchmarkCli testing exit codes', () async {
      final List<String> errLines = <String>[];
      int exitCode = await runBenchmarkCli(
        <String>['--baseline=baseline.json', '--regression-threshold=0.1'],
        runner: ({
          required List<String>? benchmark,
          required bool smokeTest,
          required String? filter,
          required String renderer,
          required bool clean,
          required bool noBuild,
          required String? localEngineSrcPath,
          required String? localWebSdk,
        }) async => <String, dynamic>{
          'benchmarks': {
            'draw_rect.canvaskit': {'a.average': 150} // regression
          }
        },
        readBaseline: (String path) => <String, dynamic>{
          'benchmarks': {
            'draw_rect.canvaskit': {'a.average': 100}
          }
        },
        err: errLines.add,
      );
      expect(exitCode, 1);

      exitCode = await runBenchmarkCli(
        <String>[],
        runner: ({
          required List<String>? benchmark,
          required bool smokeTest,
          required String? filter,
          required String renderer,
          required bool clean,
          required bool noBuild,
          required String? localEngineSrcPath,
          required String? localWebSdk,
        }) async => throw Exception('Runner failed'),
        err: errLines.add,
      );
      expect(exitCode, 3);
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
