// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

class HoverClient extends StatefulWidget {
  const HoverClient({
    Key key,
    this.onHover,
    this.child,
    this.onEnter,
    this.onExit,
  }) : super(key: key);

  final ValueChanged<bool> onHover;
  final Widget child;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  @override
  HoverClientState createState() => HoverClientState();
}

class HoverClientState extends State<HoverClient> {
  void _onExit(PointerExitEvent details) {
    if (widget.onExit != null) {
      widget.onExit();
    }
    if (widget.onHover != null) {
      widget.onHover(false);
    }
  }

  void _onEnter(PointerEnterEvent details) {
    if (widget.onEnter != null) {
      widget.onEnter();
    }
    if (widget.onHover != null) {
      widget.onHover(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: widget.child,
    );
  }
}

class HoverFeedback extends StatefulWidget {
  const HoverFeedback({Key key, this.onEnter, this.onExit}) : super(key: key);

  final VoidCallback onEnter;
  final VoidCallback onExit;

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
        onEnter: widget.onEnter,
        onExit: widget.onExit,
        child: Text(_hovering ? 'HOVERING' : 'not hovering'),
      ),
    );
  }
}

void main() {
  testWidgets('detects pointer enter', (WidgetTester tester) async {
    PointerEnterEvent enter;
    PointerHoverEvent move;
    PointerExitEvent exit;
    await tester.pumpWidget(Center(
      child: MouseRegion(
        child: Container(
          color: const Color.fromARGB(0xff, 0xff, 0x00, 0x00),
          width: 100.0,
          height: 100.0,
        ),
        onEnter: (PointerEnterEvent details) => enter = details,
        onHover: (PointerHoverEvent details) => move = details,
        onExit: (PointerExitEvent details) => exit = details,
      ),
    ));
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(const Offset(400.0, 300.0));
    await tester.pump();
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
    await tester.pumpWidget(Center(
      child: MouseRegion(
        child: Container(
          width: 100.0,
          height: 100.0,
        ),
        onEnter: (PointerEnterEvent details) => enter = details,
        onHover: (PointerHoverEvent details) => move = details,
        onExit: (PointerExitEvent details) => exit = details,
      ),
    ));
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
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
      child: MouseRegion(
        child: Container(
          width: 100.0,
          height: 100.0,
        ),
        onEnter: (PointerEnterEvent details) => enter = details,
        onHover: (PointerHoverEvent details) => move = details,
        onExit: (PointerExitEvent details) => exit = details,
      ),
    ));
    final RenderMouseRegion renderListener = tester.renderObject(find.byType(MouseRegion));
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
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
    await gesture.moveTo(const Offset(400.0, 0.0));
    await tester.pump();
    await tester.pumpWidget(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          MouseRegion(
            onEnter: (PointerEnterEvent details) => enter1.add(details),
            onHover: (PointerHoverEvent details) => move1.add(details),
            onExit: (PointerExitEvent details) => exit1.add(details),
            key: key1,
            child: Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(50.0),
              child: MouseRegion(
                key: key2,
                onEnter: (PointerEnterEvent details) => enter2.add(details),
                onHover: (PointerHoverEvent details) => move2.add(details),
                onExit: (PointerExitEvent details) => exit2.add(details),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
    final RenderMouseRegion renderListener1 = tester.renderObject(find.byKey(key1));
    final RenderMouseRegion renderListener2 = tester.renderObject(find.byKey(key2));
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
    expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener1.hoverAnnotation), isTrue);
    expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener2.hoverAnnotation), isTrue);
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
    expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener1.hoverAnnotation), isTrue);
    expect(tester.binding.mouseTracker.isAnnotationAttached(renderListener2.hoverAnnotation), isTrue);
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
          MouseRegion(
            key: key1,
            child: Container(
              width: 100.0,
              height: 100.0,
            ),
            onEnter: (PointerEnterEvent details) => enter1.add(details),
            onHover: (PointerHoverEvent details) => move1.add(details),
            onExit: (PointerExitEvent details) => exit1.add(details),
          ),
          MouseRegion(
            key: key2,
            child: Container(
              width: 100.0,
              height: 100.0,
            ),
            onEnter: (PointerEnterEvent details) => enter2.add(details),
            onHover: (PointerHoverEvent details) => move2.add(details),
            onExit: (PointerExitEvent details) => exit2.add(details),
          ),
        ],
      ),
    );
    final RenderMouseRegion renderListener1 = tester.renderObject(find.byKey(key1));
    final RenderMouseRegion renderListener2 = tester.renderObject(find.byKey(key2));
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

  testWidgets('MouseRegion uses updated callbacks', (WidgetTester tester) async {
    final List<String> logs = <String>[];
    Widget hoverableContainer({
      PointerEnterEventListener onEnter,
      PointerHoverEventListener onHover,
      PointerExitEventListener onExit,
    }) {
      return Container(
        alignment: Alignment.topLeft,
        child: MouseRegion(
          child: Container(
            color: const Color.fromARGB(0xff, 0xff, 0x00, 0x00),
            width: 100.0,
            height: 100.0,
          ),
          onEnter: onEnter,
          onHover: onHover,
          onExit: onExit,
        ),
      );
    }

    await tester.pumpWidget(hoverableContainer(
      onEnter: (PointerEnterEvent details) => logs.add('enter1'),
      onHover: (PointerHoverEvent details) => logs.add('hover1'),
      onExit: (PointerExitEvent details) => logs.add('exit1'),
    ));

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);

    // Start outside, move inside, then move outside
    await gesture.moveTo(const Offset(150.0, 150.0));
    await tester.pump();
    await gesture.moveTo(const Offset(50.0, 50.0));
    await tester.pump();
    await gesture.moveTo(const Offset(150.0, 150.0));
    await tester.pump();
    expect(logs, <String>['enter1', 'hover1', 'exit1']);
    logs.clear();

    // Same tests but with updated callbacks
    await tester.pumpWidget(hoverableContainer(
      onEnter: (PointerEnterEvent details) => logs.add('enter2'),
      onHover: (PointerHoverEvent details) => logs.add('hover2'),
      onExit: (PointerExitEvent details) => logs.add('exit2'),
    ));
    await gesture.moveTo(const Offset(150.0, 150.0));
    await tester.pump();
    await gesture.moveTo(const Offset(50.0, 50.0));
    await tester.pump();
    await gesture.moveTo(const Offset(150.0, 150.0));
    await tester.pump();
    expect(logs, <String>['enter2', 'hover2', 'exit2']);
  });

  testWidgets('needsCompositing set when parent class needsCompositing is set', (WidgetTester tester) async {
    await tester.pumpWidget(
      MouseRegion(
        onEnter: (PointerEnterEvent _) {},
        child: const Opacity(opacity: 0.5, child: Placeholder()),
      ),
    );

    RenderMouseRegion listener = tester.renderObject(find.byType(MouseRegion).first);
    expect(listener.needsCompositing, isTrue);

    await tester.pumpWidget(
      MouseRegion(
        onEnter: (PointerEnterEvent _) {},
        child: const Placeholder(),
      ),
    );

    listener = tester.renderObject(find.byType(MouseRegion).first);
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
            child: MouseRegion(
              onEnter: (PointerEnterEvent event) {
                events.add(event);
              },
              onHover: (PointerHoverEvent event) {
                events.add(event);
              },
              onExit: (PointerExitEvent event) {
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
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
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
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(
      Transform.scale(
        scale: 2.0,
        child: const MouseRegion(),
      ),
    );
    final RenderMouseRegion listener = tester.renderObject(find.byType(MouseRegion));
    expect(listener.needsCompositing, isFalse);
    // No TransformLayer for `Transform.scale` is added because composting is
    // not required and therefore the transform is executed on the canvas
    // directly. (One TransformLayer is always present for the root
    // transform.)
    expect(tester.layers.whereType<TransformLayer>(), hasLength(1));

    await tester.pumpWidget(
      Transform.scale(
        scale: 2.0,
        child: MouseRegion(
          onHover: (PointerHoverEvent _) {},
        ),
      ),
    );
    expect(listener.needsCompositing, isTrue);
    // Compositing is required, therefore a dedicated TransformLayer for
    // `Transform.scale` is added.
    expect(tester.layers.whereType<TransformLayer>(), hasLength(2));

    await tester.pumpWidget(
      Transform.scale(
        scale: 2.0,
        child: const MouseRegion(),
      ),
    );
    expect(listener.needsCompositing, isFalse);
    // TransformLayer for `Transform.scale` is removed again as transform is
    // executed directly on the canvas.
    expect(tester.layers.whereType<TransformLayer>(), hasLength(1));
  });

  testWidgets("Callbacks aren't called during build", (WidgetTester tester) async {
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);

    int numEntries = 0;
    int numExits = 0;

    await tester.pumpWidget(
      Center(
          child: HoverFeedback(
        onEnter: () => numEntries++,
        onExit: () => numExits++,
      )),
    );

    await gesture.moveTo(tester.getCenter(find.byType(Text)));
    await tester.pumpAndSettle();
    expect(numEntries, equals(1));
    expect(numExits, equals(0));
    expect(find.text('HOVERING'), findsOneWidget);

    await tester.pumpWidget(
      Container(),
    );
    await tester.pump();
    expect(numEntries, equals(1));
    expect(numExits, equals(1));

    await tester.pumpWidget(
      Center(
          child: HoverFeedback(
        onEnter: () => numEntries++,
        onExit: () => numExits++,
      )),
    );
    await tester.pump();
    expect(numEntries, equals(2));
    expect(numExits, equals(1));
  });

  testWidgets("MouseRegion activate/deactivate don't duplicate annotations", (WidgetTester tester) async {
    final GlobalKey feedbackKey = GlobalKey();
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);

    int numEntries = 0;
    int numExits = 0;

    await tester.pumpWidget(
      Center(
          child: HoverFeedback(
        key: feedbackKey,
        onEnter: () => numEntries++,
        onExit: () => numExits++,
      )),
    );

    await gesture.moveTo(tester.getCenter(find.byType(Text)));
    await tester.pumpAndSettle();
    expect(numEntries, equals(1));
    expect(numExits, equals(0));
    expect(find.text('HOVERING'), findsOneWidget);

    await tester.pumpWidget(
      Center(
          child: Container(
              child: HoverFeedback(
        key: feedbackKey,
        onEnter: () => numEntries++,
        onExit: () => numExits++,
      ))),
    );
    await tester.pump();
    expect(numEntries, equals(2));
    expect(numExits, equals(1));
    await tester.pumpWidget(
      Container(),
    );
    await tester.pump();
    expect(numEntries, equals(2));
    expect(numExits, equals(2));
  });

  testWidgets('Exit event when unplugging mouse should have a position', (WidgetTester tester) async {
    final List<PointerEnterEvent> enter = <PointerEnterEvent>[];
    final List<PointerHoverEvent> hover = <PointerHoverEvent>[];
    final List<PointerExitEvent> exit = <PointerExitEvent>[];

    await tester.pumpWidget(
      Center(
        child: MouseRegion(
          onEnter: (PointerEnterEvent e) => enter.add(e),
          onHover: (PointerHoverEvent e) => hover.add(e),
          onExit: (PointerExitEvent e) => exit.add(e),
          child: Container(
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
    await gesture.moveTo(tester.getCenter(find.byType(Container)));
    await tester.pumpAndSettle();

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

  testWidgets('detects pointer enter with closure arguments', (WidgetTester tester) async {
    await tester.pumpWidget(_HoverClientWithClosures());
    expect(find.text('not hovering'), findsOneWidget);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    // Move to a position out of MouseRegion
    await gesture.moveTo(tester.getBottomRight(find.byType(MouseRegion)) + const Offset(10, -10));
    await tester.pumpAndSettle();
    expect(find.text('not hovering'), findsOneWidget);

    // Move into MouseRegion
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pumpAndSettle();
    expect(find.text('HOVERING'), findsOneWidget);
  });

  testWidgets('MouseRegion paints child once and only once when MouseRegion is inactive', (WidgetTester tester) async {
    int paintCount = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          onEnter: (PointerEnterEvent e) {},
          child: _PaintDelegateWidget(
            onPaint: _VoidDelegate(() => paintCount++),
            child: const Text('123'),
          ),
        ),
      ),
    );

    expect(paintCount, 1);
  });

  testWidgets('MouseRegion paints child once and only once when MouseRegion is active', (WidgetTester tester) async {
    int paintCount = 0;

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          onEnter: (PointerEnterEvent e) {},
          child: _PaintDelegateWidget(
            onPaint: _VoidDelegate(() => paintCount++),
            child: const Text('123'),
          ),
        ),
      ),
    );

    expect(paintCount, 1);
  });

  testWidgets('RenderMouseRegion\'s debugFillProperties when default', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    RenderMouseRegion().debugFillProperties(builder);

    final List<String> description = builder.properties.where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info)).map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      'parentData: MISSING',
      'constraints: MISSING',
      'size: MISSING',
      'listeners: <none>',
    ]);
  });

  testWidgets('RenderMouseRegion\'s debugFillProperties when full', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    RenderMouseRegion(
      onEnter: (PointerEnterEvent event) {},
      onExit: (PointerExitEvent event) {},
      onHover: (PointerHoverEvent event) {},
      child: RenderErrorBox(),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties.where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info)).map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      'parentData: MISSING',
      'constraints: MISSING',
      'size: MISSING',
      'listeners: enter, hover, exit',
    ]);
  });

  testWidgets('No new frames are scheduled when mouse moves without triggering callbacks', (WidgetTester tester) async {
    await tester.pumpWidget(Center(
      child: MouseRegion(
        child: Container(
          width: 100.0,
          height: 100.0,
        ),
        onEnter: (PointerEnterEvent details) {},
        onHover: (PointerHoverEvent details) {},
        onExit: (PointerExitEvent details) {},
      ),
    ));
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(400.0, 300.0));
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle();
    await gesture.moveBy(const Offset(10.0, 10.0));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets("MouseTracker's attachAnnotation doesn't schedule any frames", (WidgetTester tester) async {
    // This test is here because MouseTracker can't use testWidgets.
    final MouseTrackerAnnotation annotation = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) {},
      onHover: (PointerHoverEvent event) {},
      onExit: (PointerExitEvent event) {},
    );
    RendererBinding.instance.mouseTracker.attachAnnotation(annotation);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(RendererBinding.instance.mouseTracker.isAnnotationAttached(annotation), isTrue);
    RendererBinding.instance.mouseTracker.detachAnnotation(annotation);
  });
}

// This widget allows you to send a callback that is called during `onPaint.
@immutable
class _PaintDelegateWidget extends SingleChildRenderObjectWidget {
  const _PaintDelegateWidget({
    Key key,
    Widget child,
    this.onPaint,
  }) : super(key: key, child: child);

  final _VoidDelegate onPaint;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _PaintCallbackObject(onPaint: onPaint?.callback);
  }

  @override
  void updateRenderObject(BuildContext context, _PaintCallbackObject renderObject) {
    renderObject..onPaint = onPaint?.callback;
  }
}

class _VoidDelegate {
  _VoidDelegate(this.callback);

  void Function() callback;
}

class _PaintCallbackObject extends RenderProxyBox {
  _PaintCallbackObject({
    RenderObject child,
    this.onPaint,
  }) : super(child);

  void Function() onPaint;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (onPaint != null) {
      onPaint();
    }
    super.paint(context, offset);
  }
}

class _HoverClientWithClosures extends StatefulWidget {
  @override
  _HoverClientWithClosuresState createState() => _HoverClientWithClosuresState();
}

class _HoverClientWithClosuresState extends State<_HoverClientWithClosures> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MouseRegion(
        onEnter: (PointerEnterEvent _) {
          setState(() {
            _hovering = true;
          });
        },
        onExit: (PointerExitEvent _) {
          setState(() {
            _hovering = false;
          });
        },
        child: Text(_hovering ? 'HOVERING' : 'not hovering'),
      ),
    );
  }
}
