// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SliverClipRect', () {
    testWidgets('renders its child correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          builder: (_, _) => const CustomScrollView(
            slivers: <Widget>[
              SliverClipRect(sliver: SliverToBoxAdapter(child: Text('Hello World'))),
            ],
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('applies custom clipper regarding HitTest', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          builder: (_, _) => CustomScrollView(
            slivers: <Widget>[
              SliverClipRect(
                clipper: const _HalfHeightClipper(),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    height: 100,
                    color: const Color(0xFFF44336),
                    key: const Key('target'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tapAt(const Offset(400, 25));
      await tester.pump();

      final RenderSliver renderSliver = tester.renderObject(find.byType(SliverClipRect));
      final resultSuccess = SliverHitTestResult();
      final bool hitTop = renderSliver.hitTest(
        resultSuccess,
        mainAxisPosition: 25,
        crossAxisPosition: 400,
      );
      expect(hitTop, isTrue, reason: 'Should hit inside the clipped area');

      final resultFail = SliverHitTestResult();
      final bool hitBottom = renderSliver.hitTest(
        resultFail,
        mainAxisPosition: 75, // > 50 (height / 2)
        crossAxisPosition: 400,
      );
      expect(hitBottom, isFalse, reason: 'Should NOT hit outside the clipped area');
    });

    testWidgets('clips overlap correctly when passing under a Pinned Sliver', (
      WidgetTester tester,
    ) async {
      // Scenario:
      // - SliverAppBar: Pinned, Height 100.
      // - SliverClipRect containing a generic Item (Height 100).
      // - We scroll UP by 50 pixels.
      // - Result: The item is effectively at position -50.
      // - But because of the Pinned header, the first 50 pixels of the viewport are the Header.
      // - The Item starts "visually" at 0 (relative to the sliver), but 50px are hidden by overlap.

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          builder: (_, _) => CustomScrollView(
            slivers: <Widget>[
              const _TestPersistentHeader(),
              SliverClipRect(
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

      final RenderSliverClipRect renderSliver = tester.renderObject(find.byType(SliverClipRect));

      // Verify constraints
      // The scroll offset is 50. The header is 100.
      // The "layout" position of this sliver starts at the top of the scroll view?
      // Actually, in Slivers, mainAxisPosition is relative to the sliver itself.
      // The overlap constraint should be 50 (amount of header covering this sliver).
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
              SliverClipRect(
                clipOverlap: false, // DISABLE OVERLAP CLIPPING
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

      final RenderSliverClipRect renderSliver = tester.renderObject(find.byType(SliverClipRect));

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
      // Verify that changing properties updates the render object
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverClipRect(sliver: SliverToBoxAdapter(child: SizedBox(height: 100))),
            ],
          ),
        ),
      );

      final RenderSliverClipRect renderObject = tester.renderObject(find.byType(SliverClipRect));
      expect(renderObject.clipOverlap, isTrue);
      expect(renderObject.clipBehavior, Clip.hardEdge);

      // Update widget
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverClipRect(
                clipOverlap: false,
                clipBehavior: Clip.antiAlias,
                sliver: SliverToBoxAdapter(child: SizedBox(height: 100)),
              ),
            ],
          ),
        ),
      );

      expect(renderObject.clipOverlap, isFalse);
      expect(renderObject.clipBehavior, Clip.antiAlias);
    });

    testWidgets('works correctly with horizontal axis', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          builder: (_, _) => CustomScrollView(
            scrollDirection: Axis.horizontal,
            slivers: <Widget>[
              SliverClipRect(
                clipper: const _HalfWidthClipper(),
                sliver: SliverToBoxAdapter(
                  child: Container(width: 100, height: 100, color: const Color(0xFFF44336)),
                ),
              ),
            ],
          ),
        ),
      );

      final RenderSliver renderSliver = tester.renderObject(find.byType(SliverClipRect));

      // Hit test inside the clipped area (left half)
      final resultSuccess = SliverHitTestResult();
      final bool hitLeft = renderSliver.hitTest(
        resultSuccess,
        mainAxisPosition: 25, // < 50
        crossAxisPosition: 50,
      );
      expect(hitLeft, isTrue, reason: 'Should hit inside the clipped area');

      // Hit test outside the clipped area (right half)
      final resultFail = SliverHitTestResult();
      final bool hitRight = renderSliver.hitTest(
        resultFail,
        mainAxisPosition: 75, // > 50
        crossAxisPosition: 50,
      );
      expect(hitRight, isFalse, reason: 'Should NOT hit outside the clipped area');
    });

    testWidgets('works correctly with reverse axis', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          builder: (_, _) => CustomScrollView(
            reverse: true,
            slivers: <Widget>[
              SliverClipRect(
                clipper: const _HalfHeightClipper(),
                sliver: SliverToBoxAdapter(
                  child: Container(height: 100, color: const Color(0xFFF44336)),
                ),
              ),
            ],
          ),
        ),
      );

      final RenderSliver renderSliver = tester.renderObject(find.byType(SliverClipRect));

      // Hit test inside the clipped area (top half in local coords)
      final resultSuccess = SliverHitTestResult();
      final bool hitTop = renderSliver.hitTest(
        resultSuccess,
        mainAxisPosition: 75, // >= 50 (clip is not reversed)
        crossAxisPosition: 400,
      );
      expect(hitTop, isTrue, reason: 'Should hit inside the clipped area');

      // Hit test outside the clipped area (bottom half in local coords)
      final resultFail = SliverHitTestResult();
      final bool hitBottom = renderSliver.hitTest(
        resultFail,
        mainAxisPosition: 25, // < 50
        crossAxisPosition: 400,
      );
      expect(hitBottom, isFalse, reason: 'Should NOT hit outside the clipped area');
    });
  });
}

class _HalfHeightClipper extends CustomClipper<Rect> {
  const _HalfHeightClipper();

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height / 2);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

class _HalfWidthClipper extends CustomClipper<Rect> {
  const _HalfWidthClipper();

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
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
