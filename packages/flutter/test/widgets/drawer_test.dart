// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {

  testWidgets('Drawer control test', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    BuildContext savedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            savedContext = context;
            return Scaffold(
              key: scaffoldKey,
              drawer: const Text('drawer'),
              body: Container(),
            );
          },
        ),
      ),
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
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: const Text('drawer'),
          body: Container(),
        ),
      ),
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

  testWidgets('Drawer drag cancel resume (LTR)', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: Drawer(
            child: ListView(
              children: <Widget>[
                const Text('drawer'),
                Container(
                  height: 1000.0,
                  color: Colors.blue[500],
                ),
              ],
            ),
          ),
          body: Container(),
        ),
      ),
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
    final double textLeft = tester.getTopLeft(find.text('drawer')).dx;
    expect(textLeft, lessThan(0.0));

    final TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    // drawer should be stopped.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(tester.getTopLeft(find.text('drawer')).dx, equals(textLeft));

    await gesture.moveBy(const Offset(50.0, 0.0));
    // drawer should be returning to visible
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getTopLeft(find.text('drawer')).dx, equals(0.0));

    await gesture.up();
  });

  testWidgets('Drawer drag cancel resume (RTL)', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            key: scaffoldKey,
            drawer: Drawer(
              child: ListView(
                children: <Widget>[
                  const Text('drawer'),
                  Container(
                    height: 1000.0,
                    color: Colors.blue[500],
                  ),
                ],
              ),
            ),
            body: Container(),
          ),
        ),
      ),
    );
    expect(find.text('drawer'), findsNothing);
    scaffoldKey.currentState.openDrawer();
    await tester.pump(); // drawer should be starting to animate in
    expect(find.text('drawer'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // animation done
    expect(find.text('drawer'), findsOneWidget);

    await tester.tapAt(const Offset(50.0, 100.0)); // on the mask
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    // drawer should be starting to animate away
    final double textRight = tester.getTopRight(find.text('drawer')).dx;
    expect(textRight, greaterThan(800.0));

    final TestGesture gesture = await tester.startGesture(const Offset(700.0, 100.0));
    // drawer should be stopped.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(tester.getTopRight(find.text('drawer')).dx, equals(textRight));

    await gesture.moveBy(const Offset(-50.0, 0.0));
    // drawer should be returning to visible
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getTopRight(find.text('drawer')).dx, equals(800.0));

    await gesture.up();
  });

  testWidgets('Drawer navigator back button', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    bool buttonPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              key: scaffoldKey,
              drawer: Drawer(
                child: ListView(
                  children: <Widget>[
                    const Text('drawer'),
                    FlatButton(
                      child: const Text('close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              body: Container(
                child: FlatButton(
                  child: const Text('button'),
                  onPressed: () { buttonPressed = true; },
                ),
              ),
            );
          },
        ),
      ),
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

  testWidgets('Dismissible ModalBarrier includes button in semantic tree on iOS', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final SemanticsTester semantics = SemanticsTester(tester);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              key: scaffoldKey,
              drawer: const Drawer(),
            );
          },
        ),
      ),
    );

    // Open the drawer.
    scaffoldKey.currentState.openDrawer();
    await tester.pump(const Duration(milliseconds: 100));

    expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.tap]));

    semantics.dispose();

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Dismissible ModalBarrier is hidden on Android (back button is used to dismiss)', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              key: scaffoldKey,
              drawer: const Drawer(),
              body: Container(),
            );
          },
        ),
      ),
    );

    // Open the drawer.
    scaffoldKey.currentState.openDrawer();
    await tester.pump(const Duration(milliseconds: 100));

    expect(semantics, isNot(includesNodeWith(actions: <SemanticsAction>[SemanticsAction.tap])));

    semantics.dispose();
  });

  testWidgets('Drawer contains route semantics flags', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              key: scaffoldKey,
              drawer: const Drawer(),
              body: Container(),
            );
          },
        ),
      ),
    );

    // Open the drawer.
    scaffoldKey.currentState.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(semantics, includesNodeWith(
      label: 'Navigation menu',
      flags: <SemanticsFlag>[
        SemanticsFlag.scopesRoute,
        SemanticsFlag.namesRoute,
      ],
    ));

    semantics.dispose();
  });
}


