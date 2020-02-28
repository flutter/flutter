// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
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
            destinations: _destinations(),
          ),
        ),
      ),
    );

    expect(_railMaterial(tester).color, ThemeData().colorScheme.surface);
    expect(_railMaterial(tester).elevation, 0);
    expect(_selectedIconStyle(tester).color, ThemeData().colorScheme.primary);
    expect(_unselectedIconStyle(tester).color, ThemeData().colorScheme.onSurface.withOpacity(0.64));
    expect(_selectedLabelStyle(tester).fontSize, 14.0);
    expect(_unselectedLabelStyle(tester).fontSize, 14.0);
    expect(_destinationsColumn(tester).mainAxisAlignment, MainAxisAlignment.start);
    expect(_labelType(tester), NavigationRailLabelType.none);
  });

  testWidgets('NavigationRailThemeData values are used when no NavigationRail properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0x00000001);
    const double elevation = 7.0;
    const Color selectedIconColor = Color(0x00000002);
    const Color unselectedIconColor = Color(0x00000003);
    const double selectedLabelFontSize = 13.0;
    const double unselectedLabelFontSize = 11.0;
    const NavigationRailGroupAlignment groupAlignment = NavigationRailGroupAlignment.center;
    const NavigationRailLabelType labelType = NavigationRailLabelType.all;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Theme(
            data: ThemeData(
              navigationRailTheme: const NavigationRailThemeData(
                backgroundColor: backgroundColor,
                elevation: elevation,
                selectedIconTheme: IconThemeData(color: selectedIconColor),
                unselectedIconTheme: IconThemeData(color: unselectedIconColor),
                selectedLabelTextStyle: TextStyle(fontSize: selectedLabelFontSize),
                unselectedLabelTextStyle: TextStyle(fontSize: unselectedLabelFontSize),
                groupAlignment: groupAlignment,
                labelType: labelType,
              ),
            ),
            child: NavigationRail(
              destinations: _destinations(),
            ),
          ),
        ),
      ),
    );

    expect(_railMaterial(tester).color, backgroundColor);
    expect(_railMaterial(tester).elevation, elevation);
    expect(_selectedIconStyle(tester).color, selectedIconColor);
    expect(_unselectedIconStyle(tester).color, unselectedIconColor);
    expect(_selectedLabelStyle(tester).fontSize, selectedLabelFontSize);
    expect(_unselectedLabelStyle(tester).fontSize, unselectedLabelFontSize);
    expect(_destinationsColumn(tester).mainAxisAlignment, _resolveGroupAlignment(groupAlignment));
    expect(_labelType(tester), labelType);
  });

  testWidgets('NavigationRail values take priority over NavigationRailThemeData values when both properties are specified', (WidgetTester tester) async {
    const Color backgroundColor = Color(0x00000001);
    const double elevation = 7.0;
    const Color selectedIconColor = Color(0x00000002);
    const Color unselectedIconColor = Color(0x00000003);
    const double selectedLabelFontSize = 13.0;
    const double unselectedLabelFontSize = 11.0;
    const NavigationRailGroupAlignment groupAlignment = NavigationRailGroupAlignment.center;
    const NavigationRailLabelType labelType = NavigationRailLabelType.all;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Theme(
            data: ThemeData(
              navigationRailTheme: const NavigationRailThemeData(
                backgroundColor: Color(0x00000099),
                elevation: 5,
                selectedIconTheme: IconThemeData(color: Color(0x00000098)),
                unselectedIconTheme: IconThemeData(color: Color(0x00000097)),
                selectedLabelTextStyle: TextStyle(fontSize: 9.0),
                unselectedLabelTextStyle: TextStyle(fontSize: 7.0),
                groupAlignment: NavigationRailGroupAlignment.bottom,
                labelType: NavigationRailLabelType.selected,
              ),
            ),
            child: NavigationRail(
              destinations: _destinations(),
              backgroundColor: backgroundColor,
              elevation: elevation,
              selectedIconTheme: IconThemeData(color: selectedIconColor),
              unselectedIconTheme: IconThemeData(color: unselectedIconColor),
              selectedLabelTextStyle: TextStyle(fontSize: selectedLabelFontSize),
              unselectedLabelTextStyle: TextStyle(fontSize: unselectedLabelFontSize),
              groupAlignment: groupAlignment,
              labelType: labelType,
            ),
          ),
        ),
      ),
    );

    expect(_railMaterial(tester).color, backgroundColor);
    expect(_railMaterial(tester).elevation, elevation);
    expect(_selectedIconStyle(tester).color, selectedIconColor);
    expect(_unselectedIconStyle(tester).color, unselectedIconColor);
    expect(_selectedLabelStyle(tester).fontSize, selectedLabelFontSize);
    expect(_unselectedLabelStyle(tester).fontSize, unselectedLabelFontSize);
    expect(_destinationsColumn(tester).mainAxisAlignment, _resolveGroupAlignment(groupAlignment));
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
      groupAlignment: NavigationRailGroupAlignment.bottom,
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

    expect(description[6], 'groupAlignment: NavigationRailGroupAlignment.bottom');
    expect(description[7], 'labelType: NavigationRailLabelType.selected');

  });
}

List<NavigationRailDestination> _destinations() {
  return const <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.favorite_border),
      activeIcon: Icon(Icons.favorite),
      label: Text('Abc'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.star_border),
      activeIcon: Icon(Icons.star),
      label: Text('Def'),
    ),
  ];
}

Material _railMaterial(WidgetTester tester) {
  return tester.firstWidget<Material>(
    find.descendant(
      of: find.byType(NavigationRail),
      matching: find.byType(Material),
    ),
  );
}

TextStyle _selectedIconStyle(WidgetTester tester) {
  return tester.widget<RichText>(
      _iconRichTextFinder(Icons.favorite).first
  ).text.style;
}

TextStyle _unselectedIconStyle(WidgetTester tester) {
  return tester.widget<RichText>(
    _iconRichTextFinder(Icons.star_border).first
  ).text.style;
}

Finder _iconRichTextFinder(IconData icon) {
  return find.descendant(
    of: find.byIcon(icon),
    matching: find.byType(RichText),
  );
}

TextStyle _selectedLabelStyle(WidgetTester tester) {
  return tester.widget<RichText>(
    find.descendant(
      of: find.text('Abc'),
      matching: find.byType(RichText),
    ),
  ).text.style;
}

TextStyle _unselectedLabelStyle(WidgetTester tester) {
  return tester.widget<RichText>(
    find.descendant(
      of: find.text('Def'),
      matching: find.byType(RichText),
    ),
  ).text.style;
}

Column _destinationsColumn(WidgetTester tester) {
  return tester.widget<Column>(
    find.descendant(
      of: find.byType(NavigationRail),
      matching: find.byType(Column),
    ).at(1),
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
  final Opacity opacityWidget = tester.firstWidget<Opacity>(
    find.ancestor(
      of: find.text(text),
      matching: find.byType(Opacity),
    ),
  );
  return opacityWidget.opacity;
}

MainAxisAlignment _resolveGroupAlignment(NavigationRailGroupAlignment groupAlignment) {
  switch (groupAlignment) {
    case NavigationRailGroupAlignment.top:
      return MainAxisAlignment.start;
    case NavigationRailGroupAlignment.center:
      return MainAxisAlignment.center;
    case NavigationRailGroupAlignment.bottom:
      return MainAxisAlignment.end;
  }
  return MainAxisAlignment.start;
}