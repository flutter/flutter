// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  });
}
