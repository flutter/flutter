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
  bool clipOverlap = true,
  CustomClipper<Rect>? clipper,
  Axis scrollDirection = Axis.vertical,
  bool reverse = false,
  double childExtent = 100,
}) {
  final isHorizontal = scrollDirection == Axis.horizontal;
  
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
          sliver: SliverToBoxAdapter(
            child: Container(
              height: isHorizontal ? 100 : childExtent,
              width: isHorizontal ? childExtent : null,
              color: const Color(0xFF2196F3),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: isHorizontal ? null : 1000, width: isHorizontal ? 1000 : null),
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
                  child: Container(height: 100, color: const Color(0xFFF44336)),
                ),
              ),
            ],
          ),
        ),
      );

      final RenderSliver renderSliver = tester.renderObject(find.byType(SliverClipRect));

      expect(
        renderSliver.hitTest(SliverHitTestResult(), mainAxisPosition: 25, crossAxisPosition: 400),
        isTrue,
        reason: 'Should hit inside the clipped area',
      );
      expect(
        renderSliver.hitTest(SliverHitTestResult(), mainAxisPosition: 75, crossAxisPosition: 400),
        isFalse,
        reason: 'Should NOT hit outside the clipped area',
      );
    });

    testWidgets('updates properties', (WidgetTester tester) async {
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
      expect(renderObject.clipOverlap, ClipOverlapBehavior.followEdge);
      expect(renderObject.clipBehavior, Clip.hardEdge);

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

      expect(renderObject.clipOverlap, ClipOverlapBehavior.none);
      expect(renderObject.clipBehavior, Clip.antiAlias);
    });

    // ---- Overlap hit testing: (clipOverlap × axis × reverse) matrix ----

    group('overlap hit testing', () {
      final overlapTestCases =
          <({String name, bool clipOverlap, Axis axis, bool reverse, bool expectHitInOverlap})>[
            (
              name: 'clipOverlap blocks overlap hits (vertical)',
              clipOverlap: true,
              axis: Axis.vertical,
              reverse: false,
              expectHitInOverlap: false,
            ),
            (
              name: 'clipOverlap disabled allows overlap hits (vertical)',
              clipOverlap: false,
              axis: Axis.vertical,
              reverse: false,
              expectHitInOverlap: true,
            ),
            (
              name: 'clipOverlap blocks overlap hits (horizontal)',
              clipOverlap: true,
              axis: Axis.horizontal,
              reverse: false,
              expectHitInOverlap: false,
            ),
            (
              name: 'clipOverlap disabled allows overlap hits (horizontal)',
              clipOverlap: false,
              axis: Axis.horizontal,
              reverse: false,
              expectHitInOverlap: true,
            ),
            (
              name: 'clipOverlap disabled allows overlap hits (vertical reverse)',
              clipOverlap: false,
              axis: Axis.vertical,
              reverse: true,
              expectHitInOverlap: true,
            ),
            (
              name: 'clipOverlap blocks overlap hits (horizontal reverse)',
              clipOverlap: true,
              axis: Axis.horizontal,
              reverse: true,
              expectHitInOverlap: false,
            ),
          ];

      for (final testCase in overlapTestCases) {
        testWidgets(testCase.name, (WidgetTester tester) async {
          final controller = ScrollController();
          await tester.pumpWidget(
            _buildOverlapScenario(
              controller: controller,
              clipOverlap: testCase.clipOverlap,
              scrollDirection: testCase.axis,
              reverse: testCase.reverse,
            ),
          );

          controller.jumpTo(50);
          await tester.pump();

          final RenderSliverClipRect renderSliver = tester.renderObject(
            find.byType(SliverClipRect),
          );
          expect(renderSliver.constraints.overlap, 50.0);

          final crossAxis = testCase.axis == Axis.horizontal ? 50.0 : 100.0;

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

    // ---- Custom clipper with axis/reverse ----

    group('custom clipper hit testing', () {
      testWidgets('respects half-width clipper with horizontal axis', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestWidgetsApp(
            home: CustomScrollView(
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
        expect(
          renderSliver.hitTest(SliverHitTestResult(), mainAxisPosition: 25, crossAxisPosition: 50),
          isTrue,
          reason: 'Should hit inside the clipped area',
        );
        expect(
          renderSliver.hitTest(SliverHitTestResult(), mainAxisPosition: 75, crossAxisPosition: 50),
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
                    child: Container(height: 100, color: const Color(0xFFF44336)),
                  ),
                ),
              ],
            ),
          ),
        );

        final RenderSliver renderSliver = tester.renderObject(find.byType(SliverClipRect));
        expect(
          renderSliver.hitTest(SliverHitTestResult(), mainAxisPosition: 75, crossAxisPosition: 400),
          isTrue,
          reason: 'Should hit inside the clipped area',
        );
        expect(
          renderSliver.hitTest(SliverHitTestResult(), mainAxisPosition: 25, crossAxisPosition: 400),
          isFalse,
          reason: 'Should NOT hit outside the clipped area',
        );
      });
    });
  });
}

class _HalfHeightClipper extends CustomClipper<Rect> {
  const _HalfHeightClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, size.height / 2);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

class _HalfWidthClipper extends CustomClipper<Rect> {
  const _HalfWidthClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

class _SliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SliverPersistentHeaderDelegate();
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: maxExtent, width: maxExtent, child: const Text('Header'));

  @override
  double get maxExtent => 100;

  @override
  double get minExtent => 100;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
