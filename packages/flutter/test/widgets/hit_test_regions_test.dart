// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// These tests drive the hit-test region pass through real widgets (routes,
// showGeneralDialog and its barrier, overlays, and followers) and verify
// AutomatedTestWidgetsFlutterBinding frame-phase and deferFirstFrame
// integration. The geometry, claim rules and bookkeeping are covered in
// test/rendering/hit_test_regions_test.dart.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/fake_platform_views.dart';

// Widgets are positioned in logical pixels but regions are in physical
// pixels; a ratio other than 1 checks the conversion.
const double _devicePixelRatio = 2.0;

/// The regions computed by the last frame: for each platform view, in paint
/// order, the distinct rects claimed over it, in logical pixels.
///
/// Rects are deduplicated because some widgets, such as [ModalBarrier], are
/// built from several nested boxes that each claim the same rect.
Map<int, Set<Rect>> _lastRegions() {
  final Float64List payload = RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions!;
  double logicalAt(int i) => payload[i] / _devicePixelRatio;
  final regions = <int, Set<Rect>>{};
  for (var i = 0; i < payload.length;) {
    final Set<Rect> rects = regions[payload[i].toInt()] = <Rect>{};
    final int end = i + 2 + 4 * payload[i + 1].toInt();
    for (i += 2; i < end; i += 4) {
      rects.add(Rect.fromLTRB(logicalAt(i), logicalAt(i + 1), logicalAt(i + 2), logicalAt(i + 3)));
    }
  }
  return regions;
}

Widget _platformView(int viewId) {
  return PlatformViewSurface(
    controller: FakePlatformViewController(viewId),
    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
  );
}

Widget _app(Widget home) {
  return WidgetsApp(
    color: const Color(0xFF000000),
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (BuildContext context, _, _) => builder(context),
    ),
    home: home,
  );
}

Widget _followerOverPlatformView({
  required LayerLink link,
  required ValueListenable<Offset> targetOffset,
  required Offset followerOffset,
  required Size followerSize,
  Widget child = const Listener(behavior: HitTestBehavior.opaque),
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Stack(
      children: <Widget>[
        Positioned.fromRect(rect: const Rect.fromLTWH(0, 0, 500, 500), child: _platformView(1)),
        ValueListenableBuilder<Offset>(
          valueListenable: targetOffset,
          builder: (_, Offset offset, _) => Positioned(
            left: offset.dx,
            top: offset.dy,
            width: followerSize.width,
            height: followerSize.height,
            child: CompositedTransformTarget(link: link),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          width: followerSize.width,
          height: followerSize.height,
          child: CompositedTransformFollower(link: link, offset: followerOffset, child: child),
        ),
      ],
    ),
  );
}

class _PaintCounter extends CustomPainter {
  int count = 0;

  @override
  void paint(Canvas canvas, Size size) => count += 1;

  @override
  bool shouldRepaint(_PaintCounter oldDelegate) => false;
}

void main() {
  // Must reset through addTearDown: the binding verifies that debug variables
  // are unset before tearDown callbacks run.
  void enablePass(WidgetTester tester) {
    debugEnableHitTestRegionsOnAllPlatforms = true;
    RendererBinding.instance.automaticPointerInterceptorsEnabled = true;
    tester.view.devicePixelRatio = _devicePixelRatio;
    tester.view.physicalSize = const Size(800, 600) * _devicePixelRatio;
    addTearDown(() {
      RendererBinding.instance.automaticPointerInterceptorsEnabled = false;
      debugEnableHitTestRegionsOnAllPlatforms = false;
      tester.view.reset();
    });
  }

  testWidgets('PV1 under a dismissible showGeneralDialog that contains PV2', (
    WidgetTester tester,
  ) async {
    enablePass(tester);
    const homeButton = Rect.fromLTWH(20, 30, 80, 40);
    const barrier = Rect.fromLTWH(0, 0, 800, 600);
    const dialogHeader = Rect.fromLTWH(100, 100, 200, 40);
    const dialogButton = Rect.fromLTWH(250, 150, 40, 40);
    late BuildContext homeContext;

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (BuildContext context) {
            homeContext = context;
            return Stack(
              children: <Widget>[
                // Painted below PV1, so it claims nothing.
                Positioned.fromRect(
                  rect: const Rect.fromLTWH(0, 0, 150, 150),
                  child: const ColoredBox(color: Color(0xFF112233)),
                ),
                Positioned.fromRect(
                  rect: const Rect.fromLTWH(0, 0, 500, 500),
                  child: _platformView(1),
                ),
                Positioned.fromRect(
                  rect: homeButton,
                  child: const Listener(behavior: HitTestBehavior.opaque),
                ),
              ],
            );
          },
        ),
      ),
    );
    showGeneralDialog<void>(
      context: homeContext,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (_, _, _) => Stack(
        children: <Widget>[
          Positioned.fromRect(
            rect: dialogHeader,
            child: const ColoredBox(color: Color(0xFFFFFFFF)),
          ),
          Positioned.fromRect(
            rect: const Rect.fromLTWH(100, 140, 200, 200),
            child: _platformView(2),
          ),
          Positioned.fromRect(
            rect: dialogButton,
            child: const Listener(behavior: HitTestBehavior.opaque),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // PV1's group has exactly the claims painted between PV1 and PV2,
    // including the barrier; PV2's group has only what is painted after PV2.
    final Map<int, Set<Rect>> regions = _lastRegions();
    expect(regions.keys, <int>[1, 2]);
    expect(regions, <int, Set<Rect>>{
      1: <Rect>{homeButton, barrier, dialogHeader},
      2: <Rect>{dialogButton},
    });
  });

  testWidgets('a closing dialog stops claiming as soon as its exit animation starts', (
    WidgetTester tester,
  ) async {
    enablePass(tester);
    final homePainter = _PaintCounter();
    late BuildContext homeContext;

    await tester.pumpWidget(
      _app(
        RepaintBoundary(
          child: CustomPaint(
            painter: homePainter,
            child: Builder(
              builder: (BuildContext context) {
                homeContext = context;
                return _platformView(1);
              },
            ),
          ),
        ),
      ),
    );
    showGeneralDialog<void>(
      context: homeContext,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    await tester.pumpAndSettle();
    expect(_lastRegions(), <int, Set<Rect>>{
      1: <Rect>{const Rect.fromLTWH(0, 0, 800, 600)},
    });

    final int homePaintCount = homePainter.count;
    Navigator.of(homeContext).pop();
    await tester.pump(const Duration(milliseconds: 50));

    // The barrier's IgnorePointer flips to ignoring while the home route
    // (with the platform view) is not repainted, so a region pass driven by
    // paint would miss it.
    expect(homePainter.count, homePaintCount);
    expect(_lastRegions(), <int, Set<Rect>>{1: <Rect>{}});
  });

  testWidgets('render boxes that have never been laid out are skipped', (
    WidgetTester tester,
  ) async {
    enablePass(tester);
    const button = Rect.fromLTWH(20, 30, 80, 40);

    // Offstage beneath the opaque entry from the start, so the overlay keeps it
    // in its child list but never lays it out.
    final entry1 = OverlayEntry(
      maintainState: true,
      builder: (_) => const ClipRect(child: Listener(behavior: HitTestBehavior.opaque)),
    );
    final entry2 = OverlayEntry(
      opaque: true,
      builder: (_) => Stack(
        children: <Widget>[
          _platformView(1),
          Positioned.fromRect(
            rect: button,
            child: const Listener(behavior: HitTestBehavior.opaque),
          ),
        ],
      ),
    );
    addTearDown(() {
      entry1
        ..remove()
        ..dispose();
      entry2
        ..remove()
        ..dispose();
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(initialEntries: <OverlayEntry>[entry1, entry2]),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_lastRegions(), <int, Set<Rect>>{
      1: <Rect>{button},
    });
  });

  testWidgets(
    'CompositedTransformFollower uses the current frame target position after composite, and paint-only pumps do not update regions',
    (WidgetTester tester) async {
      enablePass(tester);
      final link = LayerLink();
      const followerOffset = Offset(10, 15);
      const followerSize = Size(80, 40);
      final targetOffset = ValueNotifier<Offset>(const Offset(40, 50));
      addTearDown(targetOffset.dispose);

      await tester.pumpWidget(
        _followerOverPlatformView(
          link: link,
          targetOffset: targetOffset,
          followerOffset: followerOffset,
          followerSize: followerSize,
        ),
        phase: EnginePhase.paint,
      );

      // Stopping at paint does not run the pass.
      expect(RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions, isNull);

      // Pumping to composite runs compositeFrame first, so the follower already
      // knows the target's position in that same frame.
      tester.binding.scheduleFrame();
      await tester.pump(null, EnginePhase.composite);
      expect(_lastRegions(), <int, Set<Rect>>{
        1: <Rect>{(const Offset(40, 50) + followerOffset) & followerSize},
      });

      // Moving the target and pumping only through paint keeps the previous
      // composite regions.
      targetOffset.value = const Offset(120, 160);
      await tester.pump(null, EnginePhase.paint);
      expect(_lastRegions(), <int, Set<Rect>>{
        1: <Rect>{(const Offset(40, 50) + followerOffset) & followerSize},
      });

      // Moving the target and calling a single tester.pump() updates regions to
      // that frame's new target position.
      targetOffset.value = const Offset(200, 220);
      await tester.pump();
      expect(_lastRegions(), <int, Set<Rect>>{
        1: <Rect>{(const Offset(200, 220) + followerOffset) & followerSize},
      });
    },
  );

  testWidgets(
    'deferFirstFrame suppresses the pass until allowFirstFrame lets a frame reach the engine',
    (WidgetTester tester) async {
      enablePass(tester);
      FlutterTimeline.debugCollectionEnabled = true;
      addTearDown(() {
        FlutterTimeline.debugReset();
        FlutterTimeline.debugCollectionEnabled = false;
      });

      const button = Rect.fromLTWH(20, 30, 80, 40);
      var deferred = true;
      RendererBinding.instance.deferFirstFrame();
      addTearDown(() {
        if (deferred) {
          RendererBinding.instance.allowFirstFrame();
        }
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Positioned.fromRect(
                rect: const Rect.fromLTWH(0, 0, 500, 500),
                child: _platformView(1),
              ),
              Positioned.fromRect(
                rect: button,
                child: const Listener(behavior: HitTestBehavior.opaque),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(RendererBinding.instance.sendFramesToEngine, isFalse);
      expect(RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions, isNull);
      expect(FlutterTimeline.debugCollect().getAggregated('HIT TEST REGIONS').count, 0);

      RendererBinding.instance.allowFirstFrame();
      deferred = false;
      expect(RendererBinding.instance.sendFramesToEngine, isTrue);
      expect(RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions, isNull);

      tester.binding.scheduleFrame();
      await tester.pump();
      expect(_lastRegions(), <int, Set<Rect>>{
        1: <Rect>{button},
      });
      expect(FlutterTimeline.debugCollect().getAggregated('HIT TEST REGIONS').count, 1);
    },
  );

  testWidgets(
    'flushes hit-test regions after compositing and before semantics and post-frame callbacks',
    (WidgetTester tester) async {
      enablePass(tester);
      final SemanticsHandle semantics = tester.ensureSemantics();
      FlutterTimeline.debugCollectionEnabled = true;
      addTearDown(() {
        FlutterTimeline.debugReset();
        FlutterTimeline.debugCollectionEnabled = false;
      });

      final link = LayerLink();
      const followerOffset = Offset(10, 15);
      const followerSize = Size(80, 40);
      final targetOffset = ValueNotifier<Offset>(const Offset(40, 50));
      addTearDown(targetOffset.dispose);

      await tester.pumpWidget(
        _followerOverPlatformView(
          link: link,
          targetOffset: targetOffset,
          followerOffset: followerOffset,
          followerSize: followerSize,
          child: Semantics(
            label: 'Action',
            button: true,
            container: true,
            child: const Listener(behavior: HitTestBehavior.opaque),
          ),
        ),
      );

      final events = <String>[];
      Map<int, Set<Rect>>? regionsDuringSemantics;
      Map<int, Set<Rect>>? regionsInPostFrame;
      final SemanticsOwner semanticsOwner =
          RendererBinding.instance.renderViews.single.owner!.semanticsOwner!;
      void onSemantics() {
        events.add('semantics');
        regionsDuringSemantics = _lastRegions();
      }

      semanticsOwner.addListener(onSemantics);
      try {
        targetOffset.value = const Offset(150, 170);
        RendererBinding.instance.addPostFrameCallback((_) {
          events.add('postFrame');
          regionsInPostFrame = _lastRegions();
        });
        FlutterTimeline.debugReset();
        await tester.pump();

        const tracked = <String>{'COMPOSITING', 'HIT TEST REGIONS', 'SEMANTICS'};
        final timelineOrder = <String>[
          for (final TimedBlock block in FlutterTimeline.debugCollect().timedBlocks)
            if (tracked.contains(block.name)) block.name,
        ];
        expect(timelineOrder, <String>['COMPOSITING', 'HIT TEST REGIONS', 'SEMANTICS']);
        expect(events, <String>['semantics', 'postFrame']);

        final expected = <int, Set<Rect>>{
          1: <Rect>{(const Offset(150, 170) + followerOffset) & followerSize},
        };
        expect(regionsDuringSemantics, expected);
        expect(regionsInPostFrame, expected);
      } finally {
        semanticsOwner.removeListener(onSemantics);
        semantics.dispose();
      }
    },
  );
}
