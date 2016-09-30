// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Drag and drop - control test', (WidgetTester tester) async {
    List<int> accepted = <int>[];

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: new Text('Source'),
            feedback: new Text('Dragging')
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Container(height: 100.0, child: new Text('Target'));
            },
            onAccept: (int data) {
              accepted.add(data);
            }
          ),
        ]
      )
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);

    Point firstLocation = tester.getCenter(find.text('Source'));
    TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    Point secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);

    await gesture.up();
    await tester.pump();

    expect(accepted, equals(<int>[1]));
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
  });

  testWidgets('Drag and drop - dragging over button', (WidgetTester tester) async {
    List<String> events = <String>[];
    Point firstLocation, secondLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: new Text('Source'),
            feedback: new Text('Dragging')
          ),
          new Stack(
            children: <Widget>[
              new GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  events.add('tap');
                },
                child: new Container(child: new Text('Button')
              )
            ),
            new DragTarget<int>(
              builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                return new IgnorePointer(
                  child: new Container(child: new Text('Target'))
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
    List<String> events = <String>[];
    Point firstLocation, secondLocation;

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
              child: new Container(child: new Text('Button'))
            ),
            feedback: new Text('Dragging')
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Text('Target');
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
  });

  testWidgets('Drag and drop - long press draggable, short press', (WidgetTester tester) async {
    List<String> events = <String>[];
    Point firstLocation, secondLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new LongPressDraggable<int>(
            data: 1,
            child: new Text('Source'),
            feedback: new Text('Dragging')
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Text('Target');
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
    TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
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
    List<String> events = <String>[];
    Point firstLocation, secondLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: new Text('Source'),
            feedback: new Text('Dragging')
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Text('Target');
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
    TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
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
    List<String> events = <String>[];
    Point firstLocation, secondLocation, thirdLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Block(
        children: <Widget>[
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Text('Target');
            },
            onAccept: (int data) {
              events.add('drop $data');
            }
          ),
          new Container(height: 400.0),
          new Draggable<int>(
            data: 1,
            child: new Text('H'),
            feedback: new Text('Dragging'),
            affinity: Axis.horizontal,
          ),
          new Draggable<int>(
            data: 2,
            child: new Text('V'),
            feedback: new Text('Dragging'),
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
    expect(tester.getCenter(find.text('Target')).y, greaterThan(0.0));
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
    expect(tester.getCenter(find.text('Target')).y, greaterThan(0.0));
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
    expect(tester.getCenter(find.text('Target')).y, greaterThan(0.0));
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
    expect(tester.getCenter(find.text('Target')).y, lessThan(0.0));
    events.clear();
  });

  testWidgets('Drag and drop - horizontal and vertical draggables in horizontal block', (WidgetTester tester) async {
    List<String> events = <String>[];
    Point firstLocation, secondLocation, thirdLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Block(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Text('Target');
            },
            onAccept: (int data) {
              events.add('drop $data');
            }
          ),
          new Container(width: 400.0),
          new Draggable<int>(
            data: 1,
            child: new Text('H'),
            feedback: new Text('Dragging'),
            affinity: Axis.horizontal,
          ),
          new Draggable<int>(
            data: 2,
            child: new Text('V'),
            feedback: new Text('Dragging'),
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
    expect(tester.getCenter(find.text('Target')).x, greaterThan(0.0));
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
    expect(tester.getCenter(find.text('Target')).x, greaterThan(0.0));
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
    expect(tester.getCenter(find.text('Target')).x, greaterThan(0.0));
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
    expect(tester.getCenter(find.text('Target')).x, lessThan(0.0));
    events.clear();
  });

  testWidgets('Drag and drop - onDraggableDropped not called if dropped on accepting target', (WidgetTester tester) async {
    List<int> accepted = <int>[];
    bool onDraggableCanceledCalled = false;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: new Text('Source'),
            feedback: new Text('Dragging'),
            onDraggableCanceled: (Velocity velocity, Offset offset) {
              onDraggableCanceledCalled = true;
            }
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Container(height: 100.0, child: new Text('Target'));
            },
            onAccept: (int data) {
              accepted.add(data);
            }
          ),
        ]
      )
    ));

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);

    Point firstLocation = tester.getCenter(find.text('Source'));
    TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);

    Point secondLocation = tester.getCenter(find.text('Target'));
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

  testWidgets('Drag and drop - onDraggableDropped called if dropped on non-accepting target', (WidgetTester tester) async {
    List<int> accepted = <int>[];
    bool onDraggableCanceledCalled = false;
    Velocity onDraggableCanceledVelocity;
    Offset onDraggableCanceledOffset;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: new Text('Source'),
            feedback: new Text('Dragging'),
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
                child: new Text('Target')
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

    Point firstLocation = tester.getTopLeft(find.text('Source'));
    TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isFalse);

    Point secondLocation = tester.getCenter(find.text('Target'));
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
    expect(onDraggableCanceledOffset, equals(new Offset(secondLocation.x, secondLocation.y)));
  });

  testWidgets('Drag and drop - onDraggableDropped called if dropped on non-accepting target with correct velocity', (WidgetTester tester) async {
    List<int> accepted = <int>[];
    bool onDraggableCanceledCalled = false;
    Velocity onDraggableCanceledVelocity;
    Offset onDraggableCanceledOffset;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(children: <Widget>[
        new Draggable<int>(
          data: 1,
          child: new Text('Source'),
          feedback: new Text('Source'),
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
              child: new Text('Target')
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

    Point flingStart = tester.getTopLeft(find.text('Source'));
    await tester.flingFrom(flingStart, new Offset(0.0, 100.0), 1000.0);
    await tester.pump();

    expect(accepted, isEmpty);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Dragging'), findsNothing);
    expect(find.text('Target'), findsOneWidget);
    expect(onDraggableCanceledCalled, isTrue);
    expect(onDraggableCanceledVelocity.pixelsPerSecond.dx.abs(), lessThan(0.0000001));
    expect((onDraggableCanceledVelocity.pixelsPerSecond.dy - 1000.0).abs(), lessThan(0.0000001));
    expect(onDraggableCanceledOffset, equals(new Offset(flingStart.x, flingStart.y) + new Offset(0.0, 100.0)));
  });

  testWidgets('Drag and drop - allow pass thru of unaccepted data test', (WidgetTester tester) async {
    List<int> acceptedInts = <int>[];
    List<double> acceptedDoubles = <double>[];

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: new Text('IntSource'),
            feedback: new Text('IntDragging')
          ),
          new Draggable<double>(
            data: 1.0,
            child: new Text('DoubleSource'),
            feedback: new Text('DoubleDragging')
          ),
          new Stack(
            children: <Widget>[
              new DragTarget<int>(
                builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                  return new IgnorePointer(
                    child: new Container(
                      height: 100.0,
                      child: new Text('Target1')
                    )
                  );
                },
                onAccept: (int data) {
                  acceptedInts.add(data);
                }
              ),
              new DragTarget<double>(
                builder: (BuildContext context, List<double> data, List<dynamic> rejects) {
                  return new IgnorePointer(
                    child: new Container(
                      height: 100.0,
                      child: new Text('Target2')
                    )
                  );
                },
                onAccept: (double data) {
                  acceptedDoubles.add(data);
                }
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

    Point intLocation = tester.getCenter(find.text('IntSource'));
    Point doubleLocation = tester.getCenter(find.text('DoubleSource'));
    Point targetLocation = tester.getCenter(find.text('Target1'));

    // Drag the double draggable.
    TestGesture doubleGesture = await tester.startGesture(doubleLocation, pointer: 7);
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
    TestGesture intGesture = await tester.startGesture(intLocation, pointer: 7);
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
    List<DragTargetData> acceptedDragTargetDatas = <DragTargetData>[];
    List<ExtendedDragTargetData> acceptedExtendedDragTargetDatas = <ExtendedDragTargetData>[];
    DragTargetData dragTargetData = new DragTargetData();
    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<DragTargetData>(
            data: dragTargetData,
            child: new Text('Source'),
            feedback: new Text('Dragging')
          ),
          new Stack(
            children: <Widget>[
              new DragTarget<DragTargetData>(
                builder: (BuildContext context, List<DragTargetData> data, List<dynamic> rejects) {
                  return new IgnorePointer(
                    child: new Container(
                      height: 100.0,
                      child: new Text('Target1')
                    )
                  );
                }, onAccept: (DragTargetData data) {
                  acceptedDragTargetDatas.add(data);
                }
              ),
              new DragTarget<ExtendedDragTargetData>(
                builder: (BuildContext context, List<ExtendedDragTargetData> data, List<dynamic> rejects) {
                  return new IgnorePointer(
                    child: new Container(
                      height: 100.0,
                      child: new Text('Target2')
                    )
                  );
                },
                onAccept: (ExtendedDragTargetData data) {
                  acceptedExtendedDragTargetDatas.add(data);
                }
              ),
            ]
          )
        ]
      )
    ));

    Point dragTargetLocation = tester.getCenter(find.text('Source'));
    Point targetLocation = tester.getCenter(find.text('Target1'));

    for (int i = 0; i < 2; i += 1) {
      TestGesture gesture = await tester.startGesture(dragTargetLocation);
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
                decoration: new BoxDecoration(
                  backgroundColor: new Color(0xFFFFFF00)
                )
              ),
              feedback: new Container(
                width: 100.0,
                height: 100.0,
                decoration: new BoxDecoration(
                  backgroundColor: new Color(0xFFFF0000)
                )
              )
            )
          )
        )
      ]
    ));

    await tester.startGesture(const Point(10.0, 10.0));
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
                decoration: new BoxDecoration(
                  backgroundColor: new Color(0xFFFFFF00)
                )
              ),
              feedback: new Container(
                width: 100.0,
                height: 100.0,
                decoration: new BoxDecoration(
                  backgroundColor: new Color(0xFFFF0000)
                )
              )
            )
          )
        )
      ]
    ));

    TestGesture firstGesture = await tester.startGesture(const Point(10.0, 10.0), pointer: 24);
    TestGesture secondGesture = await tester.startGesture(const Point(10.0, 20.0), pointer: 25);

    await firstGesture.moveBy(new Offset(100.0, 0.0));
    await secondGesture.up();
  });

  testWidgets('DragTarget does not set state when remove from the tree', (WidgetTester tester) async {
    List<String> events = <String>[];
    Point firstLocation, secondLocation;

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: new Text('Source'),
            feedback: new Text('Dragging')
          ),
          new DragTarget<int>(
            builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
              return new Text('Target');
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
    TestGesture gesture = await tester.startGesture(firstLocation, pointer: 7);
    await tester.pump();

    await tester.pump(const Duration(seconds: 20));

    secondLocation = tester.getCenter(find.text('Target'));
    await gesture.moveTo(secondLocation);
    await tester.pump();

    await tester.pumpWidget(new MaterialApp(
      home: new Column(
        children: <Widget>[
          new Draggable<int>(
            data: 1,
            child: new Text('Source'),
            feedback: new Text('Dragging')
          ),
        ]
      )
    ));

    expect(events, isEmpty);
    await gesture.up();
    await tester.pump();
  });
}

class DragTargetData { }

class ExtendedDragTargetData extends DragTargetData { }
