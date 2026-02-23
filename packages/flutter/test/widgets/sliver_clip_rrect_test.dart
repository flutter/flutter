// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SliverClipRRect', () {
    testWidgets('renders its child correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          builder: (_, _) => const CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                sliver: SliverToBoxAdapter(child: Text('Hello World')),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('applies border radius regarding HitTest', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          builder: (_, _) => CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                sliver: SliverToBoxAdapter(
                  child: Container(height: 100, color: const Color(0xFFF44336)),
                ),
              ),
            ],
          ),
        ),
      );

      final RenderSliver renderSliver = tester.renderObject(find.byType(SliverClipRRect));

      // Center should be hit
      final resultCenter = SliverHitTestResult();
      final bool hitCenter = renderSliver.hitTest(
        resultCenter,
        mainAxisPosition: 50,
        crossAxisPosition: 400, // Assuming 800 width
      );
      expect(hitCenter, isTrue, reason: 'Should hit center');

      // Top-left corner (0,0) should NOT be hit because of radius 20
      final resultCorner = SliverHitTestResult();
      final bool hitCorner = renderSliver.hitTest(
        resultCorner,
        mainAxisPosition: 0,
        crossAxisPosition: 0,
      );
      expect(hitCorner, isFalse, reason: 'Should NOT hit rounded corner');

      // A bit inside from top-left (25, 25) should be hit
      final resultInside = SliverHitTestResult();
      final bool hitInside = renderSliver.hitTest(
        resultInside,
        mainAxisPosition: 25,
        crossAxisPosition: 25,
      );
      expect(hitInside, isTrue, reason: 'Should hit inside rounded corner');
    });

    testWidgets('clips overlap correctly when passing under a Pinned Sliver', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          builder: (_, _) => CustomScrollView(
            slivers: <Widget>[
              const _TestPersistentHeader(),
              SliverClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    height: 100,
                    color: const Color(0xFF2196F3),
                    child: const Center(child: Text('Item')),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000)),
            ],
          ),
        ),
      );

      // Scroll up by 50 pixels
      final ScrollableState scrollable = tester.state(find.byType(Scrollable));
      scrollable.position.jumpTo(50.0);
      await tester.pump();

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));

      expect(renderSliver.constraints.overlap, equals(50.0));

      // 1. Hit test in the overlapped area (e.g., 25px from the top of the sliver).
      // This is physically under the SliverAppBar.
      final overlapHit = SliverHitTestResult();
      final bool hitInOverlap = renderSliver.hitTest(
        overlapHit,
        mainAxisPosition: 25.0,
        crossAxisPosition: 100.0,
      );

      expect(
        hitInOverlap,
        isFalse,
        reason: 'Should NOT hit in the overlapped (hidden) area when clipOverlap is true',
      );

      // 2. Hit test in the visible area (e.g., 75px from the top of the sliver).
      final visibleHit = SliverHitTestResult();
      final bool hitInVisible = renderSliver.hitTest(
        visibleHit,
        mainAxisPosition: 75.0,
        crossAxisPosition: 100.0,
      );

      expect(hitInVisible, isTrue, reason: 'Should hit in the visible area');
    });

    testWidgets('allows hits in overlap area if clipOverlap is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          builder: (_, _) => CustomScrollView(
            slivers: <Widget>[
              const _TestPersistentHeader(),
              SliverClipRRect(
                clipOverlap: false, // DISABLE OVERLAP CLIPPING
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                sliver: SliverToBoxAdapter(
                  child: Container(height: 100, color: const Color(0xFF2196F3)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000)),
            ],
          ),
        ),
      );

      // Scroll up by 50 pixels
      final ScrollableState scrollable = tester.state(find.byType(Scrollable));
      scrollable.position.jumpTo(50.0);
      await tester.pump();

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));

      expect(renderSliver.constraints.overlap, equals(50.0));

      // Hit test in the overlapped area.
      final overlapHit = SliverHitTestResult();
      final bool hitInOverlap = renderSliver.hitTest(
        overlapHit,
        mainAxisPosition: 25.0,
        crossAxisPosition: 100.0,
      );

      expect(
        hitInOverlap,
        isTrue,
        reason: 'Should hit in the overlapped area if clipping is disabled',
      );
    });

    testWidgets('updates properties correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                sliver: SliverToBoxAdapter(child: SizedBox(height: 100)),
              ),
            ],
          ),
        ),
      );

      final RenderSliverClipRRect renderObject = tester.renderObject(find.byType(SliverClipRRect));
      expect(renderObject.clipOverlap, isTrue);
      expect(renderObject.clipBehavior, Clip.antiAlias);
      expect(renderObject.borderRadius, const BorderRadius.all(Radius.circular(10)));

      // Update widget
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                clipOverlap: false,
                clipBehavior: Clip.hardEdge,
                borderRadius: BorderRadius.all(Radius.circular(20)),
                sliver: SliverToBoxAdapter(child: SizedBox(height: 100)),
              ),
            ],
          ),
        ),
      );

      expect(renderObject.clipOverlap, isFalse);
      expect(renderObject.clipBehavior, Clip.hardEdge);
      expect(renderObject.borderRadius, const BorderRadius.all(Radius.circular(20)));
    });
  });

  testWidgets('SliverClipRRect should have a straight cut at overlap, not rounded', (
    WidgetTester tester,
  ) async {
    final controller = ScrollController();

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xffffffff),
        onGenerateRoute: (settings) => PageRouteBuilder(
          pageBuilder: (_, _, _) => CustomScrollView(
            controller: controller,
            slivers: <Widget>[
              const SliverPersistentHeader(
                delegate: _SliverPersistentHeaderDelegate(),
                pinned: true,
              ),
              SliverClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(50)),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    color: const Color(0xFF2196F3),
                    key: const Key('sliver_child'),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000)),
            ],
          ),
        ),
      ),
    );

    // Scroll so that the SliverClipRRect is partially under the pinned header.
    // Header is 100px. Scroll by 50px.
    // The SliverClipRRect now starts at viewport 50.
    // It is overlapped by the header from viewport 50 to 100 (50px of overlap).
    controller.jumpTo(50);
    await tester.pump();

    final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));
    expect(renderSliver.constraints.overlap, equals(50.0));

    // The SliverClipRRect is at viewport 50. Local y=0 is at viewport 50.
    // Overlap is 50px, so local y=0 to y=50 are overlapped.
    // The cut should be at local y=50.
    // If the cut is STRAIGHT, then local (1, 51) should be INSIDE the clip.
    // If the cut is ROUNDED (radius 50), then local (1, 51) is in the corner and should be OUTSIDE.

    // Note: mainAxisPosition is relative to the start of the sliver.
    // crossAxisPosition is relative to the left edge (in LTR).

    final result = SliverHitTestResult();
    final bool hit = renderSliver.hitTest(
      result,
      mainAxisPosition: 51.0, // Just below the overlap cut
      crossAxisPosition: 1.0, // Near the left edge
    );

    // If hit is false, it means it was clipped.
    // We WANT hit to be true for a straight cut.
    expect(
      hit,
      isTrue,
      reason: 'Overlap cut should be straight, but it seems to be rounded (clipped the corner).',
    );
  });

  testWidgets('RenderSliverClipRRect.buildClip should use total height, not middleRect.height', (
    WidgetTester tester,
  ) async {
    // This test verifies Issue 2: usage of middleRect.height in buildClip.
    // If it uses middleRect.height, the clipOrigin calculation will be wrong when scrollOffset is large.
    final controller = ScrollController();

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xffffffff),
        onGenerateRoute: (settings) => PageRouteBuilder(
          pageBuilder: (_, _, _) => CustomScrollView(
            controller: controller,
            slivers: <Widget>[
              const SliverPersistentHeader(
                delegate: _SliverPersistentHeaderDelegate(),
                pinned: true,
              ),
              SliverClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(40)),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    height: 100, // Total height 100. middleRect.height is 100 - 40 - 40 = 20.
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000)),
            ],
          ),
        ),
      ),
    );

    // Sliver is 100px tall. borderRadius 40. middleRect height is 20.
    // Header 100px.
    // If we scroll 90px.
    // Sliver starts at -90. Header covers 0 to 100.
    // Sliver is under header from viewport 0 to 10 (local 90 to 100).
    // Actually, local 0 to 90 are off-screen.
    // Local 90 to 100 are under header.
    // We should clip local 0 to 100? (Wait, I need to check my manual math again).

    // Let's just check if it's clipped when it SHOULD be.
    // If scrollOffset = 50. Overlap = 100.
    // Correct clipOrigin should be 100 (if we clip everything under header).
    // Formula: overlap (100) - max(scrollOffset (50) + overlap (100) - clipExtent, 0).
    // If clipExtent is 100: clipOrigin = 100 - max(50, 0) = 50.
    // Wait, if scrollOffset is 50 and overlap is 100.
    // Sliver local 0 to 50 are off-screen.
    // Local 50 is at viewport 0.
    // Header covers viewport 0 to 100.
    // So local 50 to 150 are under header? (But sliver only goes to 100).
    // So local 50 to 100 are under header.
    // We should clip up to local 100.
    // Formula gave 50. Why?
    // If clipOrigin is 50, we clip local 0 to 50.
    // But local 0 to 50 are off-screen anyway!
    // So we clip NOTHING that is on-screen.
    // So the entire sliver (from viewport 0 to 50) is visible UNDER the header.
    // THIS IS WRONG. The formula itself seems suspect, OR I misunderstand 'overlap'.

    // Regardless, if clipExtent is 20 (middleRect.height) instead of 100:
    // clipOrigin = 100 - max(50 + 100 - 20, 0) = 100 - 130 = -30 -> clamped? No, formula doesn't clamp yet.
    // If it's -30, it definitely clips less than 50.
    // So it's even worse.

    // Let's see what happens with current implementation.
    controller.jumpTo(50);
    await tester.pump();

    final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));
    // If middleRect.height was used, clipExtent is 20.
    // clipOrigin = 100 - max(50+100-20, 0) = -30.
    // AxisDirection.down => newClip.copyWith(top: -30).
    // Original top was 0. New top is -30. So it clips LESS.

    // Let's test hit at local 25. Viewport position: 50 - 25 = -25? No.
    // Local 0 is at viewport -50.
    // Local 25 is at viewport -25.
    // Local 50 is at viewport 0.
    // Local 75 is at viewport 25.
    // Viewport 0 to 100 is covered by header.
    // So local 50 to 100 are covered by header.
    // We should NOT be able to hit at local 75.
    final result = SliverHitTestResult();
    final bool hit = renderSliver.hitTest(result, mainAxisPosition: 75.0, crossAxisPosition: 400.0);

    expect(
      hit,
      isFalse,
      reason:
          'Should NOT hit at local 75 because it is under the 100px header (sliver starts at -50)',
    );
  });
}

class _TestPersistentHeader extends StatelessWidget {
  const _TestPersistentHeader();

  @override
  Widget build(BuildContext context) =>
      const SliverPersistentHeader(delegate: _SliverPersistentHeaderDelegate(), pinned: true);
}

class _SliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SliverPersistentHeaderDelegate();
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: maxExtent, child: const Text('Header'));

  @override
  double get maxExtent => 100;

  @override
  double get minExtent => 100;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
