// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/metrics_center.dart';
import 'package:metrics_center/metrics_center.dart';

import 'common.dart';

void main() {
  group('Parse', () {
    test('succeeds', () {
      final Map<String, dynamic> results = <String, dynamic>{
        'CommitBranch': 'master',
        'CommitSha': 'abc',
        'BuilderName': 'test',
        'ResultData': <String, dynamic>{
          'average_frame_build_time_millis': 0.4550425531914895,
          '90th_percentile_frame_build_time_millis': 0.473,
        },
        'BenchmarkScoreKeys': <String>[
          'average_frame_build_time_millis',
          '90th_percentile_frame_build_time_millis',
        ],
      };
      final List<MetricPoint> metricPoints = parse(results);

      expect(metricPoints[0].value, equals(0.4550425531914895));
      expect(metricPoints[1].value, equals(0.473));
    });

    test('succeeds - null ResultData', () {
      final Map<String, dynamic> results = <String, dynamic>{
        'CommitBranch': 'master',
        'CommitSha': 'abc',
        'BuilderName': 'test',
        'ResultData': null,
        'BenchmarkScoreKeys': null,
      };
      final List<MetricPoint> metricPoints = parse(results);

      expect(metricPoints.length, 0);
    });
  });
}
