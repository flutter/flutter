// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/tasks/web_benchmarks.dart';
import 'package:test/test.dart';

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

    test('combines targetBenchmarks and filterPattern (intersection)', () {
      final filter = BenchmarkFilter.parse(
        targetBenchmarks: <String>['draw_rect', 'bench_card'],
        filterPattern: r'^bench_',
      );
      final List<String> result = filter.filter(allBenchmarks);
      expect(result, <String>['bench_card']);
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
      final TaskResult result = processBenchmarkProfiles(<Map<String, dynamic>>[], options);
      expect(result.succeeded, isFalse);
      expect(result.message, 'No benchmark profiles were collected.');
    });

    test('missing or empty benchmark name returns TaskResult.failure', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, dynamic>>[
        <String, dynamic>{
          'name': '',
          'scoreKeys': <String>['frame_build_times'],
        },
      ], options);
      expect(result.succeeded, isFalse);
      expect(result.message, 'Benchmark name is empty');
    });

    test('empty scoreKeys returns TaskResult.failure', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, dynamic>>[
        <String, dynamic>{'name': 'draw_rect', 'scoreKeys': <String>[]},
      ], options);
      expect(result.succeeded, isFalse);
      expect(result.message, 'No metrics in benchmark "draw_rect"');
    });

    test('successful profile transformation into TaskResult.success', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'draw_rect',
          'scoreKeys': <String>['frame_build_times'],
          'frame_build_times': 123.4,
        },
      ], options);
      expect(result.succeeded, isTrue);
      expect(result.benchmarkScoreKeys, <String>['draw_rect.canvaskit.frame_build_times']);
      expect(result.data, <String, dynamic>{'draw_rect.canvaskit.frame_build_times': 123.4});
    });

    test('successful profile transformation into TaskResult.success (Skwasm)', () {
      final TaskResult result = processBenchmarkProfiles(
        <Map<String, dynamic>>[
          <String, dynamic>{
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
      expect(result.data, <String, dynamic>{'draw_rect.skwasm.frame_build_times': 123.4});
    });

    test('fails if scoreKeys contains empty string', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'draw_rect',
          'scoreKeys': <String>['frame_build_times', ''],
          'frame_build_times': 123.4,
        },
      ], options);
      expect(result.succeeded, isFalse);
      expect(result.message, 'Received an empty metric name in benchmark "draw_rect".');
    });

    test('ignores data keys that match internal keys like "name" or "scoreKeys"', () {
      final TaskResult result = processBenchmarkProfiles(<Map<String, dynamic>>[
        <String, dynamic>{
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

    test('tolerance to unexpected runner arguments or parse exceptions', () async {
      final TaskResult result = await runWebBenchmarkFromArgs(options, <String>['--invalid-flag']);
      expect(result.succeeded, isFalse);
      expect(result.message, contains('Could not find an option named "--invalid-flag".'));
    });
  });
}
