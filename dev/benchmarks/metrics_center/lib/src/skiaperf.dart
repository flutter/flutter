// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file uses Dart 2.12 semantics. This is needed as we can't upgrade
// the SDK constraint to `>=2.12.0-0` before the deps are ready.
// @dart=2.12

import 'package:metrics_center/src/common.dart';

// Skia Perf Format is a JSON file that looks like:

// {
//     "gitHash": "fe4a4029a080bc955e9588d05a6cd9eb490845d4",
//     "key": {
//         "arch": "x86",
//         "gpu": "GTX660",
//         "model": "ShuttleA",
//         "os": "Ubuntu12"
//     },
//     "results": {
//         "ChunkAlloc_PushPop_640_480": {
//             "nonrendering": {
//                 "min_ms": 0.01485466666666667,
//                 "options": {
//                     "source_type": "bench"
//                 }
//             }
//         },
//         "DeferredSurfaceCopy_discardable_640_480": {
//             "565": {
//                 "min_ms": 2.215988,
//                 "options": {
//                     "source_type": "bench"
//                 }
//             },
//     ...

class SkiaPerfPoint extends MetricPoint {
  SkiaPerfPoint._(this.githubRepo, this.gitHash, this.testName, this.subResult,
      double value, this._options, this.jsonUrl)
      : assert(_options[kGithubRepoKey] == null),
        assert(_options[kGitRevisionKey] == null),
        assert(_options[kNameKey] == null),
        super(
          value,
          <String, String>{}
            ..addAll(_options)
            ..addAll(<String, String>{
              kGithubRepoKey: githubRepo,
              kGitRevisionKey: gitHash,
              kNameKey: testName,
              kSubResultKey: subResult,
            }),
        ) {
    assert(tags[kGithubRepoKey] != null);
    assert(tags[kGitRevisionKey] != null);
    assert(tags[kNameKey] != null);
  }

  /// Construct [SkiaPerfPoint] from a well-formed [MetricPoint].
  ///
  /// The [MetricPoint] must have [kGithubRepoKey], [kGitRevisionKey],
  /// [kNameKey] in its tags for this to be successful.
  ///
  /// If the [MetricPoint] has a tag 'date', that tag will be removed so Skia
  /// perf can plot multiple metrics with different date as a single trace.
  /// Skia perf will use the git revision's date instead of this date tag in
  /// the time axis.
  factory SkiaPerfPoint.fromPoint(MetricPoint p) {
    final String githubRepo = p.tags[kGithubRepoKey]!;
    final String gitHash = p.tags[kGitRevisionKey]!;
    final String name = p.tags[kNameKey]!;
    final String subResult = p.tags[kSubResultKey] ?? kSkiaPerfValueKey;

    final Map<String, String> options = <String, String>{}..addEntries(
        p.tags.entries.where(
          (MapEntry<String, dynamic> entry) =>
              entry.key != kGithubRepoKey &&
              entry.key != kGitRevisionKey &&
              entry.key != kNameKey &&
              entry.key != kSubResultKey &&
              // https://github.com/google/benchmark automatically generates a
              // 'date' field. If it's included in options, the Skia perf won't
              // be able to connect different points in a single trace because
              // the date is always different.
              entry.key != 'date',
        ),
      );

    return SkiaPerfPoint._(
        githubRepo, gitHash, name, subResult, p.value, options, null);
  }

  /// In the format of '<owner>/<name>' such as 'flutter/flutter' or
  /// 'flutter/engine'.
  final String githubRepo;

  /// SHA such as 'ad20d368ffa09559754e4b2b5c12951341ca3b2d'
  final String gitHash;

  /// For Flutter devicelab, this is the task name (e.g.,
  /// 'flutter_gallery__transition_perf'); for Google benchmark, this is the
  /// benchmark name (e.g., 'BM_ShellShutdown').
  ///
  /// In Skia perf web dashboard, this value can be queried and filtered by
  /// "test".
  final String testName;

  /// The name of "subResult" comes from the special treatment of "sub_result"
  /// in SkiaPerf. If not provided, its value will be set to kSkiaPerfValueKey.
  ///
  /// When Google benchmarks are converted to SkiaPerfPoint, this subResult
  /// could be "cpu_time" or "real_time".
  ///
  /// When devicelab benchmarks are converted to SkiaPerfPoint, this subResult
  /// is often the metric name such as "average_frame_build_time_millis" whereas
  /// the [testName] is the benchmark or task name such as
  /// "flutter_gallery__transition_perf".
  final String subResult;

  /// The url to the Skia perf json file in the Google Cloud Storage bucket.
  ///
  /// This can be null if the point has been stored in the bucket yet.
  final String? jsonUrl;

  Map<String, dynamic> _toSubResultJson() {
    return <String, dynamic>{
      subResult: value,
      kSkiaPerfOptionsKey: _options,
    };
  }

  /// Convert a list of SkiaPoints with the same git repo and git revision into
  /// a single json file in the Skia perf format.
  ///
  /// The list must be non-empty.
  static Map<String, dynamic> toSkiaPerfJson(List<SkiaPerfPoint> points) {
    assert(points.isNotEmpty);
    assert(() {
      for (final SkiaPerfPoint p in points) {
        if (p.githubRepo != points[0].githubRepo ||
            p.gitHash != points[0].gitHash) {
          return false;
        }
      }
      return true;
    }(), 'All points must have same githubRepo and gitHash');

    final Map<String, dynamic> results = <String, dynamic>{};
    for (final SkiaPerfPoint p in points) {
      final Map<String, dynamic> subResultJson = p._toSubResultJson();
      if (results[p.testName] == null) {
        results[p.testName] = <String, dynamic>{
          kSkiaPerfDefaultConfig: subResultJson,
        };
      } else {
        // Flutter currently doesn't support having the same name but different
        // options/configurations. If this actually happens in the future, we
        // probably can use different values of config (currently there's only
        // one kSkiaPerfDefaultConfig) to resolve the conflict.
        assert(results[p.testName][kSkiaPerfDefaultConfig][kSkiaPerfOptionsKey]
                .toString() ==
            subResultJson[kSkiaPerfOptionsKey].toString());
        assert(
            results[p.testName][kSkiaPerfDefaultConfig][p.subResult] == null);
        results[p.testName][kSkiaPerfDefaultConfig][p.subResult] = p.value;
      }
    }

    return <String, dynamic>{
      kSkiaPerfGitHashKey: points[0].gitHash,
      kSkiaPerfResultsKey: results,
    };
  }

  // Equivalent to tags without git repo, git hash, and name because those two
  // are already stored somewhere else.
  final Map<String, String> _options;
}

const String kSkiaPerfGitHashKey = 'gitHash';
const String kSkiaPerfResultsKey = 'results';
const String kSkiaPerfValueKey = 'value';
const String kSkiaPerfOptionsKey = 'options';

const String kSkiaPerfDefaultConfig = 'default';
