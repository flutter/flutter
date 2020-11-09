// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e2e/e2e.dart';

bool _firstRun = true;

// TODO(CareF): move this to e2e after FrameTimingSummarizer goes into stable
// branch (#63537)
/// watches the [FrameTiming] of `action` and report it to the e2e binding.
Future<void> watchPerformance(
  E2EWidgetsFlutterBinding binding,
  Future<void> action(), {
  String reportKey = 'performance',
}) async {
  assert(() {
    if (_firstRun) {
      debugPrint(kDebugWarning);
      _firstRun = false;
    }
    return true;
  }());

  // The engine could batch FrameTimings and send them only once per second.
  // Delay for a sufficient time so either old FrameTimings are flushed and not
  // interfering our measurements here, or new FrameTimings are all reported.
  Future<void> delayForFrameTimings() =>
      Future<void>.delayed(const Duration(seconds: 2));

  await delayForFrameTimings(); // flush old FrameTimings
  final List<FrameTiming> frameTimings = <FrameTiming>[];
  final TimingsCallback watcher = frameTimings.addAll;
  binding.addTimingsCallback(watcher);
  await action();
  await delayForFrameTimings(); // make sure all FrameTimings are reported
  binding.removeTimingsCallback(watcher);
  final FrameTimingSummarizer frameTimes = FrameTimingSummarizer(frameTimings);
  binding.reportData = <String, dynamic>{reportKey: frameTimes.summary};
}
