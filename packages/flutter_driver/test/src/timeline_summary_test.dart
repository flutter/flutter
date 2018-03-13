// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;

import 'package:file/file.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver/src/driver/common.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('TimelineSummary', () {

    TimelineSummary summarize(List<Map<String, dynamic>> testEvents) {
      return new TimelineSummary.summarize(new Timeline.fromJson(<String, dynamic>{
        'traceEvents': testEvents,
      }));
    }

    Map<String, dynamic> build(int timeStamp, int duration) => <String, dynamic>{
      'name': 'Frame', 'ph': 'X', 'ts': timeStamp, 'dur': duration
    };

    Map<String, dynamic> begin(int timeStamp) => <String, dynamic>{
      'name': 'GPURasterizer::Draw', 'ph': 'B', 'ts': timeStamp
    };

    Map<String, dynamic> end(int timeStamp) => <String, dynamic>{
      'name': 'GPURasterizer::Draw', 'ph': 'E', 'ts': timeStamp
    };

    group('frame_count', () {
      test('counts frames', () {
        expect(
          summarize(<Map<String, dynamic>>[
            build(1000, 1000),
            build(3000, 2000),
          ]).countFrames(),
          2
        );
      });
    });

    group('average_frame_build_time_millis', () {
      test('returns null when there is no data', () {
        expect(summarize(<Map<String, dynamic>>[]).computeAverageFrameBuildTimeMillis(), isNull);
      });

      test('computes average frame build time in milliseconds', () {
        expect(
          summarize(<Map<String, dynamic>>[
            build(1000, 1000),
            build(3000, 2000),
          ]).computeAverageFrameBuildTimeMillis(),
          1.5
        );
      });
    });

    group('worst_frame_build_time_millis', () {
      test('returns null when there is no data', () {
        expect(summarize(<Map<String, dynamic>>[]).computeWorstFrameBuildTimeMillis(), isNull);
      });

      test('computes worst frame build time in milliseconds', () {
        expect(
          summarize(<Map<String, dynamic>>[
            build(1000, 1000),
            build(3000, 2000),
          ]).computeWorstFrameBuildTimeMillis(),
          2.0
        );
        expect(
          summarize(<Map<String, dynamic>>[
            build(3000, 2000),
            build(1000, 1000),
          ]).computeWorstFrameBuildTimeMillis(),
          2.0
        );
      });
    });

    group('computeMissedFrameBuildBudgetCount', () {
      test('computes the number of missed build budgets', () {
        final TimelineSummary summary = summarize(<Map<String, dynamic>>[
          build(1000, 9000),
          build(11000, 1000),
          build(13000, 10000),
        ]);

        expect(summary.countFrames(), 3);
        expect(summary.computeMissedFrameBuildBudgetCount(), 2);
      });
    });

    group('average_frame_rasterizer_time_millis', () {
      test('returns null when there is no data', () {
        expect(summarize(<Map<String, dynamic>>[]).computeAverageFrameRasterizerTimeMillis(), isNull);
      });

      test('computes average frame rasterizer time in milliseconds', () {
        expect(
            summarize(<Map<String, dynamic>>[
              begin(1000), end(2000),
              begin(3000), end(5000),
            ]).computeAverageFrameRasterizerTimeMillis(),
            1.5
        );
      });

      test('skips leading "end" events', () {
        expect(
            summarize(<Map<String, dynamic>>[
              end(1000),
              begin(2000), end(4000),
            ]).computeAverageFrameRasterizerTimeMillis(),
            2.0
        );
      });

      test('skips trailing "begin" events', () {
        expect(
            summarize(<Map<String, dynamic>>[
              begin(2000), end(4000),
              begin(5000),
            ]).computeAverageFrameRasterizerTimeMillis(),
            2.0
        );
      });
    });

    group('worst_frame_rasterizer_time_millis', () {
      test('returns null when there is no data', () {
        expect(summarize(<Map<String, dynamic>>[]).computeWorstFrameRasterizerTimeMillis(), isNull);
      });

      test('computes worst frame rasterizer time in milliseconds', () {
        expect(
            summarize(<Map<String, dynamic>>[
              begin(1000), end(2000),
              begin(3000), end(5000),
            ]).computeWorstFrameRasterizerTimeMillis(),
            2.0
        );
        expect(
            summarize(<Map<String, dynamic>>[
              begin(3000), end(5000),
              begin(1000), end(2000),
            ]).computeWorstFrameRasterizerTimeMillis(),
            2.0
        );
      });

      test('skips leading "end" events', () {
        expect(
            summarize(<Map<String, dynamic>>[
              end(1000),
              begin(2000), end(4000),
            ]).computeWorstFrameRasterizerTimeMillis(),
            2.0
        );
      });

      test('skips trailing "begin" events', () {
        expect(
            summarize(<Map<String, dynamic>>[
              begin(2000), end(4000),
              begin(5000),
            ]).computeWorstFrameRasterizerTimeMillis(),
            2.0
        );
      });
    });

    group('computeMissedFrameRasterizerBudgetCount', () {
      test('computes the number of missed rasterizer budgets', () {
        final TimelineSummary summary = summarize(<Map<String, dynamic>>[
          begin(1000), end(10000),
          begin(11000), end(12000),
          begin(13000), end(23000),
        ]);

        expect(summary.computeMissedFrameRasterizerBudgetCount(), 2);
      });
    });

    group('summaryJson', () {
      test('computes and returns summary as JSON', () {
        expect(
          summarize(<Map<String, dynamic>>[
            begin(1000), end(11000),
            begin(11000), end(13000),
            begin(13000), end(25000),
            build(1000, 9000),
            build(11000, 1000),
            build(13000, 11000),
          ]).summaryJson,
          <String, dynamic>{
            'average_frame_build_time_millis': 7.0,
            'worst_frame_build_time_millis': 11.0,
            'missed_frame_build_budget_count': 2,
            'average_frame_rasterizer_time_millis': 8.0,
            'worst_frame_rasterizer_time_millis': 12.0,
            'missed_frame_rasterizer_budget_count': 2,
            'frame_count': 3,
            'frame_build_times': <int>[9000, 1000, 11000],
            'frame_rasterizer_times': <int>[10000, 2000, 12000],
          }
        );
      });
    });

    group('writeTimelineToFile', () {

      Directory tempDir;

      setUp(() {
        useMemoryFileSystemForTesting();
        tempDir = fs.systemTempDirectory.createTempSync('flutter_driver_test');
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
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
          begin(1000), end(11000),
          begin(11000), end(13000),
          begin(13000), end(25000),
          build(1000, 9000),
          build(11000, 1000),
          build(13000, 11000),
        ]).writeSummaryToFile('test', destinationDirectory: tempDir.path);
        final String written =
            await fs.file(path.join(tempDir.path, 'test.timeline_summary.json')).readAsString();
        expect(json.decode(written), <String, dynamic>{
          'average_frame_build_time_millis': 7.0,
          'worst_frame_build_time_millis': 11.0,
          'missed_frame_build_budget_count': 2,
          'average_frame_rasterizer_time_millis': 8.0,
          'worst_frame_rasterizer_time_millis': 12.0,
          'missed_frame_rasterizer_budget_count': 2,
          'frame_count': 3,
          'frame_build_times': <int>[9000, 1000, 11000],
          'frame_rasterizer_times': <int>[10000, 2000, 12000],
        });
      });
    });
  });
}
