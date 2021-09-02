// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith, ==, hashCode basics', () {
    expect(const DrawerThemeData(), const DrawerThemeData().copyWith());
    expect(const DrawerThemeData().hashCode, const DrawerThemeData().copyWith().hashCode);
  });

  testWidgets('Default debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const DrawerThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('Custom debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    DrawerThemeData(
      backgroundColor: const Color(0x00000099),
      scrimColor: const Color(0x00000098),
      elevation: 5.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'backgroundColor: Color(0x00000099)',
      'scrimColor: Color(0x00000098)',
      'elevation: 5.0',
      'shape: RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.circular(2.0))',
    ]);
  });

  testWidgets('Default values are used when no Drawer or DrawerThemeData properties are specified', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: const Drawer(),
        ),
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    expect(_drawerMaterial(tester).color, null);
    expect(_drawerMaterial(tester).elevation, 16.0);
    expect(_drawerMaterial(tester).shape, null);
    expect(_scrim(tester).color, Colors.black54);
  });

  testWidgets('DrawerThemeData values are used when no Drawer properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0x00000001);
    const Color scrimColor = Color(0x00000002);
    const double elevation = 7.0;
    const RoundedRectangleBorder shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));

    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          drawerTheme: const DrawerThemeData(
            backgroundColor: backgroundColor,
            scrimColor: scrimColor,
            elevation: elevation,
            shape: shape,
          ),
        ),
        home: Scaffold(
          key: scaffoldKey,
          drawer: const Drawer(),
        ),
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    expect(_drawerMaterial(tester).color, backgroundColor);
    expect(_drawerMaterial(tester).elevation, elevation);
    expect(_drawerMaterial(tester).shape, shape);
    expect(_scrim(tester).color, scrimColor);
  });

  testWidgets('Drawer values take priority over DrawerThemeData values when both properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0x00000001);
    const Color scrimColor = Color(0x00000002);
    const double elevation = 7.0;
    const RoundedRectangleBorder shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));

    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          drawerTheme: const DrawerThemeData(
            backgroundColor: Color(0x00000003),
            scrimColor: Color(0x00000004),
            elevation: 13.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(29.0))),
          ),
        ),
        home: Scaffold(
          key: scaffoldKey,
          drawerScrimColor: scrimColor,
          drawer: const Drawer(
            backgroundColor: backgroundColor,
            elevation: elevation,
            shape: shape,
          ),
        ),
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    expect(_drawerMaterial(tester).color, backgroundColor);
    expect(_drawerMaterial(tester).elevation, elevation);
    expect(_drawerMaterial(tester).shape, shape);
    expect(_scrim(tester).color, scrimColor);
  });

  testWidgets('DrawerTheme values take priority over ThemeData.drawerTheme values when both properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0x00000001);
    const Color scrimColor = Color(0x00000002);
    const double elevation = 7.0;
    const RoundedRectangleBorder shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));

    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          drawerTheme: const DrawerThemeData(
            backgroundColor: Color(0x00000003),
            scrimColor: Color(0x00000004),
            elevation: 13.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(29.0))),
          ),
        ),
        home: DrawerTheme(
          data: const DrawerThemeData(
            backgroundColor: backgroundColor,
            scrimColor: scrimColor,
            elevation: elevation,
            shape: shape,
          ),
          child: Scaffold(
            key: scaffoldKey,
            drawer: const Drawer(),
          ),
        ),
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    expect(_drawerMaterial(tester).color, backgroundColor);
    expect(_drawerMaterial(tester).elevation, elevation);
    expect(_drawerMaterial(tester).shape, shape);
    expect(_scrim(tester).color, scrimColor);
  });
}

Material _drawerMaterial(WidgetTester tester) {
  return tester.firstWidget<Material>(
    find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Material),
    ),
  );
}

// The scrim is a Container within a Semantics node labeled "Dismiss",
// within a DrawerController.
Container _scrim(WidgetTester tester) {
  return tester.widget<Container>(
    find.descendant(
      of: find.descendant(
        of: find.byType(DrawerController),
        matching: find.byWidgetPredicate((Widget widget) {
          return widget is Semantics
              && widget.properties.label == 'Dismiss';
        }),
      ),
      matching: find.byType(Container),
    ),
  );
}
