// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Navigation drawer updates destinations when tapped',
      (WidgetTester tester) async {
    int mutatedIndex = -1;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final ThemeData theme= ThemeData.from(colorScheme: const ColorScheme.light());
    widgetSetup(tester, 3000, windowHeight: 3000);
    final Widget widget = _buildWidget(
      scaffoldKey,
      NavigationDrawer(
        children: <Widget>[
          Text('Headline', style: theme.textTheme.bodyLarge),
          NavigationDrawerDestination(
            icon: Icon(Icons.ac_unit, color: theme.iconTheme.color),
            label: Text('AC', style: theme.textTheme.bodySmall),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.access_alarm, color: theme.iconTheme.color),
            label: Text('Alarm',style: theme.textTheme.bodySmall),
          ),
        ],
        onDestinationSelected: (int i) {
          mutatedIndex = i;
        },
      ),
    );

    await tester.pumpWidget(widget);
    scaffoldKey.currentState!.openDrawer();
    await tester.pump();

    expect(find.text('Headline'), findsOneWidget);
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Alarm'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1)); // animation done

    await tester.tap(find.text('Alarm'));
    expect(mutatedIndex, 1);

    await tester.tap(find.text('AC'));
    expect(mutatedIndex, 0);
  });

  testWidgets('NavigationDrawer can update background color',
      (WidgetTester tester) async {
    const Color color = Colors.yellow;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final ThemeData theme= ThemeData.from(colorScheme: const ColorScheme.light());

    await tester.pumpWidget(
      _buildWidget(
        scaffoldKey,
        NavigationDrawer(
          backgroundColor: color,
          children: <Widget>[
            Text('Headline', style: theme.textTheme.bodyLarge),
            NavigationDrawerDestination(
              icon: Icon(Icons.ac_unit, color: theme.iconTheme.color),
              label: Text('AC', style: theme.textTheme.bodySmall),
            ),
            NavigationDrawerDestination(
              icon: Icon(Icons.access_alarm, color: theme.iconTheme.color),
              label: Text('Alarm',style: theme.textTheme.bodySmall),
            ),
          ],
          onDestinationSelected: (int i) {},
        ),
      ),
    );

    scaffoldKey.currentState!.openDrawer();
    await tester.pump(const Duration(seconds: 1)); // animation done

    expect(_getMaterial(tester).color, equals(color));
  });

  testWidgets('NavigationDrawer can update elevation',
      (WidgetTester tester) async {
    const double elevation = 42.0;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final ThemeData theme= ThemeData.from(colorScheme: const ColorScheme.light());
    final NavigationDrawer drawer = NavigationDrawer(
      elevation: elevation,
      children: <Widget>[
        Text('Headline', style: theme.textTheme.bodyLarge),
        NavigationDrawerDestination(
          icon: Icon(Icons.ac_unit, color: theme.iconTheme.color),
          label: Text('AC', style: theme.textTheme.bodySmall),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.access_alarm, color: theme.iconTheme.color),
          label: Text('Alarm',style: theme.textTheme.bodySmall),
        ),
      ],
    );

    await tester.pumpWidget(
      _buildWidget(
        scaffoldKey,
        drawer,
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pump(const Duration(seconds: 1));

    expect(_getMaterial(tester).elevation, equals(elevation));
  });

  testWidgets(
      'NavigationDrawer uses proper defaults when no parameters are given',
      (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final ThemeData theme= ThemeData.from(colorScheme: const ColorScheme.light());
    // M3 settings from the token database.
    await tester.pumpWidget(
      _buildWidget(
        scaffoldKey,
        Theme(
          data: ThemeData.light().copyWith(useMaterial3: true),
          child: NavigationDrawer(
            children: <Widget>[
              Text('Headline', style: theme.textTheme.bodyLarge),
              NavigationDrawerDestination(
                icon: Icon(Icons.ac_unit, color: theme.iconTheme.color),
                label: Text('AC', style: theme.textTheme.bodySmall),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.access_alarm, color: theme.iconTheme.color),
                label: Text('Alarm',style: theme.textTheme.bodySmall),
              ),
            ],
            onDestinationSelected: (int i) {},
          ),
        ),
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pump(const Duration(seconds: 1));

    expect(_getMaterial(tester).color, ThemeData().colorScheme.surface);
    expect(_getMaterial(tester).surfaceTintColor,
        ThemeData().colorScheme.surfaceTint);
    expect(_getMaterial(tester).elevation, 1);
    expect(_indicator(tester)?.color, const Color(0xff2196f3));
    expect(_indicator(tester)?.shape, const StadiumBorder());
  });

  testWidgets('Navigation drawer semantics', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final ThemeData theme= ThemeData.from(colorScheme: const ColorScheme.light());
    Widget widget({int selectedIndex = 0}) {
      return _buildWidget(
        scaffoldKey,
        NavigationDrawer(
          selectedIndex: selectedIndex,
          children: <Widget>[
            Text('Headline', style: theme.textTheme.bodyLarge),
            NavigationDrawerDestination(
              icon: Icon(Icons.ac_unit, color: theme.iconTheme.color),
              label: Text('AC', style: theme.textTheme.bodySmall),
            ),
            NavigationDrawerDestination(
              icon: Icon(Icons.access_alarm, color: theme.iconTheme.color),
              label: Text('Alarm',style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(widget());
    scaffoldKey.currentState!.openDrawer();
    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(widget(selectedIndex: 1));

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });
}

Widget _buildWidget(GlobalKey<ScaffoldState> scaffoldKey, Widget child) {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(
      key: scaffoldKey,
      drawer: child,
      body: Container(),
    ),
  );
}

Material _getMaterial(WidgetTester tester) {
  return tester.firstWidget<Material>(
    find.descendant(
        of: find.byType(NavigationDrawer), matching: find.byType(Material)),
  );
}

ShapeDecoration? _indicator(WidgetTester tester) {
  return tester
      .firstWidget<Container>(
        find.descendant(
          of: find.byType(FadeTransition),
          matching: find.byType(Container),
        ),
      )
      .decoration as ShapeDecoration?;
}

void widgetSetup(WidgetTester tester, double windowWidth,
    {double? windowHeight}) {
  final double height = windowHeight ?? 1000;
  tester.binding.window.devicePixelRatioTestValue = 2;
  final double dpi = tester.binding.window.devicePixelRatio;
  tester.binding.window.physicalSizeTestValue =
      Size(windowWidth * dpi, height * dpi);
}
