// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';

import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;

/// Tests frame timings in a renderer-agnostic way.
///
/// See CanvasKit-specific and HTML-specific test files `frame_timings_test.dart`.
Future<void> runFrameTimingsTest() async {
  List<ui.FrameTiming> timings;
  ui.window.onReportTimings = (List<ui.FrameTiming> data) {
    timings = data;
  };
  Completer<void> frameDone = Completer<void>();
  ui.window.onDrawFrame = () {
    final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
    sceneBuilder
      ..pushOffset(0, 0)
      ..pop();
    ui.window.render(sceneBuilder.build());
    frameDone.complete();
  };

  // Frame 1.
  ui.window.scheduleFrame();
  await frameDone.future;
  expect(timings, isNull, reason: '100 ms hasn\'t passed yet');
  await Future<void>.delayed(const Duration(milliseconds: 150));

  // Frame 2.
  frameDone = Completer<void>();
  ui.window.scheduleFrame();
  await frameDone.future;
  expect(timings, hasLength(2), reason: '100 ms passed. 2 frames pumped.');
  for (final ui.FrameTiming timing in timings) {
    expect(timing.vsyncOverhead, greaterThanOrEqualTo(Duration.zero));
    expect(timing.buildDuration, greaterThanOrEqualTo(Duration.zero));
    expect(timing.rasterDuration, greaterThanOrEqualTo(Duration.zero));
    expect(timing.totalSpan, greaterThanOrEqualTo(Duration.zero));
  }
}
