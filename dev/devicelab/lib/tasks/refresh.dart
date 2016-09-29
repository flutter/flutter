// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/adb.dart';
import '../framework/benchmarks.dart';
import '../framework/framework.dart';
import '../framework/utils.dart';

TaskFunction createRefreshTest({ String commit, DateTime timestamp }) =>
    new EditRefreshTask(commit, timestamp);

class EditRefreshTask {
  EditRefreshTask(this.commit, this.timestamp) {
    assert(commit != null);
    assert(timestamp != null);
  }

  final String commit;
  final DateTime timestamp;

  Future<TaskResult> call() async {
    Device device = await devices.workingDevice;
    await device.unlock();
    Benchmark benchmark = new EditRefreshBenchmark(commit, timestamp);
    section(benchmark.name);
    await runBenchmark(benchmark, iterations: 3, warmUpBenchmark: true);
    return benchmark.bestResult;
  }
}

class EditRefreshBenchmark extends Benchmark {
  EditRefreshBenchmark(this.commit, this.timestamp) : super('edit refresh');

  final String commit;
  final DateTime timestamp;

  Directory get megaDir => dir(
      path.join(flutterDirectory.path, 'dev/benchmarks/mega_gallery'));
  File get benchmarkFile =>
      file(path.join(megaDir.path, 'refresh_benchmark.json'));

  @override
  TaskResult get lastResult => new TaskResult.successFromFile(benchmarkFile);

  @override
  Future<Null> init() {
    return inDirectory(flutterDirectory, () async {
      await dart(<String>['dev/tools/mega_gallery.dart']);
    });
  }

  @override
  Future<num> run() async {
    Device device = await devices.workingDevice;
    rm(benchmarkFile);
    int exitCode = await inDirectory(megaDir, () async {
      return await flutter('run',
          options: <String>['-d', device.deviceId, '--benchmark'],
          canFail: true);
    });
    if (exitCode != 0) return new Future<num>.error(exitCode);
    return addBuildInfo(
      benchmarkFile,
      timestamp: timestamp,
      expected: 200,
      commit: commit,
    );
  }
}
