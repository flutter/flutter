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

/// A test [ViewRasterizer] that simulates in-flight rasterization using
/// completers to pause and resume execution.
class HoldingRasterizer extends ViewRasterizer {
  HoldingRasterizer(super.view, this.displayFactory);

  @override
  final DisplayCanvasFactory<DisplayCanvas> displayFactory;

  Completer<void>? rasterizeStarted;
  Completer<void>? rasterizeCompleter;

  /// The count of non-culled pictures delivered to [rasterize] for each frame.
  final List<int> rasterizedPictureCounts = <int>[];

  /// Simulated engine work performed after [ViewRasterizer.draw] begins but
  /// before [rasterize] is called.
  Duration prepareToDrawDelay = Duration.zero;

  /// The time, in microseconds, at which [rasterize] was last entered.
  int? lastRasterizeEnteredMicros;

  @override
  Future<void> prepareToDraw() async {
    if (prepareToDrawDelay > Duration.zero) {
      await Future<void>.delayed(prepareToDrawDelay);
    }
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) async {
    rasterizedPictureCounts.add(pictures.length);
    // Like the production rasterizers, raster start is not recorded here: it
    // is recorded by [ViewRasterizer.draw] before the engine's preroll,
    // measure, and paint passes.
    lastRasterizeEnteredMicros = (domWindow.performance.now() * 1000).toInt();
    if (rasterizeStarted != null && !rasterizeStarted!.isCompleted) {
      rasterizeStarted!.complete();
    }
    if (rasterizeCompleter != null) {
      await rasterizeCompleter!.future;
    }
    recorder?.recordRasterFinish();
  }
}

/// A dummy [DisplayCanvas] implementation for unit tests.
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

HoldingRasterizer createAndInstallHoldingRasterizer(EngineFlutterView view) {
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
  return holdingRasterizer;
}

/// Creates a simple non-empty test picture for render queue assertions.
ui.Picture createTestPicture() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 100, 100));
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 50, 50),
    ui.Paint()..color = const ui.Color(0xFF00FF00),
  );
  return recorder.endRecording();
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
      final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

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
      final Future<void> frame1Done = renderer.renderScene(scene1, view, size: view.physicalSize);

      // Wait until Frame 1 is holding in rasterize.
      await frame1Started.future;

      // Frame 2 is built and submitted while Frame 1 is in-flight rasterizing.
      FrameTimingRecorder.recordCurrentFrameNumber(2);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene2 = ui.SceneBuilder().build();
      addTearDown(scene2.dispose);
      final Future<void> frame2Done = renderer.renderScene(scene2, view, size: view.physicalSize);

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
      final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

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
      final Future<void> frame1Done = renderer.renderScene(scene1, view, size: view.physicalSize);

      // Wait until Frame 1 is holding in rasterize.
      await frame1Started.future;

      // Frame 2 is submitted while Frame 1 is holding in rasterize -> goes to renderQueue.next.
      FrameTimingRecorder.recordCurrentFrameNumber(102);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene2 = ui.SceneBuilder().build();
      addTearDown(scene2.dispose);
      final Future<void> frame2Done = renderer.renderScene(scene2, view, size: view.physicalSize);

      // Frame 3 is submitted while Frame 1 is still holding in rasterize -> overwrites Frame 2 in renderQueue.next.
      FrameTimingRecorder.recordCurrentFrameNumber(103);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene3 = ui.SceneBuilder().build();
      addTearDown(scene3.dispose);
      final Future<void> frame3Done = renderer.renderScene(scene3, view, size: view.physicalSize);

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

  test(
    'rendering scene to view with empty dimensions completes cleanly and records frame timings',
    () async {
      final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
      view.debugPhysicalSizeOverride = ui.Size.zero;
      view.debugForceResize();
      addTearDown(() {
        view.debugPhysicalSizeOverride = null;
        view.debugForceResize();
      });

      FrameTimingRecorder.recordCurrentFrameNumber(201);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene1 = ui.SceneBuilder().build();
      addTearDown(scene1.dispose);

      final Future<void> frame1Done = renderer.renderScene(scene1, view, size: view.physicalSize);
      await expectLater(frame1Done, completes);

      final allTimings = <ui.FrameTiming>[
        ...reportedTimings,
        ...FrameTimingRecorder.debugFrameTimings,
      ];
      expect(allTimings, hasLength(1));
      final ui.FrameTiming timing1 = allTimings.single;
      expect(timing1.frameNumber, 201);
      expect(timing1.buildDuration, greaterThanOrEqualTo(Duration.zero));
      expect(timing1.rasterDuration, greaterThanOrEqualTo(Duration.zero));

      // Test zero-width non-zero height
      FrameTimingRecorder.recordCurrentFrameNumber(202);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      view.debugPhysicalSizeOverride = const ui.Size(0, 50);
      view.debugForceResize();
      final ui.Scene scene2 = ui.SceneBuilder().build();
      addTearDown(scene2.dispose);

      final Future<void> frame2Done = renderer.renderScene(scene2, view, size: view.physicalSize);
      await expectLater(frame2Done, completes);

      final allTimings2 = <ui.FrameTiming>[
        ...reportedTimings,
        ...FrameTimingRecorder.debugFrameTimings,
      ];
      expect(allTimings2, hasLength(2));
      final ui.FrameTiming timing2 = allTimings2[1];
      expect(timing2.frameNumber, 202);
      expect(timing2.buildDuration, greaterThanOrEqualTo(Duration.zero));
      expect(timing2.rasterDuration, greaterThanOrEqualTo(Duration.zero));
    },
  );

  test('multiple rapid scene submissions complete intermediate dropped frame completers and discard timings', () async {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

    final frame1Started = Completer<void>();
    final frame1Hold = Completer<void>();
    holdingRasterizer.rasterizeStarted = frame1Started;
    holdingRasterizer.rasterizeCompleter = frame1Hold;

    // Frame 1: in flight
    FrameTimingRecorder.recordCurrentFrameNumber(301);
    FrameTimingRecorder.recordCurrentFrameVsync();
    FrameTimingRecorder.recordCurrentFrameBuildStart();
    final ui.Scene scene1 = ui.SceneBuilder().build();
    addTearDown(scene1.dispose);
    final Future<void> frame1Done = renderer.renderScene(scene1, view, size: view.physicalSize);

    await frame1Started.future;

    // Frames 2, 3, 4 submitted rapidly in sequence while Frame 1 is held
    final droppedFutures = <Future<void>>[];
    for (var i = 302; i <= 304; i++) {
      FrameTimingRecorder.recordCurrentFrameNumber(i);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene = ui.SceneBuilder().build();
      addTearDown(scene.dispose);
      droppedFutures.add(renderer.renderScene(scene, view, size: view.physicalSize));
    }

    // Frame 5: the final winning frame
    FrameTimingRecorder.recordCurrentFrameNumber(305);
    FrameTimingRecorder.recordCurrentFrameVsync();
    FrameTimingRecorder.recordCurrentFrameBuildStart();
    final ui.Scene scene5 = ui.SceneBuilder().build();
    addTearDown(scene5.dispose);
    final Future<void> frame5Done = renderer.renderScene(scene5, view, size: view.physicalSize);

    // All intermediate dropped frames (302, 303, 304) must have completed
    for (final dropped in droppedFutures) {
      await expectLater(dropped, completes);
    }

    // Delay while Frame 1 is still in flight to ensure Frame 5 build duration isn't inflated
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Release Frame 1
    holdingRasterizer.rasterizeCompleter = null;
    holdingRasterizer.rasterizeStarted = null;
    frame1Hold.complete();

    await Future.wait([frame1Done, frame5Done]);

    final allTimings = <ui.FrameTiming>[
      ...reportedTimings,
      ...FrameTimingRecorder.debugFrameTimings,
    ];
    final List<int> reportedFrameNumbers = allTimings.map((t) => t.frameNumber).toList();
    expect(reportedFrameNumbers, contains(301));
    expect(reportedFrameNumbers, contains(305));
    expect(reportedFrameNumbers, isNot(contains(302)));
    expect(reportedFrameNumbers, isNot(contains(303)));
    expect(reportedFrameNumbers, isNot(contains(304)));
    expect(allTimings, hasLength(2));

    final ui.FrameTiming frame5Timing = allTimings.firstWhere((t) => t.frameNumber == 305);
    expect(frame5Timing.buildDuration, lessThan(const Duration(milliseconds: 50)));
  });

  test(
    'rendering queued scenes with frame timings disabled succeeds without null dereferences',
    () async {
      final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
      final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

      // Disable frame timings
      EnginePlatformDispatcher.instance.onReportTimings = null;

      final frame1Started = Completer<void>();
      final frame1Hold = Completer<void>();
      holdingRasterizer.rasterizeStarted = frame1Started;
      holdingRasterizer.rasterizeCompleter = frame1Hold;

      final ui.Scene scene1 = ui.SceneBuilder().build();
      addTearDown(scene1.dispose);
      final Future<void> frame1Done = renderer.renderScene(scene1, view, size: view.physicalSize);

      await frame1Started.future;

      final ui.Scene scene2 = ui.SceneBuilder().build();
      addTearDown(scene2.dispose);
      final Future<void> frame2Done = renderer.renderScene(scene2, view, size: view.physicalSize);

      final ui.Scene scene3 = ui.SceneBuilder().build();
      addTearDown(scene3.dispose);
      final Future<void> frame3Done = renderer.renderScene(scene3, view, size: view.physicalSize);

      // Frame 2 is dropped and completed
      await expectLater(frame2Done, completes);

      holdingRasterizer.rasterizeCompleter = null;
      holdingRasterizer.rasterizeStarted = null;
      frame1Hold.complete();

      await Future.wait([frame1Done, frame3Done]);

      expect(reportedTimings, isEmpty);
      expect(FrameTimingRecorder.debugFrameTimings, isEmpty);
    },
  );

  test(
    'queued frame with empty dimensions waiting behind in-flight frame records timings cleanly',
    () async {
      final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
      final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

      final frame1Started = Completer<void>();
      final frame1Hold = Completer<void>();
      holdingRasterizer.rasterizeStarted = frame1Started;
      holdingRasterizer.rasterizeCompleter = frame1Hold;

      // Frame 1
      FrameTimingRecorder.recordCurrentFrameNumber(501);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene1 = ui.SceneBuilder().build();
      addTearDown(scene1.dispose);
      final Future<void> frame1Done = renderer.renderScene(scene1, view, size: view.physicalSize);

      await frame1Started.future;

      // View physical size becomes empty before Frame 2 is queued
      view.debugPhysicalSizeOverride = ui.Size.zero;
      view.debugForceResize();

      FrameTimingRecorder.recordCurrentFrameNumber(502);
      FrameTimingRecorder.recordCurrentFrameVsync();
      FrameTimingRecorder.recordCurrentFrameBuildStart();
      final ui.Scene scene2 = ui.SceneBuilder().build();
      addTearDown(scene2.dispose);
      final Future<void> frame2Done = renderer.renderScene(scene2, view, size: view.physicalSize);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Release Frame 1
      holdingRasterizer.rasterizeCompleter = null;
      holdingRasterizer.rasterizeStarted = null;
      frame1Hold.complete();

      await Future.wait([frame1Done, frame2Done]);

      final allTimings = <ui.FrameTiming>[
        ...reportedTimings,
        ...FrameTimingRecorder.debugFrameTimings,
      ];
      expect(allTimings, hasLength(2));
      final ui.FrameTiming frame2Timing = allTimings.firstWhere((t) => t.frameNumber == 502);
      expect(frame2Timing.buildDuration, lessThan(const Duration(milliseconds: 50)));
      expect(frame2Timing.rasterDuration, greaterThanOrEqualTo(Duration.zero));
    },
  );

  test('raster duration includes engine work done before pictures are rasterized', () async {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);
    const engineWork = Duration(milliseconds: 50);
    // Allow for coarse timer resolution in the browser.
    const minimumMeasuredEngineWork = Duration(milliseconds: 40);
    holdingRasterizer.prepareToDrawDelay = engineWork;

    FrameTimingRecorder.recordCurrentFrameNumber(601);
    FrameTimingRecorder.recordCurrentFrameVsync();
    FrameTimingRecorder.recordCurrentFrameBuildStart();
    final ui.Scene scene = ui.SceneBuilder().build();
    addTearDown(scene.dispose);
    await renderer.renderScene(scene, view, size: view.physicalSize);

    final allTimings = <ui.FrameTiming>[
      ...reportedTimings,
      ...FrameTimingRecorder.debugFrameTimings,
    ];
    expect(allTimings, hasLength(1));
    final ui.FrameTiming timing = allTimings.single;
    expect(timing.frameNumber, 601);

    final int buildFinish = timing.timestampInMicroseconds(ui.FramePhase.buildFinish);
    final int rasterStart = timing.timestampInMicroseconds(ui.FramePhase.rasterStart);
    expect(rasterStart, greaterThanOrEqualTo(buildFinish));
    // Raster start is recorded before the engine's preroll, measure, and paint
    // passes, not when the pictures are handed to [ViewRasterizer.rasterize].
    expect(rasterStart, lessThanOrEqualTo(holdingRasterizer.lastRasterizeEnteredMicros!));
    expect(
      holdingRasterizer.lastRasterizeEnteredMicros! - rasterStart,
      greaterThanOrEqualTo(minimumMeasuredEngineWork.inMicroseconds),
    );
    expect(timing.rasterDuration, greaterThanOrEqualTo(minimumMeasuredEngineWork));
    expect(timing.buildDuration, lessThan(engineWork));
  });
  test('queued scene with root picture retains picture after caller calls scene.dispose() immediately after render', () async {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

    final frame1Started = Completer<void>();
    final frame1Hold = Completer<void>();
    holdingRasterizer.rasterizeStarted = frame1Started;
    holdingRasterizer.rasterizeCompleter = frame1Hold;

    // Frame 1
    final builder1 = ui.SceneBuilder();
    builder1.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene1 = builder1.build();
    addTearDown(scene1.dispose);
    final Future<void> frame1Done = renderer.renderScene(scene1, view);

    // Wait until Frame 1 is holding in rasterize.
    await frame1Started.future;

    // Frame 2 is submitted while Frame 1 is in-flight, and disposed immediately.
    final builder2 = ui.SceneBuilder();
    builder2.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene2 = builder2.build();
    final Future<void> frame2Done = renderer.renderScene(scene2, view);
    scene2.dispose();

    // Release Frame 1, and ensure Frame 2 does not hold.
    holdingRasterizer.rasterizeCompleter = null;
    holdingRasterizer.rasterizeStarted = null;
    frame1Hold.complete();

    await Future.wait([frame1Done, frame2Done]);

    expect(holdingRasterizer.rasterizedPictureCounts, <int>[1, 1]);
  });

  test('queued scene with nested OffsetEngineLayer retains picture after layer.dispose() before raster', () async {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

    final frame1Started = Completer<void>();
    final frame1Hold = Completer<void>();
    holdingRasterizer.rasterizeStarted = frame1Started;
    holdingRasterizer.rasterizeCompleter = frame1Hold;

    // Frame 1
    final builder1 = ui.SceneBuilder();
    builder1.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene1 = builder1.build();
    addTearDown(scene1.dispose);
    final Future<void> frame1Done = renderer.renderScene(scene1, view);

    // Wait until Frame 1 is holding in rasterize.
    await frame1Started.future;

    // Frame 2 has a nested OffsetEngineLayer which is disposed before raster.
    final builder2 = ui.SceneBuilder();
    final ui.OffsetEngineLayer offsetLayer = builder2.pushOffset(10, 10);
    builder2.addPicture(ui.Offset.zero, createTestPicture());
    builder2.pop();
    final ui.Scene scene2 = builder2.build();
    final Future<void> frame2Done = renderer.renderScene(scene2, view);
    offsetLayer.dispose();
    addTearDown(scene2.dispose);

    // Release Frame 1, and ensure Frame 2 does not hold.
    holdingRasterizer.rasterizeCompleter = null;
    holdingRasterizer.rasterizeStarted = null;
    frame1Hold.complete();

    await Future.wait([frame1Done, frame2Done]);

    expect(holdingRasterizer.rasterizedPictureCounts, <int>[1, 1]);
  });

  test(
    'layer reuse across queued frames via SceneBuilder.addRetained rasterizes pictures completely',
    () async {
      final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
      final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

      final frame1Started = Completer<void>();
      final frame1Hold = Completer<void>();
      holdingRasterizer.rasterizeStarted = frame1Started;
      holdingRasterizer.rasterizeCompleter = frame1Hold;

      // Frame 1
      final builder1 = ui.SceneBuilder();
      final ui.OffsetEngineLayer offsetLayer = builder1.pushOffset(10, 10);
      builder1.addPicture(ui.Offset.zero, createTestPicture());
      builder1.pop();
      final ui.Scene scene1 = builder1.build();
      final Future<void> frame1Done = renderer.renderScene(scene1, view);

      // Wait until Frame 1 is holding in rasterize.
      await frame1Started.future;

      // Frame 2 reuses offsetLayer via addRetained while Frame 1 is in-flight.
      final builder2 = ui.SceneBuilder();
      builder2.addRetained(offsetLayer);
      final ui.Scene scene2 = builder2.build();
      final Future<void> frame2Done = renderer.renderScene(scene2, view);

      scene1.dispose();
      offsetLayer.dispose();
      addTearDown(scene2.dispose);

      // Release Frame 1, and ensure Frame 2 does not hold.
      holdingRasterizer.rasterizeCompleter = null;
      holdingRasterizer.rasterizeStarted = null;
      frame1Hold.complete();

      await Future.wait([frame1Done, frame2Done]);

      expect(holdingRasterizer.rasterizedPictureCounts, <int>[1, 1]);
    },
  );

  test(
    'redundant and re-entrant scene.dispose calls are idempotent on queued and rendered scenes',
    () async {
      final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
      final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

      final frame1Started = Completer<void>();
      final frame1Hold = Completer<void>();
      holdingRasterizer.rasterizeStarted = frame1Started;
      holdingRasterizer.rasterizeCompleter = frame1Hold;

      // Frame 1
      final builder1 = ui.SceneBuilder();
      builder1.addPicture(ui.Offset.zero, createTestPicture());
      final ui.Scene scene1 = builder1.build();
      final Future<void> frame1Done = renderer.renderScene(scene1, view);

      // Wait until Frame 1 is holding in rasterize.
      await frame1Started.future;

      // Frame 2 queued behind Frame 1.
      final builder2 = ui.SceneBuilder();
      builder2.addPicture(ui.Offset.zero, createTestPicture());
      final ui.Scene scene2 = builder2.build();
      final Future<void> frame2Done = renderer.renderScene(scene2, view);

      // Rapid and redundant disposals while Frame 1 is in-flight and Frame 2 is queued.
      for (var i = 0; i < 5; i++) {
        expect(scene1.dispose, returnsNormally);
        expect(scene2.dispose, returnsNormally);
      }

      // Release Frame 1, and let both frames complete.
      holdingRasterizer.rasterizeCompleter = null;
      holdingRasterizer.rasterizeStarted = null;
      frame1Hold.complete();

      await Future.wait([frame1Done, frame2Done]);

      // Redundant disposals after presentation/rasterization is fully completed.
      for (var i = 0; i < 5; i++) {
        expect(scene1.dispose, returnsNormally);
        expect(scene2.dispose, returnsNormally);
      }

      expect(holdingRasterizer.rasterizedPictureCounts, <int>[1, 1]);
    },
  );

  test('redundant EngineLayer.dispose calls before, during queueing, and after render are idempotent no-ops', () async {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

    final frame1Started = Completer<void>();
    final frame1Hold = Completer<void>();
    holdingRasterizer.rasterizeStarted = frame1Started;
    holdingRasterizer.rasterizeCompleter = frame1Hold;

    // Frame 1 in-flight
    final builder1 = ui.SceneBuilder();
    builder1.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene1 = builder1.build();
    addTearDown(scene1.dispose);
    final Future<void> frame1Done = renderer.renderScene(scene1, view);

    await frame1Started.future;

    // Frame 2 with multiple EngineLayers
    final builder2 = ui.SceneBuilder();
    final ui.OffsetEngineLayer offsetLayer = builder2.pushOffset(5, 5);
    final ui.ClipRectEngineLayer clipLayer = builder2.pushClipRect(
      const ui.Rect.fromLTWH(0, 0, 50, 50),
    );
    final ui.OpacityEngineLayer opacityLayer = builder2.pushOpacity(200);
    builder2.addPicture(ui.Offset.zero, createTestPicture());
    builder2.pop();
    builder2.pop();
    builder2.pop();
    final ui.Scene scene2 = builder2.build();

    // Redundant dispose before submission
    for (var i = 0; i < 3; i++) {
      expect(offsetLayer.dispose, returnsNormally);
    }

    final Future<void> frame2Done = renderer.renderScene(scene2, view);

    // Redundant dispose while queued
    for (var i = 0; i < 3; i++) {
      expect(clipLayer.dispose, returnsNormally);
      expect(offsetLayer.dispose, returnsNormally);
    }

    // Release Frame 1
    holdingRasterizer.rasterizeCompleter = null;
    holdingRasterizer.rasterizeStarted = null;
    frame1Hold.complete();

    await Future.wait([frame1Done, frame2Done]);

    // Redundant dispose after rasterization
    for (var i = 0; i < 3; i++) {
      expect(opacityLayer.dispose, returnsNormally);
      expect(clipLayer.dispose, returnsNormally);
      expect(offsetLayer.dispose, returnsNormally);
      expect(scene2.dispose, returnsNormally);
    }

    expect(holdingRasterizer.rasterizedPictureCounts, <int>[1, 1]);
  });

  test('multiple consecutive queued overwrites complete dropped frame futures and retain surviving frame pictures', () async {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

    final frame1Started = Completer<void>();
    final frame1Hold = Completer<void>();
    holdingRasterizer.rasterizeStarted = frame1Started;
    holdingRasterizer.rasterizeCompleter = frame1Hold;

    // Frame 1
    final builder1 = ui.SceneBuilder();
    builder1.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene1 = builder1.build();
    addTearDown(scene1.dispose);
    final Future<void> frame1Done = renderer.renderScene(scene1, view);

    await frame1Started.future;

    // Frame 2 queued
    final builder2 = ui.SceneBuilder();
    builder2.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene2 = builder2.build();
    final Future<void> frame2Done = renderer.renderScene(scene2, view);
    scene2.dispose();

    // Frame 3 queued, overwriting Frame 2
    final builder3 = ui.SceneBuilder();
    builder3.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene3 = builder3.build();
    final Future<void> frame3Done = renderer.renderScene(scene3, view);
    scene3.dispose();

    // Frame 4 queued, overwriting Frame 3
    final builder4 = ui.SceneBuilder();
    builder4.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene4 = builder4.build();
    final Future<void> frame4Done = renderer.renderScene(scene4, view);
    scene4.dispose();

    // Dropped frames 2 and 3 complete their completers upon being overwritten.
    await frame2Done;
    await frame3Done;

    // Release Frame 1
    holdingRasterizer.rasterizeCompleter = null;
    holdingRasterizer.rasterizeStarted = null;
    frame1Hold.complete();

    await Future.wait([frame1Done, frame4Done]);

    // Frames 1 and 4 rasterize completely, frames 2 and 3 were dropped cleanly.
    expect(holdingRasterizer.rasterizedPictureCounts, <int>[1, 1]);
  });

  test('deeply nested ContainerLayer DAG retains pictures when intermediate layers are disposed out-of-order', () async {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

    final frame1Started = Completer<void>();
    final frame1Hold = Completer<void>();
    holdingRasterizer.rasterizeStarted = frame1Started;
    holdingRasterizer.rasterizeCompleter = frame1Hold;

    // Frame 1
    final builder1 = ui.SceneBuilder();
    builder1.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene1 = builder1.build();
    addTearDown(scene1.dispose);
    final Future<void> frame1Done = renderer.renderScene(scene1, view);

    await frame1Started.future;

    // Frame 2: pushOffset -> pushClipRect -> pushOpacity -> pushColorFilter -> addPicture
    final builder2 = ui.SceneBuilder();
    final ui.OffsetEngineLayer offsetLayer = builder2.pushOffset(10, 20);
    final ui.ClipRectEngineLayer clipLayer = builder2.pushClipRect(
      const ui.Rect.fromLTWH(0, 0, 80, 80),
    );
    final ui.OpacityEngineLayer opacityLayer = builder2.pushOpacity(180);
    final ui.ColorFilterEngineLayer colorFilterLayer = builder2.pushColorFilter(
      const ui.ColorFilter.mode(ui.Color(0xFF0000FF), ui.BlendMode.srcIn),
    );
    builder2.addPicture(ui.Offset.zero, createTestPicture());
    builder2.pop();
    builder2.pop();
    builder2.pop();
    builder2.pop();
    final ui.Scene scene2 = builder2.build();

    final Future<void> frame2Done = renderer.renderScene(scene2, view);

    // Dispose intermediate engine layers out-of-order prior to rasterization
    clipLayer.dispose();
    scene2.dispose();
    colorFilterLayer.dispose();
    offsetLayer.dispose();
    opacityLayer.dispose();

    // Release Frame 1
    holdingRasterizer.rasterizeCompleter = null;
    holdingRasterizer.rasterizeStarted = null;
    frame1Hold.complete();

    await Future.wait([frame1Done, frame2Done]);

    expect(holdingRasterizer.rasterizedPictureCounts, <int>[1, 1]);
  });

  test(
    'empty queued scene with zero pictures completes cleanly when disposed immediately',
    () async {
      final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
      final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

      final frame1Started = Completer<void>();
      final frame1Hold = Completer<void>();
      holdingRasterizer.rasterizeStarted = frame1Started;
      holdingRasterizer.rasterizeCompleter = frame1Hold;

      // Frame 1
      final builder1 = ui.SceneBuilder();
      builder1.addPicture(ui.Offset.zero, createTestPicture());
      final ui.Scene scene1 = builder1.build();
      addTearDown(scene1.dispose);
      final Future<void> frame1Done = renderer.renderScene(scene1, view);

      await frame1Started.future;

      // Frame 2: empty scene (no pictures, no child layers)
      final builder2 = ui.SceneBuilder();
      final ui.Scene scene2 = builder2.build();
      final Future<void> frame2Done = renderer.renderScene(scene2, view);

      // Dispose immediately and redundantly
      scene2.dispose();
      scene2.dispose();

      // Release Frame 1
      holdingRasterizer.rasterizeCompleter = null;
      holdingRasterizer.rasterizeStarted = null;
      frame1Hold.complete();

      await Future.wait([frame1Done, frame2Done]);

      // Frame 1 has 1 picture, Frame 2 has 0 pictures
      expect(holdingRasterizer.rasterizedPictureCounts, <int>[1, 0]);
    },
  );

  test('clearing renderer while frame is in-flight and next is queued completes next and cleans up cleanly', () async {
    final EngineFlutterView view = EnginePlatformDispatcher.instance.implicitView!;
    final HoldingRasterizer holdingRasterizer = createAndInstallHoldingRasterizer(view);

    final frame1Started = Completer<void>();
    final frame1Hold = Completer<void>();
    holdingRasterizer.rasterizeStarted = frame1Started;
    holdingRasterizer.rasterizeCompleter = frame1Hold;

    final builder1 = ui.SceneBuilder();
    builder1.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene1 = builder1.build();
    addTearDown(scene1.dispose);
    final Future<void> frame1Done = renderer.renderScene(scene1, view);

    await frame1Started.future;

    final builder2 = ui.SceneBuilder();
    builder2.addPicture(ui.Offset.zero, createTestPicture());
    final ui.Scene scene2 = builder2.build();
    addTearDown(scene2.dispose);
    final Future<void> frame2Done = renderer.renderScene(scene2, view);

    // Call debugClear() while Frame 1 is holding and Frame 2 is in renderQueue.next.
    renderer.debugClear();

    // Frame 2 was dropped by teardown; its completer must complete.
    await expectLater(frame2Done, completes);

    // Release Frame 1.
    holdingRasterizer.rasterizeCompleter = null;
    holdingRasterizer.rasterizeStarted = null;
    frame1Hold.complete();

    await frame1Done;
  });
}
