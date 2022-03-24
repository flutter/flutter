// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BAB theme overrides color', (WidgetTester tester) async {
    const Color themedColor = Colors.black87;
    const BottomAppBarTheme theme = BottomAppBarTheme(color: themedColor);

    await tester.pumpWidget(_withTheme(theme));

    final PhysicalShape widget = _getBabRenderObject(tester);
    expect(widget.color, themedColor);
  });

  testWidgets('BAB color - Widget', (WidgetTester tester) async {
    const Color themeColor = Colors.white10;
    const Color babThemeColor = Colors.black87;
    const Color babColor = Colors.pink;
    const BottomAppBarTheme theme = BottomAppBarTheme(color: babThemeColor);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bottomAppBarTheme: theme, bottomAppBarColor: themeColor),
      home: const Scaffold(body: BottomAppBar(color: babColor)),
    ));

    final PhysicalShape widget = _getBabRenderObject(tester);
    expect(widget.color, babColor);
  });

  testWidgets('BAB color - BabTheme', (WidgetTester tester) async {
    const Color themeColor = Colors.white10;
    const Color babThemeColor = Colors.black87;
    const BottomAppBarTheme theme = BottomAppBarTheme(color: babThemeColor);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bottomAppBarTheme: theme, bottomAppBarColor: themeColor),
      home: const Scaffold(body: BottomAppBar()),
    ));

    final PhysicalShape widget = _getBabRenderObject(tester);
    expect(widget.color, babThemeColor);
  });

  testWidgets('BAB color - Theme', (WidgetTester tester) async {
    const Color themeColor = Colors.white10;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bottomAppBarColor: themeColor),
      home: const Scaffold(body: BottomAppBar()),
    ));

    final PhysicalShape widget = _getBabRenderObject(tester);
    expect(widget.color, themeColor);
  });

  testWidgets('BAB color - Default', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(),
      home: const Scaffold(body: BottomAppBar()),
    ));

    final PhysicalShape widget = _getBabRenderObject(tester);

    expect(widget.color, Colors.white);
  });

  testWidgets('BAB theme customizes shape', (WidgetTester tester) async {
    const BottomAppBarTheme theme = BottomAppBarTheme(
        color: Colors.white30,
        shape: CircularNotchedRectangle(),
        elevation: 1.0,
    );

    await tester.pumpWidget(_withTheme(theme));

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('bottom_app_bar_theme.custom_shape.png'),
    );
  });

  testWidgets('BAB theme does not affect defaults', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BottomAppBar()),
    ));

    final PhysicalShape widget = _getBabRenderObject(tester);

    expect(widget.color, Colors.white);
    expect(widget.elevation, equals(8.0));
  });
}

PhysicalShape _getBabRenderObject(WidgetTester tester) {
  return tester.widget<PhysicalShape>(
      find.descendant(
          of: find.byType(BottomAppBar),
          matching: find.byType(PhysicalShape),
      ),
  );
}

final Key _painterKey = UniqueKey();

Widget _withTheme(BottomAppBarTheme theme) {
  return MaterialApp(
    theme: ThemeData(bottomAppBarTheme: theme),
    home: Scaffold(
        floatingActionButton: const FloatingActionButton(onPressed: null),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: RepaintBoundary(
          key: _painterKey,
          child: BottomAppBar(
            child: Row(
              children: const <Widget>[
                Icon(Icons.add),
                Expanded(child: SizedBox()),
                Icon(Icons.add),
              ],
            ),
          ),
        ),
    ),
  );
}
