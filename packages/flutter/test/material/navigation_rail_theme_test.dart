// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith, ==, hashCode basics', () {
    expect(const NavigationRailThemeData(), const NavigationRailThemeData().copyWith());
    expect(const NavigationRailThemeData().hashCode, const NavigationRailThemeData().copyWith().hashCode);
  });

  testWidgets('Default values are used when no NavigationRail or NavigationRailThemeData properties are specified', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavigationRail(
            selectedIndex: 0,
            destinations: _destinations(),
          ),
        ),
      ),
    );

    expect(_railMaterial(tester).color, ThemeData().colorScheme.surface);
    expect(_railMaterial(tester).elevation, 0);
    expect(_selectedIconTheme(tester).size, 24.0);
    expect(_selectedIconTheme(tester).color, ThemeData().colorScheme.primary);
    expect(_selectedIconTheme(tester).opacity, 1.0);
    expect(_unselectedIconTheme(tester).size, 24.0);
    expect(_unselectedIconTheme(tester).color, ThemeData().colorScheme.onSurface);
    expect(_unselectedIconTheme(tester).opacity, 0.64);
    expect(_selectedLabelStyle(tester).fontSize, 14.0);
    expect(_unselectedLabelStyle(tester).fontSize, 14.0);
    expect(_destinationsAlign(tester).alignment, Alignment.topCenter);
    expect(_labelType(tester), NavigationRailLabelType.none);
  });

  testWidgets('NavigationRailThemeData values are used when no NavigationRail properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0x00000001);
    const double elevation = 7.0;
    const double selectedIconSize = 25.0;
    const double unselectedIconSize = 23.0;
    const Color selectedIconColor = Color(0x00000002);
    const Color unselectedIconColor = Color(0x00000003);
    const double selectedIconOpacity = 0.99;
    const double unselectedIconOpacity = 0.98;
    const double selectedLabelFontSize = 13.0;
    const double unselectedLabelFontSize = 11.0;
    const double groupAlignment = 0.0;
    const NavigationRailLabelType labelType = NavigationRailLabelType.all;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavigationRailTheme(
            data: const NavigationRailThemeData(
              backgroundColor: backgroundColor,
              elevation: elevation,
              selectedIconTheme: IconThemeData(
                size: selectedIconSize,
                color: selectedIconColor,
                opacity: selectedIconOpacity,
              ),
              unselectedIconTheme: IconThemeData(
                size: unselectedIconSize,
                color: unselectedIconColor,
                opacity: unselectedIconOpacity,
              ),
              selectedLabelTextStyle: TextStyle(fontSize: selectedLabelFontSize),
              unselectedLabelTextStyle: TextStyle(fontSize: unselectedLabelFontSize),
              groupAlignment: groupAlignment,
              labelType: labelType,
            ),
            child: NavigationRail(
              selectedIndex: 0,
              destinations: _destinations(),
            ),
          ),
        ),
      ),
    );

    expect(_railMaterial(tester).color, backgroundColor);
    expect(_railMaterial(tester).elevation, elevation);
    expect(_selectedIconTheme(tester).size, selectedIconSize);
    expect(_selectedIconTheme(tester).color, selectedIconColor);
    expect(_selectedIconTheme(tester).opacity, selectedIconOpacity);
    expect(_unselectedIconTheme(tester).size, unselectedIconSize);
    expect(_unselectedIconTheme(tester).color, unselectedIconColor);
    expect(_unselectedIconTheme(tester).opacity, unselectedIconOpacity);
    expect(_selectedLabelStyle(tester).fontSize, selectedLabelFontSize);
    expect(_unselectedLabelStyle(tester).fontSize, unselectedLabelFontSize);
    expect(_destinationsAlign(tester).alignment, Alignment.center);
    expect(_labelType(tester), labelType);
  });

  testWidgets('NavigationRail values take priority over NavigationRailThemeData values when both properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0x00000001);
    const double elevation = 7.0;
    const double selectedIconSize = 25.0;
    const double unselectedIconSize = 23.0;
    const Color selectedIconColor = Color(0x00000002);
    const Color unselectedIconColor = Color(0x00000003);
    const double selectedIconOpacity = 0.99;
    const double unselectedIconOpacity = 0.98;
    const double selectedLabelFontSize = 13.0;
    const double unselectedLabelFontSize = 11.0;
    const double groupAlignment = 0.0;
    const NavigationRailLabelType labelType = NavigationRailLabelType.all;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavigationRailTheme(
            data: const NavigationRailThemeData(
              backgroundColor: Color(0x00000099),
              elevation: 5,
              selectedIconTheme: IconThemeData(
                size: 31.0,
                color: Color(0x00000098),
                opacity: 0.81,
              ),
              unselectedIconTheme: IconThemeData(
                size: 37.0,
                color: Color(0x00000097),
                opacity: 0.82,
              ),
              selectedLabelTextStyle: TextStyle(fontSize: 9.0),
              unselectedLabelTextStyle: TextStyle(fontSize: 7.0),
              groupAlignment: 1.0,
              labelType: NavigationRailLabelType.selected,
            ),
            child: NavigationRail(
              selectedIndex: 0,
              destinations: _destinations(),
              backgroundColor: backgroundColor,
              elevation: elevation,
              selectedIconTheme: const IconThemeData(
                size: selectedIconSize,
                color: selectedIconColor,
                opacity: selectedIconOpacity,
              ),
              unselectedIconTheme: const IconThemeData(
                size: unselectedIconSize,
                color: unselectedIconColor,
                opacity: unselectedIconOpacity,
              ),
              selectedLabelTextStyle: const TextStyle(fontSize: selectedLabelFontSize),
              unselectedLabelTextStyle: const TextStyle(fontSize: unselectedLabelFontSize),
              groupAlignment: groupAlignment,
              labelType: labelType,
            ),
          ),
        ),
      ),
    );

    expect(_railMaterial(tester).color, backgroundColor);
    expect(_railMaterial(tester).elevation, elevation);
    expect(_selectedIconTheme(tester).size, selectedIconSize);
    expect(_selectedIconTheme(tester).color, selectedIconColor);
    expect(_selectedIconTheme(tester).opacity, selectedIconOpacity);
    expect(_unselectedIconTheme(tester).size, unselectedIconSize);
    expect(_unselectedIconTheme(tester).color, unselectedIconColor);
    expect(_unselectedIconTheme(tester).opacity, unselectedIconOpacity);
    expect(_selectedLabelStyle(tester).fontSize, selectedLabelFontSize);
    expect(_unselectedLabelStyle(tester).fontSize, unselectedLabelFontSize);
    expect(_destinationsAlign(tester).alignment, Alignment.center);
    expect(_labelType(tester), labelType);
  });

  testWidgets('Default debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const NavigationRailThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('Custom debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const NavigationRailThemeData(
      backgroundColor: Color(0x00000099),
      elevation: 5,
      selectedIconTheme: IconThemeData(color: Color(0x00000098)),
      unselectedIconTheme: IconThemeData(color: Color(0x00000097)),
      selectedLabelTextStyle: TextStyle(fontSize: 9.0),
      unselectedLabelTextStyle: TextStyle(fontSize: 7.0),
      groupAlignment: 1.0,
      labelType: NavigationRailLabelType.selected,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description[0], 'backgroundColor: Color(0x00000099)');
    expect(description[1], 'elevation: 5.0');
    expect(description[2], 'unselectedLabelTextStyle: TextStyle(inherit: true, size: 7.0)');
    expect(description[3], 'selectedLabelTextStyle: TextStyle(inherit: true, size: 9.0)');

    // Ignore instance address for IconThemeData.
    expect(description[4].contains('unselectedIconTheme: IconThemeData'), isTrue);
    expect(description[4].contains('(color: Color(0x00000097))'), isTrue);
    expect(description[5].contains('selectedIconTheme: IconThemeData'), isTrue);
    expect(description[5].contains('(color: Color(0x00000098))'), isTrue);

    expect(description[6], 'groupAlignment: 1.0');
    expect(description[7], 'labelType: NavigationRailLabelType.selected');

  });
}

List<NavigationRailDestination> _destinations() {
  return const <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite),
      label: Text('Abc'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.star_border),
      selectedIcon: Icon(Icons.star),
      label: Text('Def'),
    ),
  ];
}

Material _railMaterial(WidgetTester tester) {
  // The first material is for the rail, and the rest are for the destinations.
  return tester.firstWidget<Material>(
    find.descendant(
      of: find.byType(NavigationRail),
      matching: find.byType(Material),
    ),
  );
}

IconThemeData _selectedIconTheme(WidgetTester tester) {
  return _iconTheme(tester, Icons.favorite);
}

IconThemeData _unselectedIconTheme(WidgetTester tester) {
  return _iconTheme(tester, Icons.star_border);
}

IconThemeData _iconTheme(WidgetTester tester, IconData icon) {
  // The first IconTheme is the one added by the navigation rail.
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

Align _destinationsAlign(WidgetTester tester) {
  // The first Expanded widget is the one within the main Column for the rail
  // content.
  return tester.firstWidget<Align>(
    find.descendant(
      of: find.byType(Expanded),
      matching: find.byType(Align),
    ),
  );
}

NavigationRailLabelType _labelType(WidgetTester tester) {
  if (_opacityAboveLabel('Abc').evaluate().isNotEmpty && _opacityAboveLabel('Def').evaluate().isNotEmpty) {
    return _labelOpacity(tester, 'Abc') == 1 ? NavigationRailLabelType.selected : NavigationRailLabelType.none;
  } else {
    return NavigationRailLabelType.all;
  }
}

Finder _opacityAboveLabel(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byType(Opacity),
  );
}

// Only valid when labelType != all.
double _labelOpacity(WidgetTester tester, String text) {
  final Opacity opacityWidget = tester.widget<Opacity>(
    find.ancestor(
      of: find.text(text),
      matching: find.byType(Opacity),
    ),
  );
  return opacityWidget.opacity;
}
