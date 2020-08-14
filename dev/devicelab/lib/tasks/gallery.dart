// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/utils.dart';

TaskFunction createGalleryTransitionTest({ bool semanticsEnabled = false }) {
  return GalleryTransitionTest(semanticsEnabled: semanticsEnabled);
}

TaskFunction createGalleryTransitionE2ETest({ bool semanticsEnabled = false }) {
  return GalleryTransitionTest(
    semanticsEnabled: semanticsEnabled,
    testFile: 'transitions_perf_e2e',
    needFullTimeline: false,
    timelineSummaryFile: 'e2e_perf_summary',
    transitionDurationFile: null,
    driverFile: 'transitions_perf_e2e_test',
  );
}

class GalleryTransitionTest {

  GalleryTransitionTest({
    this.semanticsEnabled = false,
    this.testFile = 'transitions_perf',
    this.needFullTimeline = true,
    this.timelineSummaryFile = 'transitions.timeline_summary',
    this.transitionDurationFile = 'transition_durations.timeline',
    this.driverFile,
  });

  final bool semanticsEnabled;
  final bool needFullTimeline;
  final String testFile;
  final String timelineSummaryFile;
  final String transitionDurationFile;
  final String driverFile;

  Future<TaskResult> call() async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final String deviceId = device.deviceId;
    final Directory galleryDirectory =
        dir('${flutterDirectory.path}/dev/integration_tests/flutter_gallery');
    await inDirectory<void>(galleryDirectory, () async {
      await flutter('packages', options: <String>['get']);

      final String testDriver = semanticsEnabled
          ? '${testFile}_with_semantics.dart'
          : '$testFile.dart';

      await flutter('drive', options: <String>[
        '--profile',
        if (needFullTimeline)
          '--trace-startup',
        '-t',
        'test_driver/$testDriver',
        if (driverFile != null)
          ...<String>['--driver', 'test_driver/$driverFile.dart'],
        '-d',
        deviceId,
      ]);
    });

    final Map<String, dynamic> summary = json.decode(
      file('${galleryDirectory.path}/build/$timelineSummaryFile.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    if (transitionDurationFile != null) {
      final Map<String, dynamic> original = json.decode(
        file('${galleryDirectory.path}/build/$transitionDurationFile.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final Map<String, List<int>> transitions = <String, List<int>>{};
      for (final String key in original.keys) {
        transitions[key] = List<int>.from(original[key] as List<dynamic>);
      }
      summary['transitions'] = transitions;
      summary['missed_transition_count'] = _countMissedTransitions(transitions);
    }

    return TaskResult.success(summary, benchmarkScoreKeys: <String>[
      if (transitionDurationFile != null)
        'missed_transition_count',
      'average_frame_build_time_millis',
      'worst_frame_build_time_millis',
      '90th_percentile_frame_build_time_millis',
      '99th_percentile_frame_build_time_millis',
      'average_frame_rasterizer_time_millis',
      'worst_frame_rasterizer_time_millis',
      '90th_percentile_frame_rasterizer_time_millis',
      '99th_percentile_frame_rasterizer_time_millis',
    ]);
  }
}

int _countMissedTransitions(Map<String, List<int>> transitions) {
  const int _kTransitionBudget = 100000; // µs
  int count = 0;
  transitions.forEach((String demoName, List<int> durations) {
    final int longestDuration = durations.reduce(math.max);
    if (longestDuration > _kTransitionBudget) {
      print('$demoName missed transition time budget ($longestDuration µs > $_kTransitionBudget µs)');
      count++;
    }
  });
  return count;
}
