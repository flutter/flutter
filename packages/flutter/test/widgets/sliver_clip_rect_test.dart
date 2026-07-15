// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

/// Builds a [CustomScrollView] with a pinned 100px header followed by a
/// [SliverClipRect] and filler content. Suitable for all overlap-clipping tests.
Widget _buildOverlapScenario({
  required ScrollController controller,
  ClipOverlapBehavior clipOverlap = .followEdge,
  CustomClipper<Rect>? clipper,
  Axis scrollDirection = .vertical,
  bool reverse = false,
  double childExtent = 100.0,
  Clip clipBehavior = .hardEdge,
}) {
  final isHorizontal = scrollDirection == .horizontal;

  return TestWidgetsApp(
    home: CustomScrollView(
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      slivers: <Widget>[
        const SliverPersistentHeader(delegate: _SliverPersistentHeaderDelegate(), pinned: true),
        SliverClipRect(
          clipOverlap: clipOverlap,
          clipper: clipper,
          clipBehavior: clipBehavior,
          sliver: SliverToBoxAdapter(
            child: RepaintBoundary(
              child: Container(
                height: isHorizontal ? 100.0 : childExtent,
                width: isHorizontal ? childExtent : null,
                color: const Color(0xFF2196F3),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: isHorizontal ? null : 1000.0,
            width: isHorizontal ? 1000.0 : null,
          ),
        ),
      ],
    ),
  );
}

void main() {
  group('SliverClipRect', () {
    testWidgets('renders its child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverClipRect(sliver: SliverToBoxAdapter(child: Text('Hello World'))),
            ],
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('hit test respects custom clipper', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverClipRect(
                clipper: const _HalfHeightClipper(),
                sliver: SliverToBoxAdapter(
                  child: Container(height: 100.0, color: const Color(0xFFF44336)),
                ),
              ),
            ],
          ),
        ),
      );

      final RenderSliver renderSliver = tester.renderObject(find.byType(SliverClipRect));

      expect(
        renderSliver.hitTest(
          SliverHitTestResult(),
          mainAxisPosition: 25.0,
          crossAxisPosition: 400.0,
        ),
        isTrue,
        reason: 'Should hit inside the clipped area',
      );
      expect(
        renderSliver.hitTest(
          SliverHitTestResult(),
          mainAxisPosition: 75.0,
          crossAxisPosition: 400.0,
        ),
        isFalse,
        reason: 'Should NOT hit outside the clipped area',
      );
    });

    testWidgets('updates properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: .ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverClipRect(sliver: SliverToBoxAdapter(child: SizedBox(height: 100.0))),
            ],
          ),
        ),
      );

      final RenderSliverClipRect renderObject = tester.renderObject(find.byType(SliverClipRect));
      expect(renderObject.clipOverlap, ClipOverlapBehavior.followEdge);
      expect(renderObject.clipBehavior, Clip.antiAlias);

      await tester.pumpWidget(
        const Directionality(
          textDirection: .ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverClipRect(
                clipOverlap: .none,
                clipBehavior: .hardEdge,
                sliver: SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
            ],
          ),
        ),
      );

      expect(renderObject.clipOverlap, ClipOverlapBehavior.none);
      expect(renderObject.clipBehavior, Clip.hardEdge);
    });

    testWidgets('updates clip when overlap changes even if geometry is same', (
      WidgetTester tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: CustomScrollView(
            controller: controller,
            slivers: <Widget>[
              const SliverPersistentHeader(
                delegate: _SliverPersistentHeaderDelegate(),
                pinned: true,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100.0)), // Spacer
              SliverClipRect(
                sliver: SliverToBoxAdapter(
                  child: Container(height: 100.0, color: const Color(0xFF2196F3)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      final RenderSliverClipRect renderSliver = tester.renderObject(find.byType(SliverClipRect));

      // Initial state: no overlap
      // Header 0..100, Spacer 100..200, ClipRect 200..300.
      expect(renderSliver.constraints.overlap, 0.0);
      expect(renderSliver.getClip()!.top, 0.0);

      // Scroll by 150.
      // Spacer is scrolled off. ClipRect starts at y=50.
      // Since Header is pinned at 0..100, it overlaps ClipRect by 50px.
      controller.jumpTo(150.0);
      await tester.pump();

      expect(renderSliver.constraints.overlap, 50.0);
      // This should fail if the bug exists because the ClipRect is still fully visible (paintExtent=100),
      // so its geometry didn't change, and _clip was not nulled.
      expect(renderSliver.getClip()!.top, 50.0);
    });

    testWidgets('changing clipBehavior or clipOverlap invalidates the cached clip', (
      WidgetTester tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: CustomScrollView(
            controller: controller,
            slivers: <Widget>[
              const SliverPersistentHeader(
                delegate: _SliverPersistentHeaderDelegate(),
                pinned: true,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100.0)), // Spacer
              SliverClipRect(
                sliver: SliverToBoxAdapter(
                  child: Container(height: 100.0, color: const Color(0xFF2196F3)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      final RenderSliverClipRect renderSliver = tester.renderObject(find.byType(SliverClipRect));

      // Scroll to create overlap so clipOverlap takes effect.
      controller.jumpTo(150.0);
      await tester.pump();

      expect(renderSliver.constraints.overlap, 50.0);
      expect(renderSliver.clipOverlap, ClipOverlapBehavior.followEdge);
      expect(renderSliver.clipBehavior, Clip.antiAlias);

      // getClip() should be cached and have top = 50.0.
      Rect clip = renderSliver.getClip()!;
      expect(clip.top, 50.0);

      // Mutate clipOverlap -> should call _markNeedsClip() and invalidate cache.
      renderSliver.clipOverlap = .none;
      clip = renderSliver.getClip()!;
      expect(clip.top, 0.0); // should not be truncated by overlap anymore

      // Mutate clipBehavior to Clip.none -> getClip() should return null.
      renderSliver.clipBehavior = .none;
      expect(renderSliver.getClip(), isNull);

      // Mutate clipBehavior back to non-none and check that clip is rebuilt.
      renderSliver.clipBehavior = .hardEdge;
      clip = renderSliver.getClip()!;
      expect(clip.top, 0.0);
    });

    testWidgets('custom clipper boundaries are not incorrectly expanded during overlap', (
      WidgetTester tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: CustomScrollView(
            controller: controller,
            slivers: <Widget>[
              const SliverPersistentHeader(
                delegate: _SliverPersistentHeaderDelegate(),
                pinned: true,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 50.0)), // Spacer
              SliverClipRect(
                clipper: const _CustomClipper30(),
                sliver: SliverToBoxAdapter(
                  child: Container(height: 200.0, color: const Color(0xFF2196F3)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      final RenderSliverClipRect renderSliver = tester.renderObject(find.byType(SliverClipRect));

      // Spacer is 50px. ClipRect starts at y=50.
      // Scroll by 60.0 -> ClipRect layoutOffset is 150 - 60 = 90.0.
      // Header covers 0..100. So overlap is 10.0.
      controller.jumpTo(60.0);
      await tester.pump();

      expect(renderSliver.constraints.overlap, 10.0);
      // Top inset from custom clipper is 30.0. Since overlap (10.0) is less than 30.0,
      // the clip top should still be 30.0 (and not 10.0 which would expand the clip boundary).
      expect(renderSliver.getClip()!.top, 30.0);

      // Now scroll more to create an overlap of 50px (jumpTo 100.0):
      // ClipRect layoutOffset is 150 - 100 = 50.0.
      // Header covers 0..100. So overlap is 50.0.
      // Since 50.0 > 30.0, the top of the clip should be 50.0.
      controller.jumpTo(100.0);
      await tester.pump();

      expect(renderSliver.constraints.overlap, 50.0);
      expect(renderSliver.getClip()!.top, 50.0);
    });

    // ---- Overlap hit testing: (clipOverlap × axis × reverse) matrix ----

    group('overlap hit testing', () {
      final overlapTestCases =
          <
            ({
              String name,
              ClipOverlapBehavior clipOverlap,
              Axis axis,
              bool reverse,
              bool expectHitInOverlap,
            })
          >[
            (
              name: 'followEdge blocks overlap hits (vertical)',
              clipOverlap: .followEdge,
              axis: .vertical,
              reverse: false,
              expectHitInOverlap: false,
            ),
            (
              name: 'none allows overlap hits (vertical)',
              clipOverlap: .none,
              axis: .vertical,
              reverse: false,
              expectHitInOverlap: true,
            ),
            (
              name: 'preserveShape blocks overlap hits (vertical)',
              clipOverlap: .preserveShape,
              axis: .vertical,
              reverse: false,
              expectHitInOverlap: false,
            ),
            (
              name: 'followEdge blocks overlap hits (horizontal)',
              clipOverlap: .followEdge,
              axis: .horizontal,
              reverse: false,
              expectHitInOverlap: false,
            ),
            (
              name: 'none allows overlap hits (horizontal)',
              clipOverlap: .none,
              axis: .horizontal,
              reverse: false,
              expectHitInOverlap: true,
            ),
            (
              name: 'none allows overlap hits (vertical reverse)',
              clipOverlap: .none,
              axis: .vertical,
              reverse: true,
              expectHitInOverlap: true,
            ),
            (
              name: 'followEdge blocks overlap hits (horizontal reverse)',
              clipOverlap: .followEdge,
              axis: .horizontal,
              reverse: true,
              expectHitInOverlap: false,
            ),
          ];

      for (final testCase in overlapTestCases) {
        testWidgets(testCase.name, (WidgetTester tester) async {
          final controller = ScrollController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            _buildOverlapScenario(
              controller: controller,
              clipOverlap: testCase.clipOverlap,
              scrollDirection: testCase.axis,
              reverse: testCase.reverse,
            ),
          );

          controller.jumpTo(50.0);
          await tester.pump();

          final RenderSliverClipRect renderSliver = tester.renderObject(
            find.byType(SliverClipRect),
          );
          expect(renderSliver.constraints.overlap, 50.0);

          final crossAxis = testCase.axis == .horizontal ? 50.0 : 100.0;

          expect(
            renderSliver.hitTest(
              SliverHitTestResult(),
              mainAxisPosition: 25.0,
              crossAxisPosition: crossAxis,
            ),
            testCase.expectHitInOverlap ? isTrue : isFalse,
          );

          if (!testCase.expectHitInOverlap) {
            expect(
              renderSliver.hitTest(
                SliverHitTestResult(),
                mainAxisPosition: 75.0,
                crossAxisPosition: crossAxis,
              ),
              isTrue,
              reason: 'Should hit in visible area',
            );
          }
        });
      }
    });

    testWidgets('clipBehavior of Clip.none allows overlap hits', (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildOverlapScenario(controller: controller, clipBehavior: .none));

      controller.jumpTo(50.0);
      await tester.pump();

      final RenderSliverClipRect renderSliver = tester.renderObject(find.byType(SliverClipRect));
      expect(renderSliver.constraints.overlap, 50.0);

      expect(
        renderSliver.hitTest(
          SliverHitTestResult(),
          mainAxisPosition: 25.0,
          crossAxisPosition: 100.0,
        ),
        isTrue,
        reason: 'Should hit in overlap area because clipBehavior is Clip.none',
      );
    });

    // ---- Custom clipper with axis/reverse ----

    group('custom clipper hit testing', () {
      testWidgets('respects half-width clipper with horizontal axis', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestWidgetsApp(
            home: CustomScrollView(
              scrollDirection: .horizontal,
              slivers: <Widget>[
                SliverClipRect(
                  clipper: const _HalfWidthClipper(),
                  sliver: SliverToBoxAdapter(
                    child: Container(width: 100.0, height: 100.0, color: const Color(0xFFF44336)),
                  ),
                ),
              ],
            ),
          ),
        );

        final RenderSliver renderSliver = tester.renderObject(find.byType(SliverClipRect));
        expect(
          renderSliver.hitTest(
            SliverHitTestResult(),
            mainAxisPosition: 25.0,
            crossAxisPosition: 50.0,
          ),
          isTrue,
          reason: 'Should hit inside the clipped area',
        );
        expect(
          renderSliver.hitTest(
            SliverHitTestResult(),
            mainAxisPosition: 75.0,
            crossAxisPosition: 50.0,
          ),
          isFalse,
          reason: 'Should NOT hit outside the clipped area',
        );
      });

      testWidgets('respects half-height clipper with reverse axis', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestWidgetsApp(
            home: CustomScrollView(
              reverse: true,
              slivers: <Widget>[
                SliverClipRect(
                  clipper: const _HalfHeightClipper(),
                  sliver: SliverToBoxAdapter(
                    child: Container(height: 100.0, color: const Color(0xFFF44336)),
                  ),
                ),
              ],
            ),
          ),
        );

        final RenderSliver renderSliver = tester.renderObject(find.byType(SliverClipRect));
        expect(
          renderSliver.hitTest(
            SliverHitTestResult(),
            mainAxisPosition: 75.0,
            crossAxisPosition: 400.0,
          ),
          isTrue,
          reason: 'Should hit inside the clipped area',
        );
        expect(
          renderSliver.hitTest(
            SliverHitTestResult(),
            mainAxisPosition: 25.0,
            crossAxisPosition: 400.0,
          ),
          isFalse,
          reason: 'Should NOT hit outside the clipped area',
        );
      });
    });

    testWidgets('clears layer when clipBehavior is updated to Clip.none', (
      WidgetTester tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildOverlapScenario(controller: controller));
      await tester.pumpWidget(_buildOverlapScenario(controller: controller, clipBehavior: .none));

      final RenderSliverClipRect renderSliver = tester.renderObject(find.byType(SliverClipRect));

      expect(renderSliver.debugLayer, isNull);
    });

    testWidgets('leading clip stays pinned until insideClipExtent is scrolled', (
      WidgetTester tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        TestWidgetsApp(
          home: CustomScrollView(
            controller: controller,
            slivers: <Widget>[
              SliverClipRect(
                clipper: const _CustomClipper30(),
                sliver: SliverToBoxAdapter(
                  child: Container(height: 400.0, color: const Color(0xFF2196F3)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      final RenderSliverClipRect renderSliver = tester.renderObject(find.byType(SliverClipRect));

      // The clipper insets the top by 30px, so at scrollOffset 0 the clip starts
      // at y=30. The extent that can slide under the leading edge before it
      // moves is 400 - 30 = 370 (insideClipExtent).
      expect(renderSliver.constraints.scrollOffset, 0.0);
      expect(renderSliver.getClip()!.top, 30.0);

      // While insideClipExtent (370px) has not been fully consumed by the
      // scroll, the leading edge stays pinned at the viewport's leading edge (0)
      // rather than drifting up with the content.
      controller.jumpTo(100.0);
      await tester.pump();

      expect(renderSliver.constraints.scrollOffset, 100.0);
      expect(
        renderSliver.getClip()!.top,
        0.0,
        reason: 'Leading clip should stay pinned while insideClipExtent is not consumed',
      );

      // Once the scroll exceeds insideClipExtent (370px), the leading edge is
      // released and follows the content upwards: top becomes 370 - 385 = -15.
      controller.jumpTo(385.0);
      await tester.pump();

      expect(renderSliver.constraints.scrollOffset, 385.0);
      expect(
        renderSliver.getClip()!.top,
        -15.0,
        reason: 'Leading clip should follow the content once insideClipExtent is consumed',
      );
    });
  });
}

class _HalfHeightClipper extends CustomClipper<Rect> {
  const _HalfHeightClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0.0, 0.0, size.width, size.height / 2.0);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

class _HalfWidthClipper extends CustomClipper<Rect> {
  const _HalfWidthClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0.0, 0.0, size.width / 2.0, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

class _SliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SliverPersistentHeaderDelegate();
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: maxExtent, width: maxExtent, child: const Text('Header'));

  @override
  double get maxExtent => 100.0;

  @override
  double get minExtent => 100.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _CustomClipper30 extends CustomClipper<Rect> {
  const _CustomClipper30();
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0.0, 30.0, size.width, size.height);
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
