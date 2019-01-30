// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

final List<Widget> children = <Widget>[
  Container(width: 200.0, height: 150.0),
  Container(width: 200.0, height: 150.0),
  Container(width: 200.0, height: 150.0),
  Container(width: 200.0, height: 150.0),
];

void expectRects(WidgetTester tester, List<Rect> expected) {
  final Finder finder = find.byType(Container);
  finder.precache();
  final List<Rect> actual = <Rect>[];
  for (int i = 0; i < expected.length; ++i) {
    final Finder current = finder.at(i);
    expect(current, findsOneWidget);
    actual.add(tester.getRect(finder.at(i)));
  }
  expect(() => finder.at(expected.length), throwsRangeError);
  expect(actual, equals(expected));
}

void main() {

  testWidgets('ListBody down', (WidgetTester tester) async {
    await tester.pumpWidget(Flex(
      direction: Axis.vertical,
      children: <Widget>[ ListBody(children: children) ],
    ));

    expectRects(
      tester,
      <Rect>[
        Rect.fromLTWH(0.0, 0.0, 800.0, 150.0),
        Rect.fromLTWH(0.0, 150.0, 800.0, 150.0),
        Rect.fromLTWH(0.0, 300.0, 800.0, 150.0),
        Rect.fromLTWH(0.0, 450.0, 800.0, 150.0),
      ],
    );
  });

  testWidgets('ListBody up', (WidgetTester tester) async {
    await tester.pumpWidget(Flex(
      direction: Axis.vertical,
      children: <Widget>[ ListBody(reverse: true, children: children) ],
    ));

    expectRects(
      tester,
      <Rect>[
        Rect.fromLTWH(0.0, 450.0, 800.0, 150.0),
        Rect.fromLTWH(0.0, 300.0, 800.0, 150.0),
        Rect.fromLTWH(0.0, 150.0, 800.0, 150.0),
        Rect.fromLTWH(0.0, 0.0, 800.0, 150.0),
      ],
    );
  });

  testWidgets('ListBody right', (WidgetTester tester) async {
    await tester.pumpWidget(Flex(
      textDirection: TextDirection.ltr,
      direction: Axis.horizontal,
      children: <Widget>[
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListBody(mainAxis: Axis.horizontal, children: children),
        ),
      ],
    ));

    expectRects(
      tester,
      <Rect>[
        Rect.fromLTWH(0.0, 0.0, 200.0, 600.0),
        Rect.fromLTWH(200.0, 0.0, 200.0, 600.0),
        Rect.fromLTWH(400.0, 0.0, 200.0, 600.0),
        Rect.fromLTWH(600.0, 0.0, 200.0, 600.0),
      ],
    );
  });

  testWidgets('ListBody left', (WidgetTester tester) async {
    await tester.pumpWidget(Flex(
      textDirection: TextDirection.ltr,
      direction: Axis.horizontal,
      children: <Widget>[
        Directionality(
          textDirection: TextDirection.rtl,
          child: ListBody(mainAxis: Axis.horizontal, children: children),
        ),
      ],
    ));

    expectRects(
      tester,
      <Rect>[
        Rect.fromLTWH(600.0, 0.0, 200.0, 600.0),
        Rect.fromLTWH(400.0, 0.0, 200.0, 600.0),
        Rect.fromLTWH(200.0, 0.0, 200.0, 600.0),
        Rect.fromLTWH(0.0, 0.0, 200.0, 600.0),
      ],
    );
  });
}
