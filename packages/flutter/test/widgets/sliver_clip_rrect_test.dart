// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [CustomScrollView] with a pinned 100px header followed by a
/// [SliverClipRRect] and filler content. Suitable for all overlap-clipping tests.
Widget _buildOverlapScenario({
  required ScrollController controller,
  ClipOverlapBehavior clipOverlap = .followEdge,
  double borderRadius = 20.0,
  Axis scrollDirection = .vertical,
  bool reverse = false,
  double childExtent = 100.0,
  Clip clipBehavior = .antiAlias,
}) {
  final isHorizontal = scrollDirection == .horizontal;

  return TestWidgetsApp(
    home: CustomScrollView(
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      slivers: <Widget>[
        const SliverPersistentHeader(delegate: _SliverPersistentHeaderDelegate(), pinned: true),
        SliverClipRRect(
          clipOverlap: clipOverlap,
          borderRadius: .all(Radius.circular(borderRadius)),
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
  group('SliverClipRRect', () {
    testWidgets('renders its child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                borderRadius: .all(Radius.circular(10.0)),
                sliver: SliverToBoxAdapter(child: Text('Hello World')),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('hit test respects border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                borderRadius: const .all(Radius.circular(20.0)),
                sliver: SliverToBoxAdapter(
                  child: Container(height: 100.0, color: const Color(0xFFF44336)),
                ),
              ),
            ],
          ),
        ),
      );

      final RenderSliver renderSliver = tester.renderObject(find.byType(SliverClipRRect));

      expect(
        renderSliver.hitTest(
          SliverHitTestResult(),
          mainAxisPosition: 50.0,
          crossAxisPosition: 400.0,
        ),
        isTrue,
        reason: 'Should hit center',
      );
      expect(
        renderSliver.hitTest(SliverHitTestResult(), mainAxisPosition: 0.0, crossAxisPosition: 0.0),
        isFalse,
        reason: 'Should NOT hit rounded corner',
      );
      expect(
        renderSliver.hitTest(
          SliverHitTestResult(),
          mainAxisPosition: 25.0,
          crossAxisPosition: 25.0,
        ),
        isTrue,
        reason: 'Should hit inside rounded corner',
      );
    });

    testWidgets('updates properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                borderRadius: .all(Radius.circular(10.0)),
                sliver: SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
            ],
          ),
        ),
      );

      final RenderSliverClipRRect renderObject = tester.renderObject(find.byType(SliverClipRRect));
      expect(renderObject.clipOverlap, ClipOverlapBehavior.followEdge);
      expect(renderObject.clipBehavior, Clip.antiAlias);
      expect(renderObject.borderRadius, const BorderRadius.all(Radius.circular(10.0)));

      await tester.pumpWidget(
        const TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                clipOverlap: .none,
                clipBehavior: .hardEdge,
                borderRadius: .all(Radius.circular(20.0)),
                sliver: SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
            ],
          ),
        ),
      );

      expect(renderObject.clipOverlap, ClipOverlapBehavior.none);
      expect(renderObject.clipBehavior, Clip.hardEdge);
      expect(renderObject.borderRadius, const BorderRadius.all(Radius.circular(20.0)));
    });

    testWidgets('changing borderRadius or textDirection invalidates the cached clip', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const TestWidgetsApp(
          home: CustomScrollView(
            slivers: <Widget>[
              SliverClipRRect(
                borderRadius: BorderRadiusDirectional.only(topStart: .circular(10.0)),
                sliver: SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
            ],
          ),
        ),
      );

      final RenderSliverClipRRect renderObject = tester.renderObject(find.byType(SliverClipRRect));

      // LTR: topStart is topLeft.
      RRect clip = renderObject.getClip()!;
      expect(clip.tlRadius, const Radius.circular(10.0));
      expect(clip.trRadius, Radius.zero);

      // Change borderRadius and check if getClip() returns the updated clip geometry.
      renderObject.borderRadius = const BorderRadius.only(topRight: .circular(20.0));
      clip = renderObject.getClip()!;
      expect(clip.tlRadius, Radius.zero);
      expect(clip.trRadius, const Radius.circular(20.0));

      // Revert to directional border radius to test textDirection.
      renderObject.borderRadius = const BorderRadiusDirectional.only(topStart: .circular(10.0));
      clip = renderObject.getClip()!;
      expect(clip.tlRadius, const Radius.circular(10.0));
      expect(clip.trRadius, Radius.zero);

      // Change textDirection and check if getClip() returns the updated clip geometry.
      // RTL: topStart is topRight.
      renderObject.textDirection = TextDirection.rtl;
      clip = renderObject.getClip()!;
      expect(clip.tlRadius, Radius.zero);
      expect(clip.trRadius, const Radius.circular(10.0));
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
              SliverClipRRect(
                sliver: SliverToBoxAdapter(
                  child: Container(height: 100.0, color: const Color(0xFF2196F3)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));

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
      // This should fail if the bug exists because the ClipRect is still fully visible (paintExtent=100.0),
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
              SliverClipRRect(
                sliver: SliverToBoxAdapter(
                  child: Container(height: 100.0, color: const Color(0xFF2196F3)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));

      // Scroll to create overlap so clipOverlap takes effect.
      controller.jumpTo(150.0);
      await tester.pump();

      expect(renderSliver.constraints.overlap, 50.0);
      expect(renderSliver.clipOverlap, ClipOverlapBehavior.followEdge);
      expect(renderSliver.clipBehavior, Clip.antiAlias);

      // getClip() should be cached and have top = 50.0.
      RRect clip = renderSliver.getClip()!;
      expect(clip.top, 50.0);

      // Mutate clipOverlap -> should call _markNeedsClip() and invalidate cache.
      renderSliver.clipOverlap = .none;
      clip = renderSliver.getClip()!;
      expect(clip.top, 0.0); // should not be truncated by overlap anymore

      // Mutate clipBehavior to Clip.none -> getClip() should return null.
      renderSliver.clipBehavior = .none;
      expect(renderSliver.getClip(), isNull);

      // Mutate clipBehavior back to non-none and check that clip is rebuilt.
      renderSliver.clipBehavior = .antiAlias;
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
              SliverClipRRect(
                clipper: const _CustomClipperRRect30(),
                sliver: SliverToBoxAdapter(
                  child: Container(height: 200.0, color: const Color(0xFF2196F3)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));

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

          final RenderSliverClipRRect renderSliver = tester.renderObject(
            find.byType(SliverClipRRect),
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

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));
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

    // ---- followEdge-specific edge cases ----

    testWidgets('creates a straight cut at overlap', (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildOverlapScenario(
          controller: controller,
          clipOverlap: .none,
          borderRadius: 50.0,
          childExtent: 200.0,
        ),
      );

      controller.jumpTo(50.0);
      await tester.pump();

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));
      expect(renderSliver.constraints.overlap, 50.0);

      expect(
        renderSliver.hitTest(SliverHitTestResult(), mainAxisPosition: 51.0, crossAxisPosition: 1.0),
        isTrue,
        reason: 'Overlap cut should be straight, not rounded.',
      );
    });

    testWidgets('uses complete extent for hit test clipping', (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildOverlapScenario(controller: controller, borderRadius: 40.0));

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));
      expect(
        renderSliver.hitTest(
          SliverHitTestResult(),
          mainAxisPosition: 15.0,
          crossAxisPosition: 400.0,
        ),
        isTrue,
      );

      controller.jumpTo(50.0);
      await tester.pump();

      expect(
        renderSliver.hitTest(
          SliverHitTestResult(),
          mainAxisPosition: 15.0,
          crossAxisPosition: 400.0,
        ),
        isFalse,
        reason: 'Should NOT hit at local 15 because it is below the header (clip starts at 20)',
      );
    });

    testWidgets('calculates correct clip rectangle origin', (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildOverlapScenario(controller: controller, borderRadius: 40.0));

      controller.jumpTo(50.0);
      await tester.pump();

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));
      expect(renderSliver.getClip()!.top, 50.0, reason: 'clip.top should equal the overlap');
    });

    testWidgets('preserves visual content integrity at overlap cut', (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildOverlapScenario(controller: controller, borderRadius: 40.0));

      controller.jumpTo(20.0);
      await tester.pump();

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));
      expect(
        renderSliver.hitTest(SliverHitTestResult(), mainAxisPosition: 21.0, crossAxisPosition: 1.0),
        isFalse,
        reason: 'Content at (1, 21) is clipped by the rounded overlap cut.',
      );
    });

    testWidgets('handles overlap calculation with reverse scrolling', (WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildOverlapScenario(controller: controller, borderRadius: 40.0, reverse: true),
      );

      controller.jumpTo(50.0);
      await tester.pump();

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));
      expect(renderSliver.constraints.overlap, 50.0);
      expect(renderSliver.getClip()!.bottom, 50.0, reason: 'Reverse scroll clip is incorrect.');
    });

    // ---- preserveShape clip geometry ----

    group('preserveShape clip geometry', () {
      testWidgets('shifts clip origin and preserves corners (vertical)', (
        WidgetTester tester,
      ) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _buildOverlapScenario(
            controller: controller,
            clipOverlap: .preserveShape,
            borderRadius: 40.0,
          ),
        );

        controller.jumpTo(50.0);
        await tester.pump();

        final RenderSliverClipRRect renderSliver = tester.renderObject(
          find.byType(SliverClipRRect),
        );
        final RRect clip = renderSliver.getClip()!;
        final double overlap = renderSliver.constraints.overlap;

        expect(
          clip.top,
          lessThan(overlap),
          reason: 'preserveShape clip.top should be less than the overlap',
        );
        expect(
          clip.top + clip.tlRadiusY,
          greaterThan(overlap),
          reason: 'Corner arc should extend past the overlap into the visible area',
        );
      });

      testWidgets('shifts clip origin (horizontal)', (WidgetTester tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _buildOverlapScenario(
            controller: controller,
            clipOverlap: .preserveShape,
            borderRadius: 40.0,
            scrollDirection: .horizontal,
          ),
        );

        controller.jumpTo(50.0);
        await tester.pump();

        final RenderSliverClipRRect renderSliver = tester.renderObject(
          find.byType(SliverClipRRect),
        );
        expect(
          renderSliver.getClip()!.left,
          lessThan(50.0),
          reason: 'preserveShape clip.left should be less than the overlap',
        );
      });

      testWidgets('shifts clip origin (vertical reverse)', (WidgetTester tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _buildOverlapScenario(
            controller: controller,
            clipOverlap: .preserveShape,
            borderRadius: 40.0,
            reverse: true,
          ),
        );

        controller.jumpTo(50.0);
        await tester.pump();

        final RenderSliverClipRRect renderSliver = tester.renderObject(
          find.byType(SliverClipRRect),
        );

        // With followEdge in reverse, clip.bottom = 50.0.
        // preserveShape should produce a different value.
        expect(
          renderSliver.getClip()!.bottom,
          isNot(equals(50.0)),
          reason: 'preserveShape should produce a different bottom clip in reverse',
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

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));

      expect(renderSliver.debugLayer, isNull);
    });

    testWidgets(
      'preserveShape hit testing is received when pinned header is wrapped in SliverIgnorePointer',
      (WidgetTester tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        var childTapped = false;

        await tester.pumpWidget(
          TestWidgetsApp(
            home: CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                const SliverIgnorePointer(
                  sliver: SliverPersistentHeader(
                    delegate: _SliverPersistentHeaderDelegate(),
                    pinned: true,
                  ),
                ),
                SliverClipRRect(
                  clipOverlap: .preserveShape,
                  borderRadius: .circular(40.0),
                  sliver: SliverToBoxAdapter(
                    child: GestureDetector(
                      onTap: () {
                        childTapped = true;
                      },
                      child: Container(height: 100.0, color: const Color(0xFF2196F3)),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
              ],
            ),
          ),
        );

        controller.jumpTo(50.0);
        await tester.pump();

        // The header (0..100) covers the top of the SliverClipRRect (50..150),
        // creating a 50px overlap. With preserveShape, the rounded clip shifts
        // up so its corners remain visible inside the overlap band. Tapping at
        // y=90 (mainAxisPosition 40 < overlap 50) lands inside that preserved
        // shape. The hit is only received because the header is wrapped in a
        // SliverIgnorePointer, so it lets the tap fall through to the child.
        await tester.tapAt(const Offset(10.0, 90.0));
        await tester.pump();

        expect(childTapped, isTrue);
      },
    );

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
              SliverClipRRect(
                clipper: const _CustomClipperRRect30(),
                sliver: SliverToBoxAdapter(
                  child: Container(height: 400.0, color: const Color(0xFF2196F3)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      final RenderSliverClipRRect renderSliver = tester.renderObject(find.byType(SliverClipRRect));

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

class _CustomClipperRRect30 extends CustomClipper<RRect> {
  const _CustomClipperRRect30();
  @override
  RRect getClip(Size size) => RRect.fromLTRBAndCorners(0.0, 30.0, size.width, size.height);
  @override
  bool shouldReclip(covariant CustomClipper<RRect> oldClipper) => false;
}
