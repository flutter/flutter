// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  test('Deferred frames will trigger the first frame callback', () {
    FakeAsync().run((FakeAsync fakeAsync) {
      final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
      binding.deferFirstFrame();

      runApp(const Placeholder());
      fakeAsync.flushTimers();

      // Simulates the engine completing a frame render to trigger the
      // appropriate callback setting [WidgetBinding.firstFrameRasterized].
      binding.window.onReportTimings(<FrameTiming>[]);
      expect(binding.firstFrameRasterized, isFalse);

      binding.allowFirstFrame();
      fakeAsync.flushTimers();

      // Simulates the engine again.
      binding.window.onReportTimings(<FrameTiming>[]);
      expect(binding.firstFrameRasterized, isTrue);
    });
  });
}
