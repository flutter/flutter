// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../framework/benchmarks.dart';
import '../framework/framework.dart';
import '../framework/utils.dart';

TaskFunction createAnalyzerCliTest({
  @required String sdk,
  @required String commit,
  @required DateTime timestamp,
}) {
  return new AnalyzerCliTask(sdk, commit, timestamp);
}

TaskFunction createAnalyzerServerTest({
  @required String sdk,
  @required String commit,
  @required DateTime timestamp,
}) {
  return new AnalyzerServerTask(sdk, commit, timestamp);
}

abstract class AnalyzerTask {
  Benchmark benchmark;

  Future<TaskResult> call() async {
    section(benchmark.name);
    await runBenchmark(benchmark, iterations: 3, warmUpBenchmark: true);
    return benchmark.bestResult;
  }
}

class AnalyzerCliTask extends AnalyzerTask {
  AnalyzerCliTask(String sdk, String commit, DateTime timestamp) {
    benchmark = new FlutterAnalyzeBenchmark(sdk, commit, timestamp);
  }
}

class AnalyzerServerTask extends AnalyzerTask {
  AnalyzerServerTask(String sdk, String commit, DateTime timestamp) {
    benchmark = new FlutterAnalyzeAppBenchmark(sdk, commit, timestamp);
  }
}

class FlutterAnalyzeBenchmark extends Benchmark {
  FlutterAnalyzeBenchmark(this.sdk, this.commit, this.timestamp)
      : super('flutter analyze --flutter-repo');

  final String sdk;
  final String commit;
  final DateTime timestamp;

  File get benchmarkFile =>
      file(path.join(flutterDirectory.path, 'analysis_benchmark.json'));

  @override
  TaskResult get lastResult => new TaskResult.successFromFile(benchmarkFile);

  @override
  Future<num> run() async {
    rm(benchmarkFile);
    await inDirectory(flutterDirectory, () async {
      await flutter('analyze', options: <String>[
        '--flutter-repo',
        '--benchmark',
      ]);
    });
    return addBuildInfo(benchmarkFile,
        timestamp: timestamp, expected: 25.0, sdk: sdk, commit: commit);
  }
}

class FlutterAnalyzeAppBenchmark extends Benchmark {
  FlutterAnalyzeAppBenchmark(this.sdk, this.commit, this.timestamp)
      : super('analysis server mega_gallery');

  final String sdk;
  final String commit;
  final DateTime timestamp;

  @override
  TaskResult get lastResult => new TaskResult.successFromFile(benchmarkFile);

  Directory get megaDir => dir(
      path.join(flutterDirectory.path, 'dev/benchmarks/mega_gallery'));
  File get benchmarkFile =>
      file(path.join(megaDir.path, 'analysis_benchmark.json'));

  @override
  Future<Null> init() {
    return inDirectory(flutterDirectory, () async {
      await dart(<String>['dev/tools/mega_gallery.dart']);
    });
  }

  @override
  Future<num> run() async {
    rm(benchmarkFile);
    await inDirectory(megaDir, () async {
      await flutter('analyze', options: <String>[
        '--watch',
        '--benchmark',
      ]);
    });
    return addBuildInfo(benchmarkFile,
        timestamp: timestamp, expected: 10.0, sdk: sdk, commit: commit);
  }
}
