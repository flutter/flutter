// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  test('Drag and drop - control test', () {
    testWidgets((WidgetTester tester) {
      TestPointer pointer = new TestPointer(7);

      List<dynamic> accepted = <dynamic>[];

      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) { return new Column(
            children: <Widget>[
              new Draggable(
                data: 1,
                child: new Text('Source'),
                feedback: new Text('Dragging')
              ),
              new DragTarget(
                builder: (context, data, rejects) {
                  return new Container(
                    height: 100.0,
                    child: new Text('Target')
                  );
                },
                onAccept: (data) {
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
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNotNull);
      expect(tester.findText('Target'), isNotNull);

      Point secondLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNotNull);
      expect(tester.findText('Target'), isNotNull);

      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();

      expect(accepted, equals([1]));
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);
    });
  });

  test('Drag and drop - dragging over button', () {
    testWidgets((WidgetTester tester) {
      TestPointer pointer = new TestPointer(7);

      List<String> events = <String>[];
      Point firstLocation, secondLocation;

      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) { return new Column(
            children: <Widget>[
              new Draggable(
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
                  new DragTarget(
                    builder: (context, data, rejects) {
                      return new IgnorePointer(
                        child: new Container(
                          child: new Text('Target')
                        )
                      );
                    },
                    onAccept: (data) {
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
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();

      secondLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();

      expect(events, isEmpty);
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, equals(<String>['drop']));
      events.clear();

      // drag and tap and drop

      firstLocation = tester.getCenter(tester.findText('Source'));
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();

      secondLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();

      expect(events, isEmpty);
      tester.tap(tester.findText('Button'));
      tester.tap(tester.findText('Target'));
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, equals(<String>['tap', 'tap', 'drop']));
      events.clear();
    });
  });

  test('Drag and drop - tapping button', () {
    testWidgets((WidgetTester tester) {
      TestPointer pointer = new TestPointer(7);

      List<String> events = <String>[];
      Point firstLocation, secondLocation;

      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) { return new Column(
            children: <Widget>[
              new Draggable(
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
              new DragTarget(
                builder: (context, data, rejects) {
                  return new Text('Target');
                },
                onAccept: (data) {
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
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();

      secondLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();

      expect(events, isEmpty);
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, equals(<String>['drop']));
      events.clear();

    });
  });

  test('Drag and drop - long press draggable, short press', () {
    testWidgets((WidgetTester tester) {
      TestPointer pointer = new TestPointer(7);

      List<String> events = <String>[];
      Point firstLocation, secondLocation;

      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) { return new Column(
            children: <Widget>[
              new LongPressDraggable(
                data: 1,
                child: new Text('Source'),
                feedback: new Text('Dragging')
              ),
              new DragTarget(
                builder: (context, data, rejects) {
                  return new Text('Target');
                },
                onAccept: (data) {
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
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();

      secondLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();

      expect(events, isEmpty);
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, isEmpty);

    });
  });

  test('Drag and drop - long press draggable, long press', () {
    testWidgets((WidgetTester tester) {
      TestPointer pointer = new TestPointer(7);

      List<String> events = <String>[];
      Point firstLocation, secondLocation;

      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) { return new Column(
            children: <Widget>[
              new Draggable(
                data: 1,
                child: new Text('Source'),
                feedback: new Text('Dragging')
              ),
              new DragTarget(
                builder: (context, data, rejects) {
                  return new Text('Target');
                },
                onAccept: (data) {
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
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();

      tester.pump(const Duration(seconds: 20));

      secondLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();

      expect(events, isEmpty);
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, equals(<String>['drop']));
    });
  });

  test('Drag and drop - horizontal and vertical draggables in vertical block', () {
    testWidgets((WidgetTester tester) {
      TestPointer pointer = new TestPointer(7);

      List<String> events = <String>[];
      Point firstLocation, secondLocation, thirdLocation;

      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) {
            return new Block(
              children: <Widget>[
                new DragTarget(
                  builder: (context, data, rejects) {
                    return new Text('Target');
                  },
                  onAccept: (data) {
                    events.add('drop $data');
                  }
                ),
                new Container(height: 400.0),
                new HorizontalDraggable(
                  data: 1,
                  child: new Text('H'),
                  feedback: new Text('Dragging')
                ),
                new VerticalDraggable(
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
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, equals(<String>['drop 2']));
      expect(tester.getCenter(tester.findText('Target')).y, greaterThan(0.0));
      events.clear();

      // horizontal draggable drags horizontally
      expect(events, isEmpty);
      firstLocation = tester.getTopLeft(tester.findText('H'));
      secondLocation = tester.getTopRight(tester.findText('H'));
      thirdLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(thirdLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.up(), firstLocation);
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
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(thirdLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, equals(<String>['drop 2']));
      expect(tester.getCenter(tester.findText('Target')).y, greaterThan(0.0));
      events.clear();

      // horizontal draggable doesn't drag vertically when there is competition
      // for vertical gestures
      expect(events, isEmpty);
      firstLocation = tester.getCenter(tester.findText('H'));
      secondLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump(); // scrolls off screen!
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, equals(<String>[]));
      expect(tester.getCenter(tester.findText('Target')).y, lessThan(0.0));
      events.clear();

    });
  });

  test('Drag and drop - horizontal and vertical draggables in horizontal block', () {
    testWidgets((WidgetTester tester) {
      TestPointer pointer = new TestPointer(7);

      List<String> events = <String>[];
      Point firstLocation, secondLocation, thirdLocation;

      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) {
            return new Block(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                new DragTarget(
                  builder: (context, data, rejects) {
                    return new Text('Target');
                  },
                  onAccept: (data) {
                    events.add('drop $data');
                  }
                ),
                new Container(width: 400.0),
                new HorizontalDraggable(
                  data: 1,
                  child: new Text('H'),
                  feedback: new Text('Dragging')
                ),
                new VerticalDraggable(
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
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, equals(<String>['drop 1']));
      expect(tester.getCenter(tester.findText('Target')).x, greaterThan(0.0));
      events.clear();

      // vertical draggable drags vertically
      expect(events, isEmpty);
      firstLocation = tester.getTopLeft(tester.findText('V'));
      secondLocation = tester.getBottomLeft(tester.findText('V'));
      thirdLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(thirdLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.up(), firstLocation);
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
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(thirdLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, equals(<String>['drop 1']));
      expect(tester.getCenter(tester.findText('Target')).x, greaterThan(0.0));
      events.clear();

      // vertical draggable doesn't drag horizontally when there is competition
      // for horizontal gestures
      expect(events, isEmpty);
      firstLocation = tester.getCenter(tester.findText('V'));
      secondLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump(); // scrolls off screen!
      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();
      expect(events, equals(<String>[]));
      expect(tester.getCenter(tester.findText('Target')).x, lessThan(0.0));
      events.clear();

    });
  });
}
