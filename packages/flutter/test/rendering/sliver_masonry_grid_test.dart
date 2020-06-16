// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('SliverMasonryGrid', () {
    testWidgets('the size of each child', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: sliverMasonryGridBoilerplate(crossAxisCount: 2),
        textDirection: TextDirection.ltr,
      ));

      expect(
        tester.getSize(find.widgetWithText(Container, "0.He'd have you all unravel at the")),
        const Size(400.0, 50.0),
      );

      expect(tester.getSize(find.widgetWithText(Container, '1.Heed not the rabble')),
        const Size(400.0, 70.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Size(400.0, 90.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '3.Who scream')),
        const Size(400.0, 60.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '4.Revolution is coming...')),
        const Size(400.0, 80.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '5.Revolution, they...')),
        const Size(400.0, 100.0),
      );
    });

    testWidgets('the position of each child at TextDirection.ltr',
      (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: sliverMasonryGridBoilerplate(crossAxisCount: 2),
        textDirection: TextDirection.ltr,
      ));

      expect(
        tester.getTopLeft(find.widgetWithText(Container, "0.He'd have you all unravel at the")),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1.Heed not the rabble')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(400.0, 70.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4.Revolution is coming...')),
        const Offset(400.0, 130.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5.Revolution, they...')),
        const Offset(0.0, 140.0),
      );
    });

    testWidgets('the position of each child at TextDirection.rtl',
      (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: sliverMasonryGridBoilerplate(crossAxisCount: 2),
        textDirection: TextDirection.rtl),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, "0.He'd have you all unravel at the")),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1.Heed not the rabble')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(400.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(0.0, 70.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4.Revolution is coming...')),
        const Offset(0.0, 130.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5.Revolution, they...')),
        const Offset(400.0, 140.0),
      );
    });

    testWidgets('crossAxisCount change test', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: sliverMasonryGridBoilerplate(crossAxisCount: 2),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      await tester.pumpWidget(materialAppBoilerplate(
        child: sliverMasonryGridBoilerplate(crossAxisCount: 4),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(400.0, 0.0),
      );
    });

    testWidgets('crossAxisSpacing test', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: sliverMasonryGridBoilerplate(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(405.0, 70.0),
      );
    });

    testWidgets('mainAxisSpacing test', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: sliverMasonryGridBoilerplate(
          crossAxisCount: 2,
          mainAxisSpacing: 10.0,
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 60.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(400.0, 80.0),
      );
    });

    testWidgets('maxCrossAxisExtent change test', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: sliverMasonryGridBoilerplate(maxCrossAxisExtent: 400),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      await tester.pumpWidget(materialAppBoilerplate(
        child: sliverMasonryGridBoilerplate(maxCrossAxisExtent: 200),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(400.0, 0.0),
      );
    });

    testWidgets('with other slivers', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: sliverMasonryGridBoilerplate(
          crossAxisCount: 2,
          headerSlivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                height: 200.0,
                color: Colors.red,
              ),
            )
          ],
          footSlivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(
                height: 200.0,
                color: Colors.blue,
              ),
            )
          ],
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 250.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(400.0, 270.0),
      );
    });
  });
}

Widget sliverMasonryGridBoilerplate({
  int crossAxisCount = 2,
  double crossAxisSpacing = 0.0,
  double mainAxisSpacing = 0.0,
  List<Widget> headerSlivers,
  List<Widget> footSlivers,
  double maxCrossAxisExtent,
}) {

  final List<Widget> children = <Widget> [
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text("0.He'd have you all unravel at the"),
      color: Colors.teal[100],
      height: 50.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('1.Heed not the rabble'),
      color: Colors.teal[200],
      height: 70.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('2.Sound of screams but the'),
      color: Colors.teal[300],
      height: 90.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('3.Who scream'),
      color: Colors.teal[400],
      height: 60.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('4.Revolution is coming...'),
      color: Colors.teal[500],
      height: 80.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('5.Revolution, they...'),
      color: Colors.teal[600],
      height: 100.0,
    ),
  ];

  return CustomScrollView(
    slivers: <Widget>[
      if (headerSlivers != null) ...headerSlivers,
      if (maxCrossAxisExtent != null)
        SliverMasonryGrid.extent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          children: children,
        )
      else
        SliverMasonryGrid.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          children: children,
        ),
      if (footSlivers != null) ...footSlivers,
    ],
  );
}

Widget materialAppBoilerplate({
  Widget child,
  TextDirection textDirection = TextDirection.ltr,
  }) {
  return MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800.0, 600.0)),
        child: Material(
          child: child,
        ),
      ),
    ),
  );
}