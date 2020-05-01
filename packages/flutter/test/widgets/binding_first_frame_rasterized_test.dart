// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiver/testing/async.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  test('Deferred frames will trigger the first frame callback', () {
    FakeAsync().run((FakeAsync fakeAsync) {
      final WidgetsBinding binding = WidgetsBinding.instance;
      binding.deferFirstFrame();

      runApp(const Placeholder());
      fakeAsync.flushTimers();

      // Simulates the engine completing a frame render to trigger the
      // appropriate callback setting [WidgetBinding.firstFrameRasterized].
      binding.window.onReportTimings(
        // The actual timings are not important.
        <FrameTiming>[]);
      expect(binding.firstFrameRasterized, isFalse);

      binding.allowFirstFrame();
      fakeAsync.flushTimers();

      // Simulates the engine again.
      binding.window.onReportTimings(<FrameTiming>[]);
      expect(binding.firstFrameRasterized, isTrue);
    });
  });
}
