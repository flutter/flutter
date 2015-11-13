// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Can construct an empty Stack', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Stack(<Widget>[]));
    });
  });

  test('Can construct an empty Centered Stack', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Center(child: new Stack(<Widget>[])));
    });
  });

  test('Can change position data', () {
    testWidgets((WidgetTester tester) {
      Key key = new Key('container');

      tester.pumpWidget(
        new Stack(<Widget>[
          new Positioned(
            left: 10.0,
            child: new Container(
              key: key,
              width: 10.0,
              height: 10.0
            )
          )
        ])
      );

      Element container;
      StackParentData parentData;

      container = tester.findElementByKey(key);
      parentData = container.renderObject.parentData;
      expect(parentData.top, isNull);
      expect(parentData.right, isNull);
      expect(parentData.bottom, isNull);
      expect(parentData.left, equals(10.0));

      tester.pumpWidget(
        new Stack(<Widget>[
          new Positioned(
            right: 10.0,
            child: new Container(
              key: key,
              width: 10.0,
              height: 10.0
            )
          )
        ])
      );

      container = tester.findElementByKey(key);
      parentData = container.renderObject.parentData;
      expect(parentData.top, isNull);
      expect(parentData.right, equals(10.0));
      expect(parentData.bottom, isNull);
      expect(parentData.left, isNull);
    });
  });

  test('Can remove parent data', () {
    testWidgets((WidgetTester tester) {
      Key key = new Key('container');
      Container container = new Container(key: key, width: 10.0, height: 10.0);

      tester.pumpWidget(new Stack(<Widget>[ new Positioned(left: 10.0, child: container) ]));
      Element containerElement = tester.findElementByKey(key);

      StackParentData parentData;
      parentData = containerElement.renderObject.parentData;
      expect(parentData.top, isNull);
      expect(parentData.right, isNull);
      expect(parentData.bottom, isNull);
      expect(parentData.left, equals(10.0));

      tester.pumpWidget(new Stack(<Widget>[ container ]));
      containerElement = tester.findElementByKey(key);

      parentData = containerElement.renderObject.parentData;
      expect(parentData.top, isNull);
      expect(parentData.right, isNull);
      expect(parentData.bottom, isNull);
      expect(parentData.left, isNull);
    });
  });

  test('Can align non-positioned children', () {
    testWidgets((WidgetTester tester) {
      Key child0Key = new Key('child0');
      Key child1Key = new Key('child1');

      tester.pumpWidget(
        new Center(
          child: new Stack(<Widget>[
              new Container(key: child0Key, width: 20.0, height: 20.0),
              new Container(key: child1Key, width: 10.0, height: 10.0)
            ],
            alignment: const FractionalOffset(0.5, 0.5)
          )
        )
      );

      Element child0 = tester.findElementByKey(child0Key);
      final StackParentData child0RenderObjectParentData = child0.renderObject.parentData;
      expect(child0RenderObjectParentData.position, equals(const Point(0.0, 0.0)));

      Element child1 = tester.findElementByKey(child1Key);
      final StackParentData child1RenderObjectParentData = child1.renderObject.parentData;
      expect(child1RenderObjectParentData.position, equals(const Point(5.0, 5.0)));
    });
  });

  test('Can construct an empty IndexedStack', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new IndexedStack(<Widget>[]));
    });
  });

  test('Can construct an empty Centered IndexedStack', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Center(child: new IndexedStack(<Widget>[])));
    });
  });

  test('Can construct an IndexedStack', () {
    testWidgets((WidgetTester tester) {
      int itemCount = 3;
      List<int> itemsPainted;

      Widget buildFrame(int index) {
        itemsPainted = <int>[];
        List<Widget> items = new List<Widget>.generate(itemCount, (i) {
          return new CustomPaint(child: new Text('$i'), onPaint: (_, __) { itemsPainted.add(i); });
        });
        return new Center(child: new IndexedStack(items, index: index));
      }

      tester.pumpWidget(buildFrame(0));
      expect(tester.findText('0'), isNotNull);
      expect(tester.findText('1'), isNotNull);
      expect(tester.findText('2'), isNotNull);
      expect(itemsPainted, equals([0]));

      tester.pumpWidget(buildFrame(1));
      expect(itemsPainted, equals([1]));

      tester.pumpWidget(buildFrame(2));
      expect(itemsPainted, equals([2]));
    });
  });

  test('Can hit test an IndexedStack', () {
    testWidgets((WidgetTester tester) {
      Key key = new Key('indexedStack');
      int itemCount = 3;
      List<int> itemsTapped;

      Widget buildFrame(int index) {
        itemsTapped = <int>[];
        List<Widget> items = new List<Widget>.generate(itemCount, (i) {
          return new GestureDetector(child: new Text('$i'), onTap: () { itemsTapped.add(i); });
        });
        return new Center(child: new IndexedStack(items, key: key, index: index));
      }

      tester.pumpWidget(buildFrame(0));
      expect(itemsTapped, isEmpty);
      tester.tap(tester.findElementByKey(key));
      expect(itemsTapped, [0]);

      tester.pumpWidget(buildFrame(2));
      expect(itemsTapped, isEmpty);
      tester.tap(tester.findElementByKey(key));
      expect(itemsTapped, [2]);
    });
  });

}
