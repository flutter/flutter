// Copyright 2019 The Chromium Authors. All rights reserved.
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
    expect(_getIconTheme(tester).data.color, ThemeData().colorScheme.onSecondary);

    // These defaults come directly from the [FloatingActionButton].
    expect(_getRawMaterialButton(tester).elevation, 6);
    expect(_getRawMaterialButton(tester).highlightElevation, 12);
    expect(_getRawMaterialButton(tester).shape, CircleBorder());
  });

  testWidgets('FloatingActionButtonThemeData values are used when no FloatingActionButton properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0xBEEFBEEF);
    const Color foregroundColor = Color(0xFACEFACE);
    const double elevation = 7;
    const double disabledElevation = 1;
    const double highlightElevation = 13;
    const ShapeBorder shape = StadiumBorder();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.fallback().copyWith(
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: elevation,
          disabledElevation: disabledElevation,
          highlightElevation: highlightElevation,
          shape: shape,
        )
      ),
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () { },
          child: const Icon(Icons.add),
        ),
      ),
    ));

    expect(_getRawMaterialButton(tester).fillColor, backgroundColor);
    expect(_getIconTheme(tester).data.color, foregroundColor);
    expect(_getRawMaterialButton(tester).elevation, elevation);
    expect(_getRawMaterialButton(tester).disabledElevation, disabledElevation);
    expect(_getRawMaterialButton(tester).highlightElevation, highlightElevation);
    expect(_getRawMaterialButton(tester).shape, shape);
  });

  testWidgets('FloatingActionButton values take priority over FloatingActionButtonThemeData values when both properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0xBEEFBEEF);
    const Color foregroundColor = Color(0xFACEFACE);
    const double elevation = 7;
    const double highlightElevation = 13;
    const ShapeBorder shape = StadiumBorder();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.fallback().copyWith(
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xCAFECAFE),
          foregroundColor: Color(0xFEEDFEED),
          elevation: 23,
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
          elevation: elevation,
          highlightElevation: highlightElevation,
          shape: shape,
        ),
      ),
    ));

    expect(_getRawMaterialButton(tester).fillColor, backgroundColor);
    expect(_getIconTheme(tester).data.color, foregroundColor);
    expect(_getRawMaterialButton(tester).elevation, elevation);
    expect(_getRawMaterialButton(tester).highlightElevation, highlightElevation);
    expect(_getRawMaterialButton(tester).shape, shape);
  });

  testWidgets('FloatingActionButton foreground color uses iconAccentTheme if no widget or widget theme color is specified', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        floatingActionButton: Theme(
          data: ThemeData().copyWith(
            accentIconTheme: const IconThemeData(color: Color(0xFACEFACE)),
          ),
          child: FloatingActionButton(
            onPressed: () { },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    ));

    expect(_getIconTheme(tester).data.color, const Color(0xFACEFACE));
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
}

RawMaterialButton _getRawMaterialButton(WidgetTester tester) {
  return tester.widget<RawMaterialButton>(
    find.descendant(
      of: find.byType(FloatingActionButton),
      matching: find.byType(RawMaterialButton),
    ),
  );
}

IconTheme _getIconTheme(WidgetTester tester) {
  return tester.widget<IconTheme>(
    find.descendant(
      of: find.byType(FloatingActionButton),
      matching: find.byType(IconTheme),
    ).first,
  );
}
