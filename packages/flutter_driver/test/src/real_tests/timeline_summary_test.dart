// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;

import 'package:file/file.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver/src/driver/common.dart';
import 'package:path/path.dart' as path;

import '../../common.dart';

void main() {
  group('TimelineSummary', () {

    TimelineSummary summarize(List<Map<String, dynamic>> testEvents) {
      return TimelineSummary.summarize(Timeline.fromJson(<String, dynamic>{
        'traceEvents': testEvents,
      }));
    }

    Map<String, dynamic> frameBegin(int timeStamp) => <String, dynamic>{
      'name': 'Frame',
      'ph': 'B',
      'ts': timeStamp,
    };

    Map<String, dynamic> frameEnd(int timeStamp) => <String, dynamic>{
      'name': 'Frame',
      'ph': 'E',
      'ts': timeStamp,
    };

    Map<String, dynamic> begin(int timeStamp) => <String, dynamic>{
      'name': 'GPURasterizer::Draw',
      'ph': 'B',
      'ts': timeStamp,
    };

    Map<String, dynamic> end(int timeStamp) => <String, dynamic>{
      'name': 'GPURasterizer::Draw',
      'ph': 'E',
      'ts': timeStamp,
    };

    List<Map<String, dynamic>> rasterizeTimeSequenceInMillis(List<int> sequence) {
      final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
      int t = 0;
      for (final int duration in sequence) {
        result.add(begin(t));
        t += duration * 1000;
        result.add(end(t));
      }
      return result;
    }

    group('frame_count', () {
      test('counts frames', () {
        expect(
          summarize(<Map<String, dynamic>>[
            frameBegin(1000), frameEnd(2000),
            frameBegin(3000), frameEnd(5000),
          ]).countFrames(),
          2,
        );
      });
    });

    group('average_frame_build_time_millis', () {
      test('throws when there is no data', () {
        expect(
          () => summarize(<Map<String, dynamic>>[]).computeAverageFrameBuildTimeMillis(),
          throwsA(predicate<ArgumentError>((ArgumentError e) => e.message == 'durations is empty!')),
        );
      });

      test('computes average frame build time in milliseconds', () {
        expect(
          summarize(<Map<String, dynamic>>[
            frameBegin(1000), frameEnd(2000),
            frameBegin(3000), frameEnd(5000),
          ]).computeAverageFrameBuildTimeMillis(),
          1.5,
        );
      });

      test('skips leading "end" events', () {
        expect(
          summarize(<Map<String, dynamic>>[
            frameEnd(1000),
            frameBegin(2000), frameEnd(4000),
          ]).computeAverageFrameBuildTimeMillis(),
          2.0,
        );
      });

      test('skips trailing "begin" events', () {
        expect(
          summarize(<Map<String, dynamic>>[
            frameBegin(2000), frameEnd(4000),
            frameBegin(5000),
          ]).computeAverageFrameBuildTimeMillis(),
          2.0,
        );
      });

      // see https://github.com/flutter/flutter/issues/54095.
      test('ignore multiple "end" events', () {
        expect(
          summarize(<Map<String, dynamic>>[
            frameBegin(2000), frameEnd(4000),
            frameEnd(4300), // rogue frame end.
            frameBegin(5000), frameEnd(6000),
          ]).computeAverageFrameBuildTimeMillis(),
          1.5,
        );
      });

      test('pick latest when there are multiple "begin" events', () {
        expect(
          summarize(<Map<String, dynamic>>[
            frameBegin(1000), // rogue frame begin.
            frameBegin(2000), frameEnd(4000),
            frameEnd(4300), // rogue frame end.
            frameBegin(4400), // rogue frame begin.
            frameBegin(5000), frameEnd(6000),
          ]).computeAverageFrameBuildTimeMillis(),
          1.5,
        );
      });
    });

    group('worst_frame_build_time_millis', () {
      test('throws when there is no data', () {
        expect(
          () => summarize(<Map<String, dynamic>>[]).computeWorstFrameBuildTimeMillis(),
          throwsA(predicate<ArgumentError>((ArgumentError e) => e.message == 'durations is empty!')),
        );
      });

      test('computes worst frame build time in milliseconds', () {
        expect(
          summarize(<Map<String, dynamic>>[
            frameBegin(1000), frameEnd(2000),
            frameBegin(3000), frameEnd(5000),
          ]).computeWorstFrameBuildTimeMillis(),
          2.0,
        );
        expect(
          summarize(<Map<String, dynamic>>[
            frameBegin(3000), frameEnd(5000),
            frameBegin(1000), frameEnd(2000),
          ]).computeWorstFrameBuildTimeMillis(),
          2.0,
        );
      });

      test('skips leading "end" events', () {
        expect(
          summarize(<Map<String, dynamic>>[
            frameEnd(1000),
            frameBegin(2000), frameEnd(4000),
          ]).computeWorstFrameBuildTimeMillis(),
          2.0,
        );
      });

      test('skips trailing "begin" events', () {
        expect(
          summarize(<Map<String, dynamic>>[
            frameBegin(2000), frameEnd(4000),
            frameBegin(5000),
          ]).computeWorstFrameBuildTimeMillis(),
          2.0,
        );
      });
    });

    group('computeMissedFrameBuildBudgetCount', () {
      test('computes the number of missed build budgets', () {
        final TimelineSummary summary = summarize(<Map<String, dynamic>>[
          frameBegin(1000), frameEnd(18000),
          frameBegin(19000), frameEnd(28000),
          frameBegin(29000), frameEnd(47000),
        ]);

        expect(summary.countFrames(), 3);
        expect(summary.computeMissedFrameBuildBudgetCount(), 2);
      });
    });

    group('average_frame_rasterizer_time_millis', () {
      test('throws when there is no data', () {
        expect(
          () => summarize(<Map<String, dynamic>>[]).computeAverageFrameRasterizerTimeMillis(),
          throwsA(predicate<ArgumentError>((ArgumentError e) => e.message == 'durations is empty!')),
        );
      });

      test('computes average frame rasterizer time in milliseconds', () {
        expect(
            summarize(<Map<String, dynamic>>[
              begin(1000), end(2000),
              begin(3000), end(5000),
            ]).computeAverageFrameRasterizerTimeMillis(),
            1.5,
        );
      });

      test('skips leading "end" events', () {
        expect(
            summarize(<Map<String, dynamic>>[
              end(1000),
              begin(2000), end(4000),
            ]).computeAverageFrameRasterizerTimeMillis(),
            2.0,
        );
      });

      test('skips trailing "begin" events', () {
        expect(
            summarize(<Map<String, dynamic>>[
              begin(2000), end(4000),
              begin(5000),
            ]).computeAverageFrameRasterizerTimeMillis(),
            2.0,
        );
      });
    });

    group('worst_frame_rasterizer_time_millis', () {
      test('throws when there is no data', () {
        expect(
          () => summarize(<Map<String, dynamic>>[]).computeWorstFrameRasterizerTimeMillis(),
          throwsA(predicate<ArgumentError>((ArgumentError e) => e.message == 'durations is empty!')),
        );
      });


      test('computes worst frame rasterizer time in milliseconds', () {
        expect(
            summarize(<Map<String, dynamic>>[
              begin(1000), end(2000),
              begin(3000), end(5000),
            ]).computeWorstFrameRasterizerTimeMillis(),
            2.0,
        );
        expect(
            summarize(<Map<String, dynamic>>[
              begin(3000), end(5000),
              begin(1000), end(2000),
            ]).computeWorstFrameRasterizerTimeMillis(),
            2.0,
        );
      });

      test('skips leading "end" events', () {
        expect(
            summarize(<Map<String, dynamic>>[
              end(1000),
              begin(2000), end(4000),
            ]).computeWorstFrameRasterizerTimeMillis(),
            2.0,
        );
      });

      test('skips trailing "begin" events', () {
        expect(
            summarize(<Map<String, dynamic>>[
              begin(2000), end(4000),
              begin(5000),
            ]).computeWorstFrameRasterizerTimeMillis(),
            2.0,
        );
      });
    });

    group('percentile_frame_rasterizer_time_millis', () {
      test('throws when there is no data', () {
        expect(
          () => summarize(<Map<String, dynamic>>[]).computePercentileFrameRasterizerTimeMillis(90.0),
          throwsA(predicate<ArgumentError>((ArgumentError e) => e.message == 'durations is empty!')),
        );
      });


      const List<List<int>> sequences = <List<int>>[
        <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        <int>[1, 2, 3, 4, 5],
        <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
      ];

      const List<int> p90s = <int>[
        9,
        5,
        18,
      ];

      test('computes 90th frame rasterizer time in milliseconds', () {
        for (int i = 0; i < sequences.length; ++i) {
          expect(
            summarize(rasterizeTimeSequenceInMillis(sequences[i])).computePercentileFrameRasterizerTimeMillis(90.0),
            p90s[i],
          );
        }
      });

      test('compute 99th frame rasterizer time in milliseconds', () {
        final List<int> sequence = <int>[];
        for (int i = 1; i <= 100; ++i) {
          sequence.add(i);
        }
        expect(
          summarize(rasterizeTimeSequenceInMillis(sequence)).computePercentileFrameRasterizerTimeMillis(99.0),
          99,
        );
      });
    });

    group('computeMissedFrameRasterizerBudgetCount', () {
      test('computes the number of missed rasterizer budgets', () {
        final TimelineSummary summary = summarize(<Map<String, dynamic>>[
          begin(1000), end(18000),
          begin(19000), end(28000),
          begin(29000), end(47000),
        ]);

        expect(summary.computeMissedFrameRasterizerBudgetCount(), 2);
      });
    });

    group('summaryJson', () {
      test('computes and returns summary as JSON', () {
        expect(
          summarize(<Map<String, dynamic>>[
            begin(1000), end(19000),
            begin(19000), end(29000),
            begin(29000), end(49000),
            frameBegin(1000), frameEnd(18000),
            frameBegin(19000), frameEnd(28000),
            frameBegin(29000), frameEnd(48000),
          ]).summaryJson,
          <String, dynamic>{
            'average_frame_build_time_millis': 15.0,
            '90th_percentile_frame_build_time_millis': 19.0,
            '99th_percentile_frame_build_time_millis': 19.0,
            'worst_frame_build_time_millis': 19.0,
            'missed_frame_build_budget_count': 2,
            'average_frame_rasterizer_time_millis': 16.0,
            '90th_percentile_frame_rasterizer_time_millis': 20.0,
            '99th_percentile_frame_rasterizer_time_millis': 20.0,
            'worst_frame_rasterizer_time_millis': 20.0,
            'missed_frame_rasterizer_budget_count': 2,
            'frame_count': 3,
            'frame_build_times': <int>[17000, 9000, 19000],
            'frame_rasterizer_times': <int>[18000, 10000, 20000],
            'frame_begin_times': <int>[0, 18000, 28000],
          },
        );
      });
    });

    group('writeTimelineToFile', () {

      Directory tempDir;

      setUp(() {
        useMemoryFileSystemForTesting();
        tempDir = fs.systemTempDirectory.createTempSync('flutter_driver_test.');
      });

      tearDown(() {
        tryToDelete(tempDir);
        restoreFileSystem();
      });

      test('writes timeline to JSON file', () async {
        await summarize(<Map<String, String>>[<String, String>{'foo': 'bar'}])
          .writeTimelineToFile('test', destinationDirectory: tempDir.path);
        final String written =
            await fs.file(path.join(tempDir.path, 'test.timeline.json')).readAsString();
        expect(written, '{"traceEvents":[{"foo":"bar"}]}');
      });

      test('writes summary to JSON file', () async {
        await summarize(<Map<String, dynamic>>[
          begin(1000), end(19000),
          begin(19000), end(29000),
          begin(29000), end(49000),
          frameBegin(1000), frameEnd(18000),
          frameBegin(19000), frameEnd(28000),
          frameBegin(29000), frameEnd(48000),
        ]).writeSummaryToFile('test', destinationDirectory: tempDir.path);
        final String written =
            await fs.file(path.join(tempDir.path, 'test.timeline_summary.json')).readAsString();
        expect(json.decode(written), <String, dynamic>{
          'average_frame_build_time_millis': 15.0,
          'worst_frame_build_time_millis': 19.0,
          '90th_percentile_frame_build_time_millis': 19.0,
          '99th_percentile_frame_build_time_millis': 19.0,
          'missed_frame_build_budget_count': 2,
          'average_frame_rasterizer_time_millis': 16.0,
          '90th_percentile_frame_rasterizer_time_millis': 20.0,
          '99th_percentile_frame_rasterizer_time_millis': 20.0,
          'worst_frame_rasterizer_time_millis': 20.0,
          'missed_frame_rasterizer_budget_count': 2,
          'frame_count': 3,
          'frame_build_times': <int>[17000, 9000, 19000],
          'frame_rasterizer_times': <int>[18000, 10000, 20000],
          'frame_begin_times': <int>[0, 18000, 28000],
        });
      });
    });
  });
}
