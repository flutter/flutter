// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith, ==, hashCode basics', () {
    expect(const NavigationBarThemeData(), const NavigationBarThemeData().copyWith());
    expect(const NavigationBarThemeData().hashCode, const NavigationBarThemeData().copyWith().hashCode);
  });

  testWidgets('Default debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const NavigationBarThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('Custom debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const NavigationBarThemeData(
      height: 200.0,
      backgroundColor: Color(0x00000099),
      elevation: 20.0,
      indicatorColor: Color(0x00000098),
      indicatorShape: CircleBorder(),
      labelTextStyle: MaterialStatePropertyAll<TextStyle>(TextStyle(fontSize: 7.0)),
      iconTheme: MaterialStatePropertyAll<IconThemeData>(IconThemeData(color: Color(0x00000097))),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description[0], 'height: 200.0');
    expect(description[1], 'backgroundColor: Color(0x00000099)');
    expect(description[2], 'elevation: 20.0');
    expect(description[3], 'indicatorColor: Color(0x00000098)');
    expect(description[4], 'indicatorShape: CircleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none))');
    expect(description[5], 'labelTextStyle: MaterialStatePropertyAll(TextStyle(inherit: true, size: 7.0))');

    // Ignore instance address for IconThemeData.
    expect(description[6].contains('iconTheme: MaterialStatePropertyAll(IconThemeData'), isTrue);
    expect(description[6].contains('(color: Color(0x00000097))'), isTrue);

    expect(description[7], 'labelBehavior: NavigationDestinationLabelBehavior.alwaysHide');
  });

  testWidgets('NavigationBarThemeData values are used when no NavigationBar properties are specified', (WidgetTester tester) async {
    const double height = 200.0;
    const Color backgroundColor = Color(0x00000001);
    const double elevation = 42.0;
    const Color indicatorColor = Color(0x00000002);
    const ShapeBorder indicatorShape = CircleBorder();
    const double selectedIconSize = 25.0;
    const double unselectedIconSize = 23.0;
    const Color selectedIconColor = Color(0x00000003);
    const Color unselectedIconColor = Color(0x00000004);
    const double selectedIconOpacity = 0.99;
    const double unselectedIconOpacity = 0.98;
    const double selectedLabelFontSize = 13.0;
    const double unselectedLabelFontSize = 11.0;
    const NavigationDestinationLabelBehavior labelBehavior = NavigationDestinationLabelBehavior.alwaysShow;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: height,
              backgroundColor: backgroundColor,
              elevation: elevation,
              indicatorColor: indicatorColor,
              indicatorShape: indicatorShape,
              iconTheme: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return const IconThemeData(
                    size: selectedIconSize,
                    color: selectedIconColor,
                    opacity: selectedIconOpacity,
                  );
                }
                return const IconThemeData(
                  size: unselectedIconSize,
                  color: unselectedIconColor,
                  opacity: unselectedIconOpacity,
                );
              }),
              labelTextStyle: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return const TextStyle(fontSize: selectedLabelFontSize);
                }
                return const TextStyle(fontSize: unselectedLabelFontSize);
              }),
              labelBehavior: labelBehavior,
            ),
            child: NavigationBar(
              destinations: _destinations(),
            ),
          ),
        ),
      ),
    );

    expect(_barHeight(tester), height);
    expect(_barMaterial(tester).color, backgroundColor);
    expect(_barMaterial(tester).elevation, elevation);
    expect(_indicator(tester)?.color, indicatorColor);
    expect(_indicator(tester)?.shape, indicatorShape);
    expect(_selectedIconTheme(tester).size, selectedIconSize);
    expect(_selectedIconTheme(tester).color, selectedIconColor);
    expect(_selectedIconTheme(tester).opacity, selectedIconOpacity);
    expect(_unselectedIconTheme(tester).size, unselectedIconSize);
    expect(_unselectedIconTheme(tester).color, unselectedIconColor);
    expect(_unselectedIconTheme(tester).opacity, unselectedIconOpacity);
    expect(_selectedLabelStyle(tester).fontSize, selectedLabelFontSize);
    expect(_unselectedLabelStyle(tester).fontSize, unselectedLabelFontSize);
    expect(_labelBehavior(tester), labelBehavior);
  });

  testWidgets('NavigationBar values take priority over NavigationBarThemeData values when both properties are specified', (WidgetTester tester) async {
    const double height = 200.0;
    const Color backgroundColor = Color(0x00000001);
    const double elevation = 42.0;
    const NavigationDestinationLabelBehavior labelBehavior = NavigationDestinationLabelBehavior.alwaysShow;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NavigationBarTheme(
            data: const NavigationBarThemeData(
              height: 100.0,
              elevation: 18.0,
              backgroundColor: Color(0x00000099),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            ),
            child: NavigationBar(
              height: height,
              elevation: elevation,
              backgroundColor: backgroundColor,
              labelBehavior: labelBehavior,
              destinations: _destinations(),
            ),
          ),
        ),
      ),
    );

    expect(_barHeight(tester), height);
    expect(_barMaterial(tester).color, backgroundColor);
    expect(_barMaterial(tester).elevation, elevation);
    expect(_labelBehavior(tester), labelBehavior);
  });
}

List<NavigationDestination> _destinations() {
  return const <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite),
      label: 'Abc',
    ),
    NavigationDestination(
      icon: Icon(Icons.star_border),
      selectedIcon: Icon(Icons.star),
      label: 'Def',
    ),
  ];
}

double _barHeight(WidgetTester tester) {
  return tester.getRect(
    find.byType(NavigationBar),
  ).height;
}

Material _barMaterial(WidgetTester tester) {
  return tester.firstWidget<Material>(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byType(Material),
    ),
  );
}

ShapeDecoration? _indicator(WidgetTester tester) {
  return tester.firstWidget<Container>(
    find.descendant(
      of: find.byType(FadeTransition),
      matching: find.byType(Container),
    ),
  ).decoration as ShapeDecoration?;
}

IconThemeData _selectedIconTheme(WidgetTester tester) {
  return _iconTheme(tester, Icons.favorite);
}

IconThemeData _unselectedIconTheme(WidgetTester tester) {
  return _iconTheme(tester, Icons.star_border);
}

IconThemeData _iconTheme(WidgetTester tester, IconData icon) {
  return tester.firstWidget<IconTheme>(
    find.ancestor(
      of: find.byIcon(icon),
      matching: find.byType(IconTheme),
    ),
  ).data;
}

TextStyle _selectedLabelStyle(WidgetTester tester) {
  return tester.widget<RichText>(
    find.descendant(
      of: find.text('Abc'),
      matching: find.byType(RichText),
    ),
  ).text.style!;
}

TextStyle _unselectedLabelStyle(WidgetTester tester) {
  return tester.widget<RichText>(
    find.descendant(
      of: find.text('Def'),
      matching: find.byType(RichText),
    ),
  ).text.style!;
}

NavigationDestinationLabelBehavior _labelBehavior(WidgetTester tester) {
  if (_opacityAboveLabel('Abc').evaluate().isNotEmpty && _opacityAboveLabel('Def').evaluate().isNotEmpty) {
    return _labelOpacity(tester, 'Abc') == 1
        ? NavigationDestinationLabelBehavior.onlyShowSelected
        : NavigationDestinationLabelBehavior.alwaysHide;
  } else {
    return NavigationDestinationLabelBehavior.alwaysShow;
  }
}

Finder _opacityAboveLabel(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byType(Opacity),
  );
}

// Only valid when labelBehavior != alwaysShow.
double _labelOpacity(WidgetTester tester, String text) {
  final Opacity opacityWidget = tester.widget<Opacity>(
    find.ancestor(
      of: find.text(text),
      matching: find.byType(Opacity),
    ),
  );
  return opacityWidget.opacity;
}
