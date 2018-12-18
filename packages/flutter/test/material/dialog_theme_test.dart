// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

MaterialApp _appWithAlertDialog(WidgetTester tester, AlertDialog dialog, {ThemeData theme}) {
  return MaterialApp(
    theme: theme,
    home: Material(
        child: Builder(
            builder: (BuildContext context) {
              return Center(
                  child: RaisedButton(
                      child: const Text('X'),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return RepaintBoundary(key: _painterKey, child: dialog);
                          },
                        );
                      }
                  )
              );
            }
        )
    ),
  );
}

final Key _painterKey = UniqueKey();

Material _getMaterialFromDialog(WidgetTester tester) {
  return tester.widget<Material>(find.descendant(of: find.byType(AlertDialog), matching: find.byType(Material)));
}

void main() {
  testWidgets('Dialog Theme implements debugFillDescription', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const DialogTheme(
      backgroundColor: Color(0xff123456),
      elevation: 8.0,
      shape: null,
    ).debugFillProperties(builder);
    final List<String> description = builder.properties
        .where((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode n) => n.toString()).toList();
    expect(description, <String>[
      'backgroundColor: Color(0xff123456)',
      'elevation: 8.0'
    ]);
  });

  testWidgets('Dialog background color', (WidgetTester tester) async {
    const Color customColor = Colors.pink;
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(backgroundColor: customColor));

    await tester.pumpWidget(_appWithAlertDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.color, customColor);
  });

  testWidgets('Custom dialog elevation', (WidgetTester tester) async {
    const double customElevation = 12.0;
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(elevation: customElevation));

    await tester.pumpWidget(
        _appWithAlertDialog(tester, dialog, theme: theme)
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.elevation, customElevation);
  });

  testWidgets('Custom dialog shape', (WidgetTester tester) async {
    const RoundedRectangleBorder customBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(shape: customBorder));

    await tester.pumpWidget(
      _appWithAlertDialog(tester, dialog, theme: theme)
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.shape, customBorder);
  });

  testWidgets('Custom dialog shape matches golden', (WidgetTester tester) async {
    const RoundedRectangleBorder customBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      actions: <Widget>[ ],
    );
    final ThemeData theme = ThemeData(dialogTheme: const DialogTheme(shape: customBorder));

    await tester.pumpWidget(_appWithAlertDialog(tester, dialog, theme: theme));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('dialog_theme.dialog_with_custom_border.png'),
      skip: !Platform.isLinux,
    );
  });
}
