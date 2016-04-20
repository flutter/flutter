// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  test('Drag and drop - control test', () {
    testWidgets((WidgetTester tester) {
      List<int> accepted = <int>[];

      tester.pumpWidget(new MaterialApp(
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
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, doesNotHaveWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));

      Point firstLocation = tester.getCenter(find.text('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, hasWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));

      Point secondLocation = tester.getCenter(find.text('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, hasWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));

      gesture.up();
      tester.pump();

      expect(accepted, equals(<int>[1]));
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, doesNotHaveWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
    });
  });

  test('Drag and drop - dragging over button', () {
    testWidgets((WidgetTester tester) {
      List<String> events = <String>[];
      Point firstLocation, secondLocation;

      tester.pumpWidget(new MaterialApp(
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
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, doesNotHaveWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(tester, hasWidget(find.text('Button')));

      // taps (we check both to make sure the test is consistent)

      expect(events, isEmpty);
      tester.tap(find.text('Button'));
      expect(events, equals(<String>['tap']));
      events.clear();

      expect(events, isEmpty);
      tester.tap(find.text('Target'));
      expect(events, equals(<String>['tap']));
      events.clear();

      // drag and drop

      firstLocation = tester.getCenter(find.text('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      secondLocation = tester.getCenter(find.text('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(events, isEmpty);
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop']));
      events.clear();

      // drag and tap and drop

      firstLocation = tester.getCenter(find.text('Source'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      secondLocation = tester.getCenter(find.text('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(events, isEmpty);
      tester.tap(find.text('Button'));
      tester.tap(find.text('Target'));
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['tap', 'tap', 'drop']));
      events.clear();
    });
  });

  test('Drag and drop - tapping button', () {
    testWidgets((WidgetTester tester) {
      List<String> events = <String>[];
      Point firstLocation, secondLocation;

      tester.pumpWidget(new MaterialApp(
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
      expect(tester, hasWidget(find.text('Button')));
      expect(tester, hasWidget(find.text('Target')));

      expect(events, isEmpty);
      tester.tap(find.text('Button'));
      expect(events, equals(<String>['tap']));
      events.clear();

      firstLocation = tester.getCenter(find.text('Button'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      secondLocation = tester.getCenter(find.text('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(events, isEmpty);
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop']));
      events.clear();
    });
  });

  test('Drag and drop - long press draggable, short press', () {
    testWidgets((WidgetTester tester) {
      List<String> events = <String>[];
      Point firstLocation, secondLocation;

      tester.pumpWidget(new MaterialApp(
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
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, hasWidget(find.text('Target')));

      expect(events, isEmpty);
      tester.tap(find.text('Source'));
      expect(events, isEmpty);

      firstLocation = tester.getCenter(find.text('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      secondLocation = tester.getCenter(find.text('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(events, isEmpty);
      gesture.up();
      tester.pump();
      expect(events, isEmpty);
    });
  });

  test('Drag and drop - long press draggable, long press', () {
    testWidgets((WidgetTester tester) {
      List<String> events = <String>[];
      Point firstLocation, secondLocation;

      tester.pumpWidget(new MaterialApp(
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
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, hasWidget(find.text('Target')));

      expect(events, isEmpty);
      tester.tap(find.text('Source'));
      expect(events, isEmpty);

      firstLocation = tester.getCenter(find.text('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      tester.pump(const Duration(seconds: 20));

      secondLocation = tester.getCenter(find.text('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(events, isEmpty);
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop']));
    });
  });

  test('Drag and drop - horizontal and vertical draggables in vertical block',
      () {
    testWidgets((WidgetTester tester) {
      List<String> events = <String>[];
      Point firstLocation, secondLocation, thirdLocation;

      tester.pumpWidget(new MaterialApp(
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
            new HorizontalDraggable<int>(
              data: 1,
              child: new Text('H'),
              feedback: new Text('Dragging')
            ),
            new VerticalDraggable<int>(
              data: 2,
              child: new Text('V'),
              feedback: new Text('Dragging')
            ),
            new Container(height: 500.0),
            new Container(height: 500.0),
            new Container(height: 500.0),
            new Container(height: 500.0),
          ]
        )
      ));

      expect(events, isEmpty);
      expect(tester, hasWidget(find.text('Target')));
      expect(tester, hasWidget(find.text('H')));
      expect(tester, hasWidget(find.text('V')));

      // vertical draggable drags vertically
      expect(events, isEmpty);
      firstLocation = tester.getCenter(find.text('V'));
      secondLocation = tester.getCenter(find.text('Target'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 2']));
      expect(tester.getCenter(find.text('Target')).y, greaterThan(0.0));
      events.clear();

      // horizontal draggable drags horizontally
      expect(events, isEmpty);
      firstLocation = tester.getTopLeft(find.text('H'));
      secondLocation = tester.getTopRight(find.text('H'));
      thirdLocation = tester.getCenter(find.text('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.moveTo(thirdLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 1']));
      expect(tester.getCenter(find.text('Target')).y, greaterThan(0.0));
      events.clear();

      // vertical draggable drags horizontally when there's no competition
      // from other gesture detectors
      expect(events, isEmpty);
      firstLocation = tester.getTopLeft(find.text('V'));
      secondLocation = tester.getTopRight(find.text('V'));
      thirdLocation = tester.getCenter(find.text('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.moveTo(thirdLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 2']));
      expect(tester.getCenter(find.text('Target')).y, greaterThan(0.0));
      events.clear();

      // horizontal draggable doesn't drag vertically when there is competition
      // for vertical gestures
      expect(events, isEmpty);
      firstLocation = tester.getCenter(find.text('H'));
      secondLocation = tester.getCenter(find.text('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump(); // scrolls off screen!
      gesture.up();
      tester.pump();
      expect(events, equals(<String>[]));
      expect(tester.getCenter(find.text('Target')).y, lessThan(0.0));
      events.clear();
    });
  });

  test('Drag and drop - horizontal and vertical draggables in horizontal block',
      () {
    testWidgets((WidgetTester tester) {
      List<String> events = <String>[];
      Point firstLocation, secondLocation, thirdLocation;

      tester.pumpWidget(new MaterialApp(
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
            new HorizontalDraggable<int>(
              data: 1,
              child: new Text('H'),
              feedback: new Text('Dragging')
            ),
            new VerticalDraggable<int>(
              data: 2,
              child: new Text('V'),
              feedback: new Text('Dragging')
            ),
            new Container(width: 500.0),
            new Container(width: 500.0),
            new Container(width: 500.0),
            new Container(width: 500.0),
          ]
        )
      ));

      expect(events, isEmpty);
      expect(tester, hasWidget(find.text('Target')));
      expect(tester, hasWidget(find.text('H')));
      expect(tester, hasWidget(find.text('V')));

      // horizontal draggable drags horizontally
      expect(events, isEmpty);
      firstLocation = tester.getCenter(find.text('H'));
      secondLocation = tester.getCenter(find.text('Target'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 1']));
      expect(tester.getCenter(find.text('Target')).x, greaterThan(0.0));
      events.clear();

      // vertical draggable drags vertically
      expect(events, isEmpty);
      firstLocation = tester.getTopLeft(find.text('V'));
      secondLocation = tester.getBottomLeft(find.text('V'));
      thirdLocation = tester.getCenter(find.text('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.moveTo(thirdLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 2']));
      expect(tester.getCenter(find.text('Target')).x, greaterThan(0.0));
      events.clear();

      // horizontal draggable drags vertically when there's no competition
      // from other gesture detectors
      expect(events, isEmpty);
      firstLocation = tester.getTopLeft(find.text('H'));
      secondLocation = tester.getBottomLeft(find.text('H'));
      thirdLocation = tester.getCenter(find.text('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.moveTo(thirdLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 1']));
      expect(tester.getCenter(find.text('Target')).x, greaterThan(0.0));
      events.clear();

      // vertical draggable doesn't drag horizontally when there is competition
      // for horizontal gestures
      expect(events, isEmpty);
      firstLocation = tester.getCenter(find.text('V'));
      secondLocation = tester.getCenter(find.text('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump(); // scrolls off screen!
      gesture.up();
      tester.pump();
      expect(events, equals(<String>[]));
      expect(tester.getCenter(find.text('Target')).x, lessThan(0.0));
      events.clear();
    });
  });

  test(
      'Drag and drop - onDraggableDropped not called if dropped on accepting target',
      () {
    testWidgets((WidgetTester tester) {
      List<int> accepted = <int>[];
      bool onDraggableCanceledCalled = false;

      tester.pumpWidget(new MaterialApp(
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
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, doesNotHaveWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(onDraggableCanceledCalled, isFalse);

      Point firstLocation = tester.getCenter(find.text('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, hasWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(onDraggableCanceledCalled, isFalse);

      Point secondLocation = tester.getCenter(find.text('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, hasWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(onDraggableCanceledCalled, isFalse);

      gesture.up();
      tester.pump();

      expect(accepted, equals(<int>[1]));
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, doesNotHaveWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(onDraggableCanceledCalled, isFalse);
    });
  });

  test(
      'Drag and drop - onDraggableDropped called if dropped on non-accepting target',
      () {
    testWidgets((WidgetTester tester) {
      List<int> accepted = <int>[];
      bool onDraggableCanceledCalled = false;
      Velocity onDraggableCanceledVelocity;
      Offset onDraggableCanceledOffset;

      tester.pumpWidget(new MaterialApp(
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
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, doesNotHaveWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(onDraggableCanceledCalled, isFalse);

      Point firstLocation = tester.getTopLeft(find.text('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, hasWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(onDraggableCanceledCalled, isFalse);

      Point secondLocation = tester.getCenter(find.text('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, hasWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(onDraggableCanceledCalled, isFalse);

      gesture.up();
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, doesNotHaveWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(onDraggableCanceledCalled, isTrue);
      expect(onDraggableCanceledVelocity, equals(Velocity.zero));
      expect(onDraggableCanceledOffset,
          equals(new Offset(secondLocation.x, secondLocation.y)));
    });
  });

  test(
      'Drag and drop - onDraggableDropped called if dropped on non-accepting target with correct velocity',
      () {
    testWidgets((WidgetTester tester) {
      List<int> accepted = <int>[];
      bool onDraggableCanceledCalled = false;
      Velocity onDraggableCanceledVelocity;
      Offset onDraggableCanceledOffset;

      tester.pumpWidget(new MaterialApp(
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
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, doesNotHaveWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(onDraggableCanceledCalled, isFalse);

      Point flingStart = tester.getTopLeft(find.text('Source'));
      tester.flingFrom(flingStart, new Offset(0.0, 100.0), 1000.0);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester, hasWidget(find.text('Source')));
      expect(tester, doesNotHaveWidget(find.text('Dragging')));
      expect(tester, hasWidget(find.text('Target')));
      expect(onDraggableCanceledCalled, isTrue);
      expect(onDraggableCanceledVelocity.pixelsPerSecond.dx.abs(),
          lessThan(0.0000001));
      expect((onDraggableCanceledVelocity.pixelsPerSecond.dy - 1000.0).abs(),
          lessThan(0.0000001));
      expect(
          onDraggableCanceledOffset,
          equals(
              new Offset(flingStart.x, flingStart.y) + new Offset(0.0, 100.0)));
    });
  });

  test('Drag and drop - allow pass thru of unaccepted data test', () {
      testWidgets((WidgetTester tester) {
      List<int> acceptedInts = <int>[];
      List<double> acceptedDoubles = <double>[];

      tester.pumpWidget(new MaterialApp(
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
      expect(tester, hasWidget(find.text('IntSource')));
      expect(tester, doesNotHaveWidget(find.text('IntDragging')));
      expect(tester, hasWidget(find.text('DoubleSource')));
      expect(tester, doesNotHaveWidget(find.text('DoubleDragging')));
      expect(tester, hasWidget(find.text('Target1')));
      expect(tester, hasWidget(find.text('Target2')));

      Point intLocation = tester.getCenter(find.text('IntSource'));
      Point doubleLocation = tester.getCenter(find.text('DoubleSource'));
      Point targetLocation = tester.getCenter(find.text('Target1'));

      // Drag the double draggable.
      TestGesture doubleGesture =
          tester.startGesture(doubleLocation, pointer: 7);
      tester.pump();

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, isEmpty);
      expect(tester, doesNotHaveWidget(find.text('IntDragging')));
      expect(tester, hasWidget(find.text('DoubleDragging')));

      doubleGesture.moveTo(targetLocation);
      tester.pump();

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, isEmpty);
      expect(tester, doesNotHaveWidget(find.text('IntDragging')));
      expect(tester, hasWidget(find.text('DoubleDragging')));

      doubleGesture.up();
      tester.pump();

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, equals(<double>[1.0]));
      expect(tester, doesNotHaveWidget(find.text('IntDragging')));
      expect(tester, doesNotHaveWidget(find.text('DoubleDragging')));

      acceptedDoubles.clear();

      // Drag the int draggable.
      TestGesture intGesture = tester.startGesture(intLocation, pointer: 7);
      tester.pump();

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, isEmpty);
      expect(tester, hasWidget(find.text('IntDragging')));
      expect(tester, doesNotHaveWidget(find.text('DoubleDragging')));

      intGesture.moveTo(targetLocation);
      tester.pump();

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, isEmpty);
      expect(tester, hasWidget(find.text('IntDragging')));
      expect(tester, doesNotHaveWidget(find.text('DoubleDragging')));

      intGesture.up();
      tester.pump();

      expect(acceptedInts, equals(<int>[1]));
      expect(acceptedDoubles, isEmpty);
      expect(tester, doesNotHaveWidget(find.text('IntDragging')));
      expect(tester, doesNotHaveWidget(find.text('DoubleDragging')));
    });
  });

  test('Drag and drop - allow pass thru of unaccepted data twice test', () {
    testWidgets((WidgetTester tester) {
      List<DragTargetData> acceptedDragTargetDatas = <DragTargetData>[];
      List<ExtendedDragTargetData> acceptedExtendedDragTargetDatas = <ExtendedDragTargetData>[];
      DragTargetData dragTargetData = new DragTargetData();
      tester.pumpWidget(new MaterialApp(
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
                  builder: (BuildContext context, List<ExtendedDragTargetData> data, List<ExtendedDragTargetData> rejects) {
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
        TestGesture gesture = tester.startGesture(dragTargetLocation);
        tester.pump();
        gesture.moveTo(targetLocation);
        tester.pump();
        gesture.up();
        tester.pump();

        expect(acceptedDragTargetDatas, equals(<DragTargetData>[dragTargetData]));
        expect(acceptedExtendedDragTargetDatas, isEmpty);

        acceptedDragTargetDatas.clear();
        tester.pump();
      }
    });
  });
}

class DragTargetData {
}

class ExtendedDragTargetData extends DragTargetData {
}
