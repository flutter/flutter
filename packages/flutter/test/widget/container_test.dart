// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Can be placed in an infinite box', (WidgetTester tester) async {
    await tester.pumpWidget(new Block(children: <Widget>[new Container()]));
  });

  testWidgets('Size of a container within an align', (WidgetTester tester) async {
    GlobalKey innerContainerKey = new GlobalKey();

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          width: 300.0,
          height: 400.0,
          child: new Align(
            alignment:FractionalOffset.topLeft,
            child: new Container(
              key: innerContainerKey,
              width: 50.0,
              height: 100.0,
            ),
          ),
        ),
      ),
    );

    final Size size = innerContainerKey.currentContext.size;
    expect(size.width, equals(50.0));
    expect(size.height, equals(100.0));
  });

  testWidgets('Size of an aligned container\'s implicit child', (WidgetTester tester) async {
    GlobalKey innerContainerKey = new GlobalKey();

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          width: 300.0,
          height: 400.0,
          child: new Container(
            key: innerContainerKey,
            width: 50.0,
            height: 100.0,
            alignment:FractionalOffset.topLeft,
            decoration: new BoxDecoration(backgroundColor: const Color(0xFF00FF00)),
          ),
        ),
      ),
    );

    final Size size = innerContainerKey.currentContext.size;
    expect(size.width, equals(300.0));
    expect(size.height, equals(400.0));

    RenderBox box = tester.renderObject(find.byType(DecoratedBox));
    expect(box.size.width, equals(50.0));
    expect(box.size.height, equals(100.0));
  });

  testWidgets('Position of an aligned and transformed container\'s implicit child', (WidgetTester tester) async {
    GlobalKey innerContainerKey = new GlobalKey();

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          width: 300.0,
          height: 400.0,
          child: new Container(
            key: innerContainerKey,
            width: 50.0,
            height: 100.0,
            alignment:FractionalOffset.topLeft,
            decoration: new BoxDecoration(backgroundColor: const Color(0xFF00FF00)),
            transform: new Matrix4.identity()..translate(100.0, 200.0),
          ),
        ),
      ),
    );

    final Size size = innerContainerKey.currentContext.size;
    expect(size.width, equals(300.0));
    expect(size.height, equals(400.0));

    RenderBox decoratedBox = tester.renderObject(find.byType(DecoratedBox));
    expect(decoratedBox.size.width, equals(50.0));
    expect(decoratedBox.size.height, equals(100.0));

    RenderBox containerBox = innerContainerKey.currentContext.findRenderObject();
    Point decoratedBoxOrigin = containerBox.globalToLocal(decoratedBox.localToGlobal(Point.origin));
    expect(decoratedBoxOrigin.x, equals(100.0));
    expect(decoratedBoxOrigin.y, equals(200.0));
  });

  testWidgets('Position of an aligned and transformed container\'s implicit children', (WidgetTester tester) async {
    GlobalKey innerContainerKey = new GlobalKey();

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          width: 300.0,
          height: 400.0,
          child: new Container(
            key: innerContainerKey,
            width: 50.0,
            height: 100.0,
            alignment:FractionalOffset.topLeft,
            decoration: new BoxDecoration(backgroundColor: const Color(0xFF00FF00)),
            foregroundDecoration: new BoxDecoration(backgroundColor: const Color(0xFFFF0000)),
            transform: new Matrix4.identity()..translate(100.0, 200.0),
          ),
        ),
      ),
    );

    final Size size = innerContainerKey.currentContext.size;
    expect(size.width, equals(300.0));
    expect(size.height, equals(400.0));

    RenderBox containerBox = innerContainerKey.currentContext.findRenderObject();
    List<RenderObject> renderers = tester.renderObjectList(find.byType(DecoratedBox)).toList();
    expect(renderers.length, equals(2));
    for (RenderObject renderer in renderers) {
      RenderBox decoratedBox = renderer;
      expect(decoratedBox.size.width, equals(50.0));
      expect(decoratedBox.size.height, equals(100.0));

      Point decoratedBoxOrigin = containerBox.globalToLocal(decoratedBox.localToGlobal(Point.origin));
      expect(decoratedBoxOrigin.x, equals(100.0));
      expect(decoratedBoxOrigin.y, equals(200.0));
    }
  });

  testWidgets('Position of an aligned container\'s implicit children with margins', (WidgetTester tester) async {
    GlobalKey innerContainerKey = new GlobalKey();

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          width: 300.0,
          height: 400.0,
          child: new Container(
            key: innerContainerKey,
            width: 50.0,
            height: 100.0,
            alignment:FractionalOffset.topLeft,
            decoration: new BoxDecoration(backgroundColor: const Color(0xFF00FF00)),
            foregroundDecoration: new BoxDecoration(backgroundColor: const Color(0xFFFF0000)),
            margin: const EdgeInsets.only(left: 25.0, top: 75.0),
          ),
        ),
      ),
    );

    final Size size = innerContainerKey.currentContext.size;
    expect(size.width, equals(300.0));
    expect(size.height, equals(400.0));

    RenderBox containerBox = innerContainerKey.currentContext.findRenderObject();
    List<RenderObject> renderers = tester.renderObjectList(find.byType(DecoratedBox)).toList();
    expect(renderers.length, equals(2));
    for (RenderObject renderer in renderers) {
      RenderBox decoratedBox = renderer;
      expect(decoratedBox.size.width, equals(50.0));
      expect(decoratedBox.size.height, equals(100.0));

      Point decoratedBoxOrigin = containerBox.globalToLocal(decoratedBox.localToGlobal(Point.origin));
      expect(decoratedBoxOrigin.x, equals(25.0));
      expect(decoratedBoxOrigin.y, equals(75.0));
    }
  });

}
