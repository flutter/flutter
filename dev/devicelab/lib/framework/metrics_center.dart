// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:metrics_center/metrics_center.dart';

/// Authenticate and connect to gcloud storage.
///
/// It supports both token and credential authentications.
Future<FlutterDestination> connectFlutterDestination() async {
  const String kTokenPath = 'TOKEN_PATH';
  const String kGcpProject = 'GCP_PROJECT';
  final Map<String, String> env = Platform.environment;
  final bool isTesting = env['IS_TESTING'] == 'true';
  if (env.containsKey(kTokenPath) && env.containsKey(kGcpProject)) {
    return FlutterDestination.makeFromAccessToken(
      File(env[kTokenPath]!).readAsStringSync(),
      env[kGcpProject]!,
      isTesting: isTesting,
    );
  }
  return FlutterDestination.makeFromCredentialsJson(
    jsonDecode(env['BENCHMARK_GCP_CREDENTIALS']!) as Map<String, dynamic>,
    isTesting: isTesting,
  );
}

/// Parse results into Metric Points.
///
/// An example of `resultsJson`:
///   {
///     "CommitBranch": "master",
///     "CommitSha": "abc",
///     "BuilderName": "test",
///     "ResultData": {
///       "average_frame_build_time_millis": 0.4550425531914895,
///       "90th_percentile_frame_build_time_millis": 0.473
///     },
///     "BenchmarkScoreKeys": [
///       "average_frame_build_time_millis",
///       "90th_percentile_frame_build_time_millis"
///     ]
///   }
List<MetricPoint> parse(Map<String, dynamic> resultsJson) {
  final List<String> scoreKeys = (resultsJson['BenchmarkScoreKeys'] as List<dynamic>).cast<String>();
  final Map<String, dynamic> resultData = resultsJson['ResultData'] as Map<String, dynamic>;
  final String gitBranch = (resultsJson['CommitBranch'] as String).trim();
  final String gitSha = (resultsJson['CommitSha'] as String).trim();
  final String builderName = resultsJson['BuilderName'] as String;
  final List<MetricPoint> metricPoints = <MetricPoint>[];
  for (final String scoreKey in scoreKeys) {
    metricPoints.add(
      MetricPoint(
        (resultData[scoreKey] as num).toDouble(),
        <String, String>{
          kGithubRepoKey: kFlutterFrameworkRepo,
          kGitRevisionKey: gitSha,
          'branch': gitBranch,
          kNameKey: builderName,
          kSubResultKey: scoreKey,
        },
      ),
    );
  }
  return metricPoints;
}

/// Upload test metrics to metrics center.
Future<void> uploadToMetricsCenter(String? resultsPath, String? commitTime) async {
  int commitTimeSinceEpoch;
  if (resultsPath == null) {
    return;
  }
  if (commitTime != null) {
    commitTimeSinceEpoch = 1000 * int.parse(commitTime);
  } else {
    commitTimeSinceEpoch = DateTime.now().millisecondsSinceEpoch;
  }
  final File resultFile = File(resultsPath);
  Map<String, dynamic> resultsJson = <String, dynamic>{};
  resultsJson = json.decode(await resultFile.readAsString()) as Map<String, dynamic>;
  final List<MetricPoint> metricPoints = parse(resultsJson);
  final FlutterDestination metricsDestination = await connectFlutterDestination();
  await metricsDestination.update(
    metricPoints,
    DateTime.fromMillisecondsSinceEpoch(
      commitTimeSinceEpoch,
      isUtc: true,
    ),
  );
}
