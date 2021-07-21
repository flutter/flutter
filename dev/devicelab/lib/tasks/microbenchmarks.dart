// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/microbenchmarks.dart';
import 'package:path/path.dart' as path;

/// Creates a device lab task that runs benchmarks in
/// `dev/benchmarks/microbenchmarks` reports results to the dashboard.
TaskFunction createMicrobenchmarkTask() {
  return () async {
    final Device device = await devices.workingDevice;
    await device.unlock();

    Future<Map<String, double>> _runMicrobench(String benchmarkPath) async {
      Future<Map<String, double>> _run() async {
        print('Running $benchmarkPath');
        final Directory appDir = dir(
            path.join(flutterDirectory.path, 'dev/benchmarks/microbenchmarks'));
        final Process flutterProcess = await inDirectory(appDir, () async {
          final List<String> options = <String>[
            '-v',
            // --release doesn't work on iOS due to code signing issues
            '--profile',
            '--no-publish-port',
            '-d',
            device.deviceId,
          ];
          options.add(benchmarkPath);
          return startFlutter(
            'run',
            options: options,
          );
        });

        return readJsonResults(flutterProcess);
      }

      return _run();
    }

    final Map<String, double> allResults = <String, double>{
      ...await _runMicrobench('lib/stocks/layout_bench.dart'),
      ...await _runMicrobench('lib/stocks/build_bench.dart'),
      ...await _runMicrobench('lib/geometry/matrix_utils_transform_bench.dart'),
      ...await _runMicrobench('lib/geometry/rrect_contains_bench.dart'),
      ...await _runMicrobench('lib/gestures/velocity_tracker_bench.dart'),
      ...await _runMicrobench('lib/gestures/gesture_detector_bench.dart'),
      ...await _runMicrobench('lib/stocks/animation_bench.dart'),
      ...await _runMicrobench('lib/language/sync_star_bench.dart'),
      ...await _runMicrobench('lib/language/sync_star_semantics_bench.dart'),
      ...await _runMicrobench('lib/foundation/all_elements_bench.dart'),
      ...await _runMicrobench('lib/foundation/change_notifier_bench.dart'),
    };

    return TaskResult.success(allResults,
        benchmarkScoreKeys: allResults.keys.toList());
  };
}
