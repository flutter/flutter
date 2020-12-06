// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Future<void> test(WidgetTester tester, double offset, EdgeInsetsGeometry padding, AxisDirection axisDirection, TextDirection textDirection) {
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

void verify(WidgetTester tester, List<Rect> answerKey) {
  final List<Rect> testAnswers = tester.renderObjectList<RenderBox>(find.byType(SizedBox, skipOffstage: false)).map<Rect>(
    (RenderBox target) {
      final Offset topLeft = target.localToGlobal(Offset.zero);
      final Offset bottomRight = target.localToGlobal(target.size.bottomRight(Offset.zero));
      return Rect.fromPoints(topLeft, bottomRight);
    }
  ).toList();
  expect(testAnswers, equals(answerKey));
}

void main() {
  testWidgets('Viewport+SliverPadding basic test (VISUAL)', (WidgetTester tester) async {
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

  testWidgets('Viewport+SliverPadding basic test (LTR)', (WidgetTester tester) async {
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

  testWidgets('Viewport+SliverPadding basic test (RTL)', (WidgetTester tester) async {
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

  testWidgets('Viewport+SliverPadding hit testing', (WidgetTester tester) async {
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
    expect(result.path.first.target, tester.firstRenderObject<RenderObject>(find.byType(Text)));
    result = tester.hitTestOnBinding(const Offset(10.0, 60.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(100.0, 100.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).skip(1).first);
    result = tester.hitTestOnBinding(const Offset(100.0, 490.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(10.0, 520.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).last);
  });

  testWidgets('Viewport+SliverPadding hit testing up', (WidgetTester tester) async {
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
    expect(result.path.first.target, tester.firstRenderObject<RenderObject>(find.byType(Text)));
    result = tester.hitTestOnBinding(const Offset(10.0, 600.0-60.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(100.0, 600.0-100.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).skip(1).first);
    result = tester.hitTestOnBinding(const Offset(100.0, 600.0-490.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(10.0, 600.0-520.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).last);
  });

  testWidgets('Viewport+SliverPadding hit testing left', (WidgetTester tester) async {
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
    expect(result.path.first.target, tester.firstRenderObject<RenderObject>(find.byType(Text)));
    result = tester.hitTestOnBinding(const Offset(800.0-60.0, 10.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(800.0-100.0, 100.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).skip(1).first);
    result = tester.hitTestOnBinding(const Offset(800.0-490.0, 100.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(800.0-520.0, 10.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).last);
  });

  testWidgets('Viewport+SliverPadding hit testing right', (WidgetTester tester) async {
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
    expect(result.path.first.target, tester.firstRenderObject<RenderObject>(find.byType(Text)));
    result = tester.hitTestOnBinding(const Offset(60.0, 10.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(100.0, 100.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).skip(1).first);
    result = tester.hitTestOnBinding(const Offset(490.0, 100.0));
    expect(result.path.first.target, isA<RenderView>());
    result = tester.hitTestOnBinding(const Offset(520.0, 10.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).last);
  });

  testWidgets('Viewport+SliverPadding no child', (WidgetTester tester) async {
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

  testWidgets('Viewport+SliverPadding changing padding', (WidgetTester tester) async {
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

  testWidgets('Viewport+SliverPadding changing direction', (WidgetTester tester) async {
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
          axisDirection: AxisDirection.down,
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
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).afterPadding, 1.0);
  });

  testWidgets('SliverPadding propagates geometry offset corrections', (WidgetTester tester) async {
    Widget listBuilder(IndexedWidgetBuilder sliverChildBuilder) {
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
        (BuildContext context, int index) {
          return Container(
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
      tester.getRect(find.widgetWithText(Container, '2')),
      const Rect.fromLTRB(0.0, 100.0, 800.0, 300.0),
    );

    // Now item 0 is 400.0px and going back will underflow.
    await tester.pumpWidget(
      listBuilder(
        (BuildContext context, int index) {
          return Container(
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
      tester.getRect(find.widgetWithText(Container, '0')),
      const Rect.fromLTRB(0.0, -200.0, 800.0, 200.0),
    );
  });

  testWidgets('SliverPadding includes preceding padding in the precedingScrollExtent provided to child', (WidgetTester tester) async {
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
            )
          ),
        ]
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
}
