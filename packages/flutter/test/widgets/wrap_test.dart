// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';

void verify(WidgetTester tester, List<Point> answerKey) {
  final List<Point> testAnswers = tester.renderObjectList<RenderBox>(find.byType(SizedBox)).map<Point>(
    (RenderBox target) => target.localToGlobal(Point.origin)
  ).toList();
  expect(testAnswers, equals(answerKey));
}

void main() {
  testWidgets('Basic Wrap test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Wrap(
        alignment: WrapAlignment.start,
        children: <Widget>[
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
        ],
      ),
    );
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(300.0, 0.0),
      const Point(0.0, 100.0),
      const Point(300.0, 100.0),
    ]);

    await tester.pumpWidget(
      new Wrap(
        alignment: WrapAlignment.center,
        children: <Widget>[
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
        ],
      ),
    );
    verify(tester, <Point>[
      const Point(100.0, 0.0),
      const Point(400.0, 0.0),
      const Point(100.0, 100.0),
      const Point(400.0, 100.0),
    ]);

    await tester.pumpWidget(
      new Wrap(
        alignment: WrapAlignment.end,
        children: <Widget>[
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
        ],
      ),
    );
    verify(tester, <Point>[
      const Point(200.0, 0.0),
      const Point(500.0, 0.0),
      const Point(200.0, 100.0),
      const Point(500.0, 100.0),
    ]);

    await tester.pumpWidget(
      new Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: <Widget>[
          new SizedBox(width: 300.0, height: 50.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 50.0),
        ],
      ),
    );
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(300.0, 0.0),
      const Point(0.0, 100.0),
      const Point(300.0, 100.0),
    ]);

    await tester.pumpWidget(
      new Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          new SizedBox(width: 300.0, height: 50.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 50.0),
        ],
      ),
    );
    verify(tester, <Point>[
      const Point(0.0, 25.0),
      const Point(300.0, 0.0),
      const Point(0.0, 100.0),
      const Point(300.0, 125.0),
    ]);

    await tester.pumpWidget(
      new Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: <Widget>[
          new SizedBox(width: 300.0, height: 50.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 100.0),
          new SizedBox(width: 300.0, height: 50.0),
        ],
      ),
    );
    verify(tester, <Point>[
      const Point(0.0, 50.0),
      const Point(300.0, 0.0),
      const Point(0.0, 100.0),
      const Point(300.0, 150.0),
    ]);

  });

  testWidgets('Empty wrap', (WidgetTester tester) async {
    await tester.pumpWidget(new Center(child: new Wrap()));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(Size.zero));
  });

  testWidgets('Wrap alignment', (WidgetTester tester) async {
    await tester.pumpWidget(new Wrap(
      alignment: WrapAlignment.center,
      spacing: 5.0,
      children: <Widget>[
        new SizedBox(width: 100.0, height: 10.0),
        new SizedBox(width: 200.0, height: 20.0),
        new SizedBox(width: 300.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Point>[
      const Point(95.0, 0.0),
      const Point(200.0, 0.0),
      const Point(405.0, 0.0),
    ]);

    await tester.pumpWidget(new Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 5.0,
      children: <Widget>[
        new SizedBox(width: 100.0, height: 10.0),
        new SizedBox(width: 200.0, height: 20.0),
        new SizedBox(width: 300.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(200.0, 0.0),
      const Point(500.0, 0.0),
    ]);

    await tester.pumpWidget(new Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: 5.0,
      children: <Widget>[
        new SizedBox(width: 100.0, height: 10.0),
        new SizedBox(width: 200.0, height: 20.0),
        new SizedBox(width: 310.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Point>[
      const Point(30.0, 0.0),
      const Point(195.0, 0.0),
      const Point(460.0, 0.0),
    ]);

    await tester.pumpWidget(new Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 5.0,
      children: <Widget>[
        new SizedBox(width: 100.0, height: 10.0),
        new SizedBox(width: 200.0, height: 20.0),
        new SizedBox(width: 310.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Point>[
      const Point(45.0, 0.0),
      const Point(195.0, 0.0),
      const Point(445.0, 0.0),
    ]);
  });

  testWidgets('Wrap runAlignment', (WidgetTester tester) async {
    await tester.pumpWidget(new Wrap(
      runAlignment: WrapAlignment.center,
      runSpacing: 5.0,
      children: <Widget>[
        new SizedBox(width: 100.0, height: 10.0),
        new SizedBox(width: 200.0, height: 20.0),
        new SizedBox(width: 300.0, height: 30.0),
        new SizedBox(width: 400.0, height: 40.0),
        new SizedBox(width: 500.0, height: 60.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Point>[
      const Point(0.0, 230.0),
      const Point(100.0, 230.0),
      const Point(300.0, 230.0),
      const Point(0.0, 265.0),
      const Point(0.0, 310.0),
    ]);

    await tester.pumpWidget(new Wrap(
      runAlignment: WrapAlignment.spaceBetween,
      runSpacing: 5.0,
      children: <Widget>[
        new SizedBox(width: 100.0, height: 10.0),
        new SizedBox(width: 200.0, height: 20.0),
        new SizedBox(width: 300.0, height: 30.0),
        new SizedBox(width: 400.0, height: 40.0),
        new SizedBox(width: 500.0, height: 60.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(100.0, 0.0),
      const Point(300.0, 0.0),
      const Point(0.0, 265.0),
      const Point(0.0, 540.0),
    ]);

    await tester.pumpWidget(new Wrap(
      runAlignment: WrapAlignment.spaceAround,
      runSpacing: 5.0,
      children: <Widget>[
        new SizedBox(width: 100.0, height: 10.0),
        new SizedBox(width: 200.0, height: 20.0),
        new SizedBox(width: 300.0, height: 30.0),
        new SizedBox(width: 400.0, height: 40.0),
        new SizedBox(width: 500.0, height: 70.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Point>[
      const Point(0.0, 75.0),
      const Point(100.0, 75.0),
      const Point(300.0, 75.0),
      const Point(0.0, 260.0),
      const Point(0.0, 455.0),
    ]);

    await tester.pumpWidget(new Wrap(
      runAlignment: WrapAlignment.spaceEvenly,
      runSpacing: 5.0,
      children: <Widget>[
        new SizedBox(width: 100.0, height: 10.0),
        new SizedBox(width: 200.0, height: 20.0),
        new SizedBox(width: 300.0, height: 30.0),
        new SizedBox(width: 400.0, height: 40.0),
        new SizedBox(width: 500.0, height: 60.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Point>[
      const Point(0.0, 115.0),
      const Point(100.0, 115.0),
      const Point(300.0, 115.0),
      const Point(0.0, 265.0),
      const Point(0.0, 425.0),
    ]);

  });

  testWidgets('Shrink-wrapping Wrap test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Align(
        alignment: FractionalOffset.topLeft,
        child: new Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: <Widget>[
            new SizedBox(width: 100.0, height: 10.0),
            new SizedBox(width: 200.0, height: 20.0),
            new SizedBox(width: 300.0, height: 30.0),
            new SizedBox(width: 400.0, height: 40.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(600.0, 70.0)));
    verify(tester, <Point>[
      const Point(0.0, 20.0),
      const Point(100.0, 10.0),
      const Point(300.0, 0.0),
      const Point(200.0, 30.0),
    ]);

    await tester.pumpWidget(
      new Align(
        alignment: FractionalOffset.topLeft,
        child: new Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: <Widget>[
            new SizedBox(width: 400.0, height: 40.0),
            new SizedBox(width: 300.0, height: 30.0),
            new SizedBox(width: 200.0, height: 20.0),
            new SizedBox(width: 100.0, height: 10.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(700.0, 60.0)));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(400.0, 10.0),
      const Point(400.0, 40.0),
      const Point(600.0, 50.0),
    ]);
  });

  testWidgets('Wrap spacing test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Align(
        alignment: FractionalOffset.topLeft,
        child: new Wrap(
          runSpacing: 10.0,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: <Widget>[
            new SizedBox(width: 500.0, height: 10.0),
            new SizedBox(width: 500.0, height: 20.0),
            new SizedBox(width: 500.0, height: 30.0),
            new SizedBox(width: 500.0, height: 40.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(500.0, 130.0)));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(0.0, 20.0),
      const Point(0.0, 50.0),
      const Point(0.0, 90.0),
    ]);
  });

  testWidgets('Vertical Wrap test with spacing', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Align(
        alignment: FractionalOffset.topLeft,
        child: new Wrap(
          direction: Axis.vertical,
          spacing: 10.0,
          runSpacing: 15.0,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: <Widget>[
            new SizedBox(width: 10.0, height: 250.0),
            new SizedBox(width: 20.0, height: 250.0),
            new SizedBox(width: 30.0, height: 250.0),
            new SizedBox(width: 40.0, height: 250.0),
            new SizedBox(width: 50.0, height: 250.0),
            new SizedBox(width: 60.0, height: 250.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(150.0, 510.0)));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(0.0, 260.0),
      const Point(35.0, 0.0),
      const Point(35.0, 260.0),
      const Point(90.0, 0.0),
      const Point(90.0, 260.0),
    ]);

    await tester.pumpWidget(
      new Align(
        alignment: FractionalOffset.topLeft,
        child: new Wrap(
          direction: Axis.horizontal,
          spacing: 12.0,
          runSpacing: 8.0,
          children: <Widget>[
            new SizedBox(width: 10.0, height: 250.0),
            new SizedBox(width: 20.0, height: 250.0),
            new SizedBox(width: 30.0, height: 250.0),
            new SizedBox(width: 40.0, height: 250.0),
            new SizedBox(width: 50.0, height: 250.0),
            new SizedBox(width: 60.0, height: 250.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(270.0, 258.0)));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(22.0, 0.0),
      const Point(54.0, 0.0),
      const Point(96.0, 0.0),
      const Point(148.0, 0.0),
      const Point(210.0, 0.0),
    ]);
  });

  testWidgets('Visual overflow generates a clip', (WidgetTester tester) async {
    await tester.pumpWidget(new Wrap(
      children: <Widget>[
        new SizedBox(width: 500.0, height: 500.0),
      ],
    ));

    expect(tester.renderObject<RenderBox>(find.byType(Wrap)), isNot(paints..clipRect()));

    await tester.pumpWidget(new Wrap(
      children: <Widget>[
        new SizedBox(width: 500.0, height: 500.0),
        new SizedBox(width: 500.0, height: 500.0),
      ],
    ));

    expect(tester.renderObject<RenderBox>(find.byType(Wrap)), paints..clipRect());
  });

  testWidgets('Hit test children in wrap', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(new Wrap(
      spacing: 10.0,
      runSpacing: 15.0,
      children: <Widget>[
        new SizedBox(width: 200.0, height: 300.0),
        new SizedBox(width: 200.0, height: 300.0),
        new SizedBox(width: 200.0, height: 300.0),
        new SizedBox(width: 200.0, height: 300.0),
        new SizedBox(
          width: 200.0,
          height: 300.0,
          child: new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () { log.add('hit'); },
          ),
        ),
      ],
    ));

    await tester.tapAt(const Point(209.0, 314.0));
    expect(log, isEmpty);

    await tester.tapAt(const Point(211.0, 314.0));
    expect(log, isEmpty);

    await tester.tapAt(const Point(209.0, 316.0));
    expect(log, isEmpty);

    await tester.tapAt(const Point(211.0, 316.0));
    expect(log, equals(<String>['hit']));
  });

  testWidgets('RenderWrap toStringShallow control test', (WidgetTester tester) async {
    await tester.pumpWidget(new Wrap());

    final RenderBox wrap = tester.renderObject(find.byType(Wrap));
    expect(wrap.toStringShallow(), hasOneLineDescription);
  });

  testWidgets('RenderWrap toString control test', (WidgetTester tester) async {
    await tester.pumpWidget(new Wrap(
      direction: Axis.vertical,
      runSpacing: 7.0,
      children: <Widget>[
        new SizedBox(width: 500.0, height: 400.0),
        new SizedBox(width: 500.0, height: 400.0),
        new SizedBox(width: 500.0, height: 400.0),
        new SizedBox(width: 500.0, height: 400.0),
      ],
    ));

    final RenderBox wrap = tester.renderObject(find.byType(Wrap));
    final double width = wrap.getMinIntrinsicWidth(600.0);
    expect(width, equals(2021));
  });

  testWidgets('Wrap baseline control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Center(
        child: new Baseline(
          baseline: 180.0,
          baselineType: TextBaseline.alphabetic,
          child: new DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'Ahem',
              fontSize: 100.0,
            ),
            child: new Wrap(
              children: <Widget>[
                new Text('X'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.text('X')).size, const Size(100.0, 100.0));
    expect(tester.renderObject<RenderBox>(find.byType(Baseline)).size, const Size(100.0, 200.0));
  });
}
