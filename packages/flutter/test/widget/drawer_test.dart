// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {

  testWidgets('Drawer control test', (WidgetTester tester) async {
    GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    BuildContext savedContext;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Builder(
          builder: (BuildContext context) {
            savedContext = context;
            return new Scaffold(
              key: scaffoldKey,
              drawer: new Text('drawer'),
              body: new Container()
            );
          }
        )
      )
    );
    await tester.pump(); // no effect
    expect(find.text('drawer'), findsNothing);
    scaffoldKey.currentState.openDrawer();
    await tester.pump(); // drawer should be starting to animate in
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(new Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsOneWidget);
    Navigator.pop(savedContext);
    await tester.pump(); // drawer should be starting to animate away
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(new Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsNothing);
  });

  testWidgets('Drawer tap test', (WidgetTester tester) async {
    GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          key: scaffoldKey,
          drawer: new Text('drawer'),
          body: new Container()
        )
      )
    );
    await tester.pump(); // no effect
    expect(find.text('drawer'), findsNothing);
    scaffoldKey.currentState.openDrawer();
    await tester.pump(); // drawer should be starting to animate in
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(new Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsOneWidget);
    await tester.tap(find.text('drawer'));
    await tester.pump(); // nothing should have happened
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(new Duration(seconds: 1)); // ditto
    expect(find.text('drawer'), findsOneWidget);
    await tester.tapAt(const Point(750.0, 100.0)); // on the mask
    await tester.pump();
    await tester.pump(new Duration(milliseconds: 10));
    // drawer should be starting to animate away
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(new Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsNothing);
  });

  testWidgets('Drawer drag cancel resume', (WidgetTester tester) async {
    GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          key: scaffoldKey,
          drawer: new Drawer(
            child: new Block(
              children: <Widget>[
                new Text('drawer'),
                new Container(
                  height: 1000.0,
                  decoration: new BoxDecoration(
                    backgroundColor: Colors.blue[500]
                  )
                ),
              ]
            )
          ),
          body: new Container()
        )
      )
    );
    expect(find.text('drawer'), findsNothing);
    scaffoldKey.currentState.openDrawer();
    await tester.pump(); // drawer should be starting to animate in
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(new Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsOneWidget);

    await tester.tapAt(const Point(750.0, 100.0)); // on the mask
    await tester.pump();
    await tester.pump(new Duration(milliseconds: 10));
    // drawer should be starting to animate away
    RenderBox textBox = tester.renderObject(find.text('drawer'));
    double textLeft = textBox.localToGlobal(Point.origin).x;
    expect(textLeft, lessThan(0.0));

    TestGesture gesture = await tester.startGesture(new Point(100.0, 100.0));
    // drawer should be stopped.
    await tester.pump();
    await tester.pump(new Duration(milliseconds: 10));
    expect(textBox.localToGlobal(Point.origin).x, equals(textLeft));

    await gesture.moveBy(new Offset(0.0, -50.0));
    // drawer should be returning to visible
    await tester.pump();
    await tester.pump(new Duration(seconds: 1));
    expect(textBox.localToGlobal(Point.origin).x, equals(0.0));

    await gesture.up();
  });

}
