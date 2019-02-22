// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppBarTheme copyWith, ==, hashCode basics', () {
    expect(const AppBarTheme(), const AppBarTheme().copyWith());
    expect(const AppBarTheme().hashCode, const AppBarTheme().copyWith().hashCode);
  });

  testWidgets('Passing no AppBarTheme returns defaults', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle.statusBarBrightness, Brightness.dark);
    expect(widget.color, Colors.blue);
    expect(widget.elevation, 4.0);
    expect(iconTheme.data, const IconThemeData(color: Colors.white));
    expect(text.style, Typography().englishLike.body1.merge(Typography().white.body1));
  });

  testWidgets('AppBar uses values from AppBarTheme', (WidgetTester tester) async {
    final AppBarTheme appBarTheme = _appBarTheme();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: appBarTheme),
      home: Scaffold(appBar: AppBar(title: const Text('App Bar Title'),)),
    ));

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle.statusBarBrightness, appBarTheme.brightness);
    expect(widget.color, appBarTheme.color);
    expect(widget.elevation, appBarTheme.elevation);
    expect(iconTheme.data, appBarTheme.iconTheme);
    expect(text.style, appBarTheme.textTheme.body1);
  });

  testWidgets('AppBar widget properties take priority over theme', (WidgetTester tester) async {
    const Brightness brightness = Brightness.dark;
    const Color color = Colors.orange;
    const double elevation = 3.0;
    const IconThemeData iconThemeData = IconThemeData(color: Colors.green);
    const TextTheme textTheme = TextTheme(title: TextStyle(color: Colors.orange), body1: TextStyle(color: Colors.pink));

    final ThemeData themeData = _themeData().copyWith(appBarTheme: _appBarTheme());

    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(appBar: AppBar(
        backgroundColor: color,
        brightness: brightness,
        elevation: elevation,
        iconTheme: iconThemeData,
        textTheme: textTheme,)
      ),
    ));

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle.statusBarBrightness, brightness);
    expect(widget.color, color);
    expect(widget.elevation, elevation);
    expect(iconTheme.data, iconThemeData);
    expect(text.style, textTheme.body1);
  });

  testWidgets('AppBarTheme properties take priority over ThemeData properties', (WidgetTester tester) async {
    final AppBarTheme appBarTheme = _appBarTheme();
    final ThemeData themeData = _themeData().copyWith(appBarTheme: _appBarTheme());

    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle.statusBarBrightness, appBarTheme.brightness);
    expect(widget.color, appBarTheme.color);
    expect(widget.elevation, appBarTheme.elevation);
    expect(iconTheme.data, appBarTheme.iconTheme);
    expect(text.style, appBarTheme.textTheme.body1);
  });

  testWidgets('ThemeData properties are used when no AppBarTheme is set', (WidgetTester tester) async {
    final ThemeData themeData = _themeData();

    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(appBar: AppBar()),
    ));

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle.statusBarBrightness, themeData.brightness);
    expect(widget.color, themeData.primaryColor);
    expect(widget.elevation, 4.0);
    expect(iconTheme.data, themeData.primaryIconTheme);
    expect(text.style, Typography().englishLike.body1.merge(Typography().white.body1).merge(themeData.primaryTextTheme.body1));
  });
}

AppBarTheme _appBarTheme() {
  const Brightness brightness = Brightness.light;
  const Color color = Colors.lightBlue;
  const double elevation = 6.0;
  const IconThemeData iconThemeData = IconThemeData(color: Colors.black);
  const TextTheme textTheme = TextTheme(body1: TextStyle(color: Colors.yellow));
  return const AppBarTheme(
    brightness: brightness,
    color: color,
    elevation: elevation,
    iconTheme: iconThemeData,
    textTheme: textTheme
  );
}

ThemeData _themeData() {
  return ThemeData(
    primaryColor: Colors.purple,
    brightness: Brightness.dark,
    primaryIconTheme: const IconThemeData(color: Colors.green),
    primaryTextTheme: const TextTheme(title: TextStyle(color: Colors.orange), body1: TextStyle(color: Colors.pink))
  );
}

Material _getAppBarMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(Material),
    ),
  );
}

IconTheme _getAppBarIconTheme(WidgetTester tester) {
  return tester.widget<IconTheme>(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(IconTheme),
    ),
  );
}

DefaultTextStyle _getAppBarText(WidgetTester tester) {
  return tester.widget<DefaultTextStyle>(
    find.descendant(
      of: find.byType(CustomSingleChildLayout),
      matching: find.byType(DefaultTextStyle),
    ).first,
  );
}
