// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:test/test.dart';
import 'velocity_tracker_data.dart';

const int kNumIters = 10000;
const int kBatchSize = 1000;
const int kBatchOffset = 50;
const int kNumMarks = 130;

void main() {
  test('Dart velocity tracker performance', () {
    VelocityTracker tracker = new VelocityTracker();
    Stopwatch watch = new Stopwatch();
    watch.start();
    for (int i = 0; i < kNumIters; i++) {
      for (PointerEvent event in velocityEventData) {
        if (event is PointerDownEvent || event is PointerMoveEvent)
          tracker.addPosition(event.timeStamp, event.position);
        if (event is PointerUpEvent)
          tracker.getVelocity();
      }
    }
    watch.stop();
    print("Dart tracker: " + watch.elapsed.toString());
  });
}
