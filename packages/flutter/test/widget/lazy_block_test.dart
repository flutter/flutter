// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Block inside LazyBlock', (WidgetTester tester) async {
    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new Block(
            children: <Widget>[
              new Text('1'),
              new Text('2'),
              new Text('3'),
            ]
          ),
          new Block(
            children: <Widget>[
              new Text('4'),
              new Text('5'),
              new Text('6'),
            ]
          ),
        ]
      )
    ));
  });

  testWidgets('Underflowing LazyBlock should relayout for additional children', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/5950

    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new SizedBox(height: 100.0, child: new Text('100')),
        ]
      )
    ));

    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new SizedBox(height: 100.0, child: new Text('100')),
          new SizedBox(height: 200.0, child: new Text('200')),
        ]
      )
    ));

    expect(find.text('200'), findsOneWidget);
  });


  testWidgets('Underflowing LazyBlock contentExtent should track additional children', (WidgetTester tester) async {
    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new SizedBox(height: 100.0, child: new Text('100')),
        ]
      )
    ));

    StatefulElement statefulElement = tester.element(find.byType(Scrollable));
    ScrollableState scrollable = statefulElement.state;
    OverscrollWhenScrollableBehavior scrollBehavior = scrollable.scrollBehavior;
    expect(scrollBehavior.contentExtent, equals(100.0));

    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new SizedBox(height: 100.0, child: new Text('100')),
          new SizedBox(height: 200.0, child: new Text('200')),
        ]
      )
    ));
    expect(scrollBehavior.contentExtent, equals(300.0));

    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
        ]
      )
    ));
    expect(scrollBehavior.contentExtent, equals(0.0));
  });


  testWidgets('Overflowing LazyBlock should relayout for missing children', (WidgetTester tester) async {
    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new SizedBox(height: 300.0, child: new Text('300')),
          new SizedBox(height: 400.0, child: new Text('400')),
        ]
      )
    ));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);

    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new SizedBox(height: 300.0, child: new Text('300')),
        ]
      )
    ));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsNothing);

    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
        ]
      )
    ));

    expect(find.text('300'), findsNothing);
    expect(find.text('400'), findsNothing);
  });

  testWidgets('Overflowing LazyBlock should not relayout for additional children', (WidgetTester tester) async {
    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new SizedBox(height: 300.0, child: new Text('300')),
          new SizedBox(height: 400.0, child: new Text('400')),
        ]
      )
    ));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);

    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new SizedBox(height: 300.0, child: new Text('300')),
          new SizedBox(height: 400.0, child: new Text('400')),
          new SizedBox(height: 100.0, child: new Text('100')),
        ]
      )
    ));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
    expect(find.text('100'), findsNothing);

    StatefulElement statefulElement = tester.element(find.byType(Scrollable));
    ScrollableState scrollable = statefulElement.state;
    OverscrollWhenScrollableBehavior scrollBehavior = scrollable.scrollBehavior;
    expect(scrollBehavior.contentExtent, equals(700.0));
  });

  testWidgets('Overflowing LazyBlock should become scrollable', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/5920
    // When a LazyBlock's viewport hasn't overflowed, scrolling is disabled.
    // When children are added that cause it to overflow, scrolling should
    // be enabled.

    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new SizedBox(height: 100.0, child: new Text('100')),
        ]
      )
    ));

    StatefulElement statefulElement = tester.element(find.byType(Scrollable));
    ScrollableState scrollable = statefulElement.state;
    OverscrollWhenScrollableBehavior scrollBehavior = scrollable.scrollBehavior;
    expect(scrollBehavior.isScrollable, isFalse);

    await tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new SizedBox(height: 100.0, child: new Text('100')),
          new SizedBox(height: 200.0, child: new Text('200')),
          new SizedBox(height: 400.0, child: new Text('400')),
        ]
      )
    ));

    expect(scrollBehavior.isScrollable, isTrue);
  });


}
