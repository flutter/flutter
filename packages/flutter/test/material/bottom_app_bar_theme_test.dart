// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BottomAppBarThemeData copyWith, ==, hashCode, defaults', () {
    expect(const BottomAppBarThemeData(), const BottomAppBarThemeData().copyWith());
    expect(
      const BottomAppBarThemeData().hashCode,
      const BottomAppBarThemeData().copyWith().hashCode,
    );
    expect(const BottomAppBarThemeData().color, null);
    expect(const BottomAppBarThemeData().elevation, null);
    expect(const BottomAppBarThemeData().shadowColor, null);
    expect(const BottomAppBarThemeData().shape, null);
    expect(const BottomAppBarThemeData().height, null);
    expect(const BottomAppBarThemeData().surfaceTintColor, null);
    expect(const BottomAppBarThemeData().padding, null);
  });

  test('BottomAppBarThemeData lerp special cases', () {
    const theme = BottomAppBarThemeData();
    expect(identical(BottomAppBarThemeData.lerp(theme, theme, 0.5), theme), true);
  });

  testWidgets('Default BottomAppBarThemeData debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();
    const BottomAppBarThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('BottomAppBarThemeData implements debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();
    const BottomAppBarThemeData(
      color: Color(0xffff0000),
      elevation: 1.0,
      shape: CircularNotchedRectangle(),
      height: 1.0,
      shadowColor: Color(0xff0000ff),
      surfaceTintColor: Color(0xff00ff00),
      padding: EdgeInsets.all(8),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'color: ${const Color(0xffff0000)}',
      'elevation: 1.0',
      "shape: Instance of 'CircularNotchedRectangle'",
      'height: 1.0',
      'surfaceTintColor: ${const Color(0xff00ff00)}',
      'shadowColor: ${const Color(0xff0000ff)}',
      'padding: EdgeInsets.all(8.0)',
    ]);
  });

  testWidgets('Local BottomAppBarTheme overrides defaults', (WidgetTester tester) async {
    const Color color = Colors.blueAccent;
    const elevation = 1.0;
    const Color shadowColor = Colors.black87;
    const height = 100.0;
    const Color surfaceTintColor = Colors.transparent;
    const NotchedShape shape = CircularNotchedRectangle();
    const EdgeInsetsGeometry padding = EdgeInsets.all(8);
    const themeData = BottomAppBarThemeData(
      color: color,
      elevation: elevation,
      shadowColor: shadowColor,
      shape: shape,
      height: height,
      surfaceTintColor: surfaceTintColor,
      padding: padding,
    );

    await tester.pumpWidget(_withTheme(localBABTheme: themeData));

    final PhysicalShape widget = _getBabRenderObject(tester);
    expect(widget.color, themeData.color);
    expect(widget.elevation, themeData.elevation);
    expect(widget.shadowColor, themeData.shadowColor);

    final RenderBox renderBox = tester.renderObject<RenderBox>(find.byType(BottomAppBar));
    expect(renderBox.size.height, themeData.height);

    final bool hasFab = Scaffold.of(
      tester.element(find.byType(BottomAppBar)),
    ).hasFloatingActionButton;
    if (hasFab) {
      expect(widget.clipper.toString(), '_BottomAppBarClipper');
    } else {
      expect(widget.clipper, isA<ShapeBorderClipper>());
      final clipper = widget.clipper as ShapeBorderClipper;
      expect(clipper.shape, isA<RoundedRectangleBorder>());
    }

    final Color effectiveColor = ElevationOverlay.applySurfaceTint(
      themeData.color!,
      themeData.surfaceTintColor,
      themeData.elevation!,
    );
    expect(widget.color, effectiveColor);

    // The BottomAppBar has two Padding widgets in its hierarchy:
    // 1. The first Padding is from the SafeArea widget.
    // 2. The second Padding is the one that applies the theme's padding.
    final Padding paddingWidget = tester.widget<Padding>(
      find.descendant(of: find.byType(BottomAppBar), matching: find.byType(Padding).at(1)),
    );
    expect(paddingWidget.padding, padding);
  });

  group('Material 2 tests', () {
    testWidgets('Material2 - BAB theme overrides color', (WidgetTester tester) async {
      const Color themedColor = Colors.black87;
      const theme = BottomAppBarThemeData(color: themedColor);

      await tester.pumpWidget(_withTheme(babTheme: theme, useMaterial3: false));

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, themedColor);
    });

    testWidgets('Material2 - BAB color - Widget', (WidgetTester tester) async {
      const Color babThemeColor = Colors.black87;
      const Color babColor = Colors.pink;
      const theme = BottomAppBarThemeData(color: babThemeColor);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false, bottomAppBarTheme: theme),
          home: const Scaffold(body: BottomAppBar(color: babColor)),
        ),
      );

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, babColor);
    });

    testWidgets('Material2 - BAB color - BabTheme', (WidgetTester tester) async {
      const Color babThemeColor = Colors.black87;
      const theme = BottomAppBarThemeData(color: babThemeColor);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false, bottomAppBarTheme: theme),
          home: const Scaffold(body: BottomAppBar()),
        ),
      );

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, babThemeColor);
    });

    testWidgets('Material2 - BAB color - Theme', (WidgetTester tester) async {
      const Color themeColor = Colors.white10;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            bottomAppBarTheme: const BottomAppBarThemeData(color: themeColor),
          ),
          home: const Scaffold(body: BottomAppBar()),
        ),
      );

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, themeColor);
    });

    testWidgets('Material2 - BAB color - Default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: const Scaffold(body: BottomAppBar()),
        ),
      );

      final PhysicalShape widget = _getBabRenderObject(tester);

      expect(widget.color, Colors.white);
    });

    testWidgets('Material2 - BAB theme customizes shape', (WidgetTester tester) async {
      const theme = BottomAppBarThemeData(
        color: Colors.white30,
        shape: CircularNotchedRectangle(),
        elevation: 1.0,
      );

      await tester.pumpWidget(_withTheme(babTheme: theme, useMaterial3: false));

      await expectLater(
        find.byKey(_painterKey),
        matchesGoldenFile('bottom_app_bar_theme.custom_shape.png'),
      );
    });

    testWidgets('Material2 - BAB theme does not affect defaults', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: const Scaffold(body: BottomAppBar()),
        ),
      );

      final PhysicalShape widget = _getBabRenderObject(tester);

      expect(widget.color, Colors.white);
      expect(widget.elevation, equals(8.0));
    });
  });

  group('Material 3 tests', () {
    testWidgets('Material3 - BAB theme overrides color', (WidgetTester tester) async {
      const Color themedColor = Colors.black87;
      const theme = BottomAppBarThemeData(color: themedColor, elevation: 0);
      await tester.pumpWidget(_withTheme(babTheme: theme));

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, themedColor);
    });

    testWidgets('Material3 - BAB color - Widget', (WidgetTester tester) async {
      const Color babThemeColor = Colors.black87;
      const Color babColor = Colors.pink;
      const theme = BottomAppBarThemeData(color: babThemeColor);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(bottomAppBarTheme: theme),
          home: const Scaffold(
            body: BottomAppBar(color: babColor, surfaceTintColor: Colors.transparent),
          ),
        ),
      );

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, babColor);
    });

    testWidgets('Material3 - BAB color - BabTheme', (WidgetTester tester) async {
      const Color babThemeColor = Colors.black87;
      const theme = BottomAppBarThemeData(color: babThemeColor);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(bottomAppBarTheme: theme),
          home: const Scaffold(body: BottomAppBar(surfaceTintColor: Colors.transparent)),
        ),
      );

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, babThemeColor);
    });

    testWidgets('Material3 - BAB theme does not affect defaults', (WidgetTester tester) async {
      final theme = ThemeData();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: BottomAppBar(surfaceTintColor: Colors.transparent)),
        ),
      );

      final PhysicalShape widget = _getBabRenderObject(tester);

      expect(widget.color, theme.colorScheme.surfaceContainer);
      expect(widget.elevation, equals(3.0));
    });

    testWidgets('Material3 - BAB theme overrides surfaceTintColor', (WidgetTester tester) async {
      const Color color = Colors.blue; // base color that the surface tint will be applied to
      const Color babThemeSurfaceTintColor = Colors.black87;
      const theme = BottomAppBarThemeData(
        color: color,
        surfaceTintColor: babThemeSurfaceTintColor,
        elevation: 0,
      );
      await tester.pumpWidget(_withTheme(babTheme: theme));

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, ElevationOverlay.applySurfaceTint(color, babThemeSurfaceTintColor, 0));
    });

    testWidgets('Material3 - BAB theme overrides shadowColor', (WidgetTester tester) async {
      const Color babThemeShadowColor = Colors.yellow;
      const theme = BottomAppBarThemeData(shadowColor: babThemeShadowColor, elevation: 0);
      await tester.pumpWidget(_withTheme(babTheme: theme));

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.shadowColor, babThemeShadowColor);
    });

    testWidgets('Material3 - BAB surfaceTintColor - Widget', (WidgetTester tester) async {
      const Color color = Colors.white10; // base color that the surface tint will be applied to
      const Color babThemeSurfaceTintColor = Colors.black87;
      const Color babSurfaceTintColor = Colors.pink;
      const theme = BottomAppBarThemeData(surfaceTintColor: babThemeSurfaceTintColor);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(bottomAppBarTheme: theme),
          home: const Scaffold(
            body: BottomAppBar(color: color, surfaceTintColor: babSurfaceTintColor),
          ),
        ),
      );

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, ElevationOverlay.applySurfaceTint(color, babSurfaceTintColor, 3.0));
    });

    testWidgets('Material3 - BAB surfaceTintColor - BabTheme', (WidgetTester tester) async {
      const Color color = Colors.blue; // base color that the surface tint will be applied to
      const Color babThemeColor = Colors.black87;
      const theme = BottomAppBarThemeData(surfaceTintColor: babThemeColor);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(bottomAppBarTheme: theme),
          home: const Scaffold(body: BottomAppBar(color: color)),
        ),
      );

      final PhysicalShape widget = _getBabRenderObject(tester);
      expect(widget.color, ElevationOverlay.applySurfaceTint(color, babThemeColor, 3.0));
    });
  });
}

PhysicalShape _getBabRenderObject(WidgetTester tester) {
  return tester.widget<PhysicalShape>(
    find.descendant(of: find.byType(BottomAppBar), matching: find.byType(PhysicalShape)),
  );
}

final Key _painterKey = UniqueKey();

Widget _withTheme({
  BottomAppBarThemeData? babTheme,
  BottomAppBarThemeData? localBABTheme,
  bool useMaterial3 = true,
}) {
  Widget babWidget = const BottomAppBar(
    child: Row(
      children: <Widget>[
        Icon(Icons.add),
        Expanded(child: SizedBox()),
        Icon(Icons.add),
      ],
    ),
  );
  if (localBABTheme != null) {
    babWidget = BottomAppBarTheme(data: localBABTheme, child: babWidget);
  }
  return MaterialApp(
    theme: ThemeData(useMaterial3: useMaterial3, bottomAppBarTheme: babTheme),
    home: Scaffold(
      floatingActionButton: const FloatingActionButton(onPressed: null),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: RepaintBoundary(key: _painterKey, child: babWidget),
    ),
  );
}
