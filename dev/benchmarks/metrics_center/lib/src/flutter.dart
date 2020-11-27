// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:metrics_center/src/common.dart';

/// Convenient class to capture the benchmarks in the Flutter engine repo.
class FlutterEngineMetricPoint extends MetricPoint {
  FlutterEngineMetricPoint(
    String name,
    double value,
    String gitRevision, {
    Map<String, String> moreTags = const <String, String>{},
  }) : super(
          value,
          <String, String>{
            kNameKey: name,
            kGithubRepoKey: kFlutterEngineRepo,
            kGitRevisionKey: gitRevision,
          }..addAll(moreTags),
        );
}
