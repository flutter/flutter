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
  final List<FrameTiming> frameTimings = <FrameTiming>[];
  final TimingsCallback watcher = frameTimings.addAll;
  binding.addTimingsCallback(watcher);
  await action();
  binding.removeTimingsCallback(watcher);
  final FrameTimingSummarizer frameTimes = FrameTimingSummarizer(frameTimings);
  binding.reportData = <String, dynamic>{reportKey: frameTimes.summary};
}
