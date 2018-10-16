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
          drawer: Drawer()
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
            drawer: Drawer()
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
}
