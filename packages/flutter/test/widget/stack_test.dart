// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import '../rendering/rendering_tester.dart';

void main() {
  testWidgets('Can construct an empty Stack', (WidgetTester tester) {
      tester.pumpWidget(new Stack());
  });

  testWidgets('Can construct an empty Centered Stack', (WidgetTester tester) {
      tester.pumpWidget(new Center(child: new Stack()));
  });

  testWidgets('Can change position data', (WidgetTester tester) {
      Key key = new Key('container');

      tester.pumpWidget(
        new Stack(
          children: <Widget>[
            new Positioned(
              left: 10.0,
              child: new Container(
                key: key,
                width: 10.0,
                height: 10.0
              )
            )
          ]
        )
      );

      Element container;
      StackParentData parentData;

      container = tester.element(find.byKey(key));
      parentData = container.renderObject.parentData;
      expect(parentData.top, isNull);
      expect(parentData.right, isNull);
      expect(parentData.bottom, isNull);
      expect(parentData.left, equals(10.0));
      expect(parentData.width, isNull);
      expect(parentData.height, isNull);

      tester.pumpWidget(
        new Stack(
          children: <Widget>[
            new Positioned(
              right: 10.0,
              child: new Container(
                key: key,
                width: 10.0,
                height: 10.0
              )
            )
          ]
        )
      );

      container = tester.element(find.byKey(key));
      parentData = container.renderObject.parentData;
      expect(parentData.top, isNull);
      expect(parentData.right, equals(10.0));
      expect(parentData.bottom, isNull);
      expect(parentData.left, isNull);
      expect(parentData.width, isNull);
      expect(parentData.height, isNull);
  });

  testWidgets('Can remove parent data', (WidgetTester tester) {
      Key key = new Key('container');
      Container container = new Container(key: key, width: 10.0, height: 10.0);

      tester.pumpWidget(new Stack(children: <Widget>[ new Positioned(left: 10.0, child: container) ]));
      Element containerElement = tester.element(find.byKey(key));

      StackParentData parentData;
      parentData = containerElement.renderObject.parentData;
      expect(parentData.top, isNull);
      expect(parentData.right, isNull);
      expect(parentData.bottom, isNull);
      expect(parentData.left, equals(10.0));
      expect(parentData.width, isNull);
      expect(parentData.height, isNull);

      tester.pumpWidget(new Stack(children: <Widget>[ container ]));
      containerElement = tester.element(find.byKey(key));

      parentData = containerElement.renderObject.parentData;
      expect(parentData.top, isNull);
      expect(parentData.right, isNull);
      expect(parentData.bottom, isNull);
      expect(parentData.left, isNull);
      expect(parentData.width, isNull);
      expect(parentData.height, isNull);
  });

  testWidgets('Can align non-positioned children', (WidgetTester tester) {
      Key child0Key = new Key('child0');
      Key child1Key = new Key('child1');

      tester.pumpWidget(
        new Center(
          child: new Stack(
            children: <Widget>[
              new Container(key: child0Key, width: 20.0, height: 20.0),
              new Container(key: child1Key, width: 10.0, height: 10.0)
            ],
            alignment: const FractionalOffset(0.5, 0.5)
          )
        )
      );

      Element child0 = tester.element(find.byKey(child0Key));
      final StackParentData child0RenderObjectParentData = child0.renderObject.parentData;
      expect(child0RenderObjectParentData.offset, equals(const Offset(0.0, 0.0)));

      Element child1 = tester.element(find.byKey(child1Key));
      final StackParentData child1RenderObjectParentData = child1.renderObject.parentData;
      expect(child1RenderObjectParentData.offset, equals(const Offset(5.0, 5.0)));
  });

  testWidgets('Can construct an empty IndexedStack', (WidgetTester tester) {
      tester.pumpWidget(new IndexedStack());
  });

  testWidgets('Can construct an empty Centered IndexedStack', (WidgetTester tester) {
      tester.pumpWidget(new Center(child: new IndexedStack()));
  });

  testWidgets('Can construct an IndexedStack', (WidgetTester tester) {
      int itemCount = 3;
      List<int> itemsPainted;

      Widget buildFrame(int index) {
        itemsPainted = <int>[];
        List<Widget> items = new List<Widget>.generate(itemCount, (int i) {
          return new CustomPaint(
            child: new Text('$i'),
            painter: new TestCallbackPainter(
              onPaint: () { itemsPainted.add(i); }
            )
          );
        });
        return new Center(child: new IndexedStack(children: items, index: index));
      }

      tester.pumpWidget(buildFrame(0));
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(itemsPainted, equals([0]));

      tester.pumpWidget(buildFrame(1));
      expect(itemsPainted, equals([1]));

      tester.pumpWidget(buildFrame(2));
      expect(itemsPainted, equals([2]));
  });

  testWidgets('Can hit test an IndexedStack', (WidgetTester tester) {
      Key key = new Key('indexedStack');
      int itemCount = 3;
      List<int> itemsTapped;

      Widget buildFrame(int index) {
        itemsTapped = <int>[];
        List<Widget> items = new List<Widget>.generate(itemCount, (int i) {
          return new GestureDetector(child: new Text('$i'), onTap: () { itemsTapped.add(i); });
        });
        return new Center(child: new IndexedStack(children: items, key: key, index: index));
      }

      tester.pumpWidget(buildFrame(0));
      expect(itemsTapped, isEmpty);
      tester.tap(find.byKey(key));
      expect(itemsTapped, [0]);

      tester.pumpWidget(buildFrame(2));
      expect(itemsTapped, isEmpty);
      tester.tap(find.byKey(key));
      expect(itemsTapped, [2]);
  });

  testWidgets('Can set width and height', (WidgetTester tester) {
      Key key = new Key('container');

      BoxDecoration kBoxDecoration = new BoxDecoration(
        backgroundColor: new Color(0xFF00FF00)
      );

      tester.pumpWidget(
        new Stack(
          children: <Widget>[
            new Positioned(
              left: 10.0,
              width: 11.0,
              height: 12.0,
              child: new DecoratedBox(key: key, decoration: kBoxDecoration)
            )
          ]
        )
      );

      Element box;
      RenderBox renderBox;
      StackParentData parentData;

      box = tester.element(find.byKey(key));
      renderBox = box.renderObject;
      parentData = renderBox.parentData;
      expect(parentData.top, isNull);
      expect(parentData.right, isNull);
      expect(parentData.bottom, isNull);
      expect(parentData.left, equals(10.0));
      expect(parentData.width, equals(11.0));
      expect(parentData.height, equals(12.0));
      expect(parentData.offset.dx, equals(10.0));
      expect(parentData.offset.dy, equals(0.0));
      expect(renderBox.size.width, equals(11.0));
      expect(renderBox.size.height, equals(12.0));

      tester.pumpWidget(
        new Stack(
          children: <Widget>[
            new Positioned(
              right: 10.0,
              width: 11.0,
              height: 12.0,
              child: new DecoratedBox(key: key, decoration: kBoxDecoration)
            )
          ]
        )
      );

      box = tester.element(find.byKey(key));
      renderBox = box.renderObject;
      parentData = renderBox.parentData;
      expect(parentData.top, isNull);
      expect(parentData.right, equals(10.0));
      expect(parentData.bottom, isNull);
      expect(parentData.left, isNull);
      expect(parentData.width, equals(11.0));
      expect(parentData.height, equals(12.0));
      expect(parentData.offset.dx, equals(779.0));
      expect(parentData.offset.dy, equals(0.0));
      expect(renderBox.size.width, equals(11.0));
      expect(renderBox.size.height, equals(12.0));
  });

}
