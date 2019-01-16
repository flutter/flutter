// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Passing no AppBarTheme returns defaults', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);

    expect(widget.color, Colors.blue);
    expect(widget.elevation, equals(4.0));
  });

  testWidgets('AppBar uses color from AppBarTheme', (WidgetTester tester) async {
    const Color themedColor = Colors.lightBlue;
    const AppBarTheme theme = AppBarTheme(color: themedColor);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: theme),
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);
    expect(widget.color, themedColor);
  });

  testWidgets('AppBar widget backgroundColor takes priority over theme', (WidgetTester tester) async {
    const Color appBarColor = Colors.orange;
    const AppBarTheme theme = AppBarTheme(color: Colors.lightBlue);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: theme, primaryColor: Colors.white),
      home: Scaffold(appBar: AppBar(backgroundColor: appBarColor)),
    ));

    final Material widget = _getAppBarMaterial(tester);
    expect(widget.color, appBarColor);
  });

  testWidgets('AppBarTheme color takes priority over ThemeData primaryColor', (WidgetTester tester) async {
    const Color appBarThemeColor = Colors.lightBlue;
    const AppBarTheme theme = AppBarTheme(color: appBarThemeColor);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: theme, primaryColor: Colors.white),
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);
    expect(widget.color, appBarThemeColor);
  });

  testWidgets('ThemeData primaryColor is used when no AppBarTheme is set', (WidgetTester tester) async {
    const Color themeColor = Colors.white;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(primaryColor: themeColor),
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);
    expect(widget.color, themeColor);
  });

  testWidgets('AppBar uses brightness from AppBarTheme', (WidgetTester tester) async {
    const AppBarTheme theme = AppBarTheme(brightness: Brightness.light);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: theme),
      home: Scaffold(appBar: AppBar()),
    ));

    expect(SystemChrome.latestStyle.statusBarBrightness, Brightness.light);
  });
}

Material _getAppBarMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(Material),
    ),
  );
}
