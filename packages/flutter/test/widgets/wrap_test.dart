// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void verify(WidgetTester tester, List<Point> answerKey) {
  List<Point> testAnswers = tester.renderObjectList/*<RenderBox>*/(find.byType(SizedBox)).map/*<Point>*/(
    (RenderBox target) => target.localToGlobal(const Point(0.0, 0.0))
  ).toList();
  expect(testAnswers, equals(answerKey));
}
 
void main() {
  testWidgets('Basic Wrap test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Wrap(
        mainAxisAlignment: WrapAlignment.start,
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
        mainAxisAlignment: WrapAlignment.center,
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
        mainAxisAlignment: WrapAlignment.end,
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
        mainAxisAlignment: WrapAlignment.start,
        crossAxisAlignment: WrapAlignment.start,
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
        mainAxisAlignment: WrapAlignment.start,
        crossAxisAlignment: WrapAlignment.center,
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
        mainAxisAlignment: WrapAlignment.start,
        crossAxisAlignment: WrapAlignment.end,
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

  testWidgets('Shrink-wrapping Wrap test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Align(
        alignment: FractionalOffset.topLeft,
        child: new Wrap(
          mainAxisAlignment: WrapAlignment.end,
          crossAxisAlignment: WrapAlignment.end,
          children: <Widget>[
            new SizedBox(width: 100.0, height: 10.0),
            new SizedBox(width: 200.0, height: 20.0),
            new SizedBox(width: 300.0, height: 30.0),
            new SizedBox(width: 400.0, height: 40.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject/*<RenderBox>*/(find.byType(Wrap)).size, equals(const Size(800.0, 70.0)));
    verify(tester, <Point>[
      const Point(200.0, 20.0),
      const Point(300.0, 10.0),
      const Point(500.0, 0.0),
      const Point(400.0, 30.0),
    ]);

    await tester.pumpWidget(
      new Align(
        alignment: FractionalOffset.topLeft,
        child: new Wrap(
          mainAxisAlignment: WrapAlignment.end,
          crossAxisAlignment: WrapAlignment.end,
          children: <Widget>[
            new SizedBox(width: 400.0, height: 40.0),
            new SizedBox(width: 300.0, height: 30.0),
            new SizedBox(width: 200.0, height: 20.0),
            new SizedBox(width: 100.0, height: 10.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject/*<RenderBox>*/(find.byType(Wrap)).size, equals(const Size(800.0, 60.0)));
    verify(tester, <Point>[
      const Point(100.0, 0.0),
      const Point(500.0, 10.0),
      const Point(500.0, 40.0),
      const Point(700.0, 50.0),
    ]);
  });

  testWidgets('Wrap spacing test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Align(
        alignment: FractionalOffset.topLeft,
        child: new Wrap(
          spacing: 10.0,
          mainAxisAlignment: WrapAlignment.start,
          crossAxisAlignment: WrapAlignment.start,
          children: <Widget>[
            new SizedBox(width: 500.0, height: 10.0),
            new SizedBox(width: 500.0, height: 20.0),
            new SizedBox(width: 500.0, height: 30.0),
            new SizedBox(width: 500.0, height: 40.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject/*<RenderBox>*/(find.byType(Wrap)).size, equals(const Size(800.0, 130.0)));
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
          mainAxisAlignment: WrapAlignment.start,
          crossAxisAlignment: WrapAlignment.start,
          children: <Widget>[
            new SizedBox(width: 10.0, height: 250.0),
            new SizedBox(width: 20.0, height: 250.0),
            new SizedBox(width: 30.0, height: 250.0),
            new SizedBox(width: 40.0, height: 250.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject/*<RenderBox>*/(find.byType(Wrap)).size, equals(const Size(70.0, 600.0)));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(0.0, 250.0),
      const Point(30.0, 0.0),
      const Point(30.0, 250.0),
    ]);
  });
}
