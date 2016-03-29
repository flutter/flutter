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
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) { return new Column(
            children: <Widget>[
              new Draggable<int>(
                data: 1,
                child: new Text('Source'),
                feedback: new Text('Dragging')
              ),
              new DragTarget<int>(
                builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                  return new Container(
                    height: 100.0,
                    child: new Text('Target')
                  );
                },
                onAccept: (int data) {
                  accepted.add(data);
                }
              ),
            ]);
          },
        }
      ));

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);

      Point firstLocation = tester.getCenter(tester.findText('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNotNull);
      expect(tester.findText('Target'), isNotNull);

      Point secondLocation = tester.getCenter(tester.findText('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNotNull);
      expect(tester.findText('Target'), isNotNull);

      gesture.up();
      tester.pump();

      expect(accepted, equals(<int>[1]));
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);
    });
  });

  test('Drag and drop - dragging over button', () {
    testWidgets((WidgetTester tester) {
      List<String> events = <String>[];
      Point firstLocation, secondLocation;

      tester.pumpWidget(new MaterialApp(
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) { return new Column(
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
                    child: new Container(
                      child: new Text('Button')
                    )
                  ),
                  new DragTarget<int>(
                    builder: (BuildContext context, List<int> data, List<dynamic> rejects) {
                      return new IgnorePointer(
                        child: new Container(
                          child: new Text('Target')
                        )
                      );
                    },
                    onAccept: (int data) {
                      events.add('drop');
                    }
                  ),
                ]
              ),
            ]);
          },
        }
      ));

      expect(events, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);
      expect(tester.findText('Button'), isNotNull);

      // taps (we check both to make sure the test is consistent)

      expect(events, isEmpty);
      tester.tap(tester.findText('Button'));
      expect(events, equals(<String>['tap']));
      events.clear();

      expect(events, isEmpty);
      tester.tap(tester.findText('Target'));
      expect(events, equals(<String>['tap']));
      events.clear();

      // drag and drop

      firstLocation = tester.getCenter(tester.findText('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      secondLocation = tester.getCenter(tester.findText('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(events, isEmpty);
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop']));
      events.clear();

      // drag and tap and drop

      firstLocation = tester.getCenter(tester.findText('Source'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      secondLocation = tester.getCenter(tester.findText('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(events, isEmpty);
      tester.tap(tester.findText('Button'));
      tester.tap(tester.findText('Target'));
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
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) { return new Column(
            children: <Widget>[
              new Draggable<int>(
                data: 1,
                child: new GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    events.add('tap');
                  },
                  child: new Container(
                    child: new Text('Button')
                  )
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
            ]);
          },
        }
      ));

      expect(events, isEmpty);
      expect(tester.findText('Button'), isNotNull);
      expect(tester.findText('Target'), isNotNull);

      expect(events, isEmpty);
      tester.tap(tester.findText('Button'));
      expect(events, equals(<String>['tap']));
      events.clear();

      firstLocation = tester.getCenter(tester.findText('Button'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      secondLocation = tester.getCenter(tester.findText('Target'));
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
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) { return new Column(
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
            ]);
          },
        }
      ));

      expect(events, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Target'), isNotNull);

      expect(events, isEmpty);
      tester.tap(tester.findText('Source'));
      expect(events, isEmpty);

      firstLocation = tester.getCenter(tester.findText('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      secondLocation = tester.getCenter(tester.findText('Target'));
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
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) { return new Column(
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
            ]);
          },
        }
      ));

      expect(events, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Target'), isNotNull);

      expect(events, isEmpty);
      tester.tap(tester.findText('Source'));
      expect(events, isEmpty);

      firstLocation = tester.getCenter(tester.findText('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      tester.pump(const Duration(seconds: 20));

      secondLocation = tester.getCenter(tester.findText('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(events, isEmpty);
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop']));
    });
  });

  test('Drag and drop - horizontal and vertical draggables in vertical block', () {
    testWidgets((WidgetTester tester) {
      List<String> events = <String>[];
      Point firstLocation, secondLocation, thirdLocation;

      tester.pumpWidget(new MaterialApp(
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) {
            return new Block(
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
            );
          },
        }
      ));

      expect(events, isEmpty);
      expect(tester.findText('Target'), isNotNull);
      expect(tester.findText('H'), isNotNull);
      expect(tester.findText('V'), isNotNull);

      // vertical draggable drags vertically
      expect(events, isEmpty);
      firstLocation = tester.getCenter(tester.findText('V'));
      secondLocation = tester.getCenter(tester.findText('Target'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 2']));
      expect(tester.getCenter(tester.findText('Target')).y, greaterThan(0.0));
      events.clear();

      // horizontal draggable drags horizontally
      expect(events, isEmpty);
      firstLocation = tester.getTopLeft(tester.findText('H'));
      secondLocation = tester.getTopRight(tester.findText('H'));
      thirdLocation = tester.getCenter(tester.findText('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.moveTo(thirdLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 1']));
      expect(tester.getCenter(tester.findText('Target')).y, greaterThan(0.0));
      events.clear();

      // vertical draggable drags horizontally when there's no competition
      // from other gesture detectors
      expect(events, isEmpty);
      firstLocation = tester.getTopLeft(tester.findText('V'));
      secondLocation = tester.getTopRight(tester.findText('V'));
      thirdLocation = tester.getCenter(tester.findText('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.moveTo(thirdLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 2']));
      expect(tester.getCenter(tester.findText('Target')).y, greaterThan(0.0));
      events.clear();

      // horizontal draggable doesn't drag vertically when there is competition
      // for vertical gestures
      expect(events, isEmpty);
      firstLocation = tester.getCenter(tester.findText('H'));
      secondLocation = tester.getCenter(tester.findText('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump(); // scrolls off screen!
      gesture.up();
      tester.pump();
      expect(events, equals(<String>[]));
      expect(tester.getCenter(tester.findText('Target')).y, lessThan(0.0));
      events.clear();

    });
  });

  test('Drag and drop - horizontal and vertical draggables in horizontal block', () {
    testWidgets((WidgetTester tester) {
      List<String> events = <String>[];
      Point firstLocation, secondLocation, thirdLocation;

      tester.pumpWidget(new MaterialApp(
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) {
            return new Block(
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
            );
          },
        }
      ));

      expect(events, isEmpty);
      expect(tester.findText('Target'), isNotNull);
      expect(tester.findText('H'), isNotNull);
      expect(tester.findText('V'), isNotNull);

      // horizontal draggable drags horizontally
      expect(events, isEmpty);
      firstLocation = tester.getCenter(tester.findText('H'));
      secondLocation = tester.getCenter(tester.findText('Target'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 1']));
      expect(tester.getCenter(tester.findText('Target')).x, greaterThan(0.0));
      events.clear();

      // vertical draggable drags vertically
      expect(events, isEmpty);
      firstLocation = tester.getTopLeft(tester.findText('V'));
      secondLocation = tester.getBottomLeft(tester.findText('V'));
      thirdLocation = tester.getCenter(tester.findText('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.moveTo(thirdLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 2']));
      expect(tester.getCenter(tester.findText('Target')).x, greaterThan(0.0));
      events.clear();

      // horizontal draggable drags vertically when there's no competition
      // from other gesture detectors
      expect(events, isEmpty);
      firstLocation = tester.getTopLeft(tester.findText('H'));
      secondLocation = tester.getBottomLeft(tester.findText('H'));
      thirdLocation = tester.getCenter(tester.findText('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump();
      gesture.moveTo(thirdLocation);
      tester.pump();
      gesture.up();
      tester.pump();
      expect(events, equals(<String>['drop 1']));
      expect(tester.getCenter(tester.findText('Target')).x, greaterThan(0.0));
      events.clear();

      // vertical draggable doesn't drag horizontally when there is competition
      // for horizontal gestures
      expect(events, isEmpty);
      firstLocation = tester.getCenter(tester.findText('V'));
      secondLocation = tester.getCenter(tester.findText('Target'));
      gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();
      gesture.moveTo(secondLocation);
      tester.pump(); // scrolls off screen!
      gesture.up();
      tester.pump();
      expect(events, equals(<String>[]));
      expect(tester.getCenter(tester.findText('Target')).x, lessThan(0.0));
      events.clear();

    });
  });

  test('Drag and drop - onDraggableDropped not called if dropped on accepting target', () {
    testWidgets((WidgetTester tester) {
      List<int> accepted = <int>[];
      bool onDraggableCanceledCalled = false;

      tester.pumpWidget(new MaterialApp(
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) { return new Column(
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
                  return new Container(
                    height: 100.0,
                    child: new Text('Target')
                  );
                },
                onAccept: (int data) {
                  accepted.add(data);
                }
              ),
            ]);
          },
        }
      ));

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);
      expect(onDraggableCanceledCalled, isFalse);

      Point firstLocation = tester.getCenter(tester.findText('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNotNull);
      expect(tester.findText('Target'), isNotNull);
      expect(onDraggableCanceledCalled, isFalse);

      Point secondLocation = tester.getCenter(tester.findText('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNotNull);
      expect(tester.findText('Target'), isNotNull);
      expect(onDraggableCanceledCalled, isFalse);

      gesture.up();
      tester.pump();

      expect(accepted, equals(<int>[1]));
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);
      expect(onDraggableCanceledCalled, isFalse);
    });
  });

  test('Drag and drop - onDraggableDropped called if dropped on non-accepting target', () {
    testWidgets((WidgetTester tester) {
      List<int> accepted = <int>[];
      bool onDraggableCanceledCalled = false;
      Velocity onDraggableCanceledVelocity;
      Offset onDraggableCanceledOffset;

      tester.pumpWidget(new MaterialApp(
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) { return new Column(
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
            ]);
          },
        }
      ));

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);
      expect(onDraggableCanceledCalled, isFalse);

      Point firstLocation = tester.getTopLeft(tester.findText('Source'));
      TestGesture gesture = tester.startGesture(firstLocation, pointer: 7);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNotNull);
      expect(tester.findText('Target'), isNotNull);
      expect(onDraggableCanceledCalled, isFalse);

      Point secondLocation = tester.getCenter(tester.findText('Target'));
      gesture.moveTo(secondLocation);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNotNull);
      expect(tester.findText('Target'), isNotNull);
      expect(onDraggableCanceledCalled, isFalse);

      gesture.up();
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);
      expect(onDraggableCanceledCalled, isTrue);
      expect(onDraggableCanceledVelocity, equals(Velocity.zero));
      expect(onDraggableCanceledOffset, equals(new Offset(secondLocation.x, secondLocation.y)));
    });
  });

  test('Drag and drop - onDraggableDropped called if dropped on non-accepting target with correct velocity', () {
    testWidgets((WidgetTester tester) {
      List<int> accepted = <int>[];
      bool onDraggableCanceledCalled = false;
      Velocity onDraggableCanceledVelocity;
      Offset onDraggableCanceledOffset;

      tester.pumpWidget(new MaterialApp(
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) { return new Column(
            children: <Widget>[
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
                onWillAccept: (int data) => false
              ),
            ]);
          },
        }
      ));

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);
      expect(onDraggableCanceledCalled, isFalse);

      Point flingStart = tester.getTopLeft(tester.findText('Source'));
      tester.flingFrom(flingStart, new Offset(0.0,100.0), 1000.0);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);
      expect(onDraggableCanceledCalled, isTrue);
      expect(onDraggableCanceledVelocity.pixelsPerSecond.dx.abs(), lessThan(0.0000001));
      expect((onDraggableCanceledVelocity.pixelsPerSecond.dy - 1000.0).abs(), lessThan(0.0000001));
      expect(onDraggableCanceledOffset, equals(new Offset(flingStart.x, flingStart.y) + new Offset(0.0, 100.0)));
    });
  });

  test('Drag and drop - allow pass thru of unaccepted data test', () {
    testWidgets((WidgetTester tester) {
      List<int> acceptedInts = <int>[];
      List<double> acceptedDoubles = <double>[];

      tester.pumpWidget(new MaterialApp(
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) { return new Column(
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
              new Stack(children:[
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
              ])
            ]);
          },
        }
      ));

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, isEmpty);
      expect(tester.findText('IntSource'), isNotNull);
      expect(tester.findText('IntDragging'), isNull);
      expect(tester.findText('DoubleSource'), isNotNull);
      expect(tester.findText('DoubleDragging'), isNull);
      expect(tester.findText('Target1'), isNotNull);
      expect(tester.findText('Target2'), isNotNull);

      Point intLocation = tester.getCenter(tester.findText('IntSource'));
      Point doubleLocation = tester.getCenter(tester.findText('DoubleSource'));
      Point targetLocation = tester.getCenter(tester.findText('Target1'));

      // Drag the double draggable.
      TestGesture doubleGesture = tester.startGesture(doubleLocation, pointer: 7);
      tester.pump();

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, isEmpty);
      expect(tester.findText('IntDragging'), isNull);
      expect(tester.findText('DoubleDragging'), isNotNull);

      doubleGesture.moveTo(targetLocation);
      tester.pump();

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, isEmpty);
      expect(tester.findText('IntDragging'), isNull);
      expect(tester.findText('DoubleDragging'), isNotNull);

      doubleGesture.up();
      tester.pump();

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, equals(<double>[1.0]));
      expect(tester.findText('IntDragging'), isNull);
      expect(tester.findText('DoubleDragging'), isNull);

      acceptedDoubles.clear();

      // Drag the int draggable.
      TestGesture intGesture = tester.startGesture(intLocation, pointer: 7);
      tester.pump();

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, isEmpty);
      expect(tester.findText('IntDragging'), isNotNull);
      expect(tester.findText('DoubleDragging'), isNull);

      intGesture.moveTo(targetLocation);
      tester.pump();

      expect(acceptedInts, isEmpty);
      expect(acceptedDoubles, isEmpty);
      expect(tester.findText('IntDragging'), isNotNull);
      expect(tester.findText('DoubleDragging'), isNull);

      intGesture.up();
      tester.pump();

      expect(acceptedInts, equals(<int>[1]));
      expect(acceptedDoubles, isEmpty);
      expect(tester.findText('IntDragging'), isNull);
      expect(tester.findText('DoubleDragging'), isNull);
    });
  });
}
