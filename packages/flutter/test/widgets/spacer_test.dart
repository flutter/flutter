// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Spacer takes up space.', (WidgetTester tester) async {
    await tester.pumpWidget(const Column(
      children: <Widget>[
        SizedBox(width: 10.0, height: 10.0),
        Spacer(),
        SizedBox(width: 10.0, height: 10.0),
      ],
    ));
    final Rect spacerRect = tester.getRect(find.byType(Spacer));
    expect(spacerRect.size, const Size(0.0, 580.0));
    expect(spacerRect.topLeft, const Offset(400.0, 10.0));
  });

  testWidgets('Spacer takes up space proportional to flex.', (WidgetTester tester) async {
    const Spacer spacer1 = Spacer();
    const Spacer spacer2 = Spacer();
    const Spacer spacer3 = Spacer(flex: 2);
    const Spacer spacer4 = Spacer(flex: 4);
    await tester.pumpWidget(const Row(
      textDirection: TextDirection.rtl,
      children: <Widget>[
        SizedBox(width: 10.0, height: 10.0),
        spacer1,
        SizedBox(width: 10.0, height: 10.0),
        spacer2,
        SizedBox(width: 10.0, height: 10.0),
        spacer3,
        SizedBox(width: 10.0, height: 10.0),
        spacer4,
        SizedBox(width: 10.0, height: 10.0),
      ],
    ));
    final Rect spacer1Rect = tester.getRect(find.byType(Spacer).at(0));
    final Rect spacer2Rect = tester.getRect(find.byType(Spacer).at(1));
    final Rect spacer3Rect = tester.getRect(find.byType(Spacer).at(2));
    final Rect spacer4Rect = tester.getRect(find.byType(Spacer).at(3));
    expect(spacer1Rect.size.height, 0.0);
    expect(spacer1Rect.size.width, moreOrLessEquals(93.8, epsilon: 0.1));
    expect(spacer1Rect.left, moreOrLessEquals(696.3, epsilon: 0.1));
    expect(spacer2Rect.size.width, moreOrLessEquals(93.8, epsilon: 0.1));
    expect(spacer2Rect.left, moreOrLessEquals(592.5, epsilon: 0.1));
    expect(spacer3Rect.size.width, spacer2Rect.size.width * 2.0);
    expect(spacer3Rect.left, moreOrLessEquals(395.0, epsilon: 0.1));
    expect(spacer4Rect.size.width, spacer3Rect.size.width * 2.0);
    expect(spacer4Rect.left, moreOrLessEquals(10.0, epsilon: 0.1));
  });

  testWidgets('Spacer takes up space.', (WidgetTester tester) async {
    await tester.pumpWidget(const UnconstrainedBox(
      constrainedAxis: Axis.vertical,
      child: Column(
        children: <Widget>[
          SizedBox(width: 20.0, height: 10.0),
          Spacer(),
          SizedBox(width: 10.0, height: 10.0),
        ],
      ),
    ));
    final Rect spacerRect = tester.getRect(find.byType(Spacer));
    final Rect flexRect = tester.getRect(find.byType(Column));
    expect(spacerRect.size, const Size(0.0, 580.0));
    expect(spacerRect.topLeft, const Offset(400.0, 10.0));
    expect(flexRect, const Rect.fromLTWH(390.0, 0.0, 20.0, 600.0));
  });

  testWidgets('Spacer.fixed takes up space.', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: <Widget>[
            Spacer.fixed(length: 100.0),
            SizedBox.square(dimension: 10.0),
            Spacer.fixed(length: 200.0),
          ],
        ),
      ),
    );

    final Rect horizontalSpacerRect1 = tester.getRect(find.byType(Spacer).at(0));
    expect(horizontalSpacerRect1.size, const Size(100.0, 0.0));
    expect(horizontalSpacerRect1.left, 0.0);

    final Rect horizontalSpacerRect2 = tester.getRect(find.byType(Spacer).at(1));
    expect(horizontalSpacerRect2.size, const Size(200.0, 0.0));
    expect(horizontalSpacerRect2.left, 110.0);

    await tester.pumpWidget(
      const Column(
        children: <Widget>[
          Spacer.fixed(length: 100.0),
          SizedBox.square(dimension: 10.0),
          Spacer.fixed(length: 200.0),
        ],
      ),
    );

    final Rect verticalSpacerRect1 = tester.getRect(find.byType(Spacer).at(0));
    expect(verticalSpacerRect1.size, const Size(0.0, 100.0));
    expect(verticalSpacerRect1.top, 0.0);

    final Rect verticalSpacerRect2 = tester.getRect(find.byType(Spacer).at(1));
    expect(verticalSpacerRect2.size, const Size(0.0, 200.0));
    expect(verticalSpacerRect2.top, 110.0);
  });
}
