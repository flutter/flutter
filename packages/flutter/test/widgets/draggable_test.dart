// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Drag and drop - control test', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    int dragStartedCount = 0;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDragStarted: () {
              ++dragStartedCount;
            },
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add
          ),
        ]
      )
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(dragStartedCount, 0);

    final Offset firstLocation = tester.getCenter(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(dragStartedCount, 1);

    final Offset secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(dragStartedCount, 1);

    await gesture.up();
    await tester.pump();

    expect(accepted, equals(<int>[1]));
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(dragStartedCount, 1);
  });

  testWidgets('Drag and drop - dragging over button', (WidgetTester tester) async {
    final List<String> events = <String>[];
    Offset firstLocation, secondLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging')
          ),
          new Stack(
            children: <Widget>[
              new GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  events.add('tap');
                },
                child: new Container(child: const Text('Button')
              )
            ),
            new DragTarget<int>(
              builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                return new IgnorePointer(
                  child: new Container(child: const Text('Target'))
                );
              },
              onAccept: (int data) {
                events.add('drop');
              }),
            ]
          ),
        ]
      )
    ));

    expect(events, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(find.text('Button'), findsOneWidget);

    // taps (we check both to make sure the test is consistent)

    expect(events, isEmpty);
    await tester.tap(find.text('Button'));
    expect(events, equals(<String>['tap']));
    events.clear();

    expect(events, isEmpty);
    await tester.tap(find.text('Target'));
    expect(events, equals(<String>['tap']));
    events.clear();

    // drag and drop

    firstLocation = tester.getCenter(find.text('Source'));
    TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(events, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>['drop']));
    events.clear();

    // drag and tap and drop

    firstLocation = tester.getCenter(find.text('Source'));
    gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(events, isEmpty);
    await tester.tap(find.text('Button'));
    await tester.tap(find.text('Target'));
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>['tap', 'tap', 'drop']));
    events.clear();
  });

  testWidgets('Drag and drop - tapping button', (WidgetTester tester) async {
    final List<String> events = <String>[];
    Offset firstLocation, secondLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: new GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                events.add('tap');
              },
              child: new Container(child: const Text('Button'))
            ),
            feedback: const Text('Dragging')
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop');
            }
          ),
        ]
      )
    ));

    expect(events, isEmpty);
    expect(find.text('Button'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    expect(events, isEmpty);
    await tester.tap(find.text('Button'));
    expect(events, equals(<String>['tap']));
    events.clear();

    firstLocation = tester.getCenter(find.text('Button'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(events, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>['drop']));
    events.clear();
  });

  testWidgets('Drag and drop - long press draggable, short press', (WidgetTester tester) async {
    final List<String> events = <String>[];
    Offset firstLocation, secondLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          const LongPressDraggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging')
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop');
            }
          ),
        ]
      )
    ));

    expect(events, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    expect(events, isEmpty);
    await tester.tap(find.text('Source'));
    expect(events, isEmpty);

    firstLocation = tester.getCenter(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(events, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(events, isEmpty);
  });

  testWidgets('Drag and drop - long press draggable, long press', (WidgetTester tester) async {
    final List<String> events = <String>[];
    Offset firstLocation, secondLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging')
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop');
            }
          ),
        ]
      )
    ));

    expect(events, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    expect(events, isEmpty);
    await tester.tap(find.text('Source'));
    expect(events, isEmpty);

    firstLocation = tester.getCenter(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    await tester.pump(const Duration(seconds: 20));

    secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(events, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>['drop']));
  });

  testWidgets('Drag and drop - horizontal and vertical draggables in vertical block', (WidgetTester tester) async {
    final List<String> events = <String>[];
    Offset firstLocation, secondLocation, thirdLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new ListView(
        children: <Widget>[
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop $data');
            }
          ),
          new Container(height: 400.0),
          const Draggable<int>(
            data: 1,
            child: const Text('H'),
            feedback: const Text('Dragging'),
            affinity: Axis.horizontal,
          ),
          const Draggable<int>(
            data: 2,
            child: const Text('V'),
            feedback: const Text('Dragging'),
            affinity: Axis.vertical,
          ),
          new Container(height: 500.0),
          new Container(height: 500.0),
          new Container(height: 500.0),
          new Container(height: 500.0),
        ]
      )
    ));

    expect(events, isEmpty);
    expect(find.text('Target'), findsOneWidget);
    expect(find.text('H'), findsOneWidget);
    expect(find.text('V'), findsOneWidget);

    // vertical draggable drags vertically
    expect(events, isEmpty);
    firstLocation = tester.getCenter(find.text('V'));
    secondLocation = tester.getCenter(find.text('Target'));
    TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();
    await gesture.moveTo(secondLocation);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>['drop 2']));
    expect(tester.getCenter(find.text('Target')).dy, greaterThan(0.0));
    events.clear();

    // horizontal draggable drags horizontally
    expect(events, isEmpty);
    firstLocation = tester.getTopLeft(find.text('H'));
    secondLocation = tester.getTopRight(find.text('H'));
    thirdLocation = tester.getCenter(find.text('Target'));
    gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();
    await gesture.moveTo(secondLocation);
    await tester.pump();
    await gesture.moveTo(thirdLocation);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>['drop 1']));
    expect(tester.getCenter(find.text('Target')).dy, greaterThan(0.0));
    events.clear();

    // vertical draggable drags horizontally when there's no competition
    // from other gesture detectors
    expect(events, isEmpty);
    firstLocation = tester.getTopLeft(find.text('V'));
    secondLocation = tester.getTopRight(find.text('V'));
    thirdLocation = tester.getCenter(find.text('Target'));
    gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();
    await gesture.moveTo(secondLocation);
    await tester.pump();
    await gesture.moveTo(thirdLocation);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>['drop 2']));
    expect(tester.getCenter(find.text('Target')).dy, greaterThan(0.0));
    events.clear();

    // horizontal draggable doesn't drag vertically when there is competition
    // for vertical gestures
    expect(events, isEmpty);
    firstLocation = tester.getCenter(find.text('H'));
    secondLocation = tester.getCenter(find.text('Target'));
    gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();
    await gesture.moveTo(secondLocation);
    await tester.pump(); // scrolls off screen!
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>[]));
    expect(find.text('Target'), findsNothing);
    events.clear();
  });

  testWidgets('Drag and drop - horizontal and vertical draggables in horizontal block', (WidgetTester tester) async {
    final List<String> events = <String>[];
    Offset firstLocation, secondLocation, thirdLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop $data');
            }
          ),
          new Container(width: 400.0),
          const Draggable<int>(
            data: 1,
            child: const Text('H'),
            feedback: const Text('Dragging'),
            affinity: Axis.horizontal,
          ),
          const Draggable<int>(
            data: 2,
            child: const Text('V'),
            feedback: const Text('Dragging'),
            affinity: Axis.vertical,
          ),
          new Container(width: 500.0),
          new Container(width: 500.0),
          new Container(width: 500.0),
          new Container(width: 500.0),
        ]
      )
    ));

    expect(events, isEmpty);
    expect(find.text('Target'), findsOneWidget);
    expect(find.text('H'), findsOneWidget);
    expect(find.text('V'), findsOneWidget);

    // horizontal draggable drags horizontally
    expect(events, isEmpty);
    firstLocation = tester.getCenter(find.text('H'));
    secondLocation = tester.getCenter(find.text('Target'));
    TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();
    await gesture.moveTo(secondLocation);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>['drop 1']));
    expect(tester.getCenter(find.text('Target')).dx, greaterThan(0.0));
    events.clear();

    // vertical draggable drags vertically
    expect(events, isEmpty);
    firstLocation = tester.getTopLeft(find.text('V'));
    secondLocation = tester.getBottomLeft(find.text('V'));
    thirdLocation = tester.getCenter(find.text('Target'));
    gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();
    await gesture.moveTo(secondLocation);
    await tester.pump();
    await gesture.moveTo(thirdLocation);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>['drop 2']));
    expect(tester.getCenter(find.text('Target')).dx, greaterThan(0.0));
    events.clear();

    // horizontal draggable drags vertically when there's no competition
    // from other gesture detectors
    expect(events, isEmpty);
    firstLocation = tester.getTopLeft(find.text('H'));
    secondLocation = tester.getBottomLeft(find.text('H'));
    thirdLocation = tester.getCenter(find.text('Target'));
    gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();
    await gesture.moveTo(secondLocation);
    await tester.pump();
    await gesture.moveTo(thirdLocation);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>['drop 1']));
    expect(tester.getCenter(find.text('Target')).dx, greaterThan(0.0));
    events.clear();

    // vertical draggable doesn't drag horizontally when there is competition
    // for horizontal gestures
    expect(events, isEmpty);
    firstLocation = tester.getCenter(find.text('V'));
    secondLocation = tester.getCenter(find.text('Target'));
    gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();
    await gesture.moveTo(secondLocation);
    await tester.pump(); // scrolls off screen!
    await gesture.up();
    await tester.pump();
    expect(events, equals(<String>[]));
    expect(find.text('Target'), findsNothing);
    events.clear();
  });

  testWidgets('Drag and drop - onDraggableCanceled not called if dropped on accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDraggableCanceledCalled = false;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDraggableCanceled: (Velocity velocity, Offset offset) {
              onDraggableCanceledCalled = true;
            }
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add
          ),
        ]
      )
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);

    final Offset firstLocation = tester.getCenter(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);

    final Offset secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);

    await gesture.up();
    await tester.pump();

    expect(accepted, equals(<int>[1]));
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);
  });

  testWidgets('Drag and drop - onDraggableCanceled called if dropped on non-accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDraggableCanceledCalled = false;
    Velocity onDraggableCanceledVelocity;
    Offset onDraggableCanceledOffset;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDraggableCanceled: (Velocity velocity, Offset offset) {
              onDraggableCanceledCalled = true;
              onDraggableCanceledVelocity = velocity;
              onDraggableCanceledOffset = offset;
            }
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Container(
                height: 100.0,
                child: const Text('Target')
              );
            },
            onWillAccept: (int data) => false
          ),
        ]
      )
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);

    final Offset firstLocation = tester.getTopLeft(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);

    final Offset secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);

    await gesture.up();
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isTrue);
    expect(onDraggableCanceledVelocity, equals(Velocity.zero));
    expect(onDraggableCanceledOffset, equals(new Offset(secondLocation.dx, secondLocation.dy)));
  });

  testWidgets('Drag and drop - onDraggableCanceled called if dropped on non-accepting target with correct velocity', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDraggableCanceledCalled = false;
    Velocity onDraggableCanceledVelocity;
    Offset onDraggableCanceledOffset;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(children: <Widget>[
        new Draggable<int>(
          data: 1,
          child: const Text('Source'),
          feedback: const Text('Source'),
          onDraggableCanceled: (Velocity velocity, Offset offset) {
            onDraggableCanceledCalled = true;
            onDraggableCanceledVelocity = velocity;
            onDraggableCanceledOffset = offset;
          }
        ),
        new DragTarget<int>(
          builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
            return new Container(
              height: 100.0,
              child: const Text('Target')
            );
          },
          onWillAccept: (int data) => false),
        ]
      )
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);

    final Offset flingStart = tester.getTopLeft(find.text('Source'));
    await tester.flingFrom(flingStart, const Offset(0.0, 100.0), 1000.0);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isTrue);
    expect(onDraggableCanceledVelocity.pixelsPerSecond.dx.abs(), lessThan(0.0000001));
    expect((onDraggableCanceledVelocity.pixelsPerSecond.dy - 1000.0).abs(), lessThan(0.0000001));
    expect(onDraggableCanceledOffset, equals(new Offset(flingStart.dx, flingStart.dy) + const Offset(0.0, 100.0)));
  });

  testWidgets('Drag and drop - onDragCompleted not called if dropped on non-accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDragCompletedCalled = false;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDragCompleted: () {
              onDragCompletedCalled = true;
            }
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Container(
                height: 100.0,
                child: const Text('Target')
              );
            },
            onWillAccept: (int data) => false
          ),
        ]
      )
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragCompletedCalled, isFalse);

    final Offset firstLocation = tester.getTopLeft(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragCompletedCalled, isFalse);

    final Offset secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragCompletedCalled, isFalse);

    await gesture.up();
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragCompletedCalled, isFalse);
  });

  testWidgets('Drag and drop - onDragCompleted called if dropped on accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDragCompletedCalled = false;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDragCompleted: () {
              onDragCompletedCalled = true;
            }
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add
          ),
        ]
      )
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragCompletedCalled, isFalse);

    final Offset firstLocation = tester.getCenter(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragCompletedCalled, isFalse);

    final Offset secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragCompletedCalled, isFalse);

    await gesture.up();
    await tester.pump();

    expect(accepted, equals(<int>[1]));
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragCompletedCalled, isTrue);
  });

  testWidgets('Drag and drop - allow pass thru of unaccepted data test', (WidgetTester tester) async {
    final List<int> acceptedInts = <int>[];
    final List<double> acceptedDoubles = <double>[];

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: const Text('IntSource'),
            feedback: const Text('IntDragging')
          ),
          const Draggable<double>(
            data: 1.0,
            child: const Text('DoubleSource'),
            feedback: const Text('DoubleDragging')
          ),
          new Stack(
            children: <Widget>[
              new DragTarget<int>(
                builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                  return new IgnorePointer(
                    child: new Container(
                      height: 100.0,
                      child: const Text('Target1')
                    )
                  );
                },
                onAccept: acceptedInts.add
              ),
              new DragTarget<double>(
                builder: (BuildContext context, List<double> data, List<dynamic> rejects) {
                  return new IgnorePointer(
                    child: new Container(
                      height: 100.0,
                      child: const Text('Target2')
                    )
                  );
                },
                onAccept: acceptedDoubles.add
              ),
            ]
          )
        ]
      )
    ));

    expect(acceptedInts, isEmpty);
    expect(acceptedDoubles, isEmpty);
    expect(find.text('IntSource'), findsOneWidget);
    expect(find.text('IntDragging'), findsNothing);
    expect(find.text('DoubleSource'), findsOneWidget);
    expect(find.text('DoubleDragging'), findsNothing);
    expect(find.text('Target1'), findsOneWidget);
    expect(find.text('Target2'), findsOneWidget);

    final Offset intLocation = tester.getCenter(find.text('IntSource'));
    final Offset doubleLocation = tester.getCenter(find.text('DoubleSource'));
    final Offset targetLocation = tester.getCenter(find.text('Target1'));

    // Drag the double draggable.
    final TestGesture doubleGesture = await tester.startGesture(doubleLocation, pointer: 7);
    await tester.pump();

    expect(acceptedInts, isEmpty);
    expect(acceptedDoubles, isEmpty);
    expect(find.text('IntDragging'), findsNothing);
    expect(find.text('DoubleDragging'), findsOneWidget);

    await doubleGesture.moveTo(targetLocation);
    await tester.pump();

    expect(acceptedInts, isEmpty);
    expect(acceptedDoubles, isEmpty);
    expect(find.text('IntDragging'), findsNothing);
    expect(find.text('DoubleDragging'), findsOneWidget);

    await doubleGesture.up();
    await tester.pump();

    expect(acceptedInts, isEmpty);
    expect(acceptedDoubles, equals(<double>[1.0]));
    expect(find.text('IntDragging'), findsNothing);
    expect(find.text('DoubleDragging'), findsNothing);

    acceptedDoubles.clear();

    // Drag the int draggable.
    final TestGesture intGesture = await tester.startGesture(intLocation, pointer: 7);
    await tester.pump();

    expect(acceptedInts, isEmpty);
    expect(acceptedDoubles, isEmpty);
    expect(find.text('IntDragging'), findsOneWidget);
    expect(find.text('DoubleDragging'), findsNothing);

    await intGesture.moveTo(targetLocation);
    await tester.pump();

    expect(acceptedInts, isEmpty);
    expect(acceptedDoubles, isEmpty);
    expect(find.text('IntDragging'), findsOneWidget);
    expect(find.text('DoubleDragging'), findsNothing);

    await intGesture.up();
    await tester.pump();

    expect(acceptedInts, equals(<int>[1]));
    expect(acceptedDoubles, isEmpty);
    expect(find.text('IntDragging'), findsNothing);
    expect(find.text('DoubleDragging'), findsNothing);
  });

  testWidgets('Drag and drop - allow pass thru of unaccepted data twice test', (WidgetTester tester) async {
    final List<DragTargetData> acceptedDragTargetDatas = <DragTargetData>[];
    final List<ExtendedDragTargetData> acceptedExtendedDragTargetDatas = <ExtendedDragTargetData>[];
    final DragTargetData dragTargetData = new DragTargetData();
    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<DragTargetData>(
            data: dragTargetData,
            child: const Text('Source'),
            feedback: const Text('Dragging')
          ),
          new Stack(
            children: <Widget>[
              new DragTarget<DragTargetData>(
                builder: (BuildContext context, List<DragTargetData> data, List<dynamic> rejects) {
                  return new IgnorePointer(
                    child: new Container(
                      height: 100.0,
                      child: const Text('Target1')
                    )
                  );
                }, onAccept: acceptedDragTargetDatas.add
              ),
              new DragTarget<ExtendedDragTargetData>(
                builder: (BuildContext context, List<ExtendedDragTargetData> data, List<dynamic> rejects) {
                  return new IgnorePointer(
                    child: new Container(
                      height: 100.0,
                      child: const Text('Target2')
                    )
                  );
                },
                onAccept: acceptedExtendedDragTargetDatas.add
              ),
            ]
          )
        ]
      )
    ));

    final Offset dragTargetLocation = tester.getCenter(find.text('Source'));
    final Offset targetLocation = tester.getCenter(find.text('Target1'));

    for (int i = 0; i < 2; i += 1) {
      final TestGesture gesture = await tester.startGesture(dragTargetLocation);
      await tester.pump();
      await gesture.moveTo(targetLocation);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(acceptedDragTargetDatas, equals(<DragTargetData>[dragTargetData]));
      expect(acceptedExtendedDragTargetDatas, isEmpty);

      acceptedDragTargetDatas.clear();
      await tester.pump();
    }
  });

  testWidgets('Drag and drop - maxSimultaneousDrags', (WidgetTester tester) async {
    final List<int> accepted = <int>[];

    Widget build(int maxSimultaneousDrags) {
      return new MaterialApp(
        home: new Column(
          children: <Widget>[
            new Draggable<int>(
              data: 1,
              maxSimultaneousDrags: maxSimultaneousDrags,
              child: const Text('Source'),
              feedback: const Text('Dragging')
            ),
            new DragTarget<int>(
              builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                return new Container(height: 100.0, child: const Text('Target'));
              },
              onAccept: accepted.add
            ),
          ]
        )
      );
    }

    await tester.pumpWidget(build(0));

    final Offset firstLocation = tester.getCenter(find.text('Source'));
    final Offset secondLocation = tester.getCenter(find.text('Target'));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);

    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);

    await gesture.up();

    await tester.pumpWidget(build(2));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);

    final TestGesture gesture1 = await tester.startGesture(firstLocation, pointer: 8);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    final TestGesture gesture2 = await tester.startGesture(firstLocation, pointer: 9);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNWidgets(2));
    expect(find.text('Target'), findsOneWidget);

    final TestGesture gesture3 = await tester.startGesture(firstLocation, pointer: 10);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNWidgets(2));
    expect(find.text('Target'), findsOneWidget);

    await gesture1.moveTo(secondLocation);
    await gesture2.moveTo(secondLocation);
    await gesture3.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNWidgets(2));
    expect(find.text('Target'), findsOneWidget);

    await gesture1.up();
    await tester.pump();

    expect(accepted, equals(<int>[1]));
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    await gesture2.up();
    await tester.pump();

    expect(accepted, equals(<int>[1, 1]));
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);

    await gesture3.up();
    await tester.pump();

    expect(accepted, equals(<int>[1, 1]));
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
  });

  testWidgets('Draggable disposes recognizer', (WidgetTester tester) async {
    bool didTap = false;
    await tester.pumpWidget(new Overlay(
      initialEntries: <OverlayEntry>[
        new OverlayEntry(
          builder: (BuildContext context) => new GestureDetector(
            onTap: () {
              didTap = true;
            },
            child: new Draggable<dynamic>(
              child: new Container(
                color: const Color(0xFFFFFF00),
              ),
              feedback: new Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFFFF0000),
              )
            )
          )
        )
      ]
    ));

    await tester.startGesture(const Offset(10.0, 10.0));
    expect(didTap, isFalse);

    // This tears down the draggable without terminating the gesture sequence,
    // which used to trigger asserts in the multi-drag gesture recognizer.
    await tester.pumpWidget(new Container(key: new UniqueKey()));
    expect(didTap, isFalse);
  });

  // Regression test for https://github.com/flutter/flutter/issues/6128.
  testWidgets('Draggable plays nice with onTap', (WidgetTester tester) async {
    await tester.pumpWidget(new Overlay(
      initialEntries: <OverlayEntry>[
        new OverlayEntry(
          builder: (BuildContext context) => new GestureDetector(
            onTap: () { /* registers a tap recognizer */ },
            child: new Draggable<dynamic>(
              child: new Container(
                color: const Color(0xFFFFFF00),
              ),
              feedback: new Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFFFF0000),
              )
            )
          )
        )
      ]
    ));

    final TestGesture firstGesture = await tester.startGesture(const Offset(10.0, 10.0), pointer: 24);
    final TestGesture secondGesture = await tester.startGesture(const Offset(10.0, 20.0), pointer: 25);

    await firstGesture.moveBy(const Offset(100.0, 0.0));
    await secondGesture.up();
  });

  testWidgets('DragTarget does not set state when remove from the tree', (WidgetTester tester) async {
    final List<String> events = <String>[];
    Offset firstLocation, secondLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging')
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop');
            }
          ),
        ]
      )
    ));

    expect(events, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    expect(events, isEmpty);
    await tester.tap(find.text('Source'));
    expect(events, isEmpty);

    firstLocation = tester.getCenter(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    await tester.pump(const Duration(seconds: 20));

    secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging')
          ),
        ]
      )
    ));

    expect(events, isEmpty);
    await gesture.up();
    await tester.pump();
  });

  testWidgets('Drag and drop - remove draggable', (WidgetTester tester) async {
    final List<int> accepted = <int>[];

    await tester.pumpWidget(new MaterialApp(
        home: new Column(
            children: <Widget>[
              const Draggable<int>(
                  data: 1,
                  child: const Text('Source'),
                  feedback: const Text('Dragging')
              ),
              new DragTarget<int>(
                  builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                    return new Container(height: 100.0, child: const Text('Target'));
                  },
                  onAccept: accepted.add
              ),
            ]
        )
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);

    final Offset firstLocation = tester.getCenter(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    await tester.pumpWidget(new MaterialApp(
        home: new Column(
            children: <Widget>[
              new DragTarget<int>(
                  builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                    return new Container(height: 100.0, child: const Text('Target'));
                  },
                  onAccept: accepted.add
              ),
            ]
        )
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsNothing);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    final Offset secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsNothing);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    await gesture.up();
    await tester.pump();

    expect(accepted, equals(<int>[1]));
    expect(find.text('Source'), findsNothing);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
  });

  testWidgets('Tap above long-press draggable works', (WidgetTester tester) async {
    final List<String> events = <String>[];

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Center(
          child: new GestureDetector(
            onTap: () {
              events.add('tap');
            },
            child: const LongPressDraggable<int>(
              feedback: const Text('Feedback'),
              child: const Text('X'),
            ),
          ),
        ),
      ),
    ));

    expect(events, isEmpty);
    await tester.tap(find.text('X'));
    expect(events, equals(<String>['tap']));
  });

  testWidgets('Drag feedback with child anchor positions correctly', (WidgetTester tester) async {
    await _testChildAnchorFeedbackPosition(tester: tester);
  });

  testWidgets('Drag feedback with child anchor within a non-global Overlay positions correctly', (WidgetTester tester) async {
    await _testChildAnchorFeedbackPosition(tester: tester, left: 100.0, top: 100.0);
  });
}

Future<Null> _testChildAnchorFeedbackPosition({WidgetTester tester, double top: 0.0, double left: 0.0}) async {
  final List<int> accepted = <int>[];
  int dragStartedCount = 0;

  await tester.pumpWidget(new Stack(children: <Widget>[
    new Positioned(
      left: left,
      top: top,
      right: 0.0,
      bottom: 0.0,
      child: new MaterialApp(
        home: new Column(
          children: <Widget>[
            new Draggable<int>(
              data: 1,
              child: const Text('Source'),
              feedback: const Text('Dragging'),
              onDragStarted: () {
                ++dragStartedCount;
              },
            ),
            new DragTarget<int>(
              builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                return new Container(height: 100.0, child: const Text('Target'));
              },
              onAccept: accepted.add
            ),
          ]
        )
      )
    )
  ]));

  expect(accepted, isEmpty);
  expect(find.text('Source'), findsOneWidget);
  expect(find.text('Dragging'), findsNothing);
  expect(find.text('Target'), findsOneWidget);
  expect(dragStartedCount, 0);

  final Offset firstLocation = tester.getCenter(find.text('Source'));
  final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
  await tester.pump();

  expect(accepted, isEmpty);
  expect(find.text('Source'), findsOneWidget);
  expect(find.text('Dragging'), findsOneWidget);
  expect(find.text('Target'), findsOneWidget);
  expect(dragStartedCount, 1);


  final Offset secondLocation = tester.getBottomRight(find.text('Target'));
  await gesture.moveTo(secondLocation);
  await tester.pump();

  expect(accepted, isEmpty);
  expect(find.text('Source'), findsOneWidget);
  expect(find.text('Dragging'), findsOneWidget);
  expect(find.text('Target'), findsOneWidget);
  expect(dragStartedCount, 1);

  final Offset feedbackTopLeft = tester.getTopLeft(find.text('Dragging'));
  final Offset sourceTopLeft = tester.getTopLeft(find.text('Source'));
  final Offset dragOffset = secondLocation - firstLocation;
  expect(feedbackTopLeft, equals(sourceTopLeft + dragOffset));
}

class DragTargetData { }

class ExtendedDragTargetData extends DragTargetData { }
