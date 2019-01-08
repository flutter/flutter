// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Drag and drop - control test', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    int dragStartedCount = 0;

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDragStarted: () {
              ++dragStartedCount;
            },
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add,
          ),
        ],
      ),
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

  testWidgets('Drag and drop - onLeave callback fires correctly', (WidgetTester tester) async {
    final Map<String,int> leftBehind = <String,int>{
      'Target 1': 0,
      'Target 2': 0,
    };

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: Text('Source'),
            feedback: Text('Dragging'),
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(height: 100.0, child: const Text('Target 1'));
            },
            onLeave: (int data) => leftBehind['Target 1'] = leftBehind['Target 1'] + data,
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(height: 100.0, child: const Text('Target 2'));
            },
            onLeave: (int data) => leftBehind['Target 2'] = leftBehind['Target 2'] + data,
          ),
        ],
      ),
    ));

    expect(leftBehind['Target 1'], equals(0));
    expect(leftBehind['Target 2'], equals(0));

    final Offset firstLocation = tester.getCenter(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(leftBehind['Target 1'], equals(0));
    expect(leftBehind['Target 2'], equals(0));

    final Offset secondLocation = tester.getCenter(find.text('Target 1'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(leftBehind['Target 1'], equals(0));
    expect(leftBehind['Target 2'], equals(0));

    final Offset thirdLocation = tester.getCenter(find.text('Target 2'));
    await gesture.moveTo(thirdLocation);
    await tester.pump();

    expect(leftBehind['Target 1'], equals(1));
    expect(leftBehind['Target 2'], equals(0));

    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(leftBehind['Target 1'], equals(1));
    expect(leftBehind['Target 2'], equals(1));

    await gesture.up();
    await tester.pump();

    expect(leftBehind['Target 1'], equals(1));
    expect(leftBehind['Target 2'], equals(1));
    });

  testWidgets('Drag and drop - dragging over button', (WidgetTester tester) async {
    final List<String> events = <String>[];
    Offset firstLocation, secondLocation;

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: Text('Source'),
            feedback: Text('Dragging'),
          ),
          Stack(
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  events.add('tap');
                },
                child: Container(child: const Text('Button'),
              ),
            ),
            DragTarget<int>(
              builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                return IgnorePointer(
                  child: Container(child: const Text('Target')),
                );
              },
              onAccept: (int data) {
                events.add('drop');
              }),
            ],
          ),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          Draggable<int>(
            data: 1,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                events.add('tap');
              },
              child: Container(child: const Text('Button')),
            ),
            feedback: const Text('Dragging'),
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop');
            },
          ),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          const LongPressDraggable<int>(
            data: 1,
            child: Text('Source'),
            feedback: Text('Dragging'),
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop');
            },
          ),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: Text('Source'),
            feedback: Text('Dragging'),
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop');
            },
          ),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
      home: ListView(
        children: <Widget>[
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop $data');
            }
          ),
          Container(height: 400.0),
          const Draggable<int>(
            data: 1,
            child: Text('H'),
            feedback: Text('Dragging'),
            affinity: Axis.horizontal,
          ),
          const Draggable<int>(
            data: 2,
            child: Text('V'),
            feedback: Text('Dragging'),
            affinity: Axis.vertical,
          ),
          Container(height: 500.0),
          Container(height: 500.0),
          Container(height: 500.0),
          Container(height: 500.0),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
      home: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop $data');
            }
          ),
          Container(width: 400.0),
          const Draggable<int>(
            data: 1,
            child: Text('H'),
            feedback: Text('Dragging'),
            affinity: Axis.horizontal,
          ),
          const Draggable<int>(
            data: 2,
            child: Text('V'),
            feedback: Text('Dragging'),
            affinity: Axis.vertical,
          ),
          Container(width: 500.0),
          Container(width: 500.0),
          Container(width: 500.0),
          Container(width: 500.0),
        ],
      ),
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

  group('Drag and drop - Draggables with a set axis only move along that axis', () {
    final List<String> events = <String>[];

    Widget build() {
      return MaterialApp(
        home: ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            DragTarget<int>(
              builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                return const Text('Target');
              },
              onAccept: (int data) {
                events.add('drop $data');
              }
            ),
            Container(width: 400.0),
            const Draggable<int>(
              data: 1,
              child: Text('H'),
              feedback: Text('H'),
              childWhenDragging: SizedBox(),
              axis: Axis.horizontal,
            ),
            const Draggable<int>(
              data: 2,
              child: Text('V'),
              feedback: Text('V'),
              childWhenDragging: SizedBox(),
              axis: Axis.vertical,
            ),
            const Draggable<int>(
              data: 3,
              child: Text('N'),
              feedback: Text('N'),
              childWhenDragging: SizedBox(),
            ),
            Container(width: 500.0),
            Container(width: 500.0),
            Container(width: 500.0),
            Container(width: 500.0),
          ],
        ),
      );
    }
    testWidgets('Null axis draggable moves along all axes', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      final Offset firstLocation = tester.getTopLeft(find.text('N'));
      final Offset secondLocation = firstLocation + const Offset(300.0, 300.0);
      final Offset thirdLocation = firstLocation + const Offset(-300.0, -300.0);
      final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
      await tester.pump();
      await gesture.moveTo(secondLocation);
      await tester.pump();
      expect(tester.getTopLeft(find.text('N')), secondLocation);
      await gesture.moveTo(thirdLocation);
      await tester.pump();
      expect(tester.getTopLeft(find.text('N')), thirdLocation);
    });

    testWidgets('Horizontal axis draggable moves horizontally', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      final Offset firstLocation = tester.getTopLeft(find.text('H'));
      final Offset secondLocation = firstLocation + const Offset(300.0, 0.0);
      final Offset thirdLocation = firstLocation + const Offset(-300.0, 0.0);
      final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
      await tester.pump();
      await gesture.moveTo(secondLocation);
      await tester.pump();
      expect(tester.getTopLeft(find.text('H')), secondLocation);
      await gesture.moveTo(thirdLocation);
      await tester.pump();
      expect(tester.getTopLeft(find.text('H')), thirdLocation);
    });

    testWidgets('Horizontal axis draggable does not move vertically', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      final Offset firstLocation = tester.getTopLeft(find.text('H'));
      final Offset secondDragLocation = firstLocation + const Offset(300.0, 200.0);
      // The horizontal drag widget won't scroll vertically.
      final Offset secondWidgetLocation = firstLocation + const Offset(300.0, 0.0);
      final Offset thirdDragLocation = firstLocation + const Offset(-300.0, -200.0);
      final Offset thirdWidgetLocation = firstLocation + const Offset(-300.0, 0.0);
      final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
      await tester.pump();
      await gesture.moveTo(secondDragLocation);
      await tester.pump();
      expect(tester.getTopLeft(find.text('H')), secondWidgetLocation);
      await gesture.moveTo(thirdDragLocation);
      await tester.pump();
      expect(tester.getTopLeft(find.text('H')), thirdWidgetLocation);
    });

     testWidgets('Vertical axis draggable moves vertically', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      final Offset firstLocation = tester.getTopLeft(find.text('V'));
      final Offset secondLocation = firstLocation + const Offset(0.0, 300.0);
      final Offset thirdLocation = firstLocation + const Offset(0.0, -300.0);
      final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
      await tester.pump();
      await gesture.moveTo(secondLocation);
      await tester.pump();
      expect(tester.getTopLeft(find.text('V')), secondLocation);
      await gesture.moveTo(thirdLocation);
      await tester.pump();
      expect(tester.getTopLeft(find.text('V')), thirdLocation);
    });

    testWidgets('Vertical axis draggable does not move horizontally', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      final Offset firstLocation = tester.getTopLeft(find.text('V'));
      final Offset secondDragLocation = firstLocation + const Offset(200.0, 300.0);
      // The vertical drag widget won't scroll horizontally.
      final Offset secondWidgetLocation = firstLocation + const Offset(0.0, 300.0);
      final Offset thirdDragLocation = firstLocation + const Offset(-200.0, -300.0);
      final Offset thirdWidgetLocation = firstLocation + const Offset(0.0, -300.0);
      final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
      await tester.pump();
      await gesture.moveTo(secondDragLocation);
      await tester.pump();
      expect(tester.getTopLeft(find.text('V')), secondWidgetLocation);
      await gesture.moveTo(thirdDragLocation);
      await tester.pump();
      expect(tester.getTopLeft(find.text('V')), thirdWidgetLocation);
    });
  });


  testWidgets('Drag and drop - onDraggableCanceled not called if dropped on accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDraggableCanceledCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDraggableCanceled: (Velocity velocity, Offset offset) {
              onDraggableCanceledCalled = true;
            }
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add,
          ),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDraggableCanceled: (Velocity velocity, Offset offset) {
              onDraggableCanceledCalled = true;
              onDraggableCanceledVelocity = velocity;
              onDraggableCanceledOffset = offset;
            },
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(
                height: 100.0,
                child: const Text('Target')
              );
            },
            onWillAccept: (int data) => false,
          ),
        ],
      ),
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
    expect(onDraggableCanceledOffset, equals(Offset(secondLocation.dx, secondLocation.dy)));
  });

  testWidgets('Drag and drop - onDraggableCanceled called if dropped on non-accepting target with correct velocity', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDraggableCanceledCalled = false;
    Velocity onDraggableCanceledVelocity;
    Offset onDraggableCanceledOffset;

    await tester.pumpWidget(MaterialApp(
      home: Column(children: <Widget>[
        Draggable<int>(
          data: 1,
          child: const Text('Source'),
          feedback: const Text('Source'),
          onDraggableCanceled: (Velocity velocity, Offset offset) {
            onDraggableCanceledCalled = true;
            onDraggableCanceledVelocity = velocity;
            onDraggableCanceledOffset = offset;
          },
        ),
        DragTarget<int>(
          builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
            return Container(
              height: 100.0,
              child: const Text('Target'),
            );
          },
          onWillAccept: (int data) => false),
        ],
      ),
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
    expect(onDraggableCanceledOffset, equals(Offset(flingStart.dx, flingStart.dy) + const Offset(0.0, 100.0)));
  });

  testWidgets('Drag and drop - onDragEnd not called if dropped on non-accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDragEndCalled = false;
    DraggableDetails onDragEndDraggableDetails;
    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDragEnd: (DraggableDetails details) {
              onDragEndCalled = true;
              onDragEndDraggableDetails = details;
            },
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(
                height: 100.0,
                child: const Text('Target'),
              );
            },
            onWillAccept: (int data) => false,
          ),
        ],
      ),
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isFalse);

    final Offset firstLocation = tester.getTopLeft(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isFalse);

    final Offset secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isFalse);

    await gesture.up();
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isTrue);
    expect(onDragEndDraggableDetails, isNotNull);
    expect(onDragEndDraggableDetails.wasAccepted, isFalse);
    expect(onDragEndDraggableDetails.velocity, equals(Velocity.zero));
    expect(onDragEndDraggableDetails.offset,
        equals(
            Offset(secondLocation.dx, secondLocation.dy - firstLocation.dy)));
  });

  testWidgets('Drag and drop - onDragCompleted not called if dropped on non-accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDragCompletedCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDragCompleted: () {
              onDragCompletedCalled = true;
            },
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(
                height: 100.0,
                child: const Text('Target'),
              );
            },
            onWillAccept: (int data) => false,
          ),
        ],
      ),
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

  testWidgets('Drag and drop - onDragEnd called if dropped on accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDragEndCalled = false;
    DraggableDetails onDragEndDraggableDetails;
    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDragEnd: (DraggableDetails details) {
              onDragEndCalled = true;
              onDragEndDraggableDetails = details;
            },
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add,
          ),
        ],
      ),
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isFalse);

    final Offset firstLocation = tester.getCenter(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isFalse);

    final Offset secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isFalse);

    await gesture.up();
    await tester.pump();

    final Offset droppedLocation = tester.getTopLeft(find.text('Target'));
    expect(accepted, equals(<int>[1]));
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isTrue);
    expect(onDragEndDraggableDetails, isNotNull);
    expect(onDragEndDraggableDetails.wasAccepted, isTrue);
    expect(onDragEndDraggableDetails.velocity, equals(Velocity.zero));
    expect(onDragEndDraggableDetails.offset,
        equals(
            Offset(droppedLocation.dx, secondLocation.dy - firstLocation.dy)));
  });

  testWidgets('DragTarget does not call onDragEnd when remove from the tree', (WidgetTester tester) async {
    final List<String> events = <String>[];
    Offset firstLocation, secondLocation;
    int timesOnDragEndCalled = 0;
    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          Draggable<int>(
              data: 1,
              child: const Text('Source'),
              feedback: const Text('Dragging'),
              onDragEnd: (DraggableDetails details) {
                timesOnDragEndCalled++;
              },
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop');
            },
          ),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
        home: Column(
            children: const <Widget>[
              Draggable<int>(
                  data: 1,
                  child: Text('Source'),
                  feedback: Text('Dragging')
              ),
            ]
        )
    ));

    expect(events, isEmpty);
    expect(timesOnDragEndCalled, equals(1));
    await gesture.up();
    await tester.pump();
  });

  testWidgets('Drag and drop - onDragCompleted called if dropped on accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDragCompletedCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          Draggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDragCompleted: () {
              onDragCompletedCalled = true;
            },
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add,
          ),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: Text('IntSource'),
            feedback: Text('IntDragging'),
          ),
          const Draggable<double>(
            data: 1.0,
            child: Text('DoubleSource'),
            feedback: Text('DoubleDragging'),
          ),
          Stack(
            children: <Widget>[
              DragTarget<int>(
                builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                  return IgnorePointer(
                    child: Container(
                      height: 100.0,
                      child: const Text('Target1'),
                    ),
                  );
                },
                onAccept: acceptedInts.add,
              ),
              DragTarget<double>(
                builder: (BuildContext context, List<double> data, List<dynamic> rejects) {
                  return IgnorePointer(
                    child: Container(
                      height: 100.0,
                      child: const Text('Target2'),
                    ),
                  );
                },
                onAccept: acceptedDoubles.add,
              ),
            ],
          ),
        ],
      ),
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
    final DragTargetData dragTargetData = DragTargetData();
    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          Draggable<DragTargetData>(
            data: dragTargetData,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
          ),
          Stack(
            children: <Widget>[
              DragTarget<DragTargetData>(
                builder: (BuildContext context, List<DragTargetData> data, List<dynamic> rejects) {
                  return IgnorePointer(
                    child: Container(
                      height: 100.0,
                      child: const Text('Target1'),
                    ),
                  );
                }, onAccept: acceptedDragTargetDatas.add,
              ),
              DragTarget<ExtendedDragTargetData>(
                builder: (BuildContext context, List<ExtendedDragTargetData> data, List<dynamic> rejects) {
                  return IgnorePointer(
                    child: Container(
                      height: 100.0,
                      child: const Text('Target2'),
                    ),
                  );
                },
                onAccept: acceptedExtendedDragTargetDatas.add,
              ),
            ],
          ),
        ],
      ),
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
      return MaterialApp(
        home: Column(
          children: <Widget>[
            Draggable<int>(
              data: 1,
              maxSimultaneousDrags: maxSimultaneousDrags,
              child: const Text('Source'),
              feedback: const Text('Dragging'),
            ),
            DragTarget<int>(
              builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                return Container(height: 100.0, child: const Text('Target'));
              },
              onAccept: accepted.add,
            ),
          ],
        ),
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
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => GestureDetector(
                onTap: () {
                  didTap = true;
                },
                child: Draggable<dynamic>(
                  child: Container(
                    color: const Color(0xFFFFFF00),
                  ),
                  feedback: Container(
                    width: 100.0,
                    height: 100.0,
                    color: const Color(0xFFFF0000),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.startGesture(const Offset(10.0, 10.0));
    expect(didTap, isFalse);

    // This tears down the draggable without terminating the gesture sequence,
    // which used to trigger asserts in the multi-drag gesture recognizer.
    await tester.pumpWidget(Container(key: UniqueKey()));
    expect(didTap, isFalse);
  });

  // Regression test for https://github.com/flutter/flutter/issues/6128.
  testWidgets('Draggable plays nice with onTap', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => GestureDetector(
                onTap: () { /* registers a tap recognizer */ },
                child: Draggable<dynamic>(
                  child: Container(
                    color: const Color(0xFFFFFF00),
                  ),
                  feedback: Container(
                    width: 100.0,
                    height: 100.0,
                    color: const Color(0xFFFF0000),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final TestGesture firstGesture = await tester.startGesture(const Offset(10.0, 10.0), pointer: 24);
    final TestGesture secondGesture = await tester.startGesture(const Offset(10.0, 20.0), pointer: 25);

    await firstGesture.moveBy(const Offset(100.0, 0.0));
    await secondGesture.up();
  });

  testWidgets('DragTarget does not set state when remove from the tree', (WidgetTester tester) async {
    final List<String> events = <String>[];
    Offset firstLocation, secondLocation;

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: Text('Source'),
            feedback: Text('Dragging')
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return const Text('Target');
            },
            onAccept: (int data) {
              events.add('drop');
            },
          ),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: const <Widget>[
          Draggable<int>(
            data: 1,
            child: Text('Source'),
            feedback: Text('Dragging')
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

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          const Draggable<int>(
            data: 1,
            child: Text('Source'),
            feedback: Text('Dragging')
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add,
          ),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add,
          ),
        ],
      ),
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

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Center(
          child: GestureDetector(
            onTap: () {
              events.add('tap');
            },
            child: const LongPressDraggable<int>(
              feedback: Text('Feedback'),
              child: Text('X'),
            ),
          ),
        ),
      ),
    ));

    expect(events, isEmpty);
    await tester.tap(find.text('X'));
    expect(events, equals(<String>['tap']));
  });

  testWidgets('long-press draggable calls onDragEnd called if dropped on accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDragEndCalled = false;
    DraggableDetails onDragEndDraggableDetails;

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          LongPressDraggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDragEnd: (DraggableDetails details) {
              onDragEndCalled = true;
              onDragEndDraggableDetails = details;
            },
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add,
          ),
        ],
      ),
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isFalse);

    final Offset firstLocation = tester.getCenter(find.text('Source'));
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isFalse);

    await tester.pump(kLongPressTimeout);

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isFalse);


    final Offset secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isFalse);

    await gesture.up();
    await tester.pump();

    final Offset droppedLocation = tester.getTopLeft(find.text('Target'));
    expect(accepted, equals(<int>[1]));
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragEndCalled, isTrue);
    expect(onDragEndDraggableDetails, isNotNull);
    expect(onDragEndDraggableDetails.wasAccepted, isTrue);
    expect(onDragEndDraggableDetails.velocity, equals(Velocity.zero));
    expect(onDragEndDraggableDetails.offset,
        equals(
            Offset(droppedLocation.dx, secondLocation.dy - firstLocation.dy)));
  });

  testWidgets('long-press draggable calls onDragCompleted called if dropped on accepting target', (WidgetTester tester) async {
    final List<int> accepted = <int>[];
    bool onDragCompletedCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: <Widget>[
          LongPressDraggable<int>(
            data: 1,
            child: const Text('Source'),
            feedback: const Text('Dragging'),
            onDragCompleted: () {
              onDragCompletedCalled = true;
            },
          ),
          DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return Container(height: 100.0, child: const Text('Target'));
            },
            onAccept: accepted.add,
          ),
        ],
      ),
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
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDragCompletedCalled, isFalse);

    await tester.pump(kLongPressTimeout);

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

  testWidgets('long-press draggable calls onDragStartedCalled after long press', (WidgetTester tester) async {
    bool onDragStartedCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: LongPressDraggable<int>(
        data: 1,
        child: const Text('Source'),
        feedback: const Text('Dragging'),
        onDragStarted: () {
          onDragStartedCalled = true;
        },
      ),
    ));

    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(onDragStartedCalled, isFalse);

    final Offset firstLocation = tester.getCenter(find.text('Source'));
    await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(onDragStartedCalled, isFalse);

    await tester.pump(kLongPressTimeout);

    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(onDragStartedCalled, isTrue);
  });

  testWidgets('long-press draggable calls Haptic Feedback onStart', (WidgetTester tester) async {
    await _testLongPressDraggableHapticFeedback(tester: tester, hapticFeedbackOnStart: true, expectedHapticFeedbackCount: 1);
  });

  testWidgets('long-press draggable can disable Haptic Feedback', (WidgetTester tester) async {
    await _testLongPressDraggableHapticFeedback(tester: tester, hapticFeedbackOnStart: false, expectedHapticFeedbackCount: 0);
  });

  testWidgets('Drag feedback with child anchor positions correctly', (WidgetTester tester) async {
    await _testChildAnchorFeedbackPosition(tester: tester);
  });

  testWidgets('Drag feedback with child anchor within a non-global Overlay positions correctly', (WidgetTester tester) async {
    await _testChildAnchorFeedbackPosition(tester: tester, left: 100.0, top: 100.0);
  });


  testWidgets('Drag and drop can contribute semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(MaterialApp(
        home: ListView(
          scrollDirection: Axis.horizontal,
          addSemanticIndexes: false,
          children: <Widget>[
            DragTarget<int>(
              builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                return const Text('Target');
              },
            ),
            Container(width: 400.0),
            const Draggable<int>(
              data: 1,
              child: Text('H'),
              feedback: Text('H'),
              childWhenDragging: SizedBox(),
              axis: Axis.horizontal,
              ignoringFeedbackSemantics: false,
            ),
            const Draggable<int>(
              data: 2,
              child: Text('V'),
              feedback: Text('V'),
              childWhenDragging: SizedBox(),
              axis: Axis.vertical,
              ignoringFeedbackSemantics: false,
            ),
            const Draggable<int>(
              data: 3,
              child: Text('N'),
              feedback: Text('N'),
              childWhenDragging: SizedBox(),
            ),
          ],
        ),
    ));

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            id: 1,
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              TestSemantics(
                id: 2,
                flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                children: <TestSemantics>[
                  TestSemantics(
                    id: 3,
                    children: <TestSemantics>[
                      TestSemantics(
                        id: 8,
                        flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                        actions: <SemanticsAction>[SemanticsAction.scrollLeft],
                        children: <TestSemantics>[
                          TestSemantics(
                            id: 4,
                            tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                            label: 'Target',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            id: 5,
                            tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                            label: 'H',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            id: 6,
                            tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                            label: 'V',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            id: 7,
                            tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                            label: 'N',
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
    ), ignoreTransform: true, ignoreRect: true));

    final Offset firstLocation = tester.getTopLeft(find.text('N'));
    final Offset secondLocation = firstLocation + const Offset(300.0, 300.0);
    final TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            id: 1,
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              TestSemantics(
                id: 2,
                flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                children: <TestSemantics>[
                  TestSemantics(
                    id: 3,
                    children: <TestSemantics>[
                      TestSemantics(
                        id: 8,
                        flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                        children: <TestSemantics>[
                          TestSemantics(
                            id: 4,
                            tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                            label: 'Target',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            id: 5,
                            tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                            label: 'H',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            id: 6,
                            tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                            label: 'V',
                            textDirection: TextDirection.ltr,
                          ),
                          /// N is moved offscreen.
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
    ), ignoreTransform: true, ignoreRect: true));
    semantics.dispose();
  });

}

Future<void> _testLongPressDraggableHapticFeedback({WidgetTester tester, bool hapticFeedbackOnStart, int expectedHapticFeedbackCount}) async {
  bool onDragStartedCalled = false;

  int hapticFeedbackCalls = 0;
  SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'HapticFeedback.vibrate') {
      hapticFeedbackCalls++;
    }
  });

  await tester.pumpWidget(MaterialApp(
    home: LongPressDraggable<int>(
      data: 1,
      child: const Text('Source'),
      feedback: const Text('Dragging'),
      hapticFeedbackOnStart: hapticFeedbackOnStart,
      onDragStarted: () {
        onDragStartedCalled = true;
      },
    ),
  ));

  expect(find.text('Source'), findsOneWidget);
  expect(find.text('Dragging'), findsNothing);
  expect(onDragStartedCalled, isFalse);

  final Offset firstLocation = tester.getCenter(find.text('Source'));
  await tester.startGesture(firstLocation, pointer: 7);
  await tester.pump();

  expect(find.text('Source'), findsOneWidget);
  expect(find.text('Dragging'), findsNothing);
  expect(onDragStartedCalled, isFalse);

  await tester.pump(kLongPressTimeout);

  expect(find.text('Source'), findsOneWidget);
  expect(find.text('Dragging'), findsOneWidget);
  expect(onDragStartedCalled, isTrue);
  expect(hapticFeedbackCalls, expectedHapticFeedbackCount);
}

Future<void> _testChildAnchorFeedbackPosition({WidgetTester tester, double top = 0.0, double left = 0.0}) async {
  final List<int> accepted = <int>[];
  int dragStartedCount = 0;

  await tester.pumpWidget(
    Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Positioned(
          left: left,
          top: top,
          right: 0.0,
          bottom: 0.0,
          child: MaterialApp(
            home: Column(
              children: <Widget>[
                Draggable<int>(
                  data: 1,
                  child: const Text('Source'),
                  feedback: const Text('Dragging'),
                  onDragStarted: () {
                    ++dragStartedCount;
                  },
                ),
                DragTarget<int>(
                  builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                    return Container(height: 100.0, child: const Text('Target'));
                  },
                  onAccept: accepted.add,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

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
