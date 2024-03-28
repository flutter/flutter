// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void verify(WidgetTester tester, List<Offset> answerKey) {
  final List<Offset> testAnswers = tester.renderObjectList<RenderBox>(find.byType(SizedBox)).map<Offset>(
    (RenderBox target) => target.localToGlobal(Offset.zero),
  ).toList();
  expect(testAnswers, equals(answerKey));
}

void verifySize(WidgetTester tester, List<Size> answerKey) {
  final Iterable<Size> testAnswers = tester.renderObjectList<RenderBox>(find.byType(SizedBox)).map<Size>(
    (RenderBox target) => target.size,
  );
  expect(testAnswers, equals(answerKey));
}

void main() {
  testWidgets('Basic Wrap test (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Wrap(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      Offset.zero,
      const Offset(300.0, 0.0),
      const Offset(0.0, 100.0),
      const Offset(300.0, 100.0),
    ]);

    await tester.pumpWidget(
      const Wrap(
        alignment: WrapAlignment.center,
        textDirection: TextDirection.ltr,
        children: <Widget>[
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      const Offset(100.0, 0.0),
      const Offset(400.0, 0.0),
      const Offset(100.0, 100.0),
      const Offset(400.0, 100.0),
    ]);

    await tester.pumpWidget(
      const Wrap(
        alignment: WrapAlignment.end,
        textDirection: TextDirection.ltr,
        children: <Widget>[
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      const Offset(200.0, 0.0),
      const Offset(500.0, 0.0),
      const Offset(200.0, 100.0),
      const Offset(500.0, 100.0),
    ]);

    await tester.pumpWidget(
      const Wrap(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          SizedBox(width: 300.0, height: 50.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 50.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      Offset.zero,
      const Offset(300.0, 0.0),
      const Offset(0.0, 100.0),
      const Offset(300.0, 100.0),
    ]);

    await tester.pumpWidget(
      const Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        textDirection: TextDirection.ltr,
        children: <Widget>[
          SizedBox(width: 300.0, height: 50.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 50.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      const Offset(0.0, 25.0),
      const Offset(300.0, 0.0),
      const Offset(0.0, 100.0),
      const Offset(300.0, 125.0),
    ]);

    await tester.pumpWidget(
      const Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        textDirection: TextDirection.ltr,
        children: <Widget>[
          SizedBox(width: 300.0, height: 50.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 50.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      const Offset(0.0, 50.0),
      const Offset(300.0, 0.0),
      const Offset(0.0, 100.0),
      const Offset(300.0, 150.0),
    ]);

  });

  testWidgets('Basic Wrap test (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Wrap(
        textDirection: TextDirection.rtl,
        children: <Widget>[
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      const Offset(500.0, 0.0),
      const Offset(200.0, 0.0),
      const Offset(500.0, 100.0),
      const Offset(200.0, 100.0),
    ]);

    await tester.pumpWidget(
      const Wrap(
        alignment: WrapAlignment.center,
        textDirection: TextDirection.rtl,
        children: <Widget>[
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      const Offset(400.0, 0.0),
      const Offset(100.0, 0.0),
      const Offset(400.0, 100.0),
      const Offset(100.0, 100.0),
    ]);

    await tester.pumpWidget(
      const Wrap(
        alignment: WrapAlignment.end,
        textDirection: TextDirection.rtl,
        children: <Widget>[
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      const Offset(300.0, 0.0),
      Offset.zero,
      const Offset(300.0, 100.0),
      const Offset(0.0, 100.0),
    ]);

    await tester.pumpWidget(
      const Wrap(
        textDirection: TextDirection.ltr,
        verticalDirection: VerticalDirection.up,
        children: <Widget>[
          SizedBox(width: 300.0, height: 50.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 50.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      const Offset(0.0, 550.0),
      const Offset(300.0, 500.0),
      const Offset(0.0, 400.0),
      const Offset(300.0, 450.0),
    ]);

    await tester.pumpWidget(
      const Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        textDirection: TextDirection.ltr,
        verticalDirection: VerticalDirection.up,
        children: <Widget>[
          SizedBox(width: 300.0, height: 50.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 50.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      const Offset(0.0, 525.0),
      const Offset(300.0, 500.0),
      const Offset(0.0, 400.0),
      const Offset(300.0, 425.0),
    ]);

    await tester.pumpWidget(
      const Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        textDirection: TextDirection.ltr,
        verticalDirection: VerticalDirection.up,
        children: <Widget>[
          SizedBox(width: 300.0, height: 50.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 100.0),
          SizedBox(width: 300.0, height: 50.0),
        ],
      ),
    );
    verify(tester, <Offset>[
      const Offset(0.0, 500.0),
      const Offset(300.0, 500.0),
      const Offset(0.0, 400.0),
      const Offset(300.0, 400.0),
    ]);

  });

  testWidgets('Empty wrap', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(child: Wrap(alignment: WrapAlignment.center)));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(Size.zero));
  });

  testWidgets('Wrap alignment (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(const Wrap(
      alignment: WrapAlignment.center,
      spacing: 5.0,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(95.0, 0.0),
      const Offset(200.0, 0.0),
      const Offset(405.0, 0.0),
    ]);

    await tester.pumpWidget(const Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 5.0,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      Offset.zero,
      const Offset(200.0, 0.0),
      const Offset(500.0, 0.0),
    ]);

    await tester.pumpWidget(const Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: 5.0,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 310.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(30.0, 0.0),
      const Offset(195.0, 0.0),
      const Offset(460.0, 0.0),
    ]);

    await tester.pumpWidget(const Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 5.0,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 310.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(45.0, 0.0),
      const Offset(195.0, 0.0),
      const Offset(445.0, 0.0),
    ]);
  });

  testWidgets('Wrap alignment (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(const Wrap(
      alignment: WrapAlignment.center,
      spacing: 5.0,
      textDirection: TextDirection.rtl,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(605.0, 0.0),
      const Offset(400.0, 0.0),
      const Offset(95.0, 0.0),
    ]);

    await tester.pumpWidget(const Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 5.0,
      textDirection: TextDirection.rtl,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(700.0, 0.0),
      const Offset(400.0, 0.0),
      Offset.zero,
    ]);

    await tester.pumpWidget(const Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: 5.0,
      textDirection: TextDirection.rtl,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 310.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(670.0, 0.0),
      const Offset(405.0, 0.0),
      const Offset(30.0, 0.0),
    ]);

    await tester.pumpWidget(const Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 5.0,
      textDirection: TextDirection.rtl,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 310.0, height: 30.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(655.0, 0.0),
      const Offset(405.0, 0.0),
      const Offset(45.0, 0.0),
    ]);
  });

  testWidgets('Wrap runAlignment (DOWN)', (WidgetTester tester) async {
    await tester.pumpWidget(const Wrap(
      runAlignment: WrapAlignment.center,
      runSpacing: 5.0,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
        SizedBox(width: 400.0, height: 40.0),
        SizedBox(width: 500.0, height: 60.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 230.0),
      const Offset(100.0, 230.0),
      const Offset(300.0, 230.0),
      const Offset(0.0, 265.0),
      const Offset(0.0, 310.0),
    ]);

    await tester.pumpWidget(const Wrap(
      runAlignment: WrapAlignment.spaceBetween,
      runSpacing: 5.0,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
        SizedBox(width: 400.0, height: 40.0),
        SizedBox(width: 500.0, height: 60.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      Offset.zero,
      const Offset(100.0, 0.0),
      const Offset(300.0, 0.0),
      const Offset(0.0, 265.0),
      const Offset(0.0, 540.0),
    ]);

    await tester.pumpWidget(const Wrap(
      runAlignment: WrapAlignment.spaceAround,
      runSpacing: 5.0,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
        SizedBox(width: 400.0, height: 40.0),
        SizedBox(width: 500.0, height: 70.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 75.0),
      const Offset(100.0, 75.0),
      const Offset(300.0, 75.0),
      const Offset(0.0, 260.0),
      const Offset(0.0, 455.0),
    ]);

    await tester.pumpWidget(const Wrap(
      runAlignment: WrapAlignment.spaceEvenly,
      runSpacing: 5.0,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
        SizedBox(width: 400.0, height: 40.0),
        SizedBox(width: 500.0, height: 60.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 115.0),
      const Offset(100.0, 115.0),
      const Offset(300.0, 115.0),
      const Offset(0.0, 265.0),
      const Offset(0.0, 425.0),
    ]);

  });

  testWidgets('Wrap runAlignment (UP)', (WidgetTester tester) async {
    await tester.pumpWidget(const Wrap(
      runAlignment: WrapAlignment.center,
      runSpacing: 5.0,
      textDirection: TextDirection.ltr,
      verticalDirection: VerticalDirection.up,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
        SizedBox(width: 400.0, height: 40.0),
        SizedBox(width: 500.0, height: 60.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 360.0),
      const Offset(100.0, 350.0),
      const Offset(300.0, 340.0),
      const Offset(0.0, 295.0),
      const Offset(0.0, 230.0),
    ]);

    await tester.pumpWidget(const Wrap(
      runAlignment: WrapAlignment.spaceBetween,
      runSpacing: 5.0,
      textDirection: TextDirection.ltr,
      verticalDirection: VerticalDirection.up,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
        SizedBox(width: 400.0, height: 40.0),
        SizedBox(width: 500.0, height: 60.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 590.0),
      const Offset(100.0, 580.0),
      const Offset(300.0, 570.0),
      const Offset(0.0, 295.0),
      Offset.zero,
    ]);

    await tester.pumpWidget(const Wrap(
      runAlignment: WrapAlignment.spaceAround,
      runSpacing: 5.0,
      textDirection: TextDirection.ltr,
      verticalDirection: VerticalDirection.up,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
        SizedBox(width: 400.0, height: 40.0),
        SizedBox(width: 500.0, height: 70.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 515.0),
      const Offset(100.0, 505.0),
      const Offset(300.0, 495.0),
      const Offset(0.0, 300.0),
      const Offset(0.0, 75.0),
    ]);

    await tester.pumpWidget(const Wrap(
      runAlignment: WrapAlignment.spaceEvenly,
      runSpacing: 5.0,
      textDirection: TextDirection.ltr,
      verticalDirection: VerticalDirection.up,
      children: <Widget>[
        SizedBox(width: 100.0, height: 10.0),
        SizedBox(width: 200.0, height: 20.0),
        SizedBox(width: 300.0, height: 30.0),
        SizedBox(width: 400.0, height: 40.0),
        SizedBox(width: 500.0, height: 60.0),
      ],
    ));
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 475.0),
      const Offset(100.0, 465.0),
      const Offset(300.0, 455.0),
      const Offset(0.0, 295.0),
      const Offset(0.0, 115.0),
    ]);

  });

  testWidgets('Shrink-wrapping Wrap test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          textDirection: TextDirection.ltr,
          children: <Widget>[
            SizedBox(width: 100.0, height: 10.0),
            SizedBox(width: 200.0, height: 20.0),
            SizedBox(width: 300.0, height: 30.0),
            SizedBox(width: 400.0, height: 40.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(600.0, 70.0)));
    verify(tester, <Offset>[
      const Offset(0.0, 20.0),
      const Offset(100.0, 10.0),
      const Offset(300.0, 0.0),
      const Offset(200.0, 30.0),
    ]);

    await tester.pumpWidget(
      const Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          textDirection: TextDirection.ltr,
          children: <Widget>[
            SizedBox(width: 400.0, height: 40.0),
            SizedBox(width: 300.0, height: 30.0),
            SizedBox(width: 200.0, height: 20.0),
            SizedBox(width: 100.0, height: 10.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(700.0, 60.0)));
    verify(tester, <Offset>[
      Offset.zero,
      const Offset(400.0, 10.0),
      const Offset(400.0, 40.0),
      const Offset(600.0, 50.0),
    ]);
  });

  testWidgets('Wrap spacing test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          runSpacing: 10.0,
          textDirection: TextDirection.ltr,
          children: <Widget>[
            SizedBox(width: 500.0, height: 10.0),
            SizedBox(width: 500.0, height: 20.0),
            SizedBox(width: 500.0, height: 30.0),
            SizedBox(width: 500.0, height: 40.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(500.0, 130.0)));
    verify(tester, <Offset>[
      Offset.zero,
      const Offset(0.0, 20.0),
      const Offset(0.0, 50.0),
      const Offset(0.0, 90.0),
    ]);
  });

  testWidgets('Vertical Wrap test with spacing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          direction: Axis.vertical,
          spacing: 10.0,
          runSpacing: 15.0,
          textDirection: TextDirection.ltr,
          children: <Widget>[
            SizedBox(width: 10.0, height: 250.0),
            SizedBox(width: 20.0, height: 250.0),
            SizedBox(width: 30.0, height: 250.0),
            SizedBox(width: 40.0, height: 250.0),
            SizedBox(width: 50.0, height: 250.0),
            SizedBox(width: 60.0, height: 250.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(150.0, 510.0)));
    verify(tester, <Offset>[
      Offset.zero,
      const Offset(0.0, 260.0),
      const Offset(35.0, 0.0),
      const Offset(35.0, 260.0),
      const Offset(90.0, 0.0),
      const Offset(90.0, 260.0),
    ]);

    await tester.pumpWidget(
      const Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          spacing: 12.0,
          runSpacing: 8.0,
          textDirection: TextDirection.ltr,
          children: <Widget>[
            SizedBox(width: 10.0, height: 250.0),
            SizedBox(width: 20.0, height: 250.0),
            SizedBox(width: 30.0, height: 250.0),
            SizedBox(width: 40.0, height: 250.0),
            SizedBox(width: 50.0, height: 250.0),
            SizedBox(width: 60.0, height: 250.0),
          ],
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(270.0, 250.0)));
    verify(tester, <Offset>[
      Offset.zero,
      const Offset(22.0, 0.0),
      const Offset(54.0, 0.0),
      const Offset(96.0, 0.0),
      const Offset(148.0, 0.0),
      const Offset(210.0, 0.0),
    ]);
  });

  testWidgets('Visual overflow generates a clip', (WidgetTester tester) async {
    await tester.pumpWidget(const Wrap(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(width: 500.0, height: 500.0),
      ],
    ));

    expect(tester.renderObject<RenderBox>(find.byType(Wrap)), isNot(paints..clipRect()));

    await tester.pumpWidget(const Wrap(
      textDirection: TextDirection.ltr,
      clipBehavior: Clip.hardEdge,
      children: <Widget>[
        SizedBox(width: 500.0, height: 500.0),
        SizedBox(width: 500.0, height: 500.0),
      ],
    ));

    expect(tester.renderObject<RenderBox>(find.byType(Wrap)), paints..clipRect());
  });

  testWidgets('Hit test children in wrap', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(Wrap(
      spacing: 10.0,
      runSpacing: 15.0,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        const SizedBox(width: 200.0, height: 300.0),
        const SizedBox(width: 200.0, height: 300.0),
        const SizedBox(width: 200.0, height: 300.0),
        const SizedBox(width: 200.0, height: 300.0),
        SizedBox(
          width: 200.0,
          height: 300.0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () { log.add('hit'); },
          ),
        ),
      ],
    ));

    await tester.tapAt(const Offset(209.0, 314.0));
    expect(log, isEmpty);

    await tester.tapAt(const Offset(211.0, 314.0));
    expect(log, isEmpty);

    await tester.tapAt(const Offset(209.0, 316.0));
    expect(log, isEmpty);

    await tester.tapAt(const Offset(211.0, 316.0));
    expect(log, equals(<String>['hit']));
  });

  testWidgets('RenderWrap toStringShallow control test', (WidgetTester tester) async {
    await tester.pumpWidget(const Wrap(alignment: WrapAlignment.center));

    final RenderBox wrap = tester.renderObject(find.byType(Wrap));
    expect(wrap.toStringShallow(), hasOneLineDescription);
  });

  testWidgets('RenderWrap toString control test', (WidgetTester tester) async {
    await tester.pumpWidget(const Wrap(
      direction: Axis.vertical,
      runSpacing: 7.0,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(width: 500.0, height: 400.0),
        SizedBox(width: 500.0, height: 400.0),
        SizedBox(width: 500.0, height: 400.0),
        SizedBox(width: 500.0, height: 400.0),
      ],
    ));

    final RenderBox wrap = tester.renderObject(find.byType(Wrap));
    final double width = wrap.getMinIntrinsicWidth(600.0);
    expect(width, equals(2021));
  });

  testWidgets('Wrap baseline control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: Baseline(
          baseline: 175.0,
          baselineType: TextBaseline.alphabetic,
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'FlutterTest',
              fontSize: 100.0,
            ),
            child: Wrap(
              textDirection: TextDirection.ltr,
              children: <Widget>[
                Text('X', textDirection: TextDirection.ltr),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.text('X')).size, const Size(100.0, 100.0));
    expect(
      tester.renderObject<RenderBox>(find.byType(Baseline)).size,
      const Size(100.0, 200.0),
    );
  });

  testWidgets('Spacing with slight overflow', (WidgetTester tester) async {
    await tester.pumpWidget(const Wrap(
      textDirection: TextDirection.ltr,
      spacing: 10.0,
      runSpacing: 10.0,
      children: <Widget>[
        SizedBox(width: 200.0, height: 10.0),
        SizedBox(width: 200.0, height: 10.0),
        SizedBox(width: 200.0, height: 10.0),
        SizedBox(width: 171.0, height: 10.0),
      ],
    ));

    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Offset>[
      Offset.zero,
      const Offset(210.0, 0.0),
      const Offset(420.0, 0.0),
      const Offset(0.0, 20.0),
    ]);
  });

  testWidgets('Object exactly matches container width', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Column(
        children: <Widget>[
          Wrap(
            textDirection: TextDirection.ltr,
            spacing: 10.0,
            runSpacing: 10.0,
            children: <Widget>[
              SizedBox(width: 800.0, height: 10.0),
            ],
          ),
        ],
      ),
    );

    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 10.0)));
    verify(tester, <Offset>[Offset.zero]);

    await tester.pumpWidget(
      const Column(
        children: <Widget>[
          Wrap(
            textDirection: TextDirection.ltr,
            spacing: 10.0,
            runSpacing: 10.0,
            children: <Widget>[
              SizedBox(width: 800.0, height: 10.0),
              SizedBox(width: 800.0, height: 10.0),
            ],
          ),
        ],
      ),
    );

    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 30.0)));
    verify(tester, <Offset>[
      Offset.zero,
      const Offset(0.0, 20.0),
    ]);
  });

  testWidgets('Wrap can set and update clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(const Wrap(textDirection: TextDirection.ltr));
    final RenderWrap renderObject = tester.allRenderObjects.whereType<RenderWrap>().first;
    expect(renderObject.clipBehavior, equals(Clip.none));

    await tester.pumpWidget(const Wrap(textDirection: TextDirection.ltr, clipBehavior: Clip.antiAlias));
    expect(renderObject.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgets('Horizontal wrap - IntrinsicsHeight', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/48679.
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IntrinsicHeight(
            child: ColoredBox(
              color: Colors.green,
              child: Wrap(
                children: <Widget>[
                  Text('Start', style: TextStyle(height: 1.0, fontSize: 16)),
                  Row(
                    children: <Widget>[
                      SizedBox(height: 40, width: 60),
                    ],
                  ),
                  Text('End', style: TextStyle(height: 1.0, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // The row takes up the full width, therefore the "Start" and "End" text
    // are placed before and after it and the total height is the sum of the
    // individual heights.
    expect(tester.getSize(find.byType(IntrinsicHeight)).height, 2 * 16 + 40);
  });

  testWidgets('Vertical wrap - IntrinsicsWidth', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/48679.
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IntrinsicWidth(
            child: ColoredBox(
              color: Colors.green,
              child: Wrap(
                direction: Axis.vertical,
                children: <Widget>[
                  Text('Start', style: TextStyle(height: 1.0, fontSize: 16)),
                  Column(
                    children: <Widget>[
                      SizedBox(height: 40, width: 60),
                    ],
                  ),
                  Text('End', style: TextStyle(height: 1.0, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // The column takes up the full height, therefore the "Start" and "End" text
    // are placed to the left and right of it and the total width is the sum of
    // the individual widths.
    expect(tester.getSize(find.byType(IntrinsicWidth)).width, 5 * 16 + 60 + 3 * 16);
  });

  testWidgets('WrapFit horizontal', (WidgetTester tester)async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          // Children are formatted by the run, they are in.
          children: <Widget>[
            // Test WrapFit.loose
            SizedBox(width: 200, height: 1), SizedBox(width: 600, height: 1),
            SizedBox(width: 200, height: 1),
            SizedBox(width: 601, height: 1),

            // Test WrapFit.tight
            SizedBox(width: 200, height: 1),
            Wrapped(fit: WrapFit.tight, child: SizedBox(width: 200, height: 1)),
            Wrapped(fit: WrapFit.tight, child: SizedBox(width: 200, height: 1)),

            // Test WrapFit.runTight
            SizedBox(width: 200, height: 1), Wrapped(child: SizedBox(width: 600, height: 1)),
            SizedBox(width: 200, height: 1), Wrapped(child: SizedBox(width: 400, height: 1)),
            SizedBox(width: 200, height: 1),
            Wrapped(child: SizedBox(width: 601, height: 1)),
            Wrapped(child: SizedBox(width: 200, height: 1)),

            // Test WrapFit.runLoose
            SizedBox(width: 200, height: 1), Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 600, height: 1)),
            SizedBox(width: 200, height: 1), Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 400, height: 1)), Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 200, height: 1)),
            SizedBox(width: 200, height: 1), Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 400, height: 1)), Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 100, height: 1)),
            SizedBox(width: 200, height: 1),
            Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 601, height: 1)),
            Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 200, height: 1)),
          ],
        ),
      ),
    );

    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, const <Offset>[
                            Offset.zero , Offset(200,  0),
                            Offset(0,  1),
                            Offset(0,  2),

                            Offset(0,  3),
                            Offset(0,  4),
                            Offset(0,  5),

                            Offset(0,  6), Offset(200,  6),
                            Offset(0,  7), Offset(200,  7),
                            Offset(0,  8),
                            Offset(0,  9),
                            Offset(0, 10),

                            Offset(0, 11), Offset(200, 11),
                            Offset(0, 12), Offset(200, 12), Offset(600, 12),
                            Offset(0, 13), Offset(200, 13), Offset(600, 13),
                            Offset(0, 14),
                            Offset(0, 15),
                            Offset(0, 16),
                          ]);

    verifySize(tester, const <Size>[
                            Size(200, 1), Size(600, 1),
                            Size(200, 1),
                            Size(601, 1),

                            Size(200, 1),
                            Size(800, 1),
                            Size(800, 1),

                            Size(200, 1), Size(600, 1),
                            Size(200, 1), Size(600, 1),
                            Size(200, 1),
                            Size(800, 1),
                            Size(800, 1),

                            Size(200, 1), Size(600, 1),
                            Size(200, 1), Size(400, 1), Size(200, 1),
                            Size(200, 1), Size(400, 1), Size(100, 1),
                            Size(200, 1),
                            Size(601, 1),
                            Size(200, 1),
                          ]);
  });

  testWidgets('WrapFit vertical', (WidgetTester tester)async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          direction: Axis.vertical,
          // Children are formatted by the run, they are in.
          children: <Widget>[
            // Test WrapFit.loose
            SizedBox(width: 1, height: 200), SizedBox(width: 1, height: 400),
            SizedBox(width: 1, height: 200),
            SizedBox(width: 1, height: 401),

            // Test WrapFit.tight
            SizedBox(width: 1, height: 200),
            Wrapped(fit: WrapFit.tight, child: SizedBox(width: 1, height: 200)),
            Wrapped(fit: WrapFit.tight, child: SizedBox(width: 1, height: 200)),

            // Test WrapFit.runTight
            SizedBox(width: 1, height: 200), Wrapped(child: SizedBox(width: 1, height: 400)),
            SizedBox(width: 1, height: 200), Wrapped(child: SizedBox(width: 1, height: 200)),
            SizedBox(width: 1, height: 200),
            Wrapped(child: SizedBox(width: 1, height: 401)),
            Wrapped(child: SizedBox(width: 1, height: 200)),

            // Test WrapFit.runLoose
            SizedBox(width: 1, height: 200), Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 1, height: 400)),
            SizedBox(width: 1, height: 200), Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 1, height: 200)), Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 1, height: 200)),
            SizedBox(width: 1, height: 200), Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 1, height: 200)), Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 1, height: 100)),
            SizedBox(width: 1, height: 200),
            Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 1, height: 401)),
            Wrapped(fit: WrapFit.runLoose, child: SizedBox(width: 1, height: 200)),
          ],
        ),
      ),
    );

    expect(tester.renderObject<RenderBox>(find.byType(Wrap)).size, equals(const Size(800.0, 600.0)));
    verify(tester, const <Offset>[
                            Offset.zero , Offset(0, 200),
                            Offset(1,  0),
                            Offset(2,  0),

                            Offset( 3, 0),
                            Offset( 4, 0),
                            Offset( 5, 0),

                            Offset( 6, 0), Offset( 6, 200),
                            Offset( 7, 0), Offset( 7, 200),
                            Offset( 8, 0),
                            Offset( 9, 0),
                            Offset(10, 0),

                            Offset(11, 0), Offset(11, 200),
                            Offset(12, 0), Offset(12, 200), Offset(12, 400),
                            Offset(13, 0), Offset(13, 200), Offset(13, 400),
                            Offset(14, 0),
                            Offset(15, 0),
                            Offset(16, 0),
                          ]);

    verifySize(tester, const <Size>[
                            Size(1, 200), Size(1, 400),
                            Size(1, 200),
                            Size(1, 401),

                            Size(1, 200),
                            Size(1, 600),
                            Size(1, 600),

                            Size(1, 200), Size(1, 400),
                            Size(1, 200), Size(1, 400),
                            Size(1, 200),
                            Size(1, 600),
                            Size(1, 600),

                            Size(1, 200), Size(1, 400),
                            Size(1, 200), Size(1, 200), Size(1, 200),
                            Size(1, 200), Size(1, 200), Size(1, 100),
                            Size(1, 200),
                            Size(1, 401),
                            Size(1, 200),
                          ]);
  });

  testWidgets('Wrapped', (WidgetTester tester) async {

    expect(const Wrapped(child: SizedBox()).fit, WrapFit.runTight);

    WrapParentData getParentData(){
      return tester.renderObject(find.byType(SizedBox)).parentData! as WrapParentData;
    }

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          children: <Widget>[
            SizedBox(),
          ],
        ),
      ),
    );
    expect(getParentData().fit, WrapFit.loose);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          children: <Widget>[
            Wrapped(
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );
    expect(getParentData().fit, WrapFit.runTight);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          children: <Widget>[
            Wrapped(
              fit: WrapFit.runLoose,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );
    expect(getParentData().fit, WrapFit.runLoose);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          children: <Widget>[
            Wrapped(
              fit: WrapFit.tight,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );
    expect(getParentData().fit, WrapFit.tight);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          children: <Widget>[
            Wrapped(
              fit: WrapFit.tight,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );
    expect(getParentData().fit, WrapFit.tight);
  });

  test('Test WrapFit getters', () {
    for (final WrapFit fit in WrapFit.values) {
      expect(fit.isLoose != fit.isTight, true);
    }
  });
}
