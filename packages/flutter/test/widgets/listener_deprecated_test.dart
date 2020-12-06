// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

// The tests in this file are moved from listener_test.dart, which tests several
// deprecated APIs. The file should be removed once these parameters are.

class HoverClient extends StatefulWidget {
  const HoverClient({Key key, this.onHover, this.child}) : super(key: key);

  final ValueChanged<bool> onHover;
  final Widget child;

  @override
  HoverClientState createState() => HoverClientState();
}

class HoverClientState extends State<HoverClient> {
  static int numEntries = 0;
  static int numExits = 0;

  void _onExit(PointerExitEvent details) {
    numExits++;
    if (widget.onHover != null) {
      widget.onHover(false);
    }
  }

  void _onEnter(PointerEnterEvent details) {
    numEntries++;
    if (widget.onHover != null) {
      widget.onHover(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerEnter: _onEnter,
      onPointerExit: _onExit,
      child: widget.child,
    );
  }
}

class HoverFeedback extends StatefulWidget {
  const HoverFeedback({Key key}) : super(key: key);

  @override
  _HoverFeedbackState createState() => _HoverFeedbackState();
}

class _HoverFeedbackState extends State<HoverFeedback> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: HoverClient(
        onHover: (bool hovering) => setState(() => _hovering = hovering),
        child: Text(_hovering ? 'HOVERING' : 'not hovering'),
      ),
    );
  }
}

void main() {
  group('Listener hover detection', () {
    // TODO(tongmu): Remover this group of test after the deprecated callbacks
    // onPointer{Enter,Hover,Exit} are removed. They were kept for compatibility,
    // and the tests have been copied to mouse_region_test.
    // https://github.com/flutter/flutter/issues/36085
    setUp(() {
      HoverClientState.numExits = 0;
      HoverClientState.numEntries = 0;
    });

    testWidgets('detects pointer enter', (WidgetTester tester) async {
      PointerEnterEvent enter;
      PointerHoverEvent move;
      PointerExitEvent exit;
      await tester.pumpWidget(
        Center(
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
        ),
      );
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(const Offset(400.0, 300.0));
      expect(move, isNotNull);
      expect(move.position, equals(const Offset(400.0, 300.0)));
      expect(enter, isNotNull);
      expect(enter.position, equals(const Offset(400.0, 300.0)));
      expect(exit, isNull);
    });
    testWidgets('detects pointer exiting', (WidgetTester tester) async {
      PointerEnterEvent enter;
      PointerHoverEvent move;
      PointerExitEvent exit;
      await tester.pumpWidget(
        Center(
          child: Listener(
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
            onPointerEnter: (PointerEnterEvent details) => enter = details,
            onPointerHover: (PointerHoverEvent details) => move = details,
            onPointerExit: (PointerExitEvent details) => exit = details,
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(400.0, 300.0));
      addTearDown(gesture.removePointer);
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
    testWidgets('does not detect pointer exit when widget disappears', (WidgetTester tester) async {
      PointerEnterEvent enter;
      PointerHoverEvent move;
      PointerExitEvent exit;
      await tester.pumpWidget(
        Center(
          child: Listener(
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
            onPointerEnter: (PointerEnterEvent details) => enter = details,
            onPointerHover: (PointerHoverEvent details) => move = details,
            onPointerExit: (PointerExitEvent details) => exit = details,
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(400.0, 300.0));
      addTearDown(gesture.removePointer);
      await tester.pump();
      expect(move, isNull);
      expect(enter, isNotNull);
      expect(enter.position, equals(const Offset(400.0, 300.0)));
      expect(exit, isNull);
      await tester.pumpWidget(const Center(
        child: SizedBox(
          width: 100.0,
          height: 100.0,
        ),
      ));
      expect(exit, isNull);
    });
    testWidgets('Hover works with nested listeners', (WidgetTester tester) async {
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
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: const Offset(400.0, 0.0));
      await tester.pump();
      await tester.pumpWidget(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Listener(
              onPointerEnter: (PointerEnterEvent details) => enter1.add(details),
              onPointerHover: (PointerHoverEvent details) => move1.add(details),
              onPointerExit: (PointerExitEvent details) => exit1.add(details),
              key: key1,
              child: Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(50.0),
                child: Listener(
                  key: key2,
                  onPointerEnter: (PointerEnterEvent details) => enter2.add(details),
                  onPointerHover: (PointerHoverEvent details) => move2.add(details),
                  onPointerExit: (PointerExitEvent details) => exit2.add(details),
                  child: Container(),
                ),
              ),
            ),
          ],
        ),
      );
      Offset center = tester.getCenter(find.byKey(key2));
      await gesture.moveTo(center);
      await tester.pump();
      expect(move2, isNotEmpty);
      expect(enter2, isNotEmpty);
      expect(exit2, isEmpty);
      expect(move1, isNotEmpty);
      expect(move1.last.position, equals(center));
      expect(enter1, isNotEmpty);
      expect(enter1.last.position, equals(center));
      expect(exit1, isEmpty);
      clearLists();

      // Now make sure that exiting the child only triggers the child exit, not
      // the parent too.
      center = center - const Offset(75.0, 0.0);
      await gesture.moveTo(center);
      await tester.pumpAndSettle();
      expect(move2, isEmpty);
      expect(enter2, isEmpty);
      expect(exit2, isNotEmpty);
      expect(move1, isNotEmpty);
      expect(move1.last.position, equals(center));
      expect(enter1, isEmpty);
      expect(exit1, isEmpty);
      clearLists();
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
      addTearDown(gesture.removePointer);
      await gesture.moveTo(const Offset(400.0, 0.0));
      await tester.pump();
      await tester.pumpWidget(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Listener(
              key: key1,
              child: const SizedBox(
                width: 100.0,
                height: 100.0,
              ),
              onPointerEnter: (PointerEnterEvent details) => enter1.add(details),
              onPointerHover: (PointerHoverEvent details) => move1.add(details),
              onPointerExit: (PointerExitEvent details) => exit1.add(details),
            ),
            Listener(
              key: key2,
              child: const SizedBox(
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
      clearLists();
      await tester.pumpWidget(Container());
      expect(move1, isEmpty);
      expect(enter1, isEmpty);
      expect(exit1, isEmpty);
      expect(move2, isEmpty);
      expect(enter2, isEmpty);
      expect(exit2, isEmpty);
    });

    testWidgets('needsCompositing set when parent class needsCompositing is set', (WidgetTester tester) async {
      await tester.pumpWidget(
        Listener(
          onPointerEnter: (PointerEnterEvent _) {},
          child: const Opacity(opacity: 0.5, child: Placeholder()),
        ),
      );

      RenderPointerListener listener = tester.renderObject(find.byType(Listener).first);
      expect(listener.needsCompositing, isTrue);

      await tester.pumpWidget(
        Listener(
          onPointerEnter: (PointerEnterEvent _) {},
          child: const Placeholder(),
        ),
      );

      listener = tester.renderObject(find.byType(Listener).first);
      expect(listener.needsCompositing, isFalse);
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
      await gesture.addPointer(location: topLeft - const Offset(1, 1));
      addTearDown(gesture.removePointer);
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

    testWidgets('needsCompositing is always false', (WidgetTester tester) async {
      // Pretend that we have a mouse connected.
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

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
      expect(listener.needsCompositing, isFalse);
      // If compositing was required, a dedicated TransformLayer for
      // `Transform.scale` would be added.
      expect(tester.layers.whereType<TransformLayer>(), hasLength(1));
    });

    testWidgets("Callbacks aren't called during build", (WidgetTester tester) async {
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await tester.pumpWidget(
        const Center(child: HoverFeedback()),
      );

      await gesture.moveTo(tester.getCenter(find.byType(Text)));
      await tester.pumpAndSettle();
      expect(HoverClientState.numEntries, equals(1));
      expect(HoverClientState.numExits, equals(0));
      expect(find.text('HOVERING'), findsOneWidget);

      await tester.pumpWidget(
        Container(),
      );
      await tester.pump();
      expect(HoverClientState.numEntries, equals(1));
      // Unmounting a MouseRegion doesn't trigger onExit
      expect(HoverClientState.numExits, equals(0));

      await tester.pumpWidget(
        const Center(child: HoverFeedback()),
      );
      await tester.pump();
      expect(HoverClientState.numEntries, equals(2));
      expect(HoverClientState.numExits, equals(0));
    });

    testWidgets("Listener activate/deactivate don't duplicate annotations", (WidgetTester tester) async {
      final GlobalKey feedbackKey = GlobalKey();
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await tester.pumpWidget(
        Center(child: HoverFeedback(key: feedbackKey)),
      );

      await gesture.moveTo(tester.getCenter(find.byType(Text)));
      await tester.pumpAndSettle();
      expect(HoverClientState.numEntries, equals(1));
      expect(HoverClientState.numExits, equals(0));
      expect(find.text('HOVERING'), findsOneWidget);

      await tester.pumpWidget(
        Center(child: Container(child: HoverFeedback(key: feedbackKey))),
      );
      await tester.pump();
      expect(HoverClientState.numEntries, equals(1));
      expect(HoverClientState.numExits, equals(0));
      await tester.pumpWidget(
        Container(),
      );
      await tester.pump();
      expect(HoverClientState.numEntries, equals(1));
      // Unmounting a MouseRegion doesn't trigger onExit
      expect(HoverClientState.numExits, equals(0));
    });

    testWidgets('Exit event when unplugging mouse should have a position', (WidgetTester tester) async {
      final List<PointerEnterEvent> enter = <PointerEnterEvent>[];
      final List<PointerHoverEvent> hover = <PointerHoverEvent>[];
      final List<PointerExitEvent> exit = <PointerExitEvent>[];

      await tester.pumpWidget(
        Center(
          child: Listener(
            onPointerEnter: (PointerEnterEvent e) => enter.add(e),
            onPointerHover: (PointerHoverEvent e) => hover.add(e),
            onPointerExit: (PointerExitEvent e) => exit.add(e),
            child: const SizedBox(
              height: 100.0,
              width: 100.0,
            ),
          ),
        ),
      );

      // Plug-in a mouse and move it to the center of the container.
      TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(() => gesture?.removePointer());
      await tester.pumpAndSettle();
      await gesture.moveTo(tester.getCenter(find.byType(SizedBox)));

      expect(enter.length, 1);
      expect(enter.single.position, const Offset(400.0, 300.0));
      expect(hover.length, 1);
      expect(hover.single.position, const Offset(400.0, 300.0));
      expect(exit.length, 0);

      enter.clear();
      hover.clear();
      exit.clear();

      // Unplug the mouse.
      await gesture.removePointer();
      gesture = null;
      await tester.pumpAndSettle();

      expect(enter.length, 0);
      expect(hover.length, 0);
      expect(exit.length, 1);
      expect(exit.single.position, const Offset(400.0, 300.0));
      expect(exit.single.delta, Offset.zero);
    });
  });
}
