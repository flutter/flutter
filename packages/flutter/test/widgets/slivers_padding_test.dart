// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockRenderSliver extends RenderSliver {
  @override
  void performLayout() {
    geometry = const SliverGeometry(
      paintOrigin: 10,
      paintExtent: 10,
      maxPaintExtent: 10,
    );
  }

}

Future<void> test(final WidgetTester tester, final double offset, final EdgeInsetsGeometry padding, final AxisDirection axisDirection, final TextDirection textDirection) {
  return tester.pumpWidget(
    Directionality(
      textDirection: textDirection,
      child: Viewport(
        offset: ViewportOffset.fixed(offset),
        axisDirection: axisDirection,
        slivers: <Widget>[
          const SliverToBoxAdapter(child: SizedBox(width: 400.0, height: 400.0, child: Text('before'))),
          SliverPadding(
            padding: padding,
            sliver: const SliverToBoxAdapter(child: SizedBox(width: 400.0, height: 400.0, child: Text('padded'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(width: 400.0, height: 400.0, child: Text('after'))),
        ],
      ),
    ),
  );
}

void verify(final WidgetTester tester, final List<Rect> answerKey) {
  final List<Rect> testAnswers = tester.renderObjectList<RenderBox>(find.byType(SizedBox, skipOffstage: false)).map<Rect>(
    (final RenderBox target) {
      final Offset topLeft = target.localToGlobal(Offset.zero);
      final Offset bottomRight = target.localToGlobal(target.size.bottomRight(Offset.zero));
      return Rect.fromPoints(topLeft, bottomRight);
    },
  ).toList();
  expect(testAnswers, equals(answerKey));
}

void main() {
  testWidgets('Viewport+SliverPadding basic test (VISUAL)', (final WidgetTester tester) async {
    const EdgeInsets padding = EdgeInsets.fromLTRB(25.0, 20.0, 15.0, 35.0);
    await test(tester, 0.0, padding, AxisDirection.down, TextDirection.ltr);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, 0.0, 800.0, 400.0),
      const Rect.fromLTWH(25.0, 420.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 855.0, 800.0, 400.0),
    ]);

    await test(tester, 200.0, padding, AxisDirection.down, TextDirection.ltr);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -200.0, 800.0, 400.0),
      const Rect.fromLTWH(25.0, 220.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 655.0, 800.0, 400.0),
    ]);

    await test(tester, 390.0, padding, AxisDirection.down, TextDirection.ltr);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -390.0, 800.0, 400.0),
      const Rect.fromLTWH(25.0, 30.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 465.0, 800.0, 400.0),
    ]);

    await test(tester, 490.0, padding, AxisDirection.down, TextDirection.ltr);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -490.0, 800.0, 400.0),
      const Rect.fromLTWH(25.0, -70.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 365.0, 800.0, 400.0),
    ]);

    await test(tester, 10000.0, padding, AxisDirection.down, TextDirection.ltr);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -10000.0, 800.0, 400.0),
      const Rect.fromLTWH(25.0, -9580.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, -9145.0, 800.0, 400.0),
    ]);
  });

  testWidgets('Viewport+SliverPadding basic test (LTR)', (final WidgetTester tester) async {
    const EdgeInsetsDirectional padding = EdgeInsetsDirectional.fromSTEB(25.0, 20.0, 15.0, 35.0);
    await test(tester, 0.0, padding, AxisDirection.down, TextDirection.ltr);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, 0.0, 800.0, 400.0),
      const Rect.fromLTWH(25.0, 420.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 855.0, 800.0, 400.0),
    ]);

    await test(tester, 200.0, padding, AxisDirection.down, TextDirection.ltr);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -200.0, 800.0, 400.0),
      const Rect.fromLTWH(25.0, 220.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 655.0, 800.0, 400.0),
    ]);

    await test(tester, 390.0, padding, AxisDirection.down, TextDirection.ltr);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -390.0, 800.0, 400.0),
      const Rect.fromLTWH(25.0, 30.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 465.0, 800.0, 400.0),
    ]);

    await test(tester, 490.0, padding, AxisDirection.down, TextDirection.ltr);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -490.0, 800.0, 400.0),
      const Rect.fromLTWH(25.0, -70.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 365.0, 800.0, 400.0),
    ]);

    await test(tester, 10000.0, padding, AxisDirection.down, TextDirection.ltr);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -10000.0, 800.0, 400.0),
      const Rect.fromLTWH(25.0, -9580.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, -9145.0, 800.0, 400.0),
    ]);
  });

  testWidgets('Viewport+SliverPadding basic test (RTL)', (final WidgetTester tester) async {
    const EdgeInsetsDirectional padding = EdgeInsetsDirectional.fromSTEB(25.0, 20.0, 15.0, 35.0);
    await test(tester, 0.0, padding, AxisDirection.down, TextDirection.rtl);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, 0.0, 800.0, 400.0),
      const Rect.fromLTWH(15.0, 420.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 855.0, 800.0, 400.0),
    ]);

    await test(tester, 200.0, padding, AxisDirection.down, TextDirection.rtl);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -200.0, 800.0, 400.0),
      const Rect.fromLTWH(15.0, 220.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 655.0, 800.0, 400.0),
    ]);

    await test(tester, 390.0, padding, AxisDirection.down, TextDirection.rtl);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -390.0, 800.0, 400.0),
      const Rect.fromLTWH(15.0, 30.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 465.0, 800.0, 400.0),
    ]);

    await test(tester, 490.0, padding, AxisDirection.down, TextDirection.rtl);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -490.0, 800.0, 400.0),
      const Rect.fromLTWH(15.0, -70.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, 365.0, 800.0, 400.0),
    ]);

    await test(tester, 10000.0, padding, AxisDirection.down, TextDirection.rtl);
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -10000.0, 800.0, 400.0),
      const Rect.fromLTWH(15.0, -9580.0, 760.0, 400.0),
      const Rect.fromLTWH(0.0, -9145.0, 800.0, 400.0),
    ]);
  });

  testWidgets('Viewport+SliverPadding hit testing', (final WidgetTester tester) async {
    const EdgeInsets padding = EdgeInsets.all(30.0);
    await test(tester, 350.0, padding, AxisDirection.down, TextDirection.ltr);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, -350.0, 800.0, 400.0),
      const Rect.fromLTWH(30.0, 80.0, 740.0, 400.0),
      const Rect.fromLTWH(0.0, 510.0, 800.0, 400.0),
    ]);
    HitTestResult result;
    result = tester.hitTestOnBinding(const Offset(10.0, 10.0));
    expectIsTextSpan(result.path.first.target, 'before');
    result = tester.hitTestOnBinding(const Offset(10.0, 60.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(100.0, 100.0));
    expectIsTextSpan(result.path.first.target, 'padded');
    result = tester.hitTestOnBinding(const Offset(100.0, 490.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(10.0, 520.0));
    expectIsTextSpan(result.path.first.target, 'after');
  });

  testWidgets('Viewport+SliverPadding hit testing up', (final WidgetTester tester) async {
    const EdgeInsets padding = EdgeInsets.all(30.0);
    await test(tester, 350.0, padding, AxisDirection.up, TextDirection.ltr);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      const Rect.fromLTWH(0.0, 600.0+350.0-400.0, 800.0, 400.0),
      const Rect.fromLTWH(30.0, 600.0-80.0-400.0, 740.0, 400.0),
      const Rect.fromLTWH(0.0, 600.0-510.0-400.0, 800.0, 400.0),
    ]);
    HitTestResult result;
    result = tester.hitTestOnBinding(const Offset(10.0, 600.0-10.0));
    expectIsTextSpan(result.path.first.target, 'before');
    result = tester.hitTestOnBinding(const Offset(10.0, 600.0-60.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(100.0, 600.0-100.0));
    expectIsTextSpan(result.path.first.target, 'padded');
    result = tester.hitTestOnBinding(const Offset(100.0, 600.0-490.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(10.0, 600.0-520.0));
    expectIsTextSpan(result.path.first.target, 'after');
  });

  testWidgets('Viewport+SliverPadding hit testing left', (final WidgetTester tester) async {
    const EdgeInsets padding = EdgeInsets.all(30.0);
    await test(tester, 350.0, padding, AxisDirection.left, TextDirection.ltr);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      const Rect.fromLTWH(800.0+350.0-400.0, 0.0, 400.0, 600.0),
      const Rect.fromLTWH(800.0-80.0-400.0, 30.0, 400.0, 540.0),
      const Rect.fromLTWH(800.0-510.0-400.0, 0.0, 400.0, 600.0),
    ]);
    HitTestResult result;
    result = tester.hitTestOnBinding(const Offset(800.0-10.0, 10.0));
    expectIsTextSpan(result.path.first.target, 'before');
    result = tester.hitTestOnBinding(const Offset(800.0-60.0, 10.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(800.0-100.0, 100.0));
    expectIsTextSpan(result.path.first.target, 'padded');
    result = tester.hitTestOnBinding(const Offset(800.0-490.0, 100.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(800.0-520.0, 10.0));
    expectIsTextSpan(result.path.first.target, 'after');
  });

  testWidgets('Viewport+SliverPadding hit testing right', (final WidgetTester tester) async {
    const EdgeInsets padding = EdgeInsets.all(30.0);
    await test(tester, 350.0, padding, AxisDirection.right, TextDirection.ltr);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      const Rect.fromLTWH(-350.0, 0.0, 400.0, 600.0),
      const Rect.fromLTWH(80.0, 30.0, 400.0, 540.0),
      const Rect.fromLTWH(510.0, 0.0, 400.0, 600.0),
    ]);
    HitTestResult result;
    result = tester.hitTestOnBinding(const Offset(10.0, 10.0));
    expectIsTextSpan(result.path.first.target, 'before');
    result = tester.hitTestOnBinding(const Offset(60.0, 10.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(100.0, 100.0));
    expectIsTextSpan(result.path.first.target, 'padded');
    result = tester.hitTestOnBinding(const Offset(490.0, 100.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(520.0, 10.0));
    expectIsTextSpan(result.path.first.target, 'after');
  });

  testWidgets('Viewport+SliverPadding no child', (final WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Viewport(
          offset: ViewportOffset.fixed(0.0),
          slivers: const <Widget>[
            SliverPadding(padding: EdgeInsets.all(100.0)),
            SliverToBoxAdapter(child: SizedBox(width: 400.0, height: 400.0, child: Text('x'))),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.text('x')).localToGlobal(Offset.zero), const Offset(0.0, 200.0));
  });

  testWidgets('SliverPadding with no child reports correct geometry as scroll offset changes', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/64506
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: const <Widget>[
            SliverPadding(padding: EdgeInsets.all(100.0)),
            SliverToBoxAdapter(child: SizedBox(width: 400.0, height: 400.0, child: Text('x'))),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.text('x')).localToGlobal(Offset.zero), const Offset(0.0, 200.0));
    expect(
      tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).geometry!.paintExtent,
      200.0,
    );
    controller.jumpTo(50.0);
    await tester.pump();
    expect(
      tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).geometry!.paintExtent,
      150.0,
    );
  });

  testWidgets('Viewport+SliverPadding changing padding', (final WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Viewport(
          axisDirection: AxisDirection.left,
          offset: ViewportOffset.fixed(0.0),
          slivers: const <Widget>[
            SliverPadding(padding: EdgeInsets.fromLTRB(90.0, 1.0, 110.0, 2.0)),
            SliverToBoxAdapter(child: SizedBox(width: 201.0, child: Text('x'))),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.text('x')).localToGlobal(Offset.zero), const Offset(399.0, 0.0));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Viewport(
          axisDirection: AxisDirection.left,
          offset: ViewportOffset.fixed(0.0),
          slivers: const <Widget>[
            SliverPadding(padding: EdgeInsets.fromLTRB(110.0, 1.0, 80.0, 2.0)),
            SliverToBoxAdapter(child: SizedBox(width: 201.0, child: Text('x'))),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.text('x')).localToGlobal(Offset.zero), const Offset(409.0, 0.0));
  });

  testWidgets('Viewport+SliverPadding changing direction', (final WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Viewport(
          axisDirection: AxisDirection.up,
          offset: ViewportOffset.fixed(0.0),
          slivers: const <Widget>[
            SliverPadding(padding: EdgeInsets.fromLTRB(1.0, 2.0, 4.0, 8.0)),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).afterPadding, 2.0);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Viewport(
          offset: ViewportOffset.fixed(0.0),
          slivers: const <Widget>[
            SliverPadding(padding: EdgeInsets.fromLTRB(1.0, 2.0, 4.0, 8.0)),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).afterPadding, 8.0);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Viewport(
          axisDirection: AxisDirection.right,
          offset: ViewportOffset.fixed(0.0),
          slivers: const <Widget>[
            SliverPadding(padding: EdgeInsets.fromLTRB(1.0, 2.0, 4.0, 8.0)),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).afterPadding, 4.0);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Viewport(
          axisDirection: AxisDirection.left,
          offset: ViewportOffset.fixed(0.0),
          slivers: const <Widget>[
            SliverPadding(padding: EdgeInsets.fromLTRB(1.0, 2.0, 4.0, 8.0)),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).afterPadding, 1.0);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Viewport(
          axisDirection: AxisDirection.left,
          offset: ViewportOffset.fixed(99999.9),
          slivers: const <Widget>[
            SliverPadding(padding: EdgeInsets.fromLTRB(1.0, 2.0, 4.0, 8.0)),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding, skipOffstage: false)).afterPadding, 1.0);
  });

  testWidgets('SliverPadding propagates geometry offset corrections', (final WidgetTester tester) async {
    Widget listBuilder(final IndexedWidgetBuilder sliverChildBuilder) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          cacheExtent: 0.0,
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.zero,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  sliverChildBuilder,
                  childCount: 10,
                ),
              ),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(
      listBuilder(
        (final BuildContext context, final int index) {
          return SizedBox(
            height: 200.0,
            child: Center(
              child: Text(index.toString()),
            ),
          );
        },
      ),
    );

    await tester.drag(find.text('2'), const Offset(0.0, -300.0));
    await tester.pump();

    expect(
      tester.getRect(find.widgetWithText(SizedBox, '2')),
      const Rect.fromLTRB(0.0, 100.0, 800.0, 300.0),
    );

    // Now item 0 is 400.0px and going back will underflow.
    await tester.pumpWidget(
      listBuilder(
        (final BuildContext context, final int index) {
          return SizedBox(
            height: index == 0 ? 400.0 : 200.0,
            child: Center(
              child: Text(index.toString()),
            ),
          );
        },
      ),
    );

    await tester.drag(find.text('2'), const Offset(0.0, 300.0));
    // On this one frame, the scroll correction must properly propagate.
    await tester.pump();

    expect(
      tester.getRect(find.widgetWithText(SizedBox, '0')),
      const Rect.fromLTRB(0.0, -200.0, 800.0, 200.0),
    );
  });

  testWidgets('SliverPadding includes preceding padding in the precedingScrollExtent provided to child', (final WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/49195
    final UniqueKey key = UniqueKey();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.only(top: 30),
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                key: key,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    ));
    await tester.pump();

    // The value of 570 is expected since SliverFillRemaining will fill all of
    // the space available to it. In this test, the extent of the viewport is
    // 600 pixels. If the SliverPadding widget provides the right constraints
    // to SliverFillRemaining, with 30 pixels preceding it, it should only have
    // a height of 570.
    expect(
      tester.renderObject<RenderBox>(find.byKey(key)).size.height,
      equals(570),
    );
  });

  testWidgets("SliverPadding consumes only its padding from the overlap of its parent's constraints", (final WidgetTester tester) async {
    final _MockRenderSliver mock = _MockRenderSliver();
    final RenderSliverPadding renderObject = RenderSliverPadding(
      padding: const EdgeInsets.only(top: 20),
    );
    renderObject.child = mock;
    renderObject.layout(const SliverConstraints(
        viewportMainAxisExtent: 100.0,
        overlap: 100.0,
        cacheOrigin: 0.0,
        scrollOffset: 0.0,
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        userScrollDirection: ScrollDirection.idle,
        remainingPaintExtent: 100.0,
        remainingCacheExtent: 100.0,
        precedingScrollExtent: 0.0,
      ),
      parentUsesSize: true,
    );
    expect(mock.constraints.overlap, 80.0);
  });

  testWidgets("SliverPadding passes the overlap to the child if it's negative", (final WidgetTester tester) async {
    final _MockRenderSliver mock = _MockRenderSliver();
    final RenderSliverPadding renderObject = RenderSliverPadding(
      padding: const EdgeInsets.only(top: 20),
    );
    renderObject.child = mock;
    renderObject.layout(const SliverConstraints(
        viewportMainAxisExtent: 100.0,
        overlap: -100.0,
        cacheOrigin: 0.0,
        scrollOffset: 0.0,
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        userScrollDirection: ScrollDirection.idle,
        remainingPaintExtent: 100.0,
        remainingCacheExtent: 100.0,
        precedingScrollExtent: 0.0,
      ),
      parentUsesSize: true,
    );
    expect(mock.constraints.overlap, -100.0);
  });

  testWidgets('SliverPadding passes the paintOrigin of the child on', (final WidgetTester tester) async {
    final _MockRenderSliver mock = _MockRenderSliver();
    final RenderSliverPadding renderObject = RenderSliverPadding(
      padding: const EdgeInsets.only(top: 20),
    );
    renderObject.child = mock;
    renderObject.layout(const SliverConstraints(
        viewportMainAxisExtent: 100.0,
        overlap: 100.0,
        cacheOrigin: 0.0,
        scrollOffset: 0.0,
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        crossAxisExtent: 100.0,
        crossAxisDirection: AxisDirection.right,
        userScrollDirection: ScrollDirection.idle,
        remainingPaintExtent: 100.0,
        remainingCacheExtent: 100.0,
        precedingScrollExtent: 0.0,
      ),
      parentUsesSize: true,
    );
    expect(renderObject.geometry!.paintOrigin, 10.0);
  });
}

void expectIsTextSpan(final Object target, final String text) {
  expect(target, isA<TextSpan>());
  expect((target as TextSpan).text, text);
}
