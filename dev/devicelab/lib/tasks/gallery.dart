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

TaskFunction createGalleryTransitionTest({bool semanticsEnabled = false}) {
  return GalleryTransitionTest(semanticsEnabled: semanticsEnabled);
}

TaskFunction createGalleryTransitionE2ETest({bool semanticsEnabled = false}) {
  return GalleryTransitionTest(
    testFile: semanticsEnabled
        ? 'transitions_perf_e2e_with_semantics'
        : 'transitions_perf_e2e',
    needFullTimeline: false,
    timelineSummaryFile: 'e2e_perf_summary',
    transitionDurationFile: null,
    timelineTraceFile: null,
    driverFile: 'transitions_perf_e2e_test',
  );
}

TaskFunction createGalleryTransitionHybridTest({bool semanticsEnabled = false}) {
  return GalleryTransitionTest(
    semanticsEnabled: semanticsEnabled,
    driverFile: semanticsEnabled
        ? 'transitions_perf_hybrid_with_semantics_test'
        : 'transitions_perf_hybrid_test',
  );
}

class GalleryTransitionTest {

  GalleryTransitionTest({
    this.semanticsEnabled = false,
    this.testFile = 'transitions_perf',
    this.needFullTimeline = true,
    this.timelineSummaryFile = 'transitions.timeline_summary',
    this.timelineTraceFile = 'transitions.timeline',
    this.transitionDurationFile = 'transition_durations.timeline',
    this.driverFile,
  });

  final bool semanticsEnabled;
  final bool needFullTimeline;
  final String testFile;
  final String timelineSummaryFile;
  final String timelineTraceFile;
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

      final String testDriver = driverFile ?? (semanticsEnabled
          ? '${testFile}_with_semantics_test'
          : '${testFile}_test');

      await flutter('drive', options: <String>[
        '--profile',
        if (needFullTimeline)
          '--trace-startup',
        '-t',
        'test_driver/$testFile.dart',
        '--driver',
        'test_driver/$testDriver.dart',
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
    final List<String> detailFiles = <String>[
      if (transitionDurationFile != null)
        '${galleryDirectory.path}/build/$transitionDurationFile.json',
      if (timelineTraceFile != null)
        '${galleryDirectory.path}/build/$timelineTraceFile.json'
    ];

    return TaskResult.success(summary,
      detailFiles: detailFiles.isNotEmpty ? detailFiles : null,
      benchmarkScoreKeys: <String>[
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
      ],
    );
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
