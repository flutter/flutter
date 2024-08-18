// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';
import '../microbenchmarks.dart';

/// Creates a device lab task that runs benchmarks in
/// `dev/benchmarks/microbenchmarks` reports results to the dashboard.
TaskFunction createMicrobenchmarkTask({
  bool? enableImpeller,
  Map<String, String> environment = const <String, String>{},
}) {
  return () async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    await device.clearLogs();

    Future<Map<String, double>> runMicrobench(String benchmarkPath) async {
      Future<Map<String, double>> run() async {
        print('Running $benchmarkPath');
        final Directory appDir = dir(
            path.join(flutterDirectory.path, 'dev/benchmarks/microbenchmarks'));
        final Process flutterProcess = await inDirectory(appDir, () async {
          final List<String> options = <String>[
            '-v',
            // --release doesn't work on iOS due to code signing issues
            '--profile',
            '--no-publish-port',
            if (enableImpeller != null && enableImpeller) '--enable-impeller',
            if (enableImpeller != null && !enableImpeller) '--no-enable-impeller',
            '-d',
            device.deviceId,
            benchmarkPath,
          ];
          return startFlutter(
            'run',
            options: options,
            environment: environment,
          );
        });
        return readJsonResults(flutterProcess);
      }

      return run();
    }

    final Map<String, double> allResults = <String, double>{
      ...await runMicrobench('lib/foundation/all_elements_bench.dart'),
      ...await runMicrobench('lib/foundation/change_notifier_bench.dart'),
      ...await runMicrobench('lib/foundation/clamp.dart'),
      ...await runMicrobench('lib/foundation/platform_asset_bundle.dart'),
      ...await runMicrobench('lib/foundation/standard_message_codec_bench.dart'),
      ...await runMicrobench('lib/foundation/standard_method_codec_bench.dart'),
      ...await runMicrobench('lib/foundation/timeline_bench.dart'),
      ...await runMicrobench('lib/foundation/decode_and_parse_asset_manifest.dart'),
      ...await runMicrobench('lib/geometry/matrix_utils_transform_bench.dart'),
      ...await runMicrobench('lib/geometry/rrect_contains_bench.dart'),
      ...await runMicrobench('lib/gestures/gesture_detector_bench.dart'),
      ...await runMicrobench('lib/gestures/velocity_tracker_bench.dart'),
      ...await runMicrobench('lib/language/compute_bench.dart'),
      ...await runMicrobench('lib/language/sync_star_bench.dart'),
      ...await runMicrobench('lib/language/sync_star_semantics_bench.dart'),
      ...await runMicrobench('lib/stocks/animation_bench.dart'),
      ...await runMicrobench('lib/stocks/build_bench_profiled.dart'),
      ...await runMicrobench('lib/stocks/build_bench.dart'),
      ...await runMicrobench('lib/stocks/layout_bench.dart'),
      ...await runMicrobench('lib/ui/image_bench.dart'),
      ...await runMicrobench('lib/layout/text_intrinsic_bench.dart'),
    };

    return TaskResult.success(allResults,
        benchmarkScoreKeys: allResults.keys.toList());
  };
}
