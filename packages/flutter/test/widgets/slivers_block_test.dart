// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';

Future<Null> test(WidgetTester tester, double offset) {
  return tester.pumpWidget(new Viewport2(
    offset: new ViewportOffset.fixed(offset),
    slivers: <Widget>[
      new SliverList(
        delegate: new SliverChildListDelegate(<Widget>[
          new SizedBox(height: 400.0, child: new Text('a')),
          new SizedBox(height: 400.0, child: new Text('b')),
          new SizedBox(height: 400.0, child: new Text('c')),
          new SizedBox(height: 400.0, child: new Text('d')),
          new SizedBox(height: 400.0, child: new Text('e')),
        ]),
      ),
    ],
  ));
}

void verify(WidgetTester tester, List<Point> answerKey, String text) {
  List<Point> testAnswers = tester.renderObjectList<RenderBox>(find.byType(SizedBox)).map<Point>(
    (RenderBox target) => target.localToGlobal(const Point(0.0, 0.0))
  ).toList();
  expect(testAnswers, equals(answerKey));
  final String foundText =
    tester.widgetList<Text>(find.byType(Text))
    .map<String>((Text widget) => widget.data)
    .reduce((String value, String element) => value + element);
  expect(foundText, equals(text));
}

void main() {
  testWidgets('Viewport2+SliverBlock basic test', (WidgetTester tester) async {
    await test(tester, 0.0);
    expect(tester.renderObject<RenderBox>(find.byType(Viewport2)).size, equals(const Size(800.0, 600.0)));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(0.0, 400.0),
    ], 'ab');

    await test(tester, 200.0);
    verify(tester, <Point>[
      const Point(0.0, -200.0),
      const Point(0.0, 200.0),
    ], 'ab');

    await test(tester, 600.0);
    verify(tester, <Point>[
      const Point(0.0, -200.0),
      const Point(0.0, 200.0),
    ], 'bc');

    await test(tester, 900.0);
    verify(tester, <Point>[
      const Point(0.0, -100.0),
      const Point(0.0, 300.0),
    ], 'cd');

    await test(tester, 200.0);
    verify(tester, <Point>[
      const Point(0.0, -200.0),
      const Point(0.0, 200.0),
    ], 'ab');
  });

  testWidgets('Viewport2 with GlobalKey reparenting', (WidgetTester tester) async {
    Key key1 = new GlobalKey();
    ViewportOffset offset = new ViewportOffset.zero();
    await tester.pumpWidget(new Viewport2(
      offset: offset,
      slivers: <Widget>[
        new SliverList(
          delegate: new SliverChildListDelegate(<Widget>[
            new SizedBox(height: 251.0, child: new Text('a')),
            new SizedBox(height: 252.0, child: new Text('b')),
            new SizedBox(key: key1, height: 253.0, child: new Text('c')),
          ]),
        ),
      ],
    ));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(0.0, 251.0),
      const Point(0.0, 503.0),
    ], 'abc');
    await tester.pumpWidget(new Viewport2(
      offset: offset,
      slivers: <Widget>[
        new SliverList(
          delegate: new SliverChildListDelegate(<Widget>[
            new SizedBox(key: key1, height: 253.0, child: new Text('c')),
            new SizedBox(height: 251.0, child: new Text('a')),
            new SizedBox(height: 252.0, child: new Text('b')),
          ]),
        ),
      ],
    ));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(0.0, 253.0),
      const Point(0.0, 504.0),
    ], 'cab');
    await tester.pumpWidget(new Viewport2(
      offset: offset,
      slivers: <Widget>[
        new SliverList(
          delegate: new SliverChildListDelegate(<Widget>[
            new SizedBox(height: 251.0, child: new Text('a')),
            new SizedBox(key: key1, height: 253.0, child: new Text('c')),
            new SizedBox(height: 252.0, child: new Text('b')),
          ]),
        ),
      ],
    ));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(0.0, 251.0),
      const Point(0.0, 504.0),
    ], 'acb');
    await tester.pumpWidget(new Viewport2(
      offset: offset,
      slivers: <Widget>[
        new SliverList(
          delegate: new SliverChildListDelegate(<Widget>[
            new SizedBox(height: 251.0, child: new Text('a')),
            new SizedBox(height: 252.0, child: new Text('b')),
          ]),
        ),
      ],
    ));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(0.0, 251.0),
    ], 'ab');
    await tester.pumpWidget(new Viewport2(
      offset: offset,
      slivers: <Widget>[
        new SliverList(
          delegate: new SliverChildListDelegate(<Widget>[
            new SizedBox(height: 251.0, child: new Text('a')),
            new SizedBox(key: key1, height: 253.0, child: new Text('c')),
            new SizedBox(height: 252.0, child: new Text('b')),
          ]),
        ),
      ],
    ));
    verify(tester, <Point>[
      const Point(0.0, 0.0),
      const Point(0.0, 251.0),
      const Point(0.0, 504.0),
    ], 'acb');
  });

  testWidgets('Viewport2 overflow clipping of SliverToBoxAdapter', (WidgetTester tester) async {
    await tester.pumpWidget(new Viewport2(
      offset: new ViewportOffset.zero(),
      slivers: <Widget>[
        new SliverToBoxAdapter(
          child: new SizedBox(height: 400.0, child: new Text('a')),
        ),
      ],
    ));

    expect(find.byType(Viewport2), isNot(paints..clipRect()));

    await tester.pumpWidget(new Viewport2(
      offset: new ViewportOffset.fixed(100.0),
      slivers: <Widget>[
        new SliverToBoxAdapter(
          child: new SizedBox(height: 400.0, child: new Text('a')),
        ),
      ],
    ));

    expect(find.byType(Viewport2), paints..clipRect());

    await tester.pumpWidget(new Viewport2(
      offset: new ViewportOffset.fixed(100.0),
      slivers: <Widget>[
        new SliverToBoxAdapter(
          child: new SizedBox(height: 4000.0, child: new Text('a')),
        ),
      ],
    ));

    expect(find.byType(Viewport2), paints..clipRect());

    await tester.pumpWidget(new Viewport2(
      offset: new ViewportOffset.zero(),
      slivers: <Widget>[
        new SliverToBoxAdapter(
          child: new SizedBox(height: 4000.0, child: new Text('a')),
        ),
      ],
    ));

    expect(find.byType(Viewport2), paints..clipRect());
  });

  testWidgets('Viewport2 overflow clipping of SliverBlock', (WidgetTester tester) async {
    await tester.pumpWidget(new Viewport2(
      offset: new ViewportOffset.zero(),
      slivers: <Widget>[
        new SliverList(
          delegate: new SliverChildListDelegate(<Widget>[
            new SizedBox(height: 400.0, child: new Text('a')),
          ]),
        ),
      ],
    ));

    expect(find.byType(Viewport2), isNot(paints..clipRect()));

    await tester.pumpWidget(new Viewport2(
      offset: new ViewportOffset.fixed(100.0),
      slivers: <Widget>[
        new SliverList(
          delegate: new SliverChildListDelegate(<Widget>[
            new SizedBox(height: 400.0, child: new Text('a')),
          ]),
        ),
      ],
    ));

    expect(find.byType(Viewport2), paints..clipRect());

    await tester.pumpWidget(new Viewport2(
      offset: new ViewportOffset.fixed(100.0),
      slivers: <Widget>[
        new SliverList(
          delegate: new SliverChildListDelegate(<Widget>[
            new SizedBox(height: 4000.0, child: new Text('a')),
          ]),
        ),
      ],
    ));

    expect(find.byType(Viewport2), paints..clipRect());

    await tester.pumpWidget(new Viewport2(
      offset: new ViewportOffset.zero(),
      slivers: <Widget>[
        new SliverList(
          delegate: new SliverChildListDelegate(<Widget>[
            new SizedBox(height: 4000.0, child: new Text('a')),
          ]),
        ),
      ],
    ));

    expect(find.byType(Viewport2), paints..clipRect());
  });
}
