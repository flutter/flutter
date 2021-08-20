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
  // final bool isTesting = env['IS_TESTING'] == 'true';
  const bool isTesting = true;
  if (env.containsKey(kTokenPath) && env.containsKey(kGcpProject)) {
    return FlutterDestination.makeFromAccessToken(
      File(env[kTokenPath]!).readAsStringSync(),
      env[kGcpProject]!,
      // 'flutter-infra',
      isTesting: isTesting,
    );
  }
  const String credential = '''
  {
  "type": "service_account",
  "project_id": "flutter-cirrus",
  "private_key_id": "125a218c3fe0a9efbf321b1c4832d162e8b64211",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDc0re5aRMObI+m\\n/pMwritbMcK3aRYwreujmO03yIgl9z9PaNxkMmU23R/LqKrEYKP93iBCSv/GOmaj\\nEmhDrmf+jRYm/lAoBMFg2sgnAjQiMcmz7dS2Z2pB7dBkw0kpxnB0XuLqqnM0TbiW\\n1cF77H/2zwJBreIcxf8LzusP5grpdOMxz6LsH6kolpdVAsxF6j9vg7p2eS7H2hzp\\nMu/BMQFGS6uOsXLmGQeQqRnwvx31C4BofX3aAFBfiuDVIw5WGf32Gd3/oKNZqg2G\\n1e2jF/jLx7lTQxgT0FVECUH0zUjau9DAAzzYeKTgOim2YgfprDZRP5NmgoIkLjFw\\nVO9QmtJRAgMBAAECggEANEUouhm2Kg7mfhf6jWZc2uxPdAzK9ODmS0ZSuIaeO6Zn\\n9QsUSB9pt+/lq9aT/YIGr3wZ1LdeDfUbAHTF+2dYNHf/C2HdZWuivqNrB1jNMF7q\\nqM2eMUMPcuWxE3jqY5oWWmVvfy6zsGjJTeLxNr1HmQttNFDNmhQACDKFj7DbWmEh\\nDPLuSC5eQ1NI3U+iATmDbveqtR6fPi1S0/mjc61l2mWKvmiq9vHSW62Iq/0eNhv1\\nHPRGKXGh2GevFGzmRhxanGdrdHZPbMHCSak5UA+UPbKRt2eJUYH9kJ9yD2PeTMRP\\npNv+EXOcrB/IC1V/TjMBHAVMqh3Ov6Vv6LY4rkjaFQKBgQD40J7Jatn9WlZjjZjP\\ncxmRKRPLBqReLuQEbrlrVdwBGJQg9MeLYWCjgJX0GIfuBizKjzKFX4iQ9VcAUYxu\\nhDdLSIth72pfJzBFOZFnM3JpHrZhhs0Vpjv0t0qjjmXHJNJMAYEOG4R2/6YDudu+\\ntJYVMNsh4pjFWvL6yHjUX/HCuwKBgQDjMyqO9lhcYp0j2CwQ19b9gt3x5jJgd7/W\\nBM4/3RF7KDLcVn67evAdNdE7XxeddHx38z6bxe+mCKHjx5g64Az3BJbSE0CVCnAp\\nLglyh5fkcZi8xtAiD+yMNGhd1EtTbX10a6xML/arRBi1X3adX8GZfmpn66vwSD8Q\\n3O3SfJdMYwKBgBT9vLevbQ6jxXAGrSKrSjfl6EaTm+BaQmBhWwFEMBhjk3OoUwFe\\nSMHigkQioa0iFjtMk22PHr1kBWAAgUF9pBCU4TV09ltqufbNIYg8XeWicq6NqdWu\\nvZYqtIBR7iI76AYDhnjDN4y2irH7xx8yqwrEoWgdbtgPkTo5GYCJS6MrAoGAYUGH\\n2EbPsExuY+enhVY/q6mXhHM74VuhfOX1vBTP5N5iVzuXaH3Jx1dAR5//JeG1Xkt7\\n44apfXN4iV7pZVp/ckY+oZKoNKSROq+AT8yHUrzl2vloIwyZ/7J3cqLr07ys1Wc6\\nDCsD9nBh+1HwHpHc9+3LcszJf0QN6xQHofC/e20CgYArTgbxW+kIjuhf+nF31Xch\\neuOkymJgZ5bCqCr37dxmvuh7huW7xl6izA0hUcEvX7GmqQXNerfR99V4HhULKWiN\\nvdW7VVIN2BY5cOFTyhpvJRNFh9gkDvFsNDfMqMUJVp15JXFWko01wcEJGEsGMxmX\\nFtXOLqjJkWk5dAm4CvwlnQ==\\n-----END PRIVATE KEY-----\\n",
  "client_email": "metrics-center@flutter-cirrus.iam.gserviceaccount.com",
  "client_id": "101597572749149071496",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/metrics-center%40flutter-cirrus.iam.gserviceaccount.com"
}''';
  final Map<String, dynamic> map = jsonDecode(credential) as Map<String, dynamic>;
  return FlutterDestination.makeFromCredentialsJson(
    // jsonDecode(env['BENCHMARK_GCP_CREDENTIALS']!) as Map<String, dynamic>,
    map,
    isTesting: isTesting,
  );
}

/// Parse results into Metric Points.
///
/// An example of `resultsJson`:
///   {
///     CommitBranch: master,
///     CommitSha: abc,
///     BuilderName: test,
///     ResultData: {
///       average_frame_build_time_millis: 0.4550425531914895,
///       90th_percentile_frame_build_time_millis: 0.473
///     },
///     BenchmarkScoreKeys: [
///       average_frame_build_time_millis,
///       90th_percentile_frame_build_time_millis
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
