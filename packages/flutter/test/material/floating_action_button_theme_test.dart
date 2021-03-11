// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FloatingActionButtonThemeData copyWith, ==, hashCode basics', () {
    expect(const FloatingActionButtonThemeData(), const FloatingActionButtonThemeData().copyWith());
    expect(const FloatingActionButtonThemeData().hashCode, const FloatingActionButtonThemeData().copyWith().hashCode);
  });

  testWidgets('Default values are used when no FloatingActionButton or FloatingActionButtonThemeData properties are specified', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () { },
          child: const Icon(Icons.add),
        ),
      ),
    ));

    // The color scheme values are guaranteed to be non null since the default
    // [ThemeData] creates it with [ColorScheme.fromSwatch].
    expect(_getRawMaterialButton(tester).fillColor, ThemeData().colorScheme.secondary);
    expect(_getRichText(tester).text.style!.color, ThemeData().colorScheme.onSecondary);

    // These defaults come directly from the [FloatingActionButton].
    expect(_getRawMaterialButton(tester).elevation, 6);
    expect(_getRawMaterialButton(tester).highlightElevation, 12);
    expect(_getRawMaterialButton(tester).shape, const CircleBorder());
    expect(_getRawMaterialButton(tester).splashColor, ThemeData().splashColor);
  });

  testWidgets('FloatingActionButtonThemeData values are used when no FloatingActionButton properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0xBEEFBEEF);
    const Color foregroundColor = Color(0xFACEFACE);
    const Color splashColor = Color(0xCAFEFEED);
    const double elevation = 7;
    const double disabledElevation = 1;
    const double highlightElevation = 13;
    const ShapeBorder shape = StadiumBorder();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData().copyWith(
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          splashColor: splashColor,
          elevation: elevation,
          disabledElevation: disabledElevation,
          highlightElevation: highlightElevation,
          shape: shape,
        ),
      ),
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () { },
          child: const Icon(Icons.add),
        ),
      ),
    ));

    expect(_getRawMaterialButton(tester).fillColor, backgroundColor);
    expect(_getRichText(tester).text.style!.color, foregroundColor);
    expect(_getRawMaterialButton(tester).elevation, elevation);
    expect(_getRawMaterialButton(tester).disabledElevation, disabledElevation);
    expect(_getRawMaterialButton(tester).highlightElevation, highlightElevation);
    expect(_getRawMaterialButton(tester).shape, shape);
    expect(_getRawMaterialButton(tester).splashColor, splashColor);
  });

  testWidgets('FloatingActionButton values take priority over FloatingActionButtonThemeData values when both properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0x00000001);
    const Color foregroundColor = Color(0x00000002);
    const Color splashColor = Color(0x00000003);
    const double elevation = 7;
    const double disabledElevation = 1;
    const double highlightElevation = 13;
    const ShapeBorder shape = StadiumBorder();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData().copyWith(
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0x00000004),
          foregroundColor: Color(0x00000005),
          splashColor: Color(0x00000006),
          elevation: 23,
          disabledElevation: 11,
          highlightElevation: 43,
          shape: BeveledRectangleBorder(),
        ),
      ),
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () { },
          child: const Icon(Icons.add),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          splashColor: splashColor,
          elevation: elevation,
          disabledElevation: disabledElevation,
          highlightElevation: highlightElevation,
          shape: shape,
        ),
      ),
    ));

    expect(_getRawMaterialButton(tester).fillColor, backgroundColor);
    expect(_getRichText(tester).text.style!.color, foregroundColor);
    expect(_getRawMaterialButton(tester).elevation, elevation);
    expect(_getRawMaterialButton(tester).disabledElevation, disabledElevation);
    expect(_getRawMaterialButton(tester).highlightElevation, highlightElevation);
    expect(_getRawMaterialButton(tester).shape, shape);
    expect(_getRawMaterialButton(tester).splashColor, splashColor);
  });

  testWidgets('FloatingActionButton uses a custom shape when specified in the theme', (WidgetTester tester) async {
    const ShapeBorder customShape = BeveledRectangleBorder();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () { },
          shape: customShape,
        ),
      ),
    ));

    expect(_getRawMaterialButton(tester).shape, customShape);
  });

  testWidgets('default FloatingActionButton debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const FloatingActionButtonThemeData ().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('Material implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const FloatingActionButtonThemeData(
      backgroundColor: Color(0xCAFECAFE),
      foregroundColor: Color(0xFEEDFEED),
      elevation: 23,
      disabledElevation: 11,
      highlightElevation: 43,
      shape: BeveledRectangleBorder(),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[
      'foregroundColor: Color(0xfeedfeed)',
      'backgroundColor: Color(0xcafecafe)',
      'elevation: 23.0',
      'disabledElevation: 11.0',
      'highlightElevation: 43.0',
      'shape: BeveledRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.zero)',
    ]);
  });
}

RawMaterialButton _getRawMaterialButton(WidgetTester tester) {
  return tester.widget<RawMaterialButton>(
    find.descendant(
      of: find.byType(FloatingActionButton),
      matching: find.byType(RawMaterialButton),
    ),
  );
}

RichText _getRichText(WidgetTester tester) {
  return tester.widget<RichText>(
    find.descendant(
      of: find.byType(FloatingActionButton),
      matching: find.byType(RichText),
    ),
  );
}
