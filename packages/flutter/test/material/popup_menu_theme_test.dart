// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PopupMenuEntryThemeData copyWith, ==, hashCode basics', () {
    expect(const PopupMenuEntryThemeData(),
        const PopupMenuEntryThemeData().copyWith());
    expect(const PopupMenuEntryThemeData().hashCode,
        const PopupMenuEntryThemeData().copyWith().hashCode);
  });

  test('PopupMenuEntryThemeData null fields by default', () {
    const PopupMenuEntryThemeData popupMenuEntryTheme =
        PopupMenuEntryThemeData();
    expect(popupMenuEntryTheme.surfaceContainerColor, null);
    expect(popupMenuEntryTheme.shape, null);
    expect(popupMenuEntryTheme.elevation, null);
    expect(popupMenuEntryTheme.textStyle, null);
  });

  testWidgets('Default PopupMenuEntryThemeData debugFillProperties',
      (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const PopupMenuEntryThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('PopupMenuEntryThemeData implements debugFillProperties',
      (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    PopupMenuEntryThemeData(
      surfaceContainerColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
      elevation: 2.0,
      textStyle: const TextStyle(color: Color(0xffffffff)),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'surface container color: Color(0xffffffff)',
      'shape: RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.circular(2.0))',
      'elevation: 2.0',
      'text style: TextStyle(inherit: true, color: Color(0xffffffff))'
    ]);
  });

  testWidgets('Passing no PopupMenuEntryThemeData returns defaults',
      (WidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key popupItemKey = UniqueKey();
    final ThemeData theme = ThemeData();

    await tester.pumpWidget(MaterialApp(
      theme: theme,
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            PopupMenuButton<void>(
              key: popupButtonKey,
              itemBuilder: (BuildContext context) {
                final List<PopupMenuEntry<Object>> list = <PopupMenuEntry<Object>>[
                  PopupMenuItem<void>(
                    key: popupItemKey,
                    child: const Text(''),
                  ),
                ];
                return list;
              },
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    final Material button = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(popupButtonApp),
            matching: find.byType(Material),
          )
          .last,
    );
    expect(button.color, null);
    expect(button.shape, null);
    expect(button.elevation, 8.0);

    final AnimatedDefaultTextStyle text =
        tester.widget<AnimatedDefaultTextStyle>(
      find
          .descendant(
            of: find.byKey(popupItemKey),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .last,
    );
    expect(text.style.fontFamily, 'Roboto');
    expect(text.style.color, const Color(0xdd000000));
  });

  testWidgets('PopupMenuEntry uses values from PopupMenuEntryThemeData',
      (WidgetTester tester) async {
    final PopupMenuEntryThemeData popupMenuEntryTheme = _popupMenuEntryTheme();
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key popupItemKey = UniqueKey();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(popupMenuEntryTheme: popupMenuEntryTheme),
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            PopupMenuButton<void>(
              key: popupButtonKey,
              itemBuilder: (BuildContext context) {
                final List<PopupMenuEntry<Object>> list = <PopupMenuEntry<Object>>[
                  PopupMenuItem<void>(
                    key: popupItemKey,
                    child: const Text(''),
                  ),
                ];
                return list;
              },
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    final Material button = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(popupButtonApp),
            matching: find.byType(Material),
          )
          .last,
    );
    expect(button.color, popupMenuEntryTheme.surfaceContainerColor);
    expect(button.shape, popupMenuEntryTheme.shape);
    expect(button.elevation, popupMenuEntryTheme.elevation);

    final AnimatedDefaultTextStyle text =
        tester.widget<AnimatedDefaultTextStyle>(
      find
          .descendant(
            of: find.byKey(popupItemKey),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .last,
    );
    expect(text.style, popupMenuEntryTheme.textStyle);
  });

  testWidgets('PopupMenuEntry widget properties take priority over theme',
      (WidgetTester tester) async {
    final PopupMenuEntryThemeData popupMenuEntryTheme = _popupMenuEntryTheme();
    final Key popupButtonKey = UniqueKey();
    final Key popupButtonApp = UniqueKey();
    final Key popupItemKey = UniqueKey();

    const Color surfaceContainerColor = Colors.purple;
    const ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
    );
    const double elevation = 7.0;
    const TextStyle textStyle = TextStyle(
        color: Color(0x00000000), textBaseline: TextBaseline.alphabetic);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(popupMenuEntryTheme: popupMenuEntryTheme),
      key: popupButtonApp,
      home: Material(
        child: Column(
          children: <Widget>[
            PopupMenuButton<void>(
              key: popupButtonKey,
              elevation: elevation,
              color: surfaceContainerColor,
              shape: shape,
              itemBuilder: (BuildContext context) {
                final List<PopupMenuEntry<Object>> list = <PopupMenuEntry<Object>>[
                  PopupMenuItem<void>(
                    key: popupItemKey,
                    textStyle: textStyle,
                    child: const Text(''),
                  ),
                ];
                return list;
              },
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    final Material button = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(popupButtonApp),
            matching: find.byType(Material),
          )
          .last,
    );
    expect(button.color, surfaceContainerColor);
    expect(button.shape, shape);
    expect(button.elevation, elevation);

    final AnimatedDefaultTextStyle text =
        tester.widget<AnimatedDefaultTextStyle>(
      find
          .descendant(
            of: find.byKey(popupItemKey),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .last,
    );
    expect(text.style, textStyle);
  });
}

PopupMenuEntryThemeData _popupMenuEntryTheme() {
  return PopupMenuEntryThemeData(
    surfaceContainerColor: Colors.orange,
    shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 12.0,
    textStyle: const TextStyle(
        color: Color(0xffffffff), textBaseline: TextBaseline.alphabetic),
  );
}
