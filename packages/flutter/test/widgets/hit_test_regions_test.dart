// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/fake_platform_views.dart';

typedef _HitTestRegionGroup = ({int viewId, List<Rect> rects});

List<_HitTestRegionGroup> _decodePayload(Float64List payload) {
  final groups = <_HitTestRegionGroup>[];
  var i = 0;
  while (i < payload.length) {
    final int viewId = payload[i].toInt();
    final int count = payload[i + 1].toInt();
    i += 2;
    final rects = <Rect>[];
    for (var j = 0; j < count; j++) {
      rects.add(Rect.fromLTRB(payload[i], payload[i + 1], payload[i + 2], payload[i + 3]));
      i += 4;
    }
    groups.add((viewId: viewId, rects: rects));
  }
  return groups;
}

Widget _buildPlatformView(int viewId) {
  return PlatformViewSurface(
    controller: FakePlatformViewController(viewId),
    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
  );
}

Widget _buildApp(Widget home) {
  return WidgetsApp(
    color: const Color(0xFF000000),
    debugShowCheckedModeBanner: false,
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
      return PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) => builder(context),
      );
    },
    home: home,
  );
}

class _PaintCountingPainter extends CustomPainter {
  _PaintCountingPainter(this.onPaint);

  final VoidCallback onPaint;

  @override
  void paint(Canvas canvas, Size size) {
    onPaint();
  }

  @override
  bool shouldRepaint(_PaintCountingPainter oldDelegate) => false;
}

void main() {
  setUp(() {
    debugEnableHitTestRegionsOnAllPlatforms = false;
    RendererBinding.instance.automaticPointerInterceptorsEnabled = false;
  });

  tearDown(() {
    debugEnableHitTestRegionsOnAllPlatforms = false;
    RendererBinding.instance.automaticPointerInterceptorsEnabled = false;
  });

  void configureTestView(WidgetTester tester, {double devicePixelRatio = 1.0}) {
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.physicalSize = Size(800.0 * devicePixelRatio, 600.0 * devicePixelRatio);
    addTearDown(tester.view.reset);
  }

  testWidgets('does not compute hit-test regions when flag is off or not on web without override', (
    WidgetTester tester,
  ) async {
    configureTestView(tester);

    final widget = Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: <Widget>[
          Positioned(left: 0, top: 0, width: 400, height: 400, child: _buildPlatformView(1)),
          Positioned(
            left: 10,
            top: 20,
            width: 100,
            height: 50,
            child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) {}),
          ),
        ],
      ),
    );

    // 1. Flag off -> debugLastHitTestRegions is null.
    debugEnableHitTestRegionsOnAllPlatforms = true;
    RendererBinding.instance.automaticPointerInterceptorsEnabled = false;
    await tester.pumpWidget(widget);
    expect(RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions, isNull);

    // 2. Flag on, debug override off (when not on web) -> debugLastHitTestRegions is null.
    if (!kIsWeb) {
      debugEnableHitTestRegionsOnAllPlatforms = false;
      RendererBinding.instance.automaticPointerInterceptorsEnabled = true;
      await tester.pump();
      expect(RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions, isNull);
    }
  });

  testWidgets(
    'returns null when no platform view is present and clears when last platform view is removed',
    (WidgetTester tester) async {
      configureTestView(tester);
      debugEnableHitTestRegionsOnAllPlatforms = true;
      RendererBinding.instance.automaticPointerInterceptorsEnabled = true;

      // No platform view -> null.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 10,
                top: 20,
                width: 100,
                height: 50,
                child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) {}),
              ),
            ],
          ),
        ),
      );
      expect(RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions, isNull);

      // Add a platform view -> non-null payload.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Positioned(left: 0, top: 0, width: 400, height: 400, child: _buildPlatformView(1)),
              Positioned(
                left: 10,
                top: 20,
                width: 100,
                height: 50,
                child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) {}),
              ),
            ],
          ),
        ),
      );
      expect(
        RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[1.0, 1.0, 10.0, 20.0, 110.0, 70.0])),
      );

      // Remove the platform view -> debugLastHitTestRegions returns to null.
      await tester.pumpWidget(
        const Directionality(textDirection: TextDirection.ltr, child: Stack()),
      );
      expect(RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions, isNull);
    },
  );

  testWidgets(
    'home route content painted before platform view produces no rects and overlay button produces physical rect at DPR 1.0 and 3.0',
    (WidgetTester tester) async {
      configureTestView(tester);
      debugEnableHitTestRegionsOnAllPlatforms = true;
      RendererBinding.instance.automaticPointerInterceptorsEnabled = true;

      final widget = Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            // Content painted before the platform view -> produces no rects.
            const Positioned(
              left: 0,
              top: 0,
              width: 200,
              height: 200,
              child: ColoredBox(color: Color(0xFFFF0000)),
            ),
            Positioned(
              left: 20,
              top: 30,
              width: 80,
              height: 40,
              child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) {}),
            ),
            // Platform view.
            Positioned(left: 0, top: 0, width: 400, height: 400, child: _buildPlatformView(1)),
            // Button positioned over the platform view.
            Positioned(
              left: 10,
              top: 20,
              width: 100,
              height: 50,
              child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) {}),
            ),
          ],
        ),
      );

      await tester.pumpWidget(widget);
      expect(
        RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[1.0, 1.0, 10.0, 20.0, 110.0, 70.0])),
      );

      // Change DPR to 3.0 -> physical coordinates scale by 3.0.
      configureTestView(tester, devicePixelRatio: 3.0);
      await tester.pump();
      expect(
        RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[1.0, 1.0, 30.0, 60.0, 330.0, 210.0])),
      );
    },
  );

  testWidgets(
    'PV1 under showGeneralDialog (barrierDismissible) containing PV2 partitions claims into PV1 and PV2 groups',
    (WidgetTester tester) async {
      configureTestView(tester);
      debugEnableHitTestRegionsOnAllPlatforms = true;
      RendererBinding.instance.automaticPointerInterceptorsEnabled = true;

      late BuildContext savedContext;

      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (BuildContext context) {
              savedContext = context;
              return Stack(
                children: <Widget>[
                  // Home route content painted before PV1 -> produces no rects.
                  const Positioned(
                    left: 0,
                    top: 0,
                    width: 150,
                    height: 150,
                    child: ColoredBox(color: Color(0xFF112233)),
                  ),
                  // PV1 on home route.
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 500,
                    height: 500,
                    child: _buildPlatformView(1),
                  ),
                  // Floating button over PV1 on home route (painted between PV1 and PV2).
                  Positioned(
                    left: 20,
                    top: 30,
                    width: 80,
                    height: 40,
                    child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) {}),
                  ),
                ],
              );
            },
          ),
        ),
      );

      // Open a dismissible dialog containing dialog chrome before PV2, PV2 itself, and a close button after PV2.
      showGeneralDialog<void>(
        context: savedContext,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return Stack(
                children: <Widget>[
                  // Dialog header painted before PV2 (overlaps PV1).
                  const Positioned(
                    left: 100,
                    top: 100,
                    width: 200,
                    height: 40,
                    child: ColoredBox(color: Color(0xFFFFFFFF)),
                  ),
                  // PV2 inside the dialog.
                  Positioned(
                    left: 100,
                    top: 140,
                    width: 200,
                    height: 200,
                    child: _buildPlatformView(2),
                  ),
                  // Close button inside the dialog painted after PV2.
                  Positioned(
                    left: 250,
                    top: 150,
                    width: 40,
                    height: 40,
                    child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) {}),
                  ),
                ],
              );
            },
      );
      await tester.pumpAndSettle();

      final Float64List? payload =
          RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions;
      expect(payload, isNotNull);

      final List<_HitTestRegionGroup> groups = _decodePayload(payload!);
      expect(groups, hasLength(2));
      expect(groups[0].viewId, 1);
      expect(groups[1].viewId, 2);

      // PV1's group contains the home button over PV1, the full-screen modal barrier rect,
      // and the dialog header painted before PV2. It does NOT contain the home background
      // painted before PV1 or the dialog close button painted after PV2.
      const homeButtonRect = Rect.fromLTWH(20, 30, 80, 40);
      const barrierRect = Rect.fromLTWH(0, 0, 800, 600);
      const dialogHeaderRect = Rect.fromLTWH(100, 100, 200, 40);
      const dialogCloseButtonRect = Rect.fromLTWH(250, 150, 40, 40);

      expect(groups[0].rects, containsAll(<Rect>[homeButtonRect, barrierRect, dialogHeaderRect]));
      for (final Rect rect in groups[0].rects) {
        expect(
          rect == homeButtonRect || rect == barrierRect || rect == dialogHeaderRect,
          isTrue,
          reason: 'Unexpected rect $rect in PV1 group',
        );
      }

      // PV2's group contains ONLY the close button painted after PV2; no rect painted
      // before PV2 (barrier, home button, or dialog header) lands in PV2's group.
      expect(groups[1].rects, equals(<Rect>[dialogCloseButtonRect]));
    },
  );

  testWidgets(
    'dialog exit animation toggles barrier IgnorePointer and removes barrier rect without repainting underlying content',
    (WidgetTester tester) async {
      configureTestView(tester);
      debugEnableHitTestRegionsOnAllPlatforms = true;
      RendererBinding.instance.automaticPointerInterceptorsEnabled = true;

      late BuildContext savedContext;
      var homePaintCount = 0;

      await tester.pumpWidget(
        _buildApp(
          RepaintBoundary(
            child: CustomPaint(
              painter: _PaintCountingPainter(() {
                homePaintCount += 1;
              }),
              child: Builder(
                builder: (BuildContext context) {
                  savedContext = context;
                  return Stack(
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        top: 0,
                        width: 400,
                        height: 400,
                        child: _buildPlatformView(1),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      expect(homePaintCount, 1);

      showGeneralDialog<void>(
        context: savedContext,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return const Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ColoredBox(color: Color(0xFFFFFFFF)),
                ),
              );
            },
      );
      await tester.pumpAndSettle();

      const barrierRect = Rect.fromLTWH(0, 0, 800, 600);
      final List<_HitTestRegionGroup> openGroups = _decodePayload(
        RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions!,
      );
      expect(openGroups, hasLength(1));
      expect(openGroups.single.viewId, 1);
      expect(openGroups.single.rects, contains(barrierRect));

      final paintCountBeforePop = homePaintCount;

      // Start popping the dialog and pump a single frame mid-exit animation.
      Navigator.of(savedContext).pop();
      await tester.pump(const Duration(milliseconds: 50));

      // Underlying home content did not repaint.
      expect(homePaintCount, equals(paintCountBeforePop));

      // The barrier IgnorePointer toggled to ignoring: true, so the barrier rect
      // disappears from the payload immediately during the exit animation.
      final List<_HitTestRegionGroup> exitingGroups = _decodePayload(
        RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions!,
      );
      expect(exitingGroups, hasLength(1));
      expect(exitingGroups.single.viewId, 1);
      expect(exitingGroups.single.rects, isNot(contains(barrierRect)));
      expect(exitingGroups.single.rects, isEmpty);
    },
  );

  testWidgets(
    'IgnorePointer overlay produces no rect, AbsorbPointer produces one rect and no descendants, translucent GestureDetector produces no rect, and Offstage is skipped',
    (WidgetTester tester) async {
      configureTestView(tester);
      debugEnableHitTestRegionsOnAllPlatforms = true;
      RendererBinding.instance.automaticPointerInterceptorsEnabled = true;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Positioned(left: 0, top: 0, width: 400, height: 400, child: _buildPlatformView(1)),
              // 1. IgnorePointer overlay -> no rect.
              const Positioned(
                left: 10,
                top: 10,
                width: 100,
                height: 50,
                child: IgnorePointer(child: ColoredBox(color: Color(0xFFFF0000))),
              ),
              // 2. AbsorbPointer -> claims its own rect and stops descending into children.
              Positioned(
                left: 40,
                top: 50,
                width: 120,
                height: 80,
                child: AbsorbPointer(
                  child: Stack(
                    children: <Widget>[
                      const Positioned(
                        left: 0,
                        top: 0,
                        width: 60,
                        height: 30,
                        child: ColoredBox(color: Color(0xFF00FF00)),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        width: 40,
                        height: 20,
                        child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) {}),
                      ),
                    ],
                  ),
                ),
              ),
              // 3. Translucent GestureDetector -> no rect.
              Positioned(
                left: 20,
                top: 20,
                width: 100,
                height: 50,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {},
                  child: const SizedBox(width: 100, height: 50),
                ),
              ),
              // 4. Offstage -> skipped completely.
              const Positioned(
                left: 30,
                top: 30,
                width: 100,
                height: 50,
                child: Offstage(child: ColoredBox(color: Color(0xFF0000FF))),
              ),
            ],
          ),
        ),
      );

      expect(
        RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[1.0, 1.0, 40.0, 50.0, 160.0, 130.0])),
      );
    },
  );

  testWidgets(
    'PlatformViewSurface inside IgnorePointer(ignoring: true) is discovered while non-platform-view content inside IgnorePointer does not claim rects',
    (WidgetTester tester) async {
      configureTestView(tester);
      debugEnableHitTestRegionsOnAllPlatforms = true;
      RendererBinding.instance.automaticPointerInterceptorsEnabled = true;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                width: 300,
                height: 300,
                child: IgnorePointer(
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        top: 0,
                        width: 300,
                        height: 300,
                        child: _buildPlatformView(3),
                      ),
                      const Positioned(
                        left: 10,
                        top: 10,
                        width: 80,
                        height: 80,
                        child: ColoredBox(color: Color(0xFFFF0000)),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 15,
                top: 25,
                width: 90,
                height: 45,
                child: ColoredBox(color: Color(0xFF00FF00)),
              ),
            ],
          ),
        ),
      );

      expect(
        RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[3.0, 1.0, 15.0, 25.0, 105.0, 70.0])),
      );
    },
  );

  testWidgets(
    'applies ClipRect and Transform and keeps partially overlapping overlay unclipped to platform view bounds',
    (WidgetTester tester) async {
      configureTestView(tester);
      debugEnableHitTestRegionsOnAllPlatforms = true;
      RendererBinding.instance.automaticPointerInterceptorsEnabled = true;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              // Small platform view at (100, 100) to (150, 150).
              Positioned(left: 100, top: 100, width: 50, height: 50, child: _buildPlatformView(1)),
              // Larger overlay at (0, 0) to (250, 250) partially overlapping PV -> unclipped to PV.
              const Positioned(
                left: 0,
                top: 0,
                width: 250,
                height: 250,
                child: ColoredBox(color: Color(0xFF00FF00)),
              ),
              // Clipped and translated overlay -> [120, 120, 160, 160].
              Positioned(
                left: 0,
                top: 0,
                width: 40,
                height: 40,
                child: Transform.translate(
                  offset: const Offset(120, 120),
                  child: const ClipRect(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: ColoredBox(color: Color(0xFFFF0000)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      expect(
        RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions,
        equals(
          Float64List.fromList(<double>[
            1.0,
            2.0,
            0.0,
            0.0,
            250.0,
            250.0,
            120.0,
            120.0,
            160.0,
            160.0,
          ]),
        ),
      );
    },
  );

  testWidgets(
    'toggling automaticPointerInterceptorsEnabled from true to false at runtime immediately clears debugLastHitTestRegions',
    (WidgetTester tester) async {
      configureTestView(tester);
      debugEnableHitTestRegionsOnAllPlatforms = true;
      RendererBinding.instance.automaticPointerInterceptorsEnabled = true;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Positioned(left: 0, top: 0, width: 300, height: 300, child: _buildPlatformView(1)),
              const Positioned(
                left: 10,
                top: 20,
                width: 100,
                height: 50,
                child: ColoredBox(color: Color(0xFF00FF00)),
              ),
            ],
          ),
        ),
      );

      expect(
        RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions,
        equals(Float64List.fromList(<double>[1.0, 1.0, 10.0, 20.0, 110.0, 70.0])),
      );

      // Toggle off at runtime -> immediately clears debugLastHitTestRegions before next frame.
      RendererBinding.instance.automaticPointerInterceptorsEnabled = false;
      expect(RendererBinding.instance.rootPipelineOwner.debugLastHitTestRegions, isNull);
    },
  );
}
