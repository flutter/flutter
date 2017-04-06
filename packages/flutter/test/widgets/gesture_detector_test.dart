// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Uncontested scrolls start immediately', (WidgetTester tester) async {
    bool didStartDrag = false;
    double updatedDragDelta;
    bool didEndDrag = false;

    final Widget widget = new GestureDetector(
      onVerticalDragStart: (DragStartDetails details) {
        didStartDrag = true;
      },
      onVerticalDragUpdate: (DragUpdateDetails details) {
        updatedDragDelta = details.primaryDelta;
      },
      onVerticalDragEnd: (DragEndDetails details) {
        didEndDrag = true;
      },
      child: new Container(
        decoration: const BoxDecoration(
          backgroundColor: const Color(0xFF00FF00)
        )
      )
    );

    await tester.pumpWidget(widget);
    expect(didStartDrag, isFalse);
    expect(updatedDragDelta, isNull);
    expect(didEndDrag, isFalse);

    final Offset firstLocation = const Offset(10.0, 10.0);
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    expect(didStartDrag, isTrue);
    didStartDrag = false;
    expect(updatedDragDelta, isNull);
    expect(didEndDrag, isFalse);

    final Offset secondLocation = const Offset(10.0, 9.0);
    await gesture.moveTo(secondLocation);
    expect(didStartDrag, isFalse);
    expect(updatedDragDelta, -1.0);
    updatedDragDelta = null;
    expect(didEndDrag, isFalse);

    await gesture.up();
    expect(didStartDrag, isFalse);
    expect(updatedDragDelta, isNull);
    expect(didEndDrag, isTrue);
    didEndDrag = false;

    await tester.pumpWidget(new Container());
  });

  testWidgets('Match two scroll gestures in succession', (WidgetTester tester) async {
    int gestureCount = 0;
    double dragDistance = 0.0;

    final Offset downLocation = const Offset(10.0, 10.0);
    final Offset upLocation = const Offset(10.0, 20.0);

    final Widget widget = new GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails details) { dragDistance += details.primaryDelta; },
      onVerticalDragEnd: (DragEndDetails details) { gestureCount += 1; },
      onHorizontalDragUpdate: (DragUpdateDetails details) { fail("gesture should not match"); },
      onHorizontalDragEnd: (DragEndDetails details) { fail("gesture should not match"); },
      child: new Container(
        decoration: const BoxDecoration(
          backgroundColor: const Color(0xFF00FF00)
        )
      )
    );
    await tester.pumpWidget(widget);

    TestGesture gesture = await tester.startGesture(downLocation, pointer: 7);
    await gesture.moveTo(upLocation);
    await gesture.up();

    gesture = await tester.startGesture(downLocation, pointer: 7);
    await gesture.moveTo(upLocation);
    await gesture.up();

    expect(gestureCount, 2);
    expect(dragDistance, 20.0);

    await tester.pumpWidget(new Container());
  });

  testWidgets('Pan doesn\'t crash', (WidgetTester tester) async {
    bool didStartPan = false;
    Offset panDelta;
    bool didEndPan = false;

    await tester.pumpWidget(
      new GestureDetector(
        onPanStart: (DragStartDetails details) {
          didStartPan = true;
        },
        onPanUpdate: (DragUpdateDetails details) {
          panDelta = details.delta;
        },
        onPanEnd: (DragEndDetails details) {
          didEndPan = true;
        },
        child: new Container(
          decoration: const BoxDecoration(
            backgroundColor: const Color(0xFF00FF00)
          )
        )
      )
    );

    expect(didStartPan, isFalse);
    expect(panDelta, isNull);
    expect(didEndPan, isFalse);

    await tester.dragFrom(const Offset(10.0, 10.0), const Offset(20.0, 30.0));

    expect(didStartPan, isTrue);
    expect(panDelta.dx, 20.0);
    expect(panDelta.dy, 30.0);
    expect(didEndPan, isTrue);
  });

  testWidgets('Translucent', (WidgetTester tester) async {
    bool didReceivePointerDown;
    bool didTap;

    Future<Null> pumpWidgetTree(HitTestBehavior behavior) {
      return tester.pumpWidget(
        new Stack(
          children: <Widget>[
            new Listener(
              onPointerDown: (_) {
                didReceivePointerDown = true;
              },
              child: new Container(
                width: 100.0,
                height: 100.0,
                decoration: const BoxDecoration(
                  backgroundColor: const Color(0xFF00FF00)
                )
              )
            ),
            new Container(
              width: 100.0,
              height: 100.0,
              child: new GestureDetector(
                onTap: () {
                  didTap = true;
                },
                behavior: behavior
              )
            )
          ]
        )
      );
    }

    didReceivePointerDown = false;
    didTap = false;
    await pumpWidgetTree(null);
    await tester.tapAt(const Offset(10.0, 10.0));
    expect(didReceivePointerDown, isTrue);
    expect(didTap, isTrue);

    didReceivePointerDown = false;
    didTap = false;
    await pumpWidgetTree(HitTestBehavior.deferToChild);
    await tester.tapAt(const Offset(10.0, 10.0));
    expect(didReceivePointerDown, isTrue);
    expect(didTap, isFalse);

    didReceivePointerDown = false;
    didTap = false;
    await pumpWidgetTree(HitTestBehavior.opaque);
    await tester.tapAt(const Offset(10.0, 10.0));
    expect(didReceivePointerDown, isFalse);
    expect(didTap, isTrue);

    didReceivePointerDown = false;
    didTap = false;
    await pumpWidgetTree(HitTestBehavior.translucent);
    await tester.tapAt(const Offset(10.0, 10.0));
    expect(didReceivePointerDown, isTrue);
    expect(didTap, isTrue);

  });

  testWidgets('Empty', (WidgetTester tester) async {
    bool didTap = false;
    await tester.pumpWidget(
      new Center(
        child: new GestureDetector(
          onTap: () {
            didTap = true;
          },
        )
      )
    );
    expect(didTap, isFalse);
    await tester.tapAt(const Offset(10.0, 10.0));
    expect(didTap, isTrue);
  });

  testWidgets('Only container', (WidgetTester tester) async {
    bool didTap = false;
    await tester.pumpWidget(
      new Center(
        child: new GestureDetector(
          onTap: () {
            didTap = true;
          },
          child: new Container(),
        )
      )
    );
    expect(didTap, isFalse);
    await tester.tapAt(const Offset(10.0, 10.0));
    expect(didTap, isFalse);
  });
}
