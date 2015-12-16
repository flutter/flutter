// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('Uncontested scrolls start immediately', () {
    testWidgets((WidgetTester tester) {
      TestPointer pointer = new TestPointer(7);

      bool didStartDrag = false;
      double updatedDragDelta;
      bool didEndDrag = false;

      Widget widget = new GestureDetector(
        onVerticalDragStart: (_) {
          didStartDrag = true;
        },
        onVerticalDragUpdate: (double scrollDelta) {
          updatedDragDelta = scrollDelta;
        },
        onVerticalDragEnd: (Offset velocity) {
          didEndDrag = true;
        },
        child: new Container(
          decoration: const BoxDecoration(
            backgroundColor: const Color(0xFF00FF00)
          )
        )
      );

      tester.pumpWidget(widget);
      expect(didStartDrag, isFalse);
      expect(updatedDragDelta, isNull);
      expect(didEndDrag, isFalse);

      Point firstLocation = new Point(10.0, 10.0);
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      expect(didStartDrag, isTrue);
      didStartDrag = false;
      expect(updatedDragDelta, isNull);
      expect(didEndDrag, isFalse);

      Point secondLocation = new Point(10.0, 9.0);
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      expect(didStartDrag, isFalse);
      expect(updatedDragDelta, -1.0);
      updatedDragDelta = null;
      expect(didEndDrag, isFalse);

      tester.dispatchEvent(pointer.up(), firstLocation);
      expect(didStartDrag, isFalse);
      expect(updatedDragDelta, isNull);
      expect(didEndDrag, isTrue);
      didEndDrag = false;

      tester.pumpWidget(new Container());
    });
  });

  test('Match two scroll gestures in succession', () {
    testWidgets((WidgetTester tester) {
      TestPointer pointer = new TestPointer(7);

      int gestureCount = 0;
      double dragDistance = 0.0;

      Point downLocation = new Point(10.0, 10.0);
      Point upLocation = new Point(10.0, 20.0);

      Widget widget = new GestureDetector(
        onVerticalDragUpdate: (double delta) { dragDistance += delta; },
        onVerticalDragEnd: (Offset velocity) { gestureCount += 1; },
        onHorizontalDragUpdate: (_) { fail("gesture should not match"); },
        onHorizontalDragEnd: (Offset velocity) { fail("gesture should not match"); },
        child: new Container(
          decoration: const BoxDecoration(
            backgroundColor: const Color(0xFF00FF00)
          )
        )
      );
      tester.pumpWidget(widget);

      tester.dispatchEvent(pointer.down(downLocation), downLocation);
      tester.dispatchEvent(pointer.move(upLocation), downLocation);
      tester.dispatchEvent(pointer.up(), downLocation);

      tester.dispatchEvent(pointer.down(downLocation), downLocation);
      tester.dispatchEvent(pointer.move(upLocation), downLocation);
      tester.dispatchEvent(pointer.up(), downLocation);

      expect(gestureCount, 2);
      expect(dragDistance, 20.0);

      tester.pumpWidget(new Container());
    });
  });

  test('Pan doesn\'t crash', () {
    testWidgets((WidgetTester tester) {
      bool didStartPan = false;
      Offset panDelta;
      bool didEndPan = false;

      tester.pumpWidget(
        new GestureDetector(
          onPanStart: (_) {
            didStartPan = true;
          },
          onPanUpdate: (Offset delta) {
            panDelta = delta;
          },
          onPanEnd: (_) {
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

      tester.scrollAt(new Point(10.0, 10.0), new Offset(20.0, 30.0));

      expect(didStartPan, isTrue);
      expect(panDelta.dx, 20.0);
      expect(panDelta.dy, 30.0);
      expect(didEndPan, isTrue);
    });
  });

  test('Translucent', () {
    testWidgets((WidgetTester tester) {
      bool didReceivePointerDown;
      bool didTap;

      void pumpWidgetTree(HitTestBehavior behavior) {
        tester.pumpWidget(
          new Stack([
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
          ])
        );
      }

      didReceivePointerDown = false;
      didTap = false;
      pumpWidgetTree(null);
      tester.tapAt(new Point(10.0, 10.0));
      expect(didReceivePointerDown, isTrue);
      expect(didTap, isTrue);

      didReceivePointerDown = false;
      didTap = false;
      pumpWidgetTree(HitTestBehavior.deferToChild);
      tester.tapAt(new Point(10.0, 10.0));
      expect(didReceivePointerDown, isTrue);
      expect(didTap, isFalse);

      didReceivePointerDown = false;
      didTap = false;
      pumpWidgetTree(HitTestBehavior.opaque);
      tester.tapAt(new Point(10.0, 10.0));
      expect(didReceivePointerDown, isFalse);
      expect(didTap, isTrue);

      didReceivePointerDown = false;
      didTap = false;
      pumpWidgetTree(HitTestBehavior.translucent);
      tester.tapAt(new Point(10.0, 10.0));
      expect(didReceivePointerDown, isTrue);
      expect(didTap, isTrue);

    });
  });
}
