// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/metrics_center.dart';
import 'package:metrics_center/metrics_center.dart';

import 'common.dart';

void main() {
  group('Git', () {
    test('returns expected commit sha', () async {
      final ProcessResult result = await runGit(<String>['--version']);
      expect(result.exitCode, equals(0));
    });

    test('getCommitDate succeeds', () async {
      final String commitDateString = await getCommitDate();

      // Check that commitDate is an int
      final int? secondsSinceEpoch = int.tryParse(commitDateString);
      expect(secondsSinceEpoch, isNotNull);

      // Check that commitDate is a Unix Epoch
      final int millisecondsSinceEpoch = secondsSinceEpoch! * 1000;
      final DateTime commitDate = DateTime.fromMillisecondsSinceEpoch(
        millisecondsSinceEpoch,
        isUtc: true,
      );
      expect(commitDate.year > 2000, true);
      expect(commitDate.year < 3000, true);
    });
  });

  group('Parse', () {
    test('succeeds', () {
      final Map<String, dynamic> results = <String, dynamic>{
        'CommitBranch': 'master',
        'CommitSha': 'abc',
        'BuilderName': 'test',
        'ResultData': <String, dynamic>{
          'average_frame_build_time_millis': 0.4550425531914895,
          '90th_percentile_frame_build_time_millis': 0.473
        },
        'BenchmarkScoreKeys': <String>[
          'average_frame_build_time_millis',
          '90th_percentile_frame_build_time_millis'
        ]
      };
      final List<MetricPoint> metricPoints = parse(results);

      expect(metricPoints[0].value, equals(0.4550425531914895));
      expect(metricPoints[1].value, equals(0.473));
    });
  });
}
