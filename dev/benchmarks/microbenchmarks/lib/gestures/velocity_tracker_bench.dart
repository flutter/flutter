// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import '../common.dart';
import 'data/velocity_tracker_data.dart';

const int _kNumIters = 10000;

void main() {
  assert(false, "Don't run benchmarks in checked mode! Use 'flutter run --release'.");
  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  final List<VelocityTracker> trackers = <VelocityTracker>[VelocityTracker(), IOSScrollViewFlingVelocityTracker()];
  final Stopwatch watch = Stopwatch();

  for (final VelocityTracker tracker in trackers) {
    final String trackerType = tracker.runtimeType.toString();
    print('$trackerType benchmark...');
    watch.reset();
    watch.start();
    for (int i = 0; i < _kNumIters; i += 1) {
      for (final PointerEvent event in velocityEventData) {
        if (event is PointerDownEvent || event is PointerMoveEvent)
          tracker.addPosition(event.timeStamp, event.position);
        if (event is PointerUpEvent)
          tracker.getVelocity();
      }
    }
    watch.stop();
    printer.addResult(
      description: 'Velocity tracker: $trackerType',
      value: watch.elapsedMicroseconds / _kNumIters,
      unit: 'µs per iteration',
      name: 'velocity_tracker_iteration_$trackerType',
    );
  }

  printer.printToStdout();
}
