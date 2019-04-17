// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

void main() {
  testWidgets('Events bubble up the tree', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      Listener(
        onPointerDown: (_) {
          log.add('top');
        },
        child: Listener(
          onPointerDown: (_) {
            log.add('middle');
          },
          child: DecoratedBox(
            decoration: const BoxDecoration(),
            child: Listener(
              onPointerDown: (_) {
                log.add('bottom');
              },
              child: const Text('X', textDirection: TextDirection.ltr),
            ),
          ),
        ),
      )
    );

    await tester.tap(find.text('X'));

    expect(log, equals(<String>[
      'bottom',
      'middle',
      'top',
    ]));
  });

  group('Listener hover detection', () {
    testWidgets('detects pointer enter', (WidgetTester tester) async {
      PointerEnterEvent enter;
      PointerHoverEvent move;
      PointerExitEvent exit;
      await tester.pumpWidget(Center(
        child: Listener(
          child: Container(
            color: const Color.fromARGB(0xff, 0xff, 0x00, 0x00),
            width: 100.0,
            height: 100.0,
          ),
          onPointerEnter: (PointerEnterEvent details) => enter = details,
          onPointerHover: (PointerHoverEvent details) => move = details,
          onPointerExit: (PointerExitEvent details) => exit = details,
        ),
      ));
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(const Offset(400.0, 300.0));
      await tester.pump();
      expect(move, isNotNull);
      expect(move.position, equals(const Offset(400.0, 300.0)));
      expect(enter, isNotNull);
      expect(enter.position, equals(const Offset(400.0, 300.0)));
      expect(exit, isNull);
    });
    testWidgets('detects pointer exit', (WidgetTester tester) async {
      PointerEnterEvent enter;
      PointerHoverEvent move;
      PointerExitEvent exit;
      await tester.pumpWidget(Center(
        child: Listener(
          child: Container(
            width: 100.0,
            height: 100.0,
          ),
          onPointerEnter: (PointerEnterEvent details) => enter = details,
          onPointerHover: (PointerHoverEvent details) => move = details,
          onPointerExit: (PointerExitEvent details) => exit = details,
        ),
      ));
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(const Offset(400.0, 300.0));
      await tester.pump();
      move = null;
      enter = null;
      await gesture.moveTo(const Offset(1.0, 1.0));
      await tester.pump();
      expect(move, isNull);
      expect(enter, isNull);
      expect(exit, isNotNull);
      expect(exit.position, equals(const Offset(1.0, 1.0)));
    });
    testWidgets('detects pointer exit when widget disappears', (WidgetTester tester) async {
      PointerEnterEvent enter;
      PointerHoverEvent move;
      PointerExitEvent exit;
      await tester.pumpWidget(Center(
        child: Listener(
          child: Container(
            width: 100.0,
            height: 100.0,
          ),
          onPointerEnter: (PointerEnterEvent details) => enter = details,
          onPointerHover: (PointerHoverEvent details) => move = details,
          onPointerExit: (PointerExitEvent details) => exit = details,
        ),
      ));
      final RenderPointerListener renderListener = tester.renderObject(find.byType(Listener));
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(const Offset(400.0, 300.0));
      await tester.pump();
      expect(move, isNotNull);
      expect(move.position, equals(const Offset(400.0, 300.0)));
      expect(enter, isNotNull);
      expect(enter.position, equals(const Offset(400.0, 300.0)));
      expect(exit, isNull);
      await tester.pumpWidget(Center(
        child: Container(
          width: 100.0,
          height: 100.0,
        ),
      ));
      expect(exit, isNotNull);
      expect(exit.position, equals(const Offset(400.0, 300.0)));
      expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener.hoverAnnotation), isFalse);
    });
    testWidgets('Hover transfers between two listeners', (WidgetTester tester) async {
      final UniqueKey key1 = UniqueKey();
      final UniqueKey key2 = UniqueKey();
      final List<PointerEnterEvent> enter1 = <PointerEnterEvent>[];
      final List<PointerHoverEvent> move1 = <PointerHoverEvent>[];
      final List<PointerExitEvent> exit1 = <PointerExitEvent>[];
      final List<PointerEnterEvent> enter2 = <PointerEnterEvent>[];
      final List<PointerHoverEvent> move2 = <PointerHoverEvent>[];
      final List<PointerExitEvent> exit2 = <PointerExitEvent>[];
      void clearLists() {
        enter1.clear();
        move1.clear();
        exit1.clear();
        enter2.clear();
        move2.clear();
        exit2.clear();
      }

      await tester.pumpWidget(Container());
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(const Offset(400.0, 0.0));
      await tester.pump();
      await tester.pumpWidget(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Listener(
              key: key1,
              child: Container(
                width: 100.0,
                height: 100.0,
              ),
              onPointerEnter: (PointerEnterEvent details) => enter1.add(details),
              onPointerHover: (PointerHoverEvent details) => move1.add(details),
              onPointerExit: (PointerExitEvent details) => exit1.add(details),
            ),
            Listener(
              key: key2,
              child: Container(
                width: 100.0,
                height: 100.0,
              ),
              onPointerEnter: (PointerEnterEvent details) => enter2.add(details),
              onPointerHover: (PointerHoverEvent details) => move2.add(details),
              onPointerExit: (PointerExitEvent details) => exit2.add(details),
            ),
          ],
        ),
      );
      final RenderPointerListener renderListener1 = tester.renderObject(find.byKey(key1));
      final RenderPointerListener renderListener2 = tester.renderObject(find.byKey(key2));
      final Offset center1 = tester.getCenter(find.byKey(key1));
      final Offset center2 = tester.getCenter(find.byKey(key2));
      await gesture.moveTo(center1);
      await tester.pump();
      expect(move1, isNotEmpty);
      expect(move1.last.position, equals(center1));
      expect(enter1, isNotEmpty);
      expect(enter1.last.position, equals(center1));
      expect(exit1, isEmpty);
      expect(move2, isEmpty);
      expect(enter2, isEmpty);
      expect(exit2, isEmpty);
      expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener1.hoverAnnotation), isTrue);
      expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener2.hoverAnnotation), isTrue);
      clearLists();
      await gesture.moveTo(center2);
      await tester.pump();
      expect(move1, isEmpty);
      expect(enter1, isEmpty);
      expect(exit1, isNotEmpty);
      expect(exit1.last.position, equals(center2));
      expect(move2, isNotEmpty);
      expect(move2.last.position, equals(center2));
      expect(enter2, isNotEmpty);
      expect(enter2.last.position, equals(center2));
      expect(exit2, isEmpty);
      expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener1.hoverAnnotation), isTrue);
      expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener2.hoverAnnotation), isTrue);
      clearLists();
      await gesture.moveTo(const Offset(400.0, 450.0));
      await tester.pump();
      expect(move1, isEmpty);
      expect(enter1, isEmpty);
      expect(exit1, isEmpty);
      expect(move2, isEmpty);
      expect(enter2, isEmpty);
      expect(exit2, isNotEmpty);
      expect(exit2.last.position, equals(const Offset(400.0, 450.0)));
      expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener1.hoverAnnotation), isTrue);
      expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener2.hoverAnnotation), isTrue);
      clearLists();
      await tester.pumpWidget(Container());
      expect(move1, isEmpty);
      expect(enter1, isEmpty);
      expect(exit1, isEmpty);
      expect(move2, isEmpty);
      expect(enter2, isEmpty);
      expect(exit2, isEmpty);
      expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener1.hoverAnnotation), isFalse);
      expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener2.hoverAnnotation), isFalse);
    });

    testWidgets('works with transform', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/31986.
      final Key key = UniqueKey();
      const double scaleFactor = 2.0;
      const double localWidth = 150.0;
      const double localHeight = 100.0;
      final List<PointerEvent> events = <PointerEvent>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Transform.scale(
              scale: scaleFactor,
              child: Listener(
                onPointerEnter: (PointerEnterEvent event) {
                  events.add(event);
                },
                onPointerHover: (PointerHoverEvent event) {
                  events.add(event);
                },
                onPointerExit: (PointerExitEvent event) {
                  events.add(event);
                },
                child: Container(
                  key: key,
                  color: Colors.blue,
                  height: localHeight,
                  width: localWidth,
                  child: const Text('Hi'),
                ),
              ),
            ),
          ),
        ),
      );

      final Offset topLeft = tester.getTopLeft(find.byKey(key));
      final Offset topRight = tester.getTopRight(find.byKey(key));
      final Offset bottomLeft = tester.getBottomLeft(find.byKey(key));
      expect(topRight.dx - topLeft.dx, scaleFactor * localWidth);
      expect(bottomLeft.dy - topLeft.dy, scaleFactor * localHeight);

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(topLeft - const Offset(1, 1));
      await tester.pump();
      expect(events, isEmpty);

      await gesture.moveTo(topLeft + const Offset(1, 1));
      await tester.pump();
      expect(events, hasLength(2));
      expect(events.first, isA<PointerEnterEvent>());
      expect(events.last, isA<PointerHoverEvent>());
      events.clear();

      await gesture.moveTo(bottomLeft + const Offset(1, -1));
      await tester.pump();
      expect(events.single, isA<PointerHoverEvent>());
      expect(events.single.delta, const Offset(0.0, scaleFactor * localHeight - 2));
      events.clear();

      await gesture.moveTo(bottomLeft + const Offset(1, 1));
      await tester.pump();
      expect(events.single, isA<PointerExitEvent>());
      events.clear();
    });

    testWidgets('needsCompositing updates correctly and is respected', (WidgetTester tester) async {
      // Pretend that we have a mouse connected.
      final TestGesture gesture = await tester.startGesture(Offset.zero, kind: PointerDeviceKind.mouse);
      await gesture.up();

      await tester.pumpWidget(
        Transform.scale(
          scale: 2.0,
          child: Listener(
            onPointerDown: (PointerDownEvent _) { },
          ),
        ),
      );
      final RenderPointerListener listener = tester.renderObject(find.byType(Listener));
      expect(listener.needsCompositing, isFalse);
      // No TransformLayer for `Transform.scale` is added because composting is
      // not required and therefore the transform is executed on the canvas
      // directly. (One TransformLayer is always present for the root
      // transform.)
      expect(tester.layers.whereType<TransformLayer>(), hasLength(1));

      await tester.pumpWidget(
        Transform.scale(
          scale: 2.0,
          child: Listener(
            onPointerDown: (PointerDownEvent _) { },
            onPointerHover: (PointerHoverEvent _) { },
          ),
        ),
      );
      expect(listener.needsCompositing, isTrue);
      // Composting is required, therefore a dedicated TransformLayer for
      // `Transform.scale` is added.
      expect(tester.layers.whereType<TransformLayer>(), hasLength(2));

      await tester.pumpWidget(
        Transform.scale(
          scale: 2.0,
          child: Listener(
            onPointerDown: (PointerDownEvent _) { },
          ),
        ),
      );
      expect(listener.needsCompositing, isFalse);
      // TransformLayer for `Transform.scale` is removed again as transform is
      // executed directly on the canvas.
      expect(tester.layers.whereType<TransformLayer>(), hasLength(1));
    });
  });

  group('transformed events', () {
    testWidgets('simple offset for touch', (WidgetTester tester) async {
      final List<PointerEvent> events = <PointerEvent>[];
      final Key key = UniqueKey();

      await tester.pumpWidget(
        Center(
          child: Listener(
            onPointerDown: (PointerDownEvent event) {
              events.add(event);
            },
            onPointerUp: (PointerUpEvent event) {
            events.add(event);
            },
            onPointerMove: (PointerMoveEvent event) {
              events.add(event);
            },
            onPointerEnter: (PointerEnterEvent event) {
              events.add(event);
            },
            onPointerHover: (PointerHoverEvent event) {
              events.add(event);
            },
            onPointerExit: (PointerExitEvent event) {
              events.add(event);
            },
            child: Container(
              key: key,
              color: Colors.red,
              height: 100,
              width: 100,
            ),
          ),
        ),
      );
      const Offset moved = Offset(20, 30);
      final Offset center = tester.getCenter(find.byKey(key));
      final Offset topLeft = tester.getTopLeft(find.byKey(key));
      final TestGesture gesture = await tester.startGesture(center);
      await gesture.moveBy(moved);
      await gesture.up();

      expect(events, hasLength(3));
      final PointerDownEvent down = events[0];
      final PointerMoveEvent move = events[1];
      final PointerUpEvent up = events[2];

      final Matrix4 expectedTransform = Matrix4.translationValues(-topLeft.dx, -topLeft.dy, 0);

      expect(center, isNot(const Offset(50, 50)));

      expect(down.localPosition, const Offset(50, 50));
      expect(down.position, center);
      expect(down.delta, Offset.zero);
      expect(down.localDelta, Offset.zero);
      expect(down.transform, expectedTransform);

      expect(move.localPosition, const Offset(50, 50) + moved);
      expect(move.position, center + moved);
      expect(move.delta, moved);
      expect(move.localDelta, moved);
      expect(move.transform, expectedTransform);

      expect(up.localPosition, const Offset(50, 50) + moved);
      expect(up.position, center + moved);
      expect(up.delta, Offset.zero);
      expect(up.localDelta, Offset.zero);
      expect(up.transform, expectedTransform);
    });

    testWidgets('scaled for touch', (WidgetTester tester) async {
      final List<PointerEvent> events = <PointerEvent>[];
      final Key key = UniqueKey();

      const double scaleFactor = 2;

      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: Transform(
            transform: Matrix4.identity()..scale(scaleFactor),
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                events.add(event);
              },
              onPointerUp: (PointerUpEvent event) {
                events.add(event);
              },
              onPointerMove: (PointerMoveEvent event) {
                events.add(event);
              },
              child: Container(
                key: key,
                color: Colors.red,
                height: 100,
                width: 100,
              ),
            ),
          ),
        ),
      );
      const Offset moved = Offset(20, 30);
      final Offset center = tester.getCenter(find.byKey(key));
      final TestGesture gesture = await tester.startGesture(center);
      await gesture.moveBy(moved);
      await gesture.up();

      expect(events, hasLength(3));
      final PointerDownEvent down = events[0];
      final PointerMoveEvent move = events[1];
      final PointerUpEvent up = events[2];

      final Matrix4 expectedTransform = Matrix4.identity()
        ..scale(1 / scaleFactor, 1 / scaleFactor, 1.0);

      expect(center, isNot(const Offset(50, 50)));

      expect(down.localPosition, const Offset(50, 50));
      expect(down.position, center);
      expect(down.delta, Offset.zero);
      expect(down.localDelta, Offset.zero);
      expect(down.transform, expectedTransform);

      expect(move.localPosition, const Offset(50, 50) + moved / scaleFactor);
      expect(move.position, center + moved);
      expect(move.delta, moved);
      expect(move.localDelta, moved / scaleFactor);
      expect(move.transform, expectedTransform);

      expect(up.localPosition, const Offset(50, 50) + moved / scaleFactor);
      expect(up.position, center + moved);
      expect(up.delta, Offset.zero);
      expect(up.localDelta, Offset.zero);
      expect(up.transform, expectedTransform);
    });

    testWidgets('scaled and offset for touch', (WidgetTester tester) async {
      final List<PointerEvent> events = <PointerEvent>[];
      final Key key = UniqueKey();

      const double scaleFactor = 2;

      await tester.pumpWidget(
        Center(
          child: Transform(
            transform: Matrix4.identity()..scale(scaleFactor),
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                events.add(event);
              },
              onPointerUp: (PointerUpEvent event) {
                events.add(event);
              },
              onPointerMove: (PointerMoveEvent event) {
                events.add(event);
              },
              child: Container(
                key: key,
                color: Colors.red,
                height: 100,
                width: 100,
              ),
            ),
          ),
        ),
      );
      const Offset moved = Offset(20, 30);
      final Offset center = tester.getCenter(find.byKey(key));
      final Offset topLeft = tester.getTopLeft(find.byKey(key));
      final TestGesture gesture = await tester.startGesture(center);
      await gesture.moveBy(moved);
      await gesture.up();

      expect(events, hasLength(3));
      final PointerDownEvent down = events[0];
      final PointerMoveEvent move = events[1];
      final PointerUpEvent up = events[2];

      final Matrix4 expectedTransform = Matrix4.identity()
        ..scale(1 / scaleFactor, 1 / scaleFactor, 1.0)
        ..translate(-topLeft.dx, -topLeft.dy, 0);

      expect(center, isNot(const Offset(50, 50)));

      expect(down.localPosition, const Offset(50, 50));
      expect(down.position, center);
      expect(down.delta, Offset.zero);
      expect(down.localDelta, Offset.zero);
      expect(down.transform, expectedTransform);

      expect(move.localPosition, const Offset(50, 50) + moved / scaleFactor);
      expect(move.position, center + moved);
      expect(move.delta, moved);
      expect(move.localDelta, moved / scaleFactor);
      expect(move.transform, expectedTransform);

      expect(up.localPosition, const Offset(50, 50) + moved / scaleFactor);
      expect(up.position, center + moved);
      expect(up.delta, Offset.zero);
      expect(up.localDelta, Offset.zero);
      expect(up.transform, expectedTransform);
    });

    testWidgets('rotated for touch', (WidgetTester tester) async {
      final List<PointerEvent> events = <PointerEvent>[];
      final Key key = UniqueKey();

      await tester.pumpWidget(
        Center(
          child: Transform(
            transform: Matrix4.identity()..rotateZ(math.pi / 2), // 90 degrees clockwise
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                events.add(event);
              },
              onPointerUp: (PointerUpEvent event) {
                events.add(event);
              },
              onPointerMove: (PointerMoveEvent event) {
                events.add(event);
              },
              child: Container(
                key: key,
                color: Colors.red,
                height: 100,
                width: 100,
              ),
            ),
          ),
        ),
      );
      const Offset moved = Offset(20, 30);
      final Offset downPosition = tester.getCenter(find.byKey(key)) + const Offset(10, 5);
      final TestGesture gesture = await tester.startGesture(downPosition);
      await gesture.moveBy(moved);
      await gesture.up();

      expect(events, hasLength(3));
      final PointerDownEvent down = events[0];
      final PointerMoveEvent move = events[1];
      final PointerUpEvent up = events[2];

      const Offset offset = Offset((800 - 100) / 2, (600 - 100) / 2);
      final Matrix4 expectedTransform = Matrix4.identity()
        ..rotateZ(-math.pi / 2)
        ..translate(-offset.dx, -offset.dy, 0.0);

      final Offset localDownPosition = const Offset(50, 50) + const Offset(5, -10);
      expect(down.localPosition, within(distance: 0.001, from: localDownPosition));
      expect(down.position, downPosition);
      expect(down.delta, Offset.zero);
      expect(down.localDelta, Offset.zero);
      expect(down.transform, expectedTransform);

      const Offset localDelta = Offset(30, -20);
      expect(move.localPosition, within(distance: 0.001, from: localDownPosition + localDelta));
      expect(move.position, downPosition + moved);
      expect(move.delta, moved);
      expect(move.localDelta, localDelta);
      expect(move.transform, expectedTransform);

      expect(up.localPosition, within(distance: 0.001, from: localDownPosition + localDelta));
      expect(up.position, downPosition + moved);
      expect(up.delta, Offset.zero);
      expect(up.localDelta, Offset.zero);
      expect(up.transform, expectedTransform);
    });
  });
}
