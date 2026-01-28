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
          builder: (_, _) => CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                sliver: const SliverToBoxAdapter(child: Text('Hello World')),
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
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                sliver: const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                clipOverlap: false,
                clipBehavior: Clip.hardEdge,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                sliver: const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
