// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

Widget _buildTestApp({
  required Widget sliver,
  TextDirection textDirection = .ltr,
  Axis scrollDirection = .vertical,
  bool reverse = false,
  ScrollController? controller,
}) {
  return Directionality(
    textDirection: textDirection,
    child: CustomScrollView(
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      slivers: <Widget>[sliver],
    ),
  );
}

Widget _buildTapTarget({
  Key? key,
  double width = 100.0,
  double height = 100.0,
  VoidCallback? onTap,
}) {
  return SliverToBoxAdapter(
    key: key,
    child: Align(
      alignment: .topLeft,
      child: SizedBox(
        width: width,
        height: height,
        child: GestureDetector(
          behavior: .opaque,
          onTap: onTap,
          child: Container(color: const Color(0xFF00FF00)),
        ),
      ),
    ),
  );
}

void main() {
  group('SliverTransform constructors and property updates', () {
    testWidgets('SliverTransform.translate constructor', (WidgetTester tester) async {
      final Key key = UniqueKey();
      await tester.pumpWidget(
        _buildTestApp(
          sliver: SliverTransform.translate(
            key: key,
            offset: const Offset(15.0, 25.0),
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
          ),
        ),
      );

      final RenderSliverTransform render = tester.renderObject(find.byKey(key));
      final transform = Matrix4.identity();
      render.applyPaintTransform(render.child!, transform);
      expect(MatrixUtils.getAsTranslation(transform), const Offset(15.0, 25.0));
    });

    testWidgets('SliverTransform.rotate constructor', (WidgetTester tester) async {
      final Key key = UniqueKey();
      await tester.pumpWidget(
        _buildTestApp(
          sliver: SliverTransform.rotate(
            key: key,
            angle: math.pi / 2.0,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
          ),
        ),
      );

      final RenderSliverTransform render = tester.renderObject(find.byKey(key));
      expect(render.geometry!.paintExtent, 100.0);

      final transform = Matrix4.identity();
      render.applyPaintTransform(render.child!, transform);
      expect(transform.storage[0], moreOrLessEquals(0.0));
      expect(transform.storage[1], moreOrLessEquals(1.0));
      expect(transform.storage[4], moreOrLessEquals(-1.0));
      expect(transform.storage[5], moreOrLessEquals(0.0));
    });

    testWidgets('SliverTransform.scale constructor with uniform and 2D scales', (
      WidgetTester tester,
    ) async {
      final Key uniformKey = UniqueKey();
      final Key nonUniformKey = UniqueKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverTransform.scale(
                key: uniformKey,
                scale: 2.0,
                sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
              SliverTransform.scale(
                key: nonUniformKey,
                scaleX: 1.5,
                scaleY: 0.5,
                sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
            ],
          ),
        ),
      );

      final RenderSliverTransform uniformRender = tester.renderObject(find.byKey(uniformKey));
      final RenderSliverTransform nonUniformRender = tester.renderObject(find.byKey(nonUniformKey));

      final uniformTransform = Matrix4.identity();
      uniformRender.applyPaintTransform(uniformRender.child!, uniformTransform);
      expect(uniformTransform.storage[0], 2.0);
      expect(uniformTransform.storage[5], 2.0);

      final nonUniformTransform = Matrix4.identity();
      nonUniformRender.applyPaintTransform(nonUniformRender.child!, nonUniformTransform);
      expect(nonUniformTransform.storage[0], 1.5);
      expect(nonUniformTransform.storage[5], 0.5);
    });

    testWidgets('SliverTransform.flip constructor with flipX and flipY combinations', (
      WidgetTester tester,
    ) async {
      final Key keyX = UniqueKey();
      final Key keyY = UniqueKey();
      final Key keyBoth = UniqueKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverTransform.flip(
                key: keyX,
                flipX: true,
                sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
              SliverTransform.flip(
                key: keyY,
                flipY: true,
                sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
              SliverTransform.flip(
                key: keyBoth,
                flipX: true,
                flipY: true,
                sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
            ],
          ),
        ),
      );

      final RenderSliverTransform renderX = tester.renderObject(find.byKey(keyX));
      final RenderSliverTransform renderY = tester.renderObject(find.byKey(keyY));
      final RenderSliverTransform renderBoth = tester.renderObject(find.byKey(keyBoth));

      final transformX = Matrix4.identity();
      renderX.applyPaintTransform(renderX.child!, transformX);
      expect(transformX.storage[0], -1.0);
      expect(transformX.storage[5], 1.0);

      final transformY = Matrix4.identity();
      renderY.applyPaintTransform(renderY.child!, transformY);
      expect(transformY.storage[0], 1.0);
      expect(transformY.storage[5], -1.0);

      final transformBoth = Matrix4.identity();
      renderBoth.applyPaintTransform(renderBoth.child!, transformBoth);
      expect(transformBoth.storage[0], -1.0);
      expect(transformBoth.storage[5], -1.0);
    });

    testWidgets('SliverTransform updates render object properties dynamically', (
      WidgetTester tester,
    ) async {
      final Key key = UniqueKey();
      var matrix = Matrix4.identity();
      var origin = const Offset(10.0, 10.0);
      AlignmentGeometry alignment = .center;
      FilterQuality? filterQuality = .low;
      var transformHitTests = true;

      Widget buildWidget() {
        return _buildTestApp(
          sliver: SliverTransform(
            key: key,
            transform: matrix,
            origin: origin,
            alignment: alignment,
            filterQuality: filterQuality,
            transformHitTests: transformHitTests,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 50.0)),
          ),
        );
      }

      await tester.pumpWidget(buildWidget());
      final RenderSliverTransform render = tester.renderObject(find.byKey(key));
      expect(render.origin, const Offset(10.0, 10.0));
      expect(render.alignment, Alignment.center);
      expect(render.filterQuality, FilterQuality.low);
      expect(render.transformHitTests, isTrue);

      origin = const Offset(20.0, 30.0);
      alignment = .topLeft;
      filterQuality = .high;
      transformHitTests = false;
      matrix = Matrix4.rotationZ(1.0);

      await tester.pumpWidget(buildWidget());
      expect(render.origin, const Offset(20.0, 30.0));
      expect(render.alignment, Alignment.topLeft);
      expect(render.filterQuality, FilterQuality.high);
      expect(render.transformHitTests, isFalse);
    });

    testWidgets('debugFillProperties on widget and render object', (WidgetTester tester) async {
      final builder = DiagnosticPropertiesBuilder();
      SliverTransform(
        transform: Matrix4.identity(),
        origin: const Offset(5.0, 5.0),
        alignment: .bottomRight,
        transformHitTests: false,
        filterQuality: .high,
      ).debugFillProperties(builder);

      final List<String> widgetProps = builder.properties
          .map((DiagnosticsNode node) => node.toString())
          .toList();
      expect(widgetProps.any((String s) => s.contains('origin: Offset(5.0, 5.0)')), isTrue);
      expect(widgetProps.any((String s) => s.contains('alignment: Alignment.bottomRight')), isTrue);
      expect(widgetProps.contains('transform hit tests disabled'), isTrue);
      expect(widgetProps.any((String s) => s.contains('filterQuality: high')), isTrue);

      final render = RenderSliverTransform(
        delegate: .matrix(Matrix4.identity()),
        origin: const Offset(5.0, 5.0),
        alignment: .bottomRight,
        filterQuality: .medium,
      );
      final renderBuilder = DiagnosticPropertiesBuilder();
      render.debugFillProperties(renderBuilder);
      final List<String> renderProps = renderBuilder.properties
          .map((DiagnosticsNode node) => node.toString())
          .toList();
      expect(
        renderProps.any(
          (String s) => s.contains('delegate:') && s.contains('_FixedSliverTransformDelegate'),
        ),
        isTrue,
      );
      expect(renderProps.any((String s) => s.contains('origin: Offset(5.0, 5.0)')), isTrue);
      expect(renderProps.any((String s) => s.contains('alignment: Alignment.bottomRight')), isTrue);
      expect(renderProps.contains('transform hit tests enabled'), isTrue);
      expect(renderProps.any((String s) => s.contains('filterQuality: medium')), isTrue);
    });
  });

  group('Geometry and layout', () {
    testWidgets('preserves child geometry without modifying layout', (WidgetTester tester) async {
      final Key transformKey = UniqueKey();
      final Key childKey = UniqueKey();

      await tester.pumpWidget(
        _buildTestApp(
          sliver: SliverTransform(
            key: transformKey,
            transform: Matrix4.translationValues(50.0, 100.0, 0.0),
            sliver: SliverToBoxAdapter(key: childKey, child: const SizedBox(height: 120.0)),
          ),
        ),
      );

      final RenderSliverTransform renderTransform = tester.renderObject(find.byKey(transformKey));
      final RenderSliverToBoxAdapter renderChild = tester.renderObject(find.byKey(childKey));

      expect(renderTransform.geometry, equals(renderChild.geometry));
      expect(renderTransform.geometry!.scrollExtent, 120.0);
      expect(renderTransform.geometry!.paintExtent, 120.0);
      expect(renderTransform.geometry!.maxPaintExtent, 120.0);
      expect(renderTransform.geometry!.visible, isTrue);
    });

    testWidgets('does not paint and clears layer when child geometry is not visible', (
      WidgetTester tester,
    ) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final Key key = UniqueKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverTransform(
                key: key,
                transform: Matrix4.translationValues(10.0, 10.0, 0.0),
                sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      final RenderSliverTransform render = tester.renderObject(find.byKey(key));
      expect(render.geometry!.visible, isTrue);

      scrollController.jumpTo(200.0);
      await tester.pump();

      expect(render.geometry!.visible, isFalse);
      expect(render.debugLayer, isNull);
    });

    testWidgets('hitTest returns false when hitTestExtent is zero', (WidgetTester tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final Key key = UniqueKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverTransform(
                key: key,
                transform: Matrix4.identity(),
                sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      final RenderSliverTransform render = tester.renderObject(find.byKey(key));
      scrollController.jumpTo(200.0);
      await tester.pump();

      expect(render.geometry!.hitTestExtent, 0.0);
      expect(
        render.hitTest(SliverHitTestResult(), mainAxisPosition: 50.0, crossAxisPosition: 50.0),
        isFalse,
      );
    });

    testWidgets('alignment resolves with getMaxPaintRect when scrolled', (
      WidgetTester tester,
    ) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      var didReceiveTap = false;
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverTransform.scale(
                scale: 2.0,
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 100.0,
                    child: Center(
                      child: GestureDetector(
                        behavior: .opaque,
                        onTap: () {
                          didReceiveTap = true;
                        },
                        child: const SizedBox(width: 40.0, height: 40.0),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000.0)),
            ],
          ),
        ),
      );

      // Initial state: scrollOffset = 0, center of 100px sliver is at y = 50.
      await tester.tapAt(const Offset(400.0, 50.0));
      expect(didReceiveTap, isTrue);

      didReceiveTap = false;
      // Scrolled by 40px: sliver top is at y = -40, center is at y = 10.
      scrollController.jumpTo(40.0);
      await tester.pump();

      await tester.tapAt(const Offset(400.0, 10.0));
      expect(didReceiveTap, isTrue);
    });

    testWidgets('handles singular non-invertible matrix gracefully without throwing', (
      WidgetTester tester,
    ) async {
      var didReceiveTap = false;
      await tester.pumpWidget(
        _buildTestApp(
          sliver: SliverTransform(
            transform: Matrix4.zero(),
            sliver: _buildTapTarget(
              onTap: () {
                didReceiveTap = true;
              },
            ),
          ),
        ),
      );

      final RenderSliverTransform render = tester.renderObject(find.byType(SliverTransform));
      expect(render.debugLayer, isNull);

      await tester.tapAt(const Offset(50.0, 50.0));
      expect(didReceiveTap, isFalse);
    });

    testWidgets(
      'delegate returning null applies no transformation to paint, hit-test, or transform',
      (WidgetTester tester) async {
        var didReceiveTap = false;
        await tester.pumpWidget(
          _buildTestApp(
            sliver: SliverTransform.custom(
              delegate: .callback((SliverConstraints constraints, SliverGeometry geometry) => null),
              sliver: _buildTapTarget(
                onTap: () {
                  didReceiveTap = true;
                },
              ),
            ),
          ),
        );

        final RenderSliverTransform render = tester.renderObject(find.byType(SliverTransform));
        expect(render.debugLayer, isNull);

        final transform = Matrix4.identity();
        render.applyPaintTransform(render.child!, transform);
        expect(transform, equals(Matrix4.identity()));

        await tester.tapAt(const Offset(50.0, 50.0));
        expect(didReceiveTap, isTrue);
      },
    );
  });

  group('Painting and compositing', () {
    testWidgets('applyPaintTransform multiplies child transform', (WidgetTester tester) async {
      final Key key = UniqueKey();
      final Key childKey = UniqueKey();
      await tester.pumpWidget(
        _buildTestApp(
          sliver: SliverTransform.translate(
            key: key,
            offset: const Offset(10.0, 20.0),
            sliver: SliverToBoxAdapter(key: childKey, child: const SizedBox(height: 100.0)),
          ),
        ),
      );

      final RenderSliverTransform renderTransform = tester.renderObject(find.byKey(key));
      final RenderSliverToBoxAdapter renderChild = tester.renderObject(find.byKey(childKey));

      final transform = Matrix4.identity();
      renderTransform.applyPaintTransform(renderChild, transform);
      expect(MatrixUtils.getAsTranslation(transform), const Offset(10.0, 20.0));
    });

    testWidgets('filterQuality sets alwaysNeedsCompositing and pushes ImageFilterLayer', (
      WidgetTester tester,
    ) async {
      final Key key = UniqueKey();
      await tester.pumpWidget(
        _buildTestApp(
          sliver: SliverTransform(
            key: key,
            transform: Matrix4.translationValues(10.0, 10.0, 0.0),
            filterQuality: .medium,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
          ),
        ),
      );

      final RenderSliverTransform render = tester.renderObject(find.byKey(key));
      expect(render.alwaysNeedsCompositing, isTrue);
      expect(render.debugLayer, isA<ImageFilterLayer>());
    });
  });

  group('Hit testing across axes and directions', () {
    testWidgets(
      'hit testing across all 4 scroll directions (vertical/horizontal, normal/reverse)',
      (WidgetTester tester) async {
        const translation = Offset(40.0, 30.0);

        // Test matrix: (scrollDirection, reverse, hitOffset, missOffset)
        final testCases = <(Axis, bool, Offset, Offset)>[
          // Vertical normal (down): top is 0, translated target at [40..140, 30..130]
          (.vertical, false, const Offset(60.0, 50.0), const Offset(20.0, 20.0)),
          // Vertical reverse (up): bottom is 600, sliver at 500..600, translated to [40..140, 530..630]
          (.vertical, true, const Offset(60.0, 550.0), const Offset(20.0, 510.0)),
          // Horizontal normal (right): left is 0, translated target at [40..140, 30..130]
          (.horizontal, false, const Offset(60.0, 50.0), const Offset(20.0, 20.0)),
          // Horizontal reverse (left): right is 800, sliver at 700..800, translated to [740..840, 30..130]
          (.horizontal, true, const Offset(760.0, 50.0), const Offset(720.0, 20.0)),
        ];

        for (final (Axis axis, bool reverse, Offset hitOffset, Offset missOffset) in testCases) {
          var didReceiveTap = false;
          await tester.pumpWidget(
            _buildTestApp(
              scrollDirection: axis,
              reverse: reverse,
              sliver: SliverTransform.translate(
                offset: translation,
                sliver: _buildTapTarget(
                  onTap: () {
                    didReceiveTap = true;
                  },
                ),
              ),
            ),
          );

          // Tapping untransformed location should miss
          await tester.tapAt(missOffset);
          expect(
            didReceiveTap,
            isFalse,
            reason: 'Axis: $axis, reverse: $reverse should miss at $missOffset',
          );

          // Tapping transformed location should hit
          await tester.tapAt(hitOffset);
          expect(
            didReceiveTap,
            isTrue,
            reason: 'Axis: $axis, reverse: $reverse should hit at $hitOffset',
          );
        }
      },
    );

    testWidgets('hit testing with transformHitTests false ignores transformation', (
      WidgetTester tester,
    ) async {
      var didReceiveTap = false;
      await tester.pumpWidget(
        _buildTestApp(
          sliver: SliverTransform.translate(
            offset: const Offset(50.0, 50.0),
            transformHitTests: false,
            sliver: _buildTapTarget(
              onTap: () {
                didReceiveTap = true;
              },
            ),
          ),
        ),
      );

      // Untransformed location (20, 20) hits when transformHitTests is false
      await tester.tapAt(const Offset(20.0, 20.0));
      expect(didReceiveTap, isTrue);

      didReceiveTap = false;
      // Transformed location (120, 120) misses when transformHitTests is false
      await tester.tapAt(const Offset(120.0, 120.0));
      expect(didReceiveTap, isFalse);
    });

    testWidgets('hit testing with rotation', (WidgetTester tester) async {
      var didReceiveTap = false;
      // 100x100 sliver rotated 90 deg clockwise around its center (400, 50).
      await tester.pumpWidget(
        _buildTestApp(
          sliver: SliverTransform.rotate(
            angle: math.pi / 2.0,
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 100.0,
                child: Center(
                  child: SizedBox(
                    width: 100.0,
                    height: 100.0,
                    child: Align(
                      alignment: .topCenter,
                      child: SizedBox(
                        width: 40.0,
                        height: 20.0,
                        child: GestureDetector(
                          behavior: .opaque,
                          onTap: () {
                            didReceiveTap = true;
                          },
                          child: Container(color: const Color(0xFF00FF00)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // The top-center button (center at 400, 10, offset by -40 from center (400, 50))
      // rotates 90 deg clockwise to (400 + 40, 50) = (440, 50).
      await tester.tapAt(const Offset(400.0, 10.0));
      expect(didReceiveTap, isFalse);

      await tester.tapAt(const Offset(440.0, 50.0));
      expect(didReceiveTap, isTrue);
    });

    testWidgets('AlignmentDirectional resolves correctly with TextDirection for LTR and RTL', (
      WidgetTester tester,
    ) async {
      Widget buildFrame({
        required TextDirection textDirection,
        required AlignmentGeometry alignment,
      }) {
        return _buildTestApp(
          textDirection: textDirection,
          sliver: SliverTransform(
            alignment: alignment,
            transform: Matrix4.diagonal3Values(2.0, 1.0, 1.0),
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
          ),
        );
      }

      // In LTR, centerStart is centerLeft (pivot x = 0.0, translation dx = 0.0)
      await tester.pumpWidget(buildFrame(textDirection: .ltr, alignment: .centerStart));
      RenderSliverTransform render = tester.renderObject(find.byType(SliverTransform));
      var transform = Matrix4.identity();
      render.applyPaintTransform(render.child!, transform);
      expect(transform.storage[12], 0.0);

      // In RTL, centerStart is centerRight (pivot x = 800.0, translation dx = 800 - 2*800 = -800.0)
      await tester.pumpWidget(buildFrame(textDirection: .rtl, alignment: .centerStart));
      render = tester.renderObject(find.byType(SliverTransform));
      transform = Matrix4.identity();
      render.applyPaintTransform(render.child!, transform);
      expect(transform.storage[12], -800.0);

      // In LTR, centerEnd is centerRight (pivot x = 800.0, translation dx = -800.0)
      await tester.pumpWidget(buildFrame(textDirection: .ltr, alignment: .centerEnd));
      render = tester.renderObject(find.byType(SliverTransform));
      transform = Matrix4.identity();
      render.applyPaintTransform(render.child!, transform);
      expect(transform.storage[12], -800.0);

      // In RTL, centerEnd is centerLeft (pivot x = 0.0, translation dx = 0.0)
      await tester.pumpWidget(buildFrame(textDirection: .rtl, alignment: .centerEnd));
      render = tester.renderObject(find.byType(SliverTransform));
      transform = Matrix4.identity();
      render.applyPaintTransform(render.child!, transform);
      expect(transform.storage[12], 0.0);
    });
  });

  group('SliverTransformDelegate and reactivity', () {
    testWidgets(
      'SliverTransform.custom computes matrix dynamically from constraints and geometry',
      (WidgetTester tester) async {
        SliverConstraints? capturedConstraints;
        SliverGeometry? capturedGeometry;
        var didReceiveTap = false;

        await tester.pumpWidget(
          _buildTestApp(
            sliver: SliverTransform.custom(
              delegate: .callback((SliverConstraints constraints, SliverGeometry geometry) {
                capturedConstraints = constraints;
                capturedGeometry = geometry;
                return Matrix4.translationValues(0.0, geometry.scrollExtent * 0.5, 0.0);
              }),
              sliver: _buildTapTarget(
                onTap: () {
                  didReceiveTap = true;
                },
              ),
            ),
          ),
        );

        expect(capturedConstraints, isNotNull);
        expect(capturedGeometry, isNotNull);
        expect(capturedGeometry!.scrollExtent, 100.0);

        // Original position (20, 20) misses because translated down by 50px
        await tester.tapAt(const Offset(20.0, 20.0));
        expect(didReceiveTap, isFalse);

        // Transformed position (20, 70) hits (20 + 50 = 70)
        await tester.tapAt(const Offset(20.0, 70.0));
        expect(didReceiveTap, isTrue);
      },
    );

    testWidgets('SliverTransform.custom updates delegate dynamically', (WidgetTester tester) async {
      final Key key = UniqueKey();
      const delegate1 = _TestSliverTransformDelegate(offset: Offset(10.0, 0.0));
      const delegate2 = _TestSliverTransformDelegate(offset: Offset(30.0, 0.0));

      SliverTransformDelegate activeDelegate = delegate1;
      late StateSetter localSetState;

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              localSetState = setState;
              return CustomScrollView(
                slivers: <Widget>[
                  SliverTransform.custom(
                    key: key,
                    delegate: activeDelegate,
                    sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
                  ),
                ],
              );
            },
          ),
        ),
      );

      final RenderSliverTransform render = tester.renderObject(find.byKey(key));
      expect(render.delegate, same(delegate1));

      localSetState(() {
        activeDelegate = delegate2;
      });
      await tester.pump();
      expect(render.delegate, same(delegate2));
    });

    testWidgets('SliverTransform transitions between static transform and custom delegate', (
      WidgetTester tester,
    ) async {
      final Key key = UniqueKey();
      var useCustom = false;
      late StateSetter localSetState;

      const customDelegate = _TestSliverTransformDelegate(offset: Offset(5.0, 5.0));

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              localSetState = setState;
              if (useCustom) {
                return CustomScrollView(
                  slivers: <Widget>[
                    SliverTransform.custom(
                      key: key,
                      delegate: customDelegate,
                      sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
                    ),
                  ],
                );
              }
              return CustomScrollView(
                slivers: <Widget>[
                  SliverTransform(
                    key: key,
                    transform: Matrix4.translationValues(15.0, 15.0, 0.0),
                    sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
                  ),
                ],
              );
            },
          ),
        ),
      );

      final RenderSliverTransform render = tester.renderObject(find.byKey(key));
      expect(render.delegate, isA<SliverTransformDelegate>());
      expect(
        render.delegate.computeTransform(
          const SliverConstraints(
            axisDirection: .down,
            growthDirection: .forward,
            userScrollDirection: .idle,
            scrollOffset: 0.0,
            precedingScrollExtent: 0.0,
            overlap: 0.0,
            remainingPaintExtent: 100.0,
            crossAxisExtent: 100.0,
            crossAxisDirection: .right,
            viewportMainAxisExtent: 100.0,
            remainingCacheExtent: 100.0,
            cacheOrigin: 0.0,
          ),
          SliverGeometry.zero,
        ),
        equals(Matrix4.translationValues(15.0, 15.0, 0.0)),
      );

      localSetState(() {
        useCustom = true;
      });
      await tester.pump();
      expect(render.delegate, same(customDelegate));
    });

    testWidgets('SliverTransformDelegate classes and resolution', (WidgetTester tester) async {
      final callbackDelegate = SliverTransformDelegate.callback(
        (SliverConstraints c, SliverGeometry g) => Matrix4.identity(),
      );
      final matrixDelegate = SliverTransformDelegate.matrix(Matrix4.identity());
      const customDelegate = _TestSliverTransformDelegate(offset: Offset(10.0, 20.0));

      const constraints = SliverConstraints(
        axisDirection: .down,
        growthDirection: .forward,
        userScrollDirection: .idle,
        scrollOffset: 0.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 100.0,
        crossAxisExtent: 100.0,
        crossAxisDirection: .right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 100.0,
        cacheOrigin: 0.0,
      );

      const geometry = SliverGeometry(scrollExtent: 100.0, paintExtent: 100.0);

      expect(callbackDelegate.computeTransform(constraints, geometry), isNotNull);
      expect(callbackDelegate.toString(), contains('SliverTransformCallbackDelegate'));

      expect(matrixDelegate.computeTransform(constraints, geometry), equals(Matrix4.identity()));
      expect(matrixDelegate.toString(), contains('_FixedSliverTransformDelegate'));
      expect(
        matrixDelegate.shouldRepaint(SliverTransformDelegate.matrix(Matrix4.identity())),
        isFalse,
      );
      expect(
        matrixDelegate.shouldRepaint(SliverTransformDelegate.matrix(Matrix4.rotationZ(1.0))),
        isTrue,
      );
      expect(matrixDelegate == SliverTransformDelegate.matrix(Matrix4.identity()), isTrue);

      expect(
        customDelegate.computeTransform(constraints, geometry),
        Matrix4.translationValues(10.0, 20.0, 0.0),
      );
      expect(
        customDelegate.shouldRepaint(
          const _TestSliverTransformDelegate(offset: Offset(10.0, 20.0)),
        ),
        isFalse,
      );
      expect(
        customDelegate.shouldRepaint(const _TestSliverTransformDelegate(offset: Offset(5.0, 5.0))),
        isTrue,
      );

      final callbackRepaint = ChangeNotifier();
      final callbackSemantics = ChangeNotifier();
      Matrix4? callbackFn(SliverConstraints c, SliverGeometry g) => Matrix4.identity();
      final callback1 = SliverTransformDelegate.callback(
        callbackFn,
        repaint: callbackRepaint,
        semanticsUpdate: callbackSemantics,
      );
      final callback2 = SliverTransformDelegate.callback(
        callbackFn,
        repaint: callbackRepaint,
        semanticsUpdate: callbackSemantics,
      );
      final callbackDifferentSemantics = SliverTransformDelegate.callback(
        callbackFn,
        repaint: callbackRepaint,
      );
      expect(callback1 == callback2, isTrue);
      expect(callback1.hashCode == callback2.hashCode, isTrue);
      expect(callback1 == callbackDifferentSemantics, isFalse);
    });

    testWidgets('RenderSliverTransform delegate getter and setter', (WidgetTester tester) async {
      final initialDelegate = SliverTransformDelegate.matrix(Matrix4.identity());
      final render = RenderSliverTransform(delegate: initialDelegate);

      expect(render.delegate, equals(initialDelegate));

      const delegate = _TestSliverTransformDelegate();
      render.delegate = delegate;
      expect(render.delegate, same(delegate));

      final newDelegate = SliverTransformDelegate.matrix(Matrix4.rotationZ(1.0));
      render.delegate = newDelegate;
      expect(render.delegate, equals(newDelegate));
    });

    testWidgets(
      'SliverTransformDelegate repaint notification marks render object for paint and semantics by default',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        final repaintNotifier = ChangeNotifier();
        final delegate = _TestSliverTransformDelegate(repaint: repaintNotifier);

        await tester.pumpWidget(
          _buildTestApp(
            sliver: SliverTransform.custom(
              delegate: delegate,
              sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
            ),
          ),
        );

        final RenderSliverTransform render = tester.renderObject(find.byType(SliverTransform));

        expect(render.debugNeedsPaint, isFalse);
        expect(render.debugNeedsSemanticsUpdate, isFalse);
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        repaintNotifier.notifyListeners();
        expect(render.debugNeedsPaint, isTrue);
        expect(render.debugNeedsSemanticsUpdate, isTrue);

        handle.dispose();
      },
    );

    testWidgets('SliverTransformDelegate uses custom semanticsUpdate when provided', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final repaintNotifier = ChangeNotifier();
      final semanticsNotifier = ChangeNotifier();
      final delegate = _TestSliverTransformDelegate(
        repaint: repaintNotifier,
        semanticsUpdate: semanticsNotifier,
      );

      await tester.pumpWidget(
        _buildTestApp(
          sliver: SliverTransform.custom(
            delegate: delegate,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
          ),
        ),
      );

      final RenderSliverTransform render = tester.renderObject(find.byType(SliverTransform));

      expect(render.debugNeedsPaint, isFalse);
      expect(render.debugNeedsSemanticsUpdate, isFalse);

      // Only repaint notifies: marks paint, not semantics.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      repaintNotifier.notifyListeners();
      expect(render.debugNeedsPaint, isTrue);
      expect(render.debugNeedsSemanticsUpdate, isFalse);

      await tester.pump();
      expect(render.debugNeedsPaint, isFalse);
      expect(render.debugNeedsSemanticsUpdate, isFalse);

      // Only semanticsUpdate notifies: marks semantics, not paint.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      semanticsNotifier.notifyListeners();
      expect(render.debugNeedsPaint, isFalse);
      expect(render.debugNeedsSemanticsUpdate, isTrue);

      handle.dispose();
    });

    testWidgets(
      'RenderSliverTransform updates repaint and semanticsUpdate listeners on delegate change',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        final repaint1 = ChangeNotifier();
        final semantics1 = ChangeNotifier();
        final repaint2 = ChangeNotifier();
        final semantics2 = ChangeNotifier();

        final delegate1 = _TestSliverTransformDelegate(
          repaint: repaint1,
          semanticsUpdate: semantics1,
        );
        final delegate2 = _TestSliverTransformDelegate(
          repaint: repaint2,
          semanticsUpdate: semantics2,
        );

        await tester.pumpWidget(
          _buildTestApp(
            sliver: SliverTransform.custom(
              delegate: delegate1,
              sliver: const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
            ),
          ),
        );

        final RenderSliverTransform render = tester.renderObject(find.byType(SliverTransform));

        render.delegate = delegate2;
        await tester.pump();

        expect(render.debugNeedsPaint, isFalse);
        expect(render.debugNeedsSemanticsUpdate, isFalse);

        // Old notifiers do not affect render object anymore.
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        repaint1.notifyListeners();
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        semantics1.notifyListeners();
        expect(render.debugNeedsPaint, isFalse);
        expect(render.debugNeedsSemanticsUpdate, isFalse);

        // New notifiers work as expected.
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        repaint2.notifyListeners();
        expect(render.debugNeedsPaint, isTrue);
        expect(render.debugNeedsSemanticsUpdate, isFalse);

        await tester.pump();
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        semantics2.notifyListeners();
        expect(render.debugNeedsPaint, isFalse);
        expect(render.debugNeedsSemanticsUpdate, isTrue);

        handle.dispose();
      },
    );
  });

  group('Semantics and accessibility', () {
    testWidgets('SliverTransform applies transformation to semantics node', (
      WidgetTester tester,
    ) async {
      final semantics = SemanticsTester(tester);

      await tester.pumpWidget(
        _buildTestApp(
          sliver: SliverTransform.translate(
            offset: const Offset(40.0, 60.0),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                label: 'transformed_label',
                container: true,
                child: const SizedBox(width: 100.0, height: 100.0),
              ),
            ),
          ),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.bySemanticsLabel('transformed_label'));
      expect(MatrixUtils.getAsTranslation(node.transform!), const Offset(40.0, 60.0));

      semantics.dispose();
    });
  });
}

class _TestSliverTransformDelegate extends SliverTransformDelegate {
  const _TestSliverTransformDelegate({this.offset = .zero, super.repaint, super.semanticsUpdate});

  final Offset offset;

  @override
  Matrix4? computeTransform(SliverConstraints constraints, SliverGeometry geometry) {
    return Matrix4.translationValues(offset.dx, offset.dy, 0.0);
  }

  @override
  bool shouldRepaint(covariant _TestSliverTransformDelegate oldDelegate) {
    return oldDelegate.offset != offset;
  }
}
