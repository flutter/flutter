// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';

TaskFunction createGalleryTransitionTest({ bool semanticsEnabled = false }) {
  return GalleryTransitionTest(semanticsEnabled: semanticsEnabled);
}

class GalleryTransitionTest {

  GalleryTransitionTest({ this.semanticsEnabled = false });

  final bool semanticsEnabled;

  Future<TaskResult> call() async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final String deviceId = device.deviceId;
    final Directory galleryDirectory =
        dir('${flutterDirectory.path}/examples/flutter_gallery');
    await inDirectory<void>(galleryDirectory, () async {
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios)
        await prepareProvisioningCertificates(galleryDirectory.path);

      final String testDriver = semanticsEnabled
          ? 'transitions_perf_with_semantics.dart'
          : 'transitions_perf.dart';

      await flutter('drive', options: <String>[
        '--profile',
        '--trace-startup',
        '-t',
        'test_driver/$testDriver',
        '-d',
        deviceId,
      ]);
    });

    // Route paths contains slashes, which Firebase doesn't accept in keys, so we
    // remove them.
    final Map<String, dynamic> original = Map<String, dynamic>.from(
        json.decode(
            file('${galleryDirectory.path}/build/transition_durations.timeline.json').readAsStringSync()
        ));
    final Map<String, List<int>> transitions = <String, List<int>>{};
    for (String key in original.keys) {
      transitions[key.replaceAll('/', '')] = List<int>.from(original[key]);
    }

    final Map<String, dynamic> summary = json.decode(file('${galleryDirectory.path}/build/transitions.timeline_summary.json').readAsStringSync());

    final Map<String, dynamic> data = <String, dynamic>{
      'transitions': transitions,
      'missed_transition_count': _countMissedTransitions(transitions),
    };
    data.addAll(summary);

    return TaskResult.success(data, benchmarkScoreKeys: <String>[
      'missed_transition_count',
      'average_frame_build_time_millis',
      'worst_frame_build_time_millis',
      'missed_frame_build_budget_count',
      '90th_percentile_frame_build_time_millis',
      '99th_percentile_frame_build_time_millis',
      'average_frame_rasterizer_time_millis',
      'worst_frame_rasterizer_time_millis',
      'missed_frame_rasterizer_budget_count',
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
