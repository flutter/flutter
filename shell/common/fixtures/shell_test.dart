// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';
import 'dart:ui';

void main() {}

void nativeReportTimingsCallback(List<int> timings) native 'NativeReportTimingsCallback';
void nativeOnBeginFrame(int microseconds) native 'NativeOnBeginFrame';

@pragma('vm:entry-point')
void reportTimingsMain() {
  window.onReportTimings = (List<FrameTiming> timings) {
    List<int> timestamps = [];
    for (FrameTiming t in timings) {
      for (FramePhase phase in FramePhase.values) {
        timestamps.add(t.timestampInMicroseconds(phase));
      }
    }
    nativeReportTimingsCallback(timestamps);
  };
}

@pragma('vm:entry-point')
void onBeginFrameMain() {
  window.onBeginFrame = (Duration beginTime) {
    nativeOnBeginFrame(beginTime.inMicroseconds);
  };
}

@pragma('vm:entry-point')
void emptyMain() {}

@pragma('vm:entry-point')
void dummyReportTimingsMain() {
  window.onReportTimings = (List<FrameTiming> timings) {};
}

@pragma('vm:entry-point')
void fixturesAreFunctionalMain() {
  sayHiFromFixturesAreFunctionalMain();
}

void sayHiFromFixturesAreFunctionalMain() native 'SayHiFromFixturesAreFunctionalMain';

void notifyNative() native 'NotifyNative';

void secondaryIsolateMain(String message) {
  print('Secondary isolate got message: ' + message);
  notifyNative();
}

@pragma('vm:entry-point')
void testCanLaunchSecondaryIsolate() {
  Isolate.spawn(secondaryIsolateMain, 'Hello from root isolate.');
  notifyNative();
}
