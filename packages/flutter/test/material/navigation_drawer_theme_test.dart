// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NavigationDrawerThemeData copyWith, ==, hashCode, basics', () {
    expect(const NavigationDrawerThemeData(), const NavigationDrawerThemeData().copyWith());
    expect(const NavigationDrawerThemeData().hashCode, const NavigationDrawerThemeData().copyWith().hashCode);
  });

  test('NavigationDrawerThemeData lerp special cases', () {
    expect(NavigationDrawerThemeData.lerp(null, null, 0), null);
    const NavigationDrawerThemeData data = NavigationDrawerThemeData();
    expect(identical(NavigationDrawerThemeData.lerp(data, data, 0.5), data), true);
  });

  testWidgets('Default debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const NavigationDrawerThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('Custom debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const NavigationDrawerThemeData(
      tileHeight: 50,
      backgroundColor: Color(0x00000099),
      elevation: 5.0,
      shadowColor: Color(0x00000097),
      surfaceTintColor: Color(0x00000096),
      indicatorColor: Color(0x00000098),
      indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0))),
      indicatorSize: Size(10, 10),
      labelTextStyle:
          MaterialStatePropertyAll<TextStyle>(TextStyle(fontSize: 7.0)),
      iconTheme: MaterialStatePropertyAll<IconThemeData>(
          IconThemeData(color: Color(0x00000097))),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description[0], 'tileHeight: 50.0');
    expect(description[1], 'backgroundColor: Color(0x00000099)');
    expect(description[2], 'elevation: 5.0');
    expect(description[3], 'shadowColor: Color(0x00000097)');
    expect(description[4], 'surfaceTintColor: Color(0x00000096)');
    expect(description[5], 'indicatorColor: Color(0x00000098)');
    expect(description[6], 'indicatorShape: RoundedRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(2.0))');
    expect(description[7], 'indicatorSize: Size(10.0, 10.0)');
    expect(description[8], 'labelTextStyle: MaterialStatePropertyAll(TextStyle(inherit: true, size: 7.0))');

    // Ignore instance address for IconThemeData.
    expect(description[9].contains('iconTheme: MaterialStatePropertyAll(IconThemeData'),isTrue);
    expect(description[9].contains('(color: Color(0x00000097))'), isTrue);
  });

  testWidgets(
      'NavigationDrawerThemeData values are used when no NavigationDrawer properties are specified',
      (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    const Color backgroundColor = Color(0x00000001);
    const double elevation = 7.0;
    const Color shadowColor = Color(0x00000003);
    const Color surfaceTintColor = Color(0x00000004);
    const Color iconColor = Color(0x00000005);
    const TextStyle labelStyle = TextStyle(fontSize: 7.0);
    const RoundedRectangleBorder indicatorShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)));

    const Color indicatorColor = Color(0x00000005);
    final ThemeData theme = ThemeData(
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: backgroundColor,
        elevation: elevation,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
        indicatorShape: indicatorShape,
        indicatorColor: indicatorColor,
        labelTextStyle:
            MaterialStatePropertyAll<TextStyle>(TextStyle(fontSize: 7.0)),
        iconTheme: MaterialStatePropertyAll<IconThemeData>(
            IconThemeData(color: iconColor)),
      ),
    );
    await tester.pumpWidget(
      _buildWidget(
        scaffoldKey,
        NavigationDrawer(
          children: <Widget>[
            Text('Headline', style: theme.textTheme.bodyLarge),
            const NavigationDrawerDestination(
              icon: Icon(Icons.ac_unit),
              label: Text('AC'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.access_alarm),
              label: Text('Alarm'),
            ),
          ],
          onDestinationSelected: (int i) {},
        ),
        theme: theme,
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pump(const Duration(seconds: 1));

    // Test drawer Material.
    expect(_getMaterial(tester).color, backgroundColor);
    expect(_getMaterial(tester).surfaceTintColor, surfaceTintColor);
    expect(_getMaterial(tester).shadowColor, shadowColor);
    expect(_getMaterial(tester).elevation, 7);
    // Test indicator decoration.
    expect(_getIndicatorDecoration(tester)?.color, indicatorColor);
    expect(_getIndicatorDecoration(tester)?.shape, indicatorShape);
    // Test icon.
    expect(_iconStyle(tester, Icons.ac_unit)?.color, iconColor);
    expect(_iconStyle(tester, Icons.access_alarm)?.color, iconColor);
    // Test label.
    expect(_labelStyle(tester, 'AC'), labelStyle);
    expect(_labelStyle(tester, 'Alarm'), labelStyle);
  });

  testWidgets(
      'NavigationDrawer values take priority over NavigationDrawerThemeData values when both properties are specified',
      (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    const Color backgroundColor = Color(0x00000001);
    const double elevation = 7.0;
    const Color shadowColor = Color(0x00000003);
    const Color surfaceTintColor = Color(0x00000004);
    const RoundedRectangleBorder indicatorShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)));

    const Color indicatorColor = Color(0x00000005);
    final ThemeData theme = ThemeData(
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: Color(0x00000000),
        elevation: 3,
        shadowColor: Color(0x00000000),
        surfaceTintColor: Color(0x00000000),
        indicatorShape: RoundedRectangleBorder(),
        indicatorColor: Color(0x00000000),
      ),
    );
    await tester.pumpWidget(
      _buildWidget(
        scaffoldKey,
        NavigationDrawer(
          backgroundColor: backgroundColor,
          elevation: elevation,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          indicatorShape: indicatorShape,
          indicatorColor: indicatorColor,
          children: <Widget>[
            Text('Headline', style: theme.textTheme.bodyLarge),
            const NavigationDrawerDestination(
              icon: Icon(Icons.ac_unit),
              label: Text('AC'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.access_alarm),
              label: Text('Alarm'),
            ),
          ],
          onDestinationSelected: (int i) {},
        ),
        theme: theme,
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pump(const Duration(seconds: 1));

    // Test drawer Material.
    expect(_getMaterial(tester).color, backgroundColor);
    expect(_getMaterial(tester).surfaceTintColor, surfaceTintColor);
    expect(_getMaterial(tester).shadowColor, shadowColor);
    expect(_getMaterial(tester).elevation, 7);
    // Test indicator decoration.
    expect(_getIndicatorDecoration(tester)?.color, indicatorColor);
    expect(_getIndicatorDecoration(tester)?.shape, indicatorShape);
  });

  testWidgets(
      'NavigationDrawerTheme values take priority over ThemeData.navigationDrawer values when both properties are specified',
      (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    const Color backgroundColor = Color(0x00000001);
    const double elevation = 7.0;
    const Color shadowColor = Color(0x00000003);
    const Color surfaceTintColor = Color(0x00000004);
    const Color iconColor = Color(0x00000005);
    const TextStyle labelStyle = TextStyle(fontSize: 7.0);
    const RoundedRectangleBorder indicatorShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const Color indicatorColor = Color(0x00000005);

    final ThemeData theme = ThemeData(
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: Color(0x00000000),
        elevation: 3,
        shadowColor: Color(0x00000000),
        surfaceTintColor: Color(0x00000000),
        indicatorShape: RoundedRectangleBorder(),
        indicatorColor: Color(0x00000000),
        labelTextStyle:
            MaterialStatePropertyAll<TextStyle>(TextStyle(fontSize: 1.0)),
        iconTheme: MaterialStatePropertyAll<IconThemeData>(IconThemeData(
          color: Color(0x00000000),
        )),
      ),
    );
    await tester.pumpWidget(
      _buildWidget(
        scaffoldKey,
        NavigationDrawerTheme(
          data: const NavigationDrawerThemeData(
            backgroundColor: backgroundColor,
            elevation: elevation,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            indicatorShape: indicatorShape,
            indicatorColor: indicatorColor,
            labelTextStyle:
                MaterialStatePropertyAll<TextStyle>(TextStyle(fontSize: 7.0)),
            iconTheme: MaterialStatePropertyAll<IconThemeData>(
                IconThemeData(color: iconColor)),
          ),
          child: NavigationDrawer(
            children: <Widget>[
              Text('Headline', style: theme.textTheme.bodyLarge),
              const NavigationDrawerDestination(
                icon: Icon(Icons.ac_unit),
                label: Text('AC'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.access_alarm),
                label: Text('Alarm'),
              ),
            ],
            onDestinationSelected: (int i) {},
          ),
        ),
        theme: theme,
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pump(const Duration(seconds: 1));

    // Test drawer Material.
    expect(_getMaterial(tester).color, backgroundColor);
    expect(_getMaterial(tester).surfaceTintColor, surfaceTintColor);
    expect(_getMaterial(tester).shadowColor, shadowColor);
    expect(_getMaterial(tester).elevation, 7);
    // Test indicator decoration.
    expect(_getIndicatorDecoration(tester)?.color, indicatorColor);
    expect(_getIndicatorDecoration(tester)?.shape, indicatorShape);
    // Test icon.
    expect(_iconStyle(tester, Icons.ac_unit)?.color, iconColor);
    expect(_iconStyle(tester, Icons.access_alarm)?.color, iconColor);
    // Test label.
    expect(_labelStyle(tester, 'AC'), labelStyle);
    expect(_labelStyle(tester, 'Alarm'), labelStyle);
  });
}

Widget _buildWidget(GlobalKey<ScaffoldState> scaffoldKey, Widget child, { ThemeData? theme }) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      key: scaffoldKey,
      drawer: child,
      body: Container(),
    ),
  );
}

Material _getMaterial(WidgetTester tester) {
  return tester.firstWidget<Material>(find.descendant(
    of: find.byType(NavigationDrawer),
    matching: find.byType(Material),
  ));
}

ShapeDecoration? _getIndicatorDecoration(WidgetTester tester) {
  return tester
      .firstWidget<Container>(
        find.descendant(
          of: find.byType(FadeTransition),
          matching: find.byType(Container),
        ),
      )
      .decoration as ShapeDecoration?;
}

TextStyle? _iconStyle(WidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style;
}

TextStyle? _labelStyle(WidgetTester tester, String label) {
  final RichText labelRichText = tester.widget<RichText>(
    find.descendant(of: find.text(label), matching: find.byType(RichText)),
  );
  return labelRichText.text.style;
}
