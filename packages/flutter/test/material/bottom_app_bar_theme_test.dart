// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BAB theme overrides color', (WidgetTester tester) async {
    const Color themedColor = Colors.black87;
    const BottomAppBarTheme theme = BottomAppBarTheme(color: themedColor);

    await tester.pumpWidget(_withTheme(theme));

    final PhysicalShape widget = tester.widget(
        find.descendant(of: find.byType(BottomAppBar),
            matching: find.byType(PhysicalShape)).first);
    expect(widget.color, themedColor);
  });

  testWidgets('BAB theme color supersedes theme BottomAppBarColor', (WidgetTester tester) async {
    const Color babThemeColor = Colors.black87;
    const Color themeColor = Colors.white10;
    const BottomAppBarTheme theme = BottomAppBarTheme(color: babThemeColor);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bottomAppBarTheme: theme, bottomAppBarColor: themeColor),
      home: const Scaffold(body: BottomAppBar()),
    ));

    final PhysicalShape widget = tester.widget(find
        .descendant(
            of: find.byType(BottomAppBar), matching: find.byType(PhysicalShape))
        .first);
    expect(widget.color, babThemeColor);
  });

  testWidgets('BAB theme customizes shape and notch margin', (WidgetTester tester) async {
    const BottomAppBarTheme theme = BottomAppBarTheme(
        color: Colors.white30,
        shape: CircularNotchedRectangle(),
        elevation: 1.0,
    );

    await tester.pumpWidget(_withTheme(theme));

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('bottom_app_bar_theme.custom_shape.png'),
      skip: !Platform.isLinux,
    );
  });
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
            child: Row(children: const <Widget>[
              Icon(Icons.add),
              Expanded(child: SizedBox()),
              Icon(Icons.add),
            ]
            ),
          ),
        )
    ),
  );
}
