// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Card theme overrides color', (WidgetTester tester) async {
    const Color themedColor = Colors.black87;
    const CardTheme theme = CardTheme(color: themedColor);

    await tester.pumpWidget(_withTheme(theme));

    final PhysicalShape widget = _getCardRenderObject(tester);
    expect(widget.color, themedColor);
  });

  testWidgets('Card color - Widget', (WidgetTester tester) async {
    const Color themeColor = Colors.white10;
    const Color cardThemeColor = Colors.black87;
    const Color cardColor = Colors.pink;
    const CardTheme theme = CardTheme(color: cardThemeColor);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(cardTheme: theme, bottomAppBarColor: themeColor),
      home: const Scaffold(body: Card(color: cardColor)),
    ));

    final PhysicalShape widget = _getCardRenderObject(tester);
    expect(widget.color, cardColor);
  });

  testWidgets('Card color - CardTheme', (WidgetTester tester) async {
    const Color themeColor = Colors.white10;
    const Color cardThemeColor = Colors.black87;
    const CardTheme theme = CardTheme(color: cardThemeColor);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(cardTheme: theme, bottomAppBarColor: themeColor),
      home: const Scaffold(body: Card()),
    ));

    final PhysicalShape widget = _getCardRenderObject(tester);
    expect(widget.color, cardThemeColor);
  });

  testWidgets('Card color - Theme', (WidgetTester tester) async {
    const Color themeColor = Colors.white10;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(cardColor: themeColor),
      home: const Scaffold(body: Card()),
    ));

    final PhysicalShape widget = _getCardRenderObject(tester);
    expect(widget.color, themeColor);
  });

  testWidgets('Card color - Default', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(),
      home: const Scaffold(body: Card()),
    ));

    final PhysicalShape widget = _getCardRenderObject(tester);

    expect(widget.color, Colors.white);
  });

  testWidgets('Card theme customizes shape', (WidgetTester tester) async {
    const CardTheme theme = CardTheme(
      color: Colors.white30,
      shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(7))),
      elevation: 1.0,
    );

    await tester.pumpWidget(_withTheme(theme));

    // TODO(rami-a): Add golden.
//    await expectLater(
//      find.byKey(_painterKey),
//      matchesGoldenFile('bottom_app_bar_theme.custom_shape.png'),
//      skip: !Platform.isLinux,
//    );
  });

  testWidgets('Card theme does not affect defaults', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Card()),
    ));

    final PhysicalShape widget = _getCardRenderObject(tester);

    expect(widget.color, Colors.white);
    expect(widget.elevation, equals(1.0));
  });
}

PhysicalShape _getCardRenderObject(WidgetTester tester) {
  return tester.widget<PhysicalShape>(
    find.descendant(
      of: find.byType(Card),
      matching: find.byType(PhysicalShape),
    ),
  );
}

final Key _painterKey = UniqueKey();

Widget _withTheme(CardTheme theme) {
  return MaterialApp(
    theme: ThemeData(cardTheme: theme),
    home: const Scaffold(
      body: Center(child: Card()),
    ),
  );
}