// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Material 2 tests', () {
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
        theme: ThemeData(
          bottomAppBarTheme: theme,
          bottomAppBarColor: themeColor
        ),
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
        theme: ThemeData(
          bottomAppBarTheme: theme,
          bottomAppBarColor: themeColor
        ),
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
  });

  group('Material 3 tests', () {
    Material getBabRenderObject(WidgetTester tester) {
      return tester.widget<Material>(
        find.descendant(
          of: find.byType(BottomAppBar),
          matching: find.byType(Material),
        ),
      );
    }

    testWidgets('BAB theme overrides color - M3', (WidgetTester tester) async {
      const Color themedColor = Colors.black87;
      const BottomAppBarTheme theme = BottomAppBarTheme(
        color: themedColor,
        elevation: 0
      );
      await tester.pumpWidget(_withTheme(theme, true));

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, themedColor);
    });

    testWidgets('BAB color - Widget - M3', (WidgetTester tester) async {
      const Color themeColor = Colors.white10;
      const Color babThemeColor = Colors.black87;
      const Color babColor = Colors.pink;
      const BottomAppBarTheme theme = BottomAppBarTheme(color: babThemeColor);

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          bottomAppBarTheme: theme,
          bottomAppBarColor: themeColor
        ),
        home: const Scaffold(body: BottomAppBar(color: babColor)),
      ));

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, babColor);
    });

    testWidgets('BAB color - BabTheme - M3', (WidgetTester tester) async {
      const Color themeColor = Colors.white10;
      const Color babThemeColor = Colors.black87;
      const BottomAppBarTheme theme = BottomAppBarTheme(color: babThemeColor);

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          bottomAppBarTheme: theme,
          bottomAppBarColor: themeColor
        ),
        home: const Scaffold(body: BottomAppBar()),
      ));

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, babThemeColor);
    });

    testWidgets('BAB theme does not affect defaults - M3', (WidgetTester tester) async {
      final ThemeData theme = ThemeData(useMaterial3: true);
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(body: BottomAppBar()),
      ));

      final PhysicalShape widget = _getBabRenderObject(tester);

      expect(widget.color, theme.colorScheme.surface);
      expect(widget.elevation, equals(3.0));
    });

    testWidgets('BAB theme overrides surfaceTintColor - M3', (WidgetTester tester) async {
      const Color babThemeSurfaceTintColor = Colors.black87;
      const BottomAppBarTheme theme = BottomAppBarTheme(
        surfaceTintColor: babThemeSurfaceTintColor, elevation: 0
      );
      await tester.pumpWidget(_withTheme(theme, true));

      final Material widget = getBabRenderObject(tester);
      expect(widget.surfaceTintColor, babThemeSurfaceTintColor);
    });

    testWidgets('BAB surfaceTintColor - Widget - M3', (WidgetTester tester) async {
      const Color themeSurfaceTintColor = Colors.white10;
      const Color babThemeSurfaceTintColor = Colors.black87;
      const Color babSurfaceTintColor = Colors.pink;
      const BottomAppBarTheme theme = BottomAppBarTheme(
        surfaceTintColor: babThemeSurfaceTintColor
      );
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          bottomAppBarTheme: theme,
          bottomAppBarColor: themeSurfaceTintColor
        ),
        home: const Scaffold(
          body: BottomAppBar(surfaceTintColor: babSurfaceTintColor)
        ),
      ));

      final Material widget = getBabRenderObject(tester);
      expect(widget.surfaceTintColor, babSurfaceTintColor);
    });

    testWidgets('BAB surfaceTintColor - BabTheme - M3', (WidgetTester tester) async {
      const Color themeColor = Colors.white10;
      const Color babThemeColor = Colors.black87;
      const BottomAppBarTheme theme = BottomAppBarTheme(
        surfaceTintColor: babThemeColor
      );

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          bottomAppBarTheme: theme,
          bottomAppBarColor: themeColor
        ),
        home: const Scaffold(body: BottomAppBar()),
      ));

      final Material widget = getBabRenderObject(tester);
      expect(widget.surfaceTintColor, babThemeColor);
    });
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

Widget _withTheme(BottomAppBarTheme theme, [bool useMaterial3 = false]) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: useMaterial3, bottomAppBarTheme: theme),
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
