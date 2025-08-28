// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('FrameTimingRecorder', () {
    setUp(() {
      EnginePlatformDispatcher.instance.onReportTimings = null;
      FrameTimingRecorder.debugResetCurrentFrameNumber();
      FrameTimingRecorder.debugResetCurrentFrameVsync();
      FrameTimingRecorder.debugResetCurrentFrameBuildStart();
      FrameTimingRecorder.debugResetFrameTimings();
    });

    tearDown(() {
      EnginePlatformDispatcher.instance.onReportTimings = null;
      FrameTimingRecorder.debugResetCurrentFrameNumber();
      FrameTimingRecorder.debugResetCurrentFrameVsync();
      FrameTimingRecorder.debugResetCurrentFrameBuildStart();
      FrameTimingRecorder.debugResetFrameTimings();
    });

    test('frameTimingsEnabled is false when onReportTimings is not set', () {
      expect(EnginePlatformDispatcher.instance.onReportTimings, isNull);
      expect(FrameTimingRecorder.frameTimingsEnabled, isFalse);
    });

    test('frameTimingsEnabled is true when onReportTimings is set', () {
      EnginePlatformDispatcher.instance.onReportTimings = (_) {};
      expect(EnginePlatformDispatcher.instance.onReportTimings, isNotNull);
      expect(FrameTimingRecorder.frameTimingsEnabled, isTrue);
    });

    test('uses recorded frame number', () {
      EnginePlatformDispatcher.instance.onReportTimings = (_) {};
      expect(FrameTimingRecorder.frameTimingsEnabled, isTrue);

      const int frameNumber1 = 333;
      FrameTimingRecorder.recordCurrentFrameNumber(frameNumber1);

      FrameTimingRecorder()
        ..recordBuildFinish()
        ..recordRasterStart()
        ..recordRasterFinish()
        ..submitTimings();

      expect(FrameTimingRecorder.debugFrameTimings.length, 1);
      final ui.FrameTiming timing1 = FrameTimingRecorder.debugFrameTimings.first;
      expect(timing1.frameNumber, frameNumber1);

      const int frameNumber2 = 334;
      FrameTimingRecorder.recordCurrentFrameNumber(frameNumber2);

      FrameTimingRecorder()
        ..recordBuildFinish()
        ..recordRasterStart()
        ..recordRasterFinish()
        ..submitTimings();

      expect(FrameTimingRecorder.debugFrameTimings.length, 2);
      final ui.FrameTiming timing2 = FrameTimingRecorder.debugFrameTimings.last;
      expect(timing2.frameNumber, frameNumber2);
    });
  });
}
