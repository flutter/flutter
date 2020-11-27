// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Timeout(Duration(seconds: 3600))

import 'dart:convert';

import 'package:metrics_center/src/common.dart';
import 'package:metrics_center/src/flutter.dart';
import 'package:metrics_center/src/skiaperf.dart';

import 'common.dart';

void main() {
  const double kValue1 = 1.0;
  const double kValue2 = 2.0;

  const String kFrameworkRevision1 = '9011cece2595447eea5dd91adaa241c1c9ef9a33';
  const String kTaskName = 'analyzer_benchmark';
  const String kMetric1 = 'flutter_repo_batch_maximum';
  const String kMetric2 = 'flutter_repo_watch_maximum';

  final MetricPoint cocoonPointRev1Metric1 = MetricPoint(
    kValue1,
    const <String, String>{
      kGithubRepoKey: kFlutterFrameworkRepo,
      kGitRevisionKey: kFrameworkRevision1,
      kNameKey: kTaskName,
      kSubResultKey: kMetric1,
      kUnitKey: 's',
    },
  );

  final MetricPoint cocoonPointRev1Metric2 = MetricPoint(
    kValue2,
    const <String, String>{
      kGithubRepoKey: kFlutterFrameworkRepo,
      kGitRevisionKey: kFrameworkRevision1,
      kNameKey: kTaskName,
      kSubResultKey: kMetric2,
      kUnitKey: 's',
    },
  );

  final MetricPoint cocoonPointBetaRev1Metric1 = MetricPoint(
    kValue1,
    const <String, String>{
      kGithubRepoKey: kFlutterFrameworkRepo,
      kGitRevisionKey: kFrameworkRevision1,
      kNameKey: 'beta/$kTaskName',
      kSubResultKey: kMetric1,
      kUnitKey: 's',
      'branch': 'beta',
    },
  );

  final MetricPoint cocoonPointBetaRev1Metric1BadBranch = MetricPoint(
    kValue1,
    const <String, String>{
      kGithubRepoKey: kFlutterFrameworkRepo,
      kGitRevisionKey: kFrameworkRevision1,
      kNameKey: kTaskName,
      kSubResultKey: kMetric1,
      kUnitKey: 's',

      // If we only add this 'branch' tag without changing the test or sub-result name, an exception
      // would be thrown as Skia Perf currently only supports the same set of tags for a pair of
      // kNameKey and kSubResultKey values. So to support branches, one also has to add the branch
      // name to the test name.
      'branch': 'beta',
    },
  );

  const String engineMetricName = 'BM_PaintRecordInit';
  const String engineRevision = 'ca799fa8b2254d09664b78ee80c43b434788d112';
  const double engineValue1 = 101;
  const double engineValue2 = 102;

  final FlutterEngineMetricPoint enginePoint1 = FlutterEngineMetricPoint(
    engineMetricName,
    engineValue1,
    engineRevision,
    moreTags: const <String, String>{
      kSubResultKey: 'cpu_time',
      kUnitKey: 'ns',
      'date': '2019-12-17 15:14:14',
      'num_cpus': '56',
      'mhz_per_cpu': '2594',
      'cpu_scaling_enabled': 'true',
      'library_build_type': 'release',
    },
  );

  final FlutterEngineMetricPoint enginePoint2 = FlutterEngineMetricPoint(
    engineMetricName,
    engineValue2,
    engineRevision,
    moreTags: const <String, String>{
      kSubResultKey: 'real_time',
      kUnitKey: 'ns',
      'date': '2019-12-17 15:14:14',
      'num_cpus': '56',
      'mhz_per_cpu': '2594',
      'cpu_scaling_enabled': 'true',
      'library_build_type': 'release',
    },
  );

  test('Throw if invalid points are converted to SkiaPoint', () {
    final MetricPoint noGithubRepoPoint = MetricPoint(
      kValue1,
      const <String, String>{
        kGitRevisionKey: kFrameworkRevision1,
        kNameKey: kTaskName,
      },
    );

    final MetricPoint noGitRevisionPoint = MetricPoint(
      kValue1,
      const <String, String>{
        kGithubRepoKey: kFlutterFrameworkRepo,
        kNameKey: kTaskName,
      },
    );

    final MetricPoint noTestNamePoint = MetricPoint(
      kValue1,
      const <String, String>{
        kGithubRepoKey: kFlutterFrameworkRepo,
        kGitRevisionKey: kFrameworkRevision1,
      },
    );

    expect(() => SkiaPerfPoint.fromPoint(noGithubRepoPoint), throwsA(anything));
    expect(
        () => SkiaPerfPoint.fromPoint(noGitRevisionPoint), throwsA(anything));
    expect(() => SkiaPerfPoint.fromPoint(noTestNamePoint), throwsA(anything));
  });

  test('Correctly convert a metric point from cocoon to SkiaPoint', () {
    final SkiaPerfPoint skiaPoint1 =
        SkiaPerfPoint.fromPoint(cocoonPointRev1Metric1);
    expect(skiaPoint1, isNotNull);
    expect(skiaPoint1.testName, equals(kTaskName));
    expect(skiaPoint1.subResult, equals(kMetric1));
    expect(skiaPoint1.value, equals(cocoonPointRev1Metric1.value));
    expect(skiaPoint1.jsonUrl, isNull); // Not inserted yet
  });

  test('Cocoon points correctly encode into Skia perf json format', () {
    final SkiaPerfPoint p1 = SkiaPerfPoint.fromPoint(cocoonPointRev1Metric1);
    final SkiaPerfPoint p2 = SkiaPerfPoint.fromPoint(cocoonPointRev1Metric2);
    final SkiaPerfPoint p3 =
        SkiaPerfPoint.fromPoint(cocoonPointBetaRev1Metric1);

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');

    expect(
        encoder
            .convert(SkiaPerfPoint.toSkiaPerfJson(<SkiaPerfPoint>[p1, p2, p3])),
        equals('''
{
  "gitHash": "9011cece2595447eea5dd91adaa241c1c9ef9a33",
  "results": {
    "analyzer_benchmark": {
      "default": {
        "flutter_repo_batch_maximum": 1.0,
        "options": {
          "unit": "s"
        },
        "flutter_repo_watch_maximum": 2.0
      }
    },
    "beta/analyzer_benchmark": {
      "default": {
        "flutter_repo_batch_maximum": 1.0,
        "options": {
          "branch": "beta",
          "unit": "s"
        }
      }
    }
  }
}'''));
  });

  test('Engine metric points correctly encode into Skia perf json format', () {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    expect(
      encoder.convert(SkiaPerfPoint.toSkiaPerfJson(<SkiaPerfPoint>[
        SkiaPerfPoint.fromPoint(enginePoint1),
        SkiaPerfPoint.fromPoint(enginePoint2),
      ])),
      equals(
        '''
{
  "gitHash": "ca799fa8b2254d09664b78ee80c43b434788d112",
  "results": {
    "BM_PaintRecordInit": {
      "default": {
        "cpu_time": 101.0,
        "options": {
          "cpu_scaling_enabled": "true",
          "library_build_type": "release",
          "mhz_per_cpu": "2594",
          "num_cpus": "56",
          "unit": "ns"
        },
        "real_time": 102.0
      }
    }
  }
}''',
      ),
    );
  });

  test(
      'Throw if engine points with the same test name but different options are converted to '
      'Skia perf points', () {
    final FlutterEngineMetricPoint enginePoint1 = FlutterEngineMetricPoint(
      'BM_PaintRecordInit',
      101,
      'ca799fa8b2254d09664b78ee80c43b434788d112',
      moreTags: const <String, String>{
        kSubResultKey: 'cpu_time',
        kUnitKey: 'ns',
        'cpu_scaling_enabled': 'true',
      },
    );
    final FlutterEngineMetricPoint enginePoint2 = FlutterEngineMetricPoint(
      'BM_PaintRecordInit',
      102,
      'ca799fa8b2254d09664b78ee80c43b434788d112',
      moreTags: const <String, String>{
        kSubResultKey: 'real_time',
        kUnitKey: 'ns',
        'cpu_scaling_enabled': 'false',
      },
    );

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    expect(
      () => encoder.convert(SkiaPerfPoint.toSkiaPerfJson(<SkiaPerfPoint>[
        SkiaPerfPoint.fromPoint(enginePoint1),
        SkiaPerfPoint.fromPoint(enginePoint2),
      ])),
      throwsA(anything),
    );
  });

  test(
      'Throw if two Cocoon metric points with the same name and subResult keys '
      'but different options are converted to Skia perf points', () {
    final SkiaPerfPoint p1 = SkiaPerfPoint.fromPoint(cocoonPointRev1Metric1);
    final SkiaPerfPoint p2 =
        SkiaPerfPoint.fromPoint(cocoonPointBetaRev1Metric1BadBranch);

    expect(
      () => SkiaPerfPoint.toSkiaPerfJson(<SkiaPerfPoint>[p1, p2]),
      throwsA(anything),
    );
  });
}
