// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// These tests drive the hit-test region pass through real widgets (routes,
// showGeneralDialog and its barrier) under the flutter_test binding. The
// geometry, claim rules and bookkeeping are covered in
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
  double at(int i) => payload[i] / _devicePixelRatio;
  final regions = <int, Set<Rect>>{};
  for (var i = 0; i < payload.length;) {
    final Set<Rect> rects = regions[payload[i].toInt()] = <Rect>{};
    final int end = i + 2 + 4 * payload[i + 1].toInt();
    for (i += 2; i < end; i += 4) {
      rects.add(Rect.fromLTRB(at(i), at(i + 1), at(i + 2), at(i + 3)));
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
}
