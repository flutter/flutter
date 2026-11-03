// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

class HoldingRasterizer extends ViewRasterizer {
  HoldingRasterizer(super.view, this.displayFactory);

  @override
  final DisplayCanvasFactory<DisplayCanvas> displayFactory;

  Completer<void>? rasterizeStarted;
  Completer<void>? rasterizeCompleter;

  @override
  Future<void> prepareToDraw() async {}

  @override
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) async {
    recorder?.recordRasterStart();
    if (rasterizeStarted != null && !rasterizeStarted!.isCompleted) {
      rasterizeStarted!.complete();
    }
    if (rasterizeCompleter != null) {
      await rasterizeCompleter!.future;
    }
    recorder?.recordRasterFinish();
  }
}

class FakeDisplayCanvas extends DisplayCanvas {
  @override
  final DomElement hostElement = domDocument.createElement('div');
  @override
  bool get isConnected => true;
  @override
  void initialize() {}
  @override
  void dispose() {}
}

void testMain() {
  setUpUnitTests(withImplicitView: true);

  final reportedTimings = <ui.FrameTiming>[];

  setUp(() {
    reportedTimings.clear();
    EnginePlatformDispatcher.instance.onReportTimings = reportedTimings.addAll;
    FrameTimingRecorder.debugResetFrameTimings();
    FrameTimingRecorder.debugResetCurrentFrameBuildStart();
    FrameTimingRecorder.debugResetCurrentFrameVsync();
    FrameTimingRecorder.debugResetCurrentFrameNumber();
  });

  tearDown(() {
    EnginePlatformDispatcher.instance.onReportTimings = null;
    FrameTimingRecorder.debugResetFrameTimings();
    FrameTimingRecorder.debugResetCurrentFrameBuildStart();
    FrameTimingRecorder.debugResetCurrentFrameVsync();
    FrameTimingRecorder.debugResetCurrentFrameNumber();
  });

  test(
    'build duration of queued frame does not include wait time behind in-flight rasterization',
    () async {
      final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
      view.debugPhysicalSizeOverride = const ui.Size(100, 100);
      view.debugForceResize();

      final displayFactory = DisplayCanvasFactory<DisplayCanvas>(
        createCanvas: () => FakeDisplayCanvas(),
      );
      final holdingRasterizer = HoldingRasterizer(view, displayFactory);
      final ViewRasterizer originalRasterizer = renderer.rasterizers[view.viewId]!;
      renderer.rasterizers[view.viewId] = holdingRasterizer;
      addTearDown(() {
        renderer.rasterizers[view.viewId] = originalRasterizer;
        view.debugPhysicalSizeOverride = null;
        view.debugForceResize();
      });

      final frame1Started = Completer<void>();
      final frame1Hold = Completer<void>();
      holdingRasterizer.rasterizeStarted = frame1Started;
      holdingRasterizer.rasterizeCompleter = frame1Hold;

      // Frame 1
      FrameTimingRecorder.recordCurrentFrameNumber(1);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene1 = ui.SceneBuilder().build();
      addTearDown(scene1.dispose);
      final Future<void> frame1Done = renderer.renderScene(scene1, view);

      // Wait until Frame 1 is holding in rasterize.
      await frame1Started.future;

      // Frame 2 is built and submitted while Frame 1 is in-flight rasterizing.
      FrameTimingRecorder.recordCurrentFrameNumber(2);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene2 = ui.SceneBuilder().build();
      addTearDown(scene2.dispose);
      final Future<void> frame2Done = renderer.renderScene(scene2, view);

      // Simulate 100ms in-flight rasterization for Frame 1.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Release Frame 1, and ensure Frame 2 does not hold.
      holdingRasterizer.rasterizeCompleter = null;
      holdingRasterizer.rasterizeStarted = null;
      frame1Hold.complete();

      await Future.wait([frame1Done, frame2Done]);

      final allTimings = <ui.FrameTiming>[
        ...reportedTimings,
        ...FrameTimingRecorder.debugFrameTimings,
      ];
      expect(allTimings, hasLength(2));
      final ui.FrameTiming frame2Timing = allTimings[1];
      expect(frame2Timing.frameNumber, 2);

      // The build duration of Frame 2 must not include the 100ms spent waiting
      // in renderQueue.next behind Frame 1's in-flight rasterization.
      expect(frame2Timing.buildDuration, lessThan(const Duration(milliseconds: 50)));
    },
  );

  test(
    'dropped frame request completer completes and timing is discarded when overwritten',
    () async {
      final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
      view.debugPhysicalSizeOverride = const ui.Size(100, 100);
      view.debugForceResize();

      final displayFactory = DisplayCanvasFactory<DisplayCanvas>(
        createCanvas: () => FakeDisplayCanvas(),
      );
      final holdingRasterizer = HoldingRasterizer(view, displayFactory);
      final ViewRasterizer originalRasterizer = renderer.rasterizers[view.viewId]!;
      renderer.rasterizers[view.viewId] = holdingRasterizer;
      addTearDown(() {
        renderer.rasterizers[view.viewId] = originalRasterizer;
        view.debugPhysicalSizeOverride = null;
        view.debugForceResize();
      });

      final frame1Started = Completer<void>();
      final frame1Hold = Completer<void>();
      holdingRasterizer.rasterizeStarted = frame1Started;
      holdingRasterizer.rasterizeCompleter = frame1Hold;

      // Frame 1
      FrameTimingRecorder.recordCurrentFrameNumber(101);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene1 = ui.SceneBuilder().build();
      addTearDown(scene1.dispose);
      final Future<void> frame1Done = renderer.renderScene(scene1, view);

      // Wait until Frame 1 is holding in rasterize.
      await frame1Started.future;

      // Frame 2 is submitted while Frame 1 is holding in rasterize -> goes to renderQueue.next.
      FrameTimingRecorder.recordCurrentFrameNumber(102);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene2 = ui.SceneBuilder().build();
      addTearDown(scene2.dispose);
      final Future<void> frame2Done = renderer.renderScene(scene2, view);

      // Frame 3 is submitted while Frame 1 is still holding in rasterize -> overwrites Frame 2 in renderQueue.next.
      FrameTimingRecorder.recordCurrentFrameNumber(103);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene3 = ui.SceneBuilder().build();
      addTearDown(scene3.dispose);
      final Future<void> frame3Done = renderer.renderScene(scene3, view);

      // Frame 2 was dropped: its completer must complete.
      await expectLater(frame2Done, completes);

      // Release Frame 1, and don't hold Frame 3.
      holdingRasterizer.rasterizeCompleter = null;
      holdingRasterizer.rasterizeStarted = null;
      frame1Hold.complete();

      await Future.wait([frame1Done, frame3Done]);

      // Verify that only presented frames (101 and 103) have timings collected,
      // and dropped frame 102 was cleanly discarded without submitting timings.
      final allTimings = <ui.FrameTiming>[
        ...reportedTimings,
        ...FrameTimingRecorder.debugFrameTimings,
      ];
      final List<int> reportedFrameNumbers = allTimings
          .map((ui.FrameTiming t) => t.frameNumber)
          .toList();
      expect(reportedFrameNumbers, contains(101));
      expect(reportedFrameNumbers, isNot(contains(102)));
      expect(reportedFrameNumbers, contains(103));
      expect(allTimings, hasLength(2));
    },
  );
}
