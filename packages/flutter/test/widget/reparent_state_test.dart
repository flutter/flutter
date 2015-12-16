// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class StateMarker extends StatefulComponent {
  StateMarker({ Key key, this.child }) : super(key: key);

  final Widget child;

  StateMarkerState createState() => new StateMarkerState();
}

class StateMarkerState extends State<StateMarker> {
  String marker;

  Widget build(BuildContext context) {
    if (config.child != null)
      return config.child;
    return new Container();
  }
}

void main() {
  test('can reparent state', () {
    testWidgets((WidgetTester tester) {
      GlobalKey left = new GlobalKey();
      GlobalKey right = new GlobalKey();

      StateMarker grandchild = new StateMarker();
      tester.pumpWidget(
        new Stack(<Widget>[
          new Container(
            child: new StateMarker(key: left)
          ),
          new Container(
            child: new StateMarker(
              key: right,
              child: grandchild
            )
          ),
        ])
      );

      (left.currentState as StateMarkerState).marker = "left";
      (right.currentState as StateMarkerState).marker = "right";

      StateMarkerState grandchildState = tester.findStateByConfig(grandchild);
      expect(grandchildState, isNotNull);
      grandchildState.marker = "grandchild";

      StateMarker newGrandchild = new StateMarker();
      tester.pumpWidget(
        new Stack(<Widget>[
          new Container(
            child: new StateMarker(
              key: right,
              child: newGrandchild
            )
          ),
          new Container(
            child: new StateMarker(key: left)
          ),
        ])
      );

      expect((left.currentState as StateMarkerState).marker, equals("left"));
      expect((right.currentState as StateMarkerState).marker, equals("right"));

      StateMarkerState newGrandchildState = tester.findStateByConfig(newGrandchild);
      expect(newGrandchildState, isNotNull);
      expect(newGrandchildState, equals(grandchildState));
      expect(newGrandchildState.marker, equals("grandchild"));

      tester.pumpWidget(
        new Center(
          child: new Container(
            child: new StateMarker(
              key: left,
              child: new Container()
            )
          )
        )
      );

      expect((left.currentState as StateMarkerState).marker, equals("left"));
      expect(right.currentState, isNull);
    });
  });

  test('can with scrollable list', () {
    testWidgets((WidgetTester tester) {
      GlobalKey key = new GlobalKey();

      tester.pumpWidget(new StateMarker(key: key));

      (key.currentState as StateMarkerState).marker = "marked";

      tester.pumpWidget(new ScrollableList<int>(
        items: <int>[0],
        itemExtent: 100.0,
        itemBuilder: (BuildContext context, int item, int index) {
          return new Container(
            key: new Key('container'),
            height: 100.0,
            child: new StateMarker(key: key)
          );
        }
      ));

      expect((key.currentState as StateMarkerState).marker, equals("marked"));

      tester.pumpWidget(new StateMarker(key: key));

      expect((key.currentState as StateMarkerState).marker, equals("marked"));
    });
  });
}
