// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppBar theme overrides color', (WidgetTester tester) async {
    const Color themedColor = Colors.lightBlue;
    const AppBarTheme theme = AppBarTheme(color: themedColor);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: theme),
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);
    expect(widget.color, themedColor);
  });

  testWidgets('AppBar color - Widget', (WidgetTester tester) async {
    const Color themeColor = Colors.white;
    const Color appBarThemeColor = Colors.lightBlue;
    const Color appBarColor = Colors.orange;
    const AppBarTheme theme = AppBarTheme(color: appBarThemeColor);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: theme, primaryColor: themeColor),
      home: Scaffold(appBar: AppBar(backgroundColor: appBarColor)),
    ));

    final Material widget = _getAppBarMaterial(tester);
    expect(widget.color, appBarColor);
  });

  testWidgets('AppBar color - AppBarTheme', (WidgetTester tester) async {
    const Color themeColor = Colors.white;
    const Color appBarThemeColor = Colors.lightBlue;
    const AppBarTheme theme = AppBarTheme(color: appBarThemeColor);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: theme, primaryColor: themeColor),
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);
    expect(widget.color, appBarThemeColor);
  });

  testWidgets('AppBar color - Theme', (WidgetTester tester) async {
    const Color themeColor = Colors.white;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(primaryColor: themeColor),
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);
    expect(widget.color, themeColor);
  });

  testWidgets('AppBar color - Default', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(),
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);

    expect(widget.color, Colors.blue);
  });

  testWidgets('AppBar brightness - AppBarTheme', (WidgetTester tester) async {
    const AppBarTheme theme = AppBarTheme(brightness: Brightness.light);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: theme),
      home: Scaffold(appBar: AppBar()),
    ));

    expect(SystemChrome.latestStyle.statusBarBrightness, Brightness.light);
  });

  testWidgets('AppBar theme does not affect defaults', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);

    expect(widget.color, Colors.blue);
    expect(widget.elevation, equals(4.0));
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
