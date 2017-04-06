// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Future<Null> test(WidgetTester tester, double offset, EdgeInsets padding, AxisDirection axisDirection) {
  return tester.pumpWidget(new Viewport(
    offset: new ViewportOffset.fixed(offset),
    axisDirection: axisDirection,
    slivers: <Widget>[
      const SliverToBoxAdapter(child: const SizedBox(width: 400.0, height: 400.0, child: const Text('before'))),
      new SliverPadding(
        padding: padding,
        sliver: const SliverToBoxAdapter(child: const SizedBox(width: 400.0, height: 400.0, child: const Text('padded'))),
      ),
      const SliverToBoxAdapter(child: const SizedBox(width: 400.0, height: 400.0, child: const Text('after'))),
    ],
  ));
}

void verify(WidgetTester tester, List<Rect> answerKey) {
  final List<Rect> testAnswers = tester.renderObjectList<RenderBox>(find.byType(SizedBox)).map<Rect>(
    (RenderBox target) {
      final Point topLeft = target.localToGlobal(Point.origin);
      final Point bottomRight = target.localToGlobal(target.size.bottomRight(Point.origin));
      return new Rect.fromPoints(topLeft, bottomRight);
    }
  ).toList();
  expect(testAnswers, equals(answerKey));
}

void main() {
  testWidgets('Viewport+SliverPadding basic test', (WidgetTester tester) async {
    final EdgeInsets padding = const EdgeInsets.fromLTRB(25.0, 20.0, 15.0, 35.0);
    await test(tester, 0.0, padding, AxisDirection.down);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      new Rect.fromLTWH(0.0, 0.0, 800.0, 400.0),
      new Rect.fromLTWH(25.0, 420.0, 760.0, 400.0),
      new Rect.fromLTWH(0.0, 600.0, 800.0, 400.0),
    ]);

    await test(tester, 200.0, padding, AxisDirection.down);
    verify(tester, <Rect>[
      new Rect.fromLTWH(0.0, -200.0, 800.0, 400.0),
      new Rect.fromLTWH(25.0, 220.0, 760.0, 400.0),
      new Rect.fromLTWH(0.0, 600.0, 800.0, 400.0),
    ]);

    await test(tester, 390.0, padding, AxisDirection.down);
    verify(tester, <Rect>[
      new Rect.fromLTWH(0.0, -390.0, 800.0, 400.0),
      new Rect.fromLTWH(25.0, 30.0, 760.0, 400.0),
      new Rect.fromLTWH(0.0, 465.0, 800.0, 400.0),
    ]);

    await test(tester, 490.0, padding, AxisDirection.down);
    verify(tester, <Rect>[
      new Rect.fromLTWH(0.0, -490.0, 800.0, 400.0),
      new Rect.fromLTWH(25.0, -70.0, 760.0, 400.0),
      new Rect.fromLTWH(0.0, 365.0, 800.0, 400.0),
    ]);

    await test(tester, 10000.0, padding, AxisDirection.down);
    verify(tester, <Rect>[
      new Rect.fromLTWH(0.0, -10000.0, 800.0, 400.0),
      new Rect.fromLTWH(25.0, -9580.0, 760.0, 400.0),
      new Rect.fromLTWH(0.0, -9145.0, 800.0, 400.0),
    ]);
  });

  testWidgets('Viewport+SliverPadding hit testing', (WidgetTester tester) async {
    final EdgeInsets padding = const EdgeInsets.all(30.0);
    await test(tester, 350.0, padding, AxisDirection.down);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      new Rect.fromLTWH(0.0, -350.0, 800.0, 400.0),
      new Rect.fromLTWH(30.0, 80.0, 740.0, 400.0),
      new Rect.fromLTWH(0.0, 510.0, 800.0, 400.0),
    ]);
    HitTestResult result;
    result = tester.hitTestOnBinding(const Point(10.0, 10.0));
    expect(result.path.first.target, tester.firstRenderObject<RenderObject>(find.byType(Text)));
    result = tester.hitTestOnBinding(const Point(10.0, 60.0));
    expect(result.path.first.target, const isInstanceOf<RenderView>());
    result = tester.hitTestOnBinding(const Point(100.0, 100.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).skip(1).first);
    result = tester.hitTestOnBinding(const Point(100.0, 490.0));
    expect(result.path.first.target, const isInstanceOf<RenderView>());
    result = tester.hitTestOnBinding(const Point(10.0, 520.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).last);
  });

  testWidgets('Viewport+SliverPadding hit testing up', (WidgetTester tester) async {
    final EdgeInsets padding = const EdgeInsets.all(30.0);
    await test(tester, 350.0, padding, AxisDirection.up);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      new Rect.fromLTWH(0.0, 600.0+350.0-400.0, 800.0, 400.0),
      new Rect.fromLTWH(30.0, 600.0-80.0-400.0, 740.0, 400.0),
      new Rect.fromLTWH(0.0, 600.0-510.0-400.0, 800.0, 400.0),
    ]);
    HitTestResult result;
    result = tester.hitTestOnBinding(const Point(10.0, 600.0-10.0));
    expect(result.path.first.target, tester.firstRenderObject<RenderObject>(find.byType(Text)));
    result = tester.hitTestOnBinding(const Point(10.0, 600.0-60.0));
    expect(result.path.first.target, const isInstanceOf<RenderView>());
    result = tester.hitTestOnBinding(const Point(100.0, 600.0-100.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).skip(1).first);
    result = tester.hitTestOnBinding(const Point(100.0, 600.0-490.0));
    expect(result.path.first.target, const isInstanceOf<RenderView>());
    result = tester.hitTestOnBinding(const Point(10.0, 600.0-520.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).last);
  });

  testWidgets('Viewport+SliverPadding hit testing left', (WidgetTester tester) async {
    final EdgeInsets padding = const EdgeInsets.all(30.0);
    await test(tester, 350.0, padding, AxisDirection.left);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      new Rect.fromLTWH(800.0+350.0-400.0, 0.0, 400.0, 600.0),
      new Rect.fromLTWH(800.0-80.0-400.0, 30.0, 400.0, 540.0),
      new Rect.fromLTWH(800.0-510.0-400.0, 0.0, 400.0, 600.0),
    ]);
    HitTestResult result;
    result = tester.hitTestOnBinding(const Point(800.0-10.0, 10.0));
    expect(result.path.first.target, tester.firstRenderObject<RenderObject>(find.byType(Text)));
    result = tester.hitTestOnBinding(const Point(800.0-60.0, 10.0));
    expect(result.path.first.target, const isInstanceOf<RenderView>());
    result = tester.hitTestOnBinding(const Point(800.0-100.0, 100.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).skip(1).first);
    result = tester.hitTestOnBinding(const Point(800.0-490.0, 100.0));
    expect(result.path.first.target, const isInstanceOf<RenderView>());
    result = tester.hitTestOnBinding(const Point(800.0-520.0, 10.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).last);
  });

  testWidgets('Viewport+SliverPadding hit testing right', (WidgetTester tester) async {
    final EdgeInsets padding = const EdgeInsets.all(30.0);
    await test(tester, 350.0, padding, AxisDirection.right);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Rect>[
      new Rect.fromLTWH(-350.0, 0.0, 400.0, 600.0),
      new Rect.fromLTWH(80.0, 30.0, 400.0, 540.0),
      new Rect.fromLTWH(510.0, 0.0, 400.0, 600.0),
    ]);
    HitTestResult result;
    result = tester.hitTestOnBinding(const Point(10.0, 10.0));
    expect(result.path.first.target, tester.firstRenderObject<RenderObject>(find.byType(Text)));
    result = tester.hitTestOnBinding(const Point(60.0, 10.0));
    expect(result.path.first.target, const isInstanceOf<RenderView>());
    result = tester.hitTestOnBinding(const Point(100.0, 100.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).skip(1).first);
    result = tester.hitTestOnBinding(const Point(490.0, 100.0));
    expect(result.path.first.target, const isInstanceOf<RenderView>());
    result = tester.hitTestOnBinding(const Point(520.0, 10.0));
    expect(result.path.first.target, tester.renderObjectList<RenderObject>(find.byType(Text)).last);
  });

  testWidgets('Viewport+SliverPadding no child', (WidgetTester tester) async {
    await tester.pumpWidget(new Viewport(
      offset: new ViewportOffset.fixed(0.0),
      slivers: <Widget>[
        const SliverPadding(padding: const EdgeInsets.all(100.0)),
        const SliverToBoxAdapter(child: const SizedBox(width: 400.0, height: 400.0, child: const Text('x'))),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.text('x')).localToGlobal(Point.origin), const Point(0.0, 200.0));
  });

  testWidgets('Viewport+SliverPadding changing padding', (WidgetTester tester) async {
    await tester.pumpWidget(new Viewport(
      axisDirection: AxisDirection.left,
      offset: new ViewportOffset.fixed(0.0),
      slivers: <Widget>[
        const SliverPadding(padding: const EdgeInsets.fromLTRB(90.0, 1.0, 110.0, 2.0)),
        const SliverToBoxAdapter(child: const SizedBox(width: 201.0, child: const Text('x'))),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.text('x')).localToGlobal(Point.origin), const Point(399.0, 0.0));
    await tester.pumpWidget(new Viewport(
      axisDirection: AxisDirection.left,
      offset: new ViewportOffset.fixed(0.0),
      slivers: <Widget>[
        const SliverPadding(padding: const EdgeInsets.fromLTRB(110.0, 1.0, 80.0, 2.0)),
        const SliverToBoxAdapter(child: const SizedBox(width: 201.0, child: const Text('x'))),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.text('x')).localToGlobal(Point.origin), const Point(409.0, 0.0));
  });

  testWidgets('Viewport+SliverPadding changing direction', (WidgetTester tester) async {
    await tester.pumpWidget(new Viewport(
      axisDirection: AxisDirection.up,
      offset: new ViewportOffset.fixed(0.0),
      slivers: <Widget>[
        const SliverPadding(padding: const EdgeInsets.fromLTRB(1.0, 2.0, 4.0, 8.0)),
      ],
    ));
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).afterPadding, 2.0);
    await tester.pumpWidget(new Viewport(
      axisDirection: AxisDirection.down,
      offset: new ViewportOffset.fixed(0.0),
      slivers: <Widget>[
        const SliverPadding(padding: const EdgeInsets.fromLTRB(1.0, 2.0, 4.0, 8.0)),
      ],
    ));
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).afterPadding, 8.0);
    await tester.pumpWidget(new Viewport(
      axisDirection: AxisDirection.right,
      offset: new ViewportOffset.fixed(0.0),
      slivers: <Widget>[
        const SliverPadding(padding: const EdgeInsets.fromLTRB(1.0, 2.0, 4.0, 8.0)),
      ],
    ));
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).afterPadding, 4.0);
    await tester.pumpWidget(new Viewport(
      axisDirection: AxisDirection.left,
      offset: new ViewportOffset.fixed(0.0),
      slivers: <Widget>[
        const SliverPadding(padding: const EdgeInsets.fromLTRB(1.0, 2.0, 4.0, 8.0)),
      ],
    ));
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).afterPadding, 1.0);
    await tester.pumpWidget(new Viewport(
      axisDirection: AxisDirection.left,
      offset: new ViewportOffset.fixed(99999.9),
      slivers: <Widget>[
        const SliverPadding(padding: const EdgeInsets.fromLTRB(1.0, 2.0, 4.0, 8.0)),
      ],
    ));
    expect(tester.renderObject<RenderSliverPadding>(find.byType(SliverPadding)).afterPadding, 1.0);
  });
}
