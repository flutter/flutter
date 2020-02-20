// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:convert';
import 'dart:io';

import 'package:git/git.dart';
import 'package:metrics_center/flutter.dart';
import 'package:metrics_center/google_benchmark.dart';

Future<String> _getGitRevision() async {
  final GitDir gitDir = await GitDir.fromExisting('../../');
  // Somehow gitDir.currentBranch() doesn't work in Cirrus with "fatal: 'HEAD' -
  // not a valid ref". Therefore, we use "git log" to get the revision manually.
  final ProcessResult logResult =
      await gitDir.runCommand(<String>['log', '--pretty=format:%H', '-n', '1']);
  if (logResult.exitCode != 0) {
    throw 'Unexpected exit code ${logResult.exitCode}';
  }
  return logResult.stdout.toString();
}

Future<List<FlutterEngineMetricPoint>> _parse(String jsonFileName) async {
  final String gitRevision = await _getGitRevision();
  final List<MetricPoint> rawPoints =
      await GoogleBenchmarkParser.parse(jsonFileName);
  final List<FlutterEngineMetricPoint> points = <FlutterEngineMetricPoint>[];
  for (MetricPoint rawPoint in rawPoints) {
    points.add(FlutterEngineMetricPoint(
      rawPoint.tags[kNameKey],
      rawPoint.value,
      gitRevision,
      moreTags: rawPoint.tags,
    ));
  }
  return points;
}

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw 'Must have one argument: <benchmark_json_file>';
  }
  final List<FlutterEngineMetricPoint> points = await _parse(args[0]);
  // The data will be sent to the Datastore of the GCP project specified through
  // environment variable BENCHMARK_GCP_CREDENTIALS. The engine Cirrus job has
  // currently configured the GCP project to flutter-cirrus for test. We'll
  // eventually migrate to flutter-infra project once the test is done.
  final FlutterDestination destination =
      await FlutterDestination.makeFromCredentialsJson(
    jsonDecode(Platform.environment['BENCHMARK_GCP_CREDENTIALS']),
  );
  await destination.update(points);
}
