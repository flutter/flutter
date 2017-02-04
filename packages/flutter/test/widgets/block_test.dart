// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'test_widgets.dart';

final Key blockKey = new Key('test');

void main() {
  testWidgets('Cannot scroll a non-overflowing block', (WidgetTester tester) async {
    await tester.pumpWidget(
      new ListView(
        key: blockKey,
        children: <Widget>[
          new Container(
            height: 200.0, // less than 600, the height of the test area
            child: new Text('Hello')
          )
        ]
      )
    );

    Point middleOfContainer = tester.getCenter(find.text('Hello'));
    Point target = tester.getCenter(find.byKey(blockKey));
    TestGesture gesture = await tester.startGesture(target);
    await gesture.moveBy(const Offset(0.0, -10.0));

    await tester.pump(const Duration(milliseconds: 1));

    expect(tester.getCenter(find.text('Hello')) == middleOfContainer, isTrue);

    await gesture.up();
  });

  testWidgets('Can scroll an overflowing block', (WidgetTester tester) async {
    await tester.pumpWidget(
      new ListView(
        key: blockKey,
        children: <Widget>[
          new Container(
            height: 2000.0, // more than 600, the height of the test area
            child: new Text('Hello')
          )
        ]
      )
    );

    Point middleOfContainer = tester.getCenter(find.text('Hello'));
    expect(middleOfContainer.x, equals(400.0));
    expect(middleOfContainer.y, equals(1000.0));

    Point target = tester.getCenter(find.byKey(blockKey));
    TestGesture gesture = await tester.startGesture(target);
    await gesture.moveBy(const Offset(0.0, -10.0));

    await tester.pump(); // redo layout

    expect(tester.getCenter(find.text('Hello')), isNot(equals(middleOfContainer)));

    await gesture.up();
  });

  testWidgets('Scroll anchor', (WidgetTester tester) async {
    int first = 0;
    int second = 0;

    Widget buildBlock(ViewportAnchor scrollAnchor) {
      return new Block(
        key: new UniqueKey(),
        scrollAnchor: scrollAnchor,
        children: <Widget>[
          new GestureDetector(
            onTap: () { ++first; },
            child: new Container(
              height: 2000.0, // more than 600, the height of the test area
              decoration: const BoxDecoration(
                backgroundColor: const Color(0xFF00FF00)
              )
            )
          ),
          new GestureDetector(
            onTap: () { ++second; },
            child: new Container(
              height: 2000.0, // more than 600, the height of the test area
              decoration: const BoxDecoration(
                backgroundColor: const Color(0xFF0000FF)
              )
            )
          )
        ]
      );
    }

    await tester.pumpWidget(buildBlock(ViewportAnchor.end));

    Point target = const Point(200.0, 200.0);
    await tester.tapAt(target);
    expect(first, equals(0));
    expect(second, equals(1));

    await tester.pumpWidget(buildBlock(ViewportAnchor.start));

    await tester.tapAt(target);
    expect(first, equals(1));
    expect(second, equals(1));
  });

  testWidgets('Block scrollableKey', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/4046
    // The Block's scrollableKey needs to become its Scrollable descendant's key.
    final GlobalKey<ScrollableState<Scrollable>> key = new GlobalKey<ScrollableState<Scrollable>>();
    Widget buildBlock() {
      return new Block(
        scrollableKey: key,
        children: <Widget>[new Text("A"), new Text("B"), new Text("C")]
      );
    }
    await tester.pumpWidget(buildBlock());
    expect(key.currentState.scrollOffset, 0.0);
  });

  testWidgets('SliverBlockChildListDelegate.estimateMaxScrollOffset hits end', (WidgetTester tester) async {
    SliverChildListDelegate delegate = new SliverChildListDelegate(<Widget>[
      new Container(),
      new Container(),
      new Container(),
      new Container(),
      new Container(),
    ]);

    await tester.pumpWidget(new TestScrollable(
      slivers: <Widget>[
        new SliverList(
          delegate: delegate,
        ),
      ],
    ));

    final SliverMultiBoxAdaptorElement element = tester.element(find.byType(SliverList));

    final double maxScrollOffset = element.estimateMaxScrollOffset(
      null,
      firstIndex: 3,
      lastIndex: 4,
      leadingScrollOffset: 25.0,
      trailingScrollOffset: 26.0
    );
    expect(maxScrollOffset, equals(26.0));
  });
}
