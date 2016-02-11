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
}
