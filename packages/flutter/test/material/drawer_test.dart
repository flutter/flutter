// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Drawer control test', (WidgetTester tester) async {
    const Key containerKey = Key('container');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: Drawer(
            child: ListView(
              children: <Widget>[
                DrawerHeader(
                  child: Container(
                    key: containerKey,
                    child: const Text('header'),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.archive),
                  title: Text('Archive'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Archive'), findsNothing);
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Archive'), findsOneWidget);

    RenderBox box = tester.renderObject(find.byType(DrawerHeader));
    expect(box.size.height, equals(160.0 + 8.0 + 1.0)); // height + bottom margin + bottom edge

    final double drawerWidth = box.size.width;
    final double drawerHeight = box.size.height;

    box = tester.renderObject(find.byKey(containerKey));
    expect(box.size.width, equals(drawerWidth - 2 * 16.0));
    expect(box.size.height, equals(drawerHeight - 2 * 16.0));

    expect(find.text('header'), findsOneWidget);
  });

  testWidgets('Drawer dismiss barrier has label on iOS', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: Drawer(),
        ),
      ),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(
      label: const DefaultMaterialLocalizations().modalBarrierDismissLabel,
      actions: <SemanticsAction>[SemanticsAction.tap],
    ));

    semantics.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Drawer dismiss barrier has no label on Android', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
            drawer: Drawer(),
        ),
      ),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, isNot(includesNodeWith(
      label: const DefaultMaterialLocalizations().modalBarrierDismissLabel,
      actions: <SemanticsAction>[SemanticsAction.tap],
    )));

    semantics.dispose();
  });

  testWidgets('Drawer callback is called when animation ends', (WidgetTester tester) async {
    int isDrawerOpenCount = 0;
    int isDrawerCloseCount = 0;
    int isEndDrawerOpenCount = 0;
    int isEndDrawerCloseCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          onDrawerAnimationEnd: (bool isOpen) {
            if (isOpen)
              isDrawerOpenCount += 1;
            else
              isDrawerCloseCount += 1;
          },
          drawer: const Drawer(),
          onEndDrawerAnimationEnd: (bool isOpen) {
            if (isOpen)
              isEndDrawerOpenCount += 1;
            else
              isEndDrawerCloseCount += 1;
          },
          endDrawer: const Drawer(),
        ),
      ),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    expect(isDrawerOpenCount, 0);
    expect(isDrawerCloseCount, 0);
    expect(isEndDrawerOpenCount, 0);
    expect(isEndDrawerCloseCount, 0);

    state.openDrawer();
    // First pump to kick start animation.
    await tester.pump();
    // No callback should be called before animation ends.
    await tester.pump(const Duration(milliseconds: 10));
    expect(isDrawerOpenCount, 0);
    expect(isDrawerCloseCount, 0);
    expect(isEndDrawerOpenCount, 0);
    expect(isEndDrawerCloseCount, 0);

    await tester.pumpAndSettle();
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 0);
    expect(isEndDrawerOpenCount, 0);
    expect(isEndDrawerCloseCount, 0);

    state.openEndDrawer();
    // First pump to kick start animation.
    await tester.pump();
    // No new callback should be called before animation ends.
    await tester.pump(const Duration(milliseconds: 10));
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 0);
    expect(isEndDrawerOpenCount, 0);
    expect(isEndDrawerCloseCount, 0);

    // Draw Should be closed while endDrawer open.
    await tester.pumpAndSettle();
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 1);
    expect(isEndDrawerOpenCount, 1);
    expect(isEndDrawerCloseCount, 0);

    state.openDrawer();
    // First pump to kick start animation.
    await tester.pump();
    // No new callback should be called before animation ends.
    await tester.pump(const Duration(milliseconds: 10));
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 1);
    expect(isEndDrawerOpenCount, 1);
    expect(isEndDrawerCloseCount, 0);

    // Draw Should be closed while endDrawer open.
    await tester.pumpAndSettle();
    expect(isDrawerOpenCount, 2);
    expect(isDrawerCloseCount, 1);
    expect(isEndDrawerOpenCount, 1);
    expect(isEndDrawerCloseCount, 1);
  });

  testWidgets('Drawer callback is called when drag', (WidgetTester tester) async {
    int isDrawerOpenCount = 0;
    int isDrawerCloseCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          onDrawerAnimationEnd: (bool isOpen) {
            if (isOpen)
              isDrawerOpenCount += 1;
            else
              isDrawerCloseCount += 1;
          },
          drawer: const Drawer(),
        ),
      ),
    );

    expect(isDrawerOpenCount, 0);
    expect(isDrawerCloseCount, 0);
    // Fully drags to the right.
    TestGesture gesture = await tester.startGesture(const Offset(10.0, 200.0));
    await tester.pump();
    expect(isDrawerOpenCount, 0);
    expect(isDrawerCloseCount, 0);
    await gesture.moveBy(const Offset(100.0, 0.0));
    expect(isDrawerOpenCount, 0);
    expect(isDrawerCloseCount, 0);
    await gesture.moveBy(const Offset(100.0, 0.0));
    expect(isDrawerOpenCount, 0);
    expect(isDrawerCloseCount, 0);
    await gesture.moveBy(const Offset(100.0, 0.0));
    expect(isDrawerOpenCount, 0);
    expect(isDrawerCloseCount, 0);
    await gesture.moveBy(const Offset(100.0, 0.0));
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 0);
    await gesture.up();
    // Makes sure animation settling does not cause another callback.
    await tester.pumpAndSettle();
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 0);

    // Fully drags it back.
    gesture = await tester.startGesture(const Offset(400.0, 200.0));
    await tester.pump();
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 0);
    await gesture.moveBy(const Offset(-100.0, 0.0));
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 0);
    await gesture.moveBy(const Offset(-100.0, 0.0));
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 0);
    await gesture.moveBy(const Offset(-100.0, 0.0));
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 0);
    await gesture.moveBy(const Offset(-100.0, 0.0));
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 0);
    // Reverse drag requires additional animation to close.
    await gesture.up();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 1);

    // Slightly drags to the right should close upon release.
    gesture = await tester.startGesture(const Offset(10.0, 200.0));
    await tester.pump();
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 1);
    await gesture.moveBy(const Offset(100.0, 0.0));
    await gesture.up();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(isDrawerOpenCount, 1);
    expect(isDrawerCloseCount, 2);
  });

  testWidgets('Scaffold drawerScrimColor', (WidgetTester tester) async {
    // The scrim is a Container within a Semantics node labeled "Dismiss",
    // within a DrawerController. Sorry.
    Container getScrim() {
      return tester.widget<Container>(
        find.descendant(
          of: find.descendant(
            of: find.byType(DrawerController),
            matching: find.byWidgetPredicate((Widget widget) {
              if (widget is! Semantics)
                return false;
              final Semantics semantics = widget;
              return semantics.properties.label == 'Dismiss';
            }),
          ),
          matching: find.byType(Container),
        ),
      );
    }

    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    Widget buildFrame({ Color drawerScrimColor }) {
      return MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawerScrimColor: drawerScrimColor,
          drawer: Drawer(
            child: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () { Navigator.pop(context); }, // close drawer
                );
              },
            ),
          ),
        ),
      );
    }

    // Default drawerScrimColor

    await tester.pumpWidget(buildFrame(drawerScrimColor: null));
    scaffoldKey.currentState.openDrawer();
    await tester.pumpAndSettle();

    BoxDecoration decoration = getScrim().decoration;
    expect(decoration.color, Colors.black54);
    expect(decoration.shape, BoxShape.rectangle);

    await tester.tap(find.byType(Drawer));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);

    // Specific drawerScrimColor

    await tester.pumpWidget(buildFrame(drawerScrimColor: const Color(0xFF323232)));
    scaffoldKey.currentState.openDrawer();
    await tester.pumpAndSettle();

    decoration = getScrim().decoration;
    expect(decoration.color, const Color(0xFF323232));
    expect(decoration.shape, BoxShape.rectangle);

    await tester.tap(find.byType(Drawer));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
  });
}
