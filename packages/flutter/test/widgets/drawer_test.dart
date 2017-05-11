// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {

  testWidgets('Drawer control test', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    BuildContext savedContext;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Builder(
          builder: (BuildContext context) {
            savedContext = context;
            return new Scaffold(
              key: scaffoldKey,
              drawer: const Text('drawer'),
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
    await tester.pump(const Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsOneWidget);
    Navigator.pop(savedContext);
    await tester.pump(); // drawer should be starting to animate away
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsNothing);
  });

  testWidgets('Drawer tap test', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          key: scaffoldKey,
          drawer: const Text('drawer'),
          body: new Container()
        )
      )
    );
    await tester.pump(); // no effect
    expect(find.text('drawer'), findsNothing);
    scaffoldKey.currentState.openDrawer();
    await tester.pump(); // drawer should be starting to animate in
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsOneWidget);
    await tester.tap(find.text('drawer'));
    await tester.pump(); // nothing should have happened
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // ditto
    expect(find.text('drawer'), findsOneWidget);
    await tester.tapAt(const Offset(750.0, 100.0)); // on the mask
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    // drawer should be starting to animate away
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsNothing);
  });

  testWidgets('Drawer drag cancel resume', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          key: scaffoldKey,
          drawer: new Drawer(
            child: new ListView(
              children: <Widget>[
                const Text('drawer'),
                new Container(
                  height: 1000.0,
                  color: Colors.blue[500],
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
    await tester.pump(const Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsOneWidget);

    await tester.tapAt(const Offset(750.0, 100.0)); // on the mask
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    // drawer should be starting to animate away
    final RenderBox textBox = tester.renderObject(find.text('drawer'));
    final double textLeft = textBox.localToGlobal(Offset.zero).dx;
    expect(textLeft, lessThan(0.0));

    final TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    // drawer should be stopped.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(textBox.localToGlobal(Offset.zero).dx, equals(textLeft));

    await gesture.moveBy(const Offset(0.0, 50.0));
    // drawer should be returning to visible
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(textBox.localToGlobal(Offset.zero).dx, equals(0.0));

    await gesture.up();
  });

  testWidgets('Drawer navigator back button', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    bool buttonPressed = false;

    await tester.pumpWidget(
      new MaterialApp(
        home: new Builder(
          builder: (BuildContext context) {
            return new Scaffold(
              key: scaffoldKey,
              drawer: new Drawer(
                child: new ListView(
                  children: <Widget>[
                    const Text('drawer'),
                    new FlatButton(
                      child: const Text('close'),
                      onPressed: () => Navigator.pop(context)
                    ),
                  ]
                )
              ),
              body: new Container(
                child: new FlatButton(
                  child: const Text('button'),
                  onPressed: () { buttonPressed = true; }
                )
              )
            );
          }
        )
      )
    );

    // Open the drawer.
    scaffoldKey.currentState.openDrawer();
    await tester.pump(); // drawer should be starting to animate in
    expect(find.text('drawer'), findsOneWidget);

    // Tap the close button to pop the drawer route.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('close'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('drawer'), findsNothing);

    // Confirm that a button in the scaffold body is still clickable.
    await tester.tap(find.text('button'));
    expect(buttonPressed, equals(true));
  });

}
