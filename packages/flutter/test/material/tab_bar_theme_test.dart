// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

const String _tab1Text = 'tab 1';
const String _tab2Text = 'tab 2';
const String _tab3Text = 'tab 3';

final Key _painterKey = UniqueKey();

const List<Tab> _tabs = <Tab>[
  Tab(text: _tab1Text, icon: Icon(Icons.looks_one)),
  Tab(text: _tab2Text, icon: Icon(Icons.looks_two)),
  Tab(text: _tab3Text, icon: Icon(Icons.looks_3)),
];

final List<SizedBox> _sizedTabs = <SizedBox>[
  SizedBox(key: UniqueKey(), width: 100.0, height: 50.0),
  SizedBox(key: UniqueKey(), width: 100.0, height: 50.0),
];

Widget buildTabBar({
  TabBarTheme? tabBarTheme,
  bool secondaryTabBar = false,
  List<Widget> tabs = _tabs,
  bool isScrollable = false,
  bool useMaterial3 = false,
}) {
  if (secondaryTabBar) {
    return MaterialApp(
      theme: ThemeData(tabBarTheme: tabBarTheme, useMaterial3: useMaterial3),
      home: Scaffold(
        body: RepaintBoundary(
          key: _painterKey,
          child: TabBar.secondary(
            tabs: tabs,
            isScrollable: isScrollable,
            controller: TabController(length: tabs.length, vsync: const TestVSync()),
          ),
        ),
      ),
    );
  }
  return MaterialApp(
    theme: ThemeData(tabBarTheme: tabBarTheme, useMaterial3: useMaterial3),
    home: Scaffold(
      body: RepaintBoundary(
        key: _painterKey,
        child: TabBar(
          tabs: tabs,
          isScrollable: isScrollable,
          controller: TabController(length: tabs.length, vsync: const TestVSync()),
        ),
      ),
    ),
  );
}


RenderParagraph _getIcon(WidgetTester tester, IconData icon) {
  return tester.renderObject<RenderParagraph>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
}

RenderParagraph _getText(WidgetTester tester, String text) {
  return  tester.renderObject<RenderParagraph>(find.text(text));
}

void main() {
  test('TabBarTheme copyWith, ==, hashCode, defaults', () {
    expect(const TabBarTheme(), const TabBarTheme().copyWith());
    expect(const TabBarTheme().hashCode, const TabBarTheme().copyWith().hashCode);

    expect(const TabBarTheme().indicator, null);
    expect(const TabBarTheme().indicatorColor, null);
    expect(const TabBarTheme().indicatorSize, null);
    expect(const TabBarTheme().dividerColor, null);
    expect(const TabBarTheme().labelColor, null);
    expect(const TabBarTheme().labelPadding, null);
    expect(const TabBarTheme().labelStyle, null);
    expect(const TabBarTheme().unselectedLabelColor, null);
    expect(const TabBarTheme().unselectedLabelStyle, null);
    expect(const TabBarTheme().overlayColor, null);
    expect(const TabBarTheme().splashFactory, null);
    expect(const TabBarTheme().mouseCursor, null);
  });

  test('TabBarTheme lerp special cases', () {
    const TabBarTheme theme = TabBarTheme();
    expect(identical(TabBarTheme.lerp(theme, theme, 0.5), theme), true);
  });

  testWidgets('Tab bar defaults (primary)', (WidgetTester tester) async {
    // Test default label color and label styles.
    await tester.pumpWidget(buildTabBar(useMaterial3: true));

    final ThemeData theme = ThemeData(useMaterial3: true);
    final RenderParagraph selectedLabel = _getText(tester, _tab1Text);
    expect(selectedLabel.text.style!.fontFamily, equals(theme.textTheme.titleSmall!.fontFamily));
    expect(selectedLabel.text.style!.fontSize, equals(14.0));
    expect(selectedLabel.text.style!.color, equals(theme.colorScheme.primary));
    final RenderParagraph unselectedLabel = _getText(tester, _tab2Text);
    expect(unselectedLabel.text.style!.fontFamily, equals(theme.textTheme.titleSmall!.fontFamily));
    expect(unselectedLabel.text.style!.fontSize, equals(14.0));
    expect(unselectedLabel.text.style!.color, equals(theme.colorScheme.onSurfaceVariant));

    // Test default labelPadding.
    await tester.pumpWidget(buildTabBar(tabs: _sizedTabs, isScrollable: true));

    const double indicatorWeight = 2.0;
    final Rect tabBar = tester.getRect(find.byType(TabBar));
    final Rect tabOneRect = tester.getRect(find.byKey(_sizedTabs[0].key!));
    final Rect tabTwoRect = tester.getRect(find.byKey(_sizedTabs[1].key!));

    // Verify tabOne coordinates.
    expect(tabOneRect.left, equals(kTabLabelPadding.left));
    expect(tabOneRect.top, equals(kTabLabelPadding.top));
    expect(tabOneRect.bottom, equals(tabBar.bottom - kTabLabelPadding.bottom - indicatorWeight));

    // Verify tabTwo coordinates.
    expect(tabTwoRect.right, equals(tabBar.width - kTabLabelPadding.right));
    expect(tabTwoRect.top, equals(kTabLabelPadding.top));
    expect(tabTwoRect.bottom, equals(tabBar.bottom - kTabLabelPadding.bottom - indicatorWeight));

    // Verify tabOne and tabTwo is separated by right padding of tabOne and left padding of tabTwo.
    expect(tabOneRect.right, equals(tabTwoRect.left - kTabLabelPadding.left - kTabLabelPadding.right));

    // Verify divider color and indicator color.
    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    expect(
      tabBarBox,
      paints
        ..line(color: theme.colorScheme.surfaceVariant)
        // Indicator is a rrect in the primary tab bar.
        ..rrect(color: theme.colorScheme.primary),
    );
  });

  testWidgets('Tab bar defaults (secondary)', (WidgetTester tester) async {
    // Test default label color and label styles.
    await tester.pumpWidget(buildTabBar(secondaryTabBar: true, useMaterial3: true));

    final ThemeData theme = ThemeData(useMaterial3: true);
    final RenderParagraph selectedLabel = _getText(tester, _tab1Text);
    expect(selectedLabel.text.style!.fontFamily, equals(theme.textTheme.titleSmall!.fontFamily));
    expect(selectedLabel.text.style!.fontSize, equals(14.0));
    expect(selectedLabel.text.style!.color, equals(theme.colorScheme.onSurface));
    final RenderParagraph unselectedLabel = _getText(tester, _tab2Text);
    expect(unselectedLabel.text.style!.fontFamily, equals(theme.textTheme.titleSmall!.fontFamily));
    expect(unselectedLabel.text.style!.fontSize, equals(14.0));
    expect(unselectedLabel.text.style!.color, equals(theme.colorScheme.onSurfaceVariant));

    // Test default labelPadding.
    await tester.pumpWidget(buildTabBar(
      secondaryTabBar: true,
      tabs: _sizedTabs,
      isScrollable: true,
      useMaterial3: true,
    ));

    const double indicatorWeight = 2.0;
    final Rect tabBar = tester.getRect(find.byType(TabBar));
    final Rect tabOneRect = tester.getRect(find.byKey(_sizedTabs[0].key!));
    final Rect tabTwoRect = tester.getRect(find.byKey(_sizedTabs[1].key!));

    // Verify tabOne coordinates.
    expect(tabOneRect.left, equals(kTabLabelPadding.left));
    expect(tabOneRect.top, equals(kTabLabelPadding.top));
    expect(tabOneRect.bottom, equals(tabBar.bottom - kTabLabelPadding.bottom - indicatorWeight));

    // Verify tabTwo coordinates.
    expect(tabTwoRect.right, equals(tabBar.width - kTabLabelPadding.right));
    expect(tabTwoRect.top, equals(kTabLabelPadding.top));
    expect(tabTwoRect.bottom, equals(tabBar.bottom - kTabLabelPadding.bottom - indicatorWeight));

    // Verify tabOne and tabTwo is separated by right padding of tabOne and left padding of tabTwo.
    expect(tabOneRect.right, equals(tabTwoRect.left - kTabLabelPadding.left - kTabLabelPadding.right));

    // Verify divider color and indicator color.
    final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
    expect(
      tabBarBox,
      paints
        ..line(color: theme.colorScheme.surfaceVariant)
        // Indicator is a line in the secondary tab bar.
        ..line(color: theme.colorScheme.primary),
    );
  });

  testWidgets('Tab bar theme overrides label color (selected)', (WidgetTester tester) async {
    const Color labelColor = Colors.black;
    const TabBarTheme tabBarTheme = TabBarTheme(labelColor: labelColor);

    await tester.pumpWidget(buildTabBar(tabBarTheme: tabBarTheme));

    final RenderParagraph tabLabel = _getText(tester, _tab1Text);
    expect(tabLabel.text.style!.color, equals(labelColor));
    final RenderParagraph tabIcon = _getIcon(tester, Icons.looks_one);
    expect(tabIcon.text.style!.color, equals(labelColor));
  });

  testWidgets('Tab bar theme overrides label padding', (WidgetTester tester) async {
    const double topPadding = 10.0;
    const double bottomPadding = 7.0;
    const double rightPadding = 13.0;
    const double leftPadding = 16.0;
    const double indicatorWeight = 2.0; // default value

    const EdgeInsetsGeometry labelPadding = EdgeInsets.fromLTRB(
      leftPadding, topPadding, rightPadding, bottomPadding,
    );

    const TabBarTheme tabBarTheme = TabBarTheme(labelPadding: labelPadding);

    await tester.pumpWidget(buildTabBar(
      tabBarTheme: tabBarTheme,
      tabs: _sizedTabs,
      isScrollable: true,
    ));

    final Rect tabBar = tester.getRect(find.byType(TabBar));
    final Rect tabOneRect = tester.getRect(find.byKey(_sizedTabs[0].key!));
    final Rect tabTwoRect = tester.getRect(find.byKey(_sizedTabs[1].key!));

    // verify coordinates of tabOne
    expect(tabOneRect.left, equals(leftPadding));
    expect(tabOneRect.top, equals(topPadding));
    expect(tabOneRect.bottom, equals(tabBar.bottom - bottomPadding - indicatorWeight));

    // verify coordinates of tabTwo
    expect(tabTwoRect.right, equals(tabBar.width - rightPadding));
    expect(tabTwoRect.top, equals(topPadding));
    expect(tabTwoRect.bottom, equals(tabBar.bottom - bottomPadding - indicatorWeight));

    // verify tabOne and tabTwo are separated by right padding of tabOne and left padding of tabTwo
    expect(tabOneRect.right, equals(tabTwoRect.left - leftPadding - rightPadding));
  });

  testWidgets('Tab bar theme overrides label styles', (WidgetTester tester) async {
    const TextStyle labelStyle = TextStyle(fontFamily: 'foobar');
    const TextStyle unselectedLabelStyle = TextStyle(fontFamily: 'baz');
    const TabBarTheme tabBarTheme = TabBarTheme(
      labelStyle: labelStyle,
      unselectedLabelStyle: unselectedLabelStyle,
    );

    await tester.pumpWidget(buildTabBar(tabBarTheme: tabBarTheme));

    final RenderParagraph selectedLabel = _getText(tester, _tab1Text);
    expect(selectedLabel.text.style!.fontFamily, equals(labelStyle.fontFamily));
    final RenderParagraph unselectedLabel = _getText(tester, _tab2Text);
    expect(unselectedLabel.text.style!.fontFamily, equals(unselectedLabelStyle.fontFamily));
  });

  testWidgets('Tab bar theme with just label style specified', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/28784
    const TextStyle labelStyle = TextStyle(fontFamily: 'foobar');
    const TabBarTheme tabBarTheme = TabBarTheme(
      labelStyle: labelStyle,
    );

    await tester.pumpWidget(buildTabBar(tabBarTheme: tabBarTheme));

    final RenderParagraph selectedLabel = _getText(tester, _tab1Text);
    expect(selectedLabel.text.style!.fontFamily, equals(labelStyle.fontFamily));
    final RenderParagraph unselectedLabel = _getText(tester, _tab2Text);
    expect(unselectedLabel.text.style!.fontFamily, equals('Roboto'));
    expect(unselectedLabel.text.style!.fontSize, equals(14.0));
    expect(unselectedLabel.text.style!.color, equals(Colors.white.withAlpha(0xB2)));
  });

  testWidgets('Tab bar label styles override theme label styles', (WidgetTester tester) async {
    const TextStyle labelStyle = TextStyle(fontFamily: '1');
    const TextStyle unselectedLabelStyle = TextStyle(fontFamily: '2');
    const TextStyle themeLabelStyle = TextStyle(fontFamily: '3');
    const TextStyle themeUnselectedLabelStyle = TextStyle(fontFamily: '4');
    const TabBarTheme tabBarTheme = TabBarTheme(
      labelStyle: themeLabelStyle,
      unselectedLabelStyle: themeUnselectedLabelStyle,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(tabBarTheme: tabBarTheme),
        home: Scaffold(
          body: TabBar(
            tabs: _tabs,
            controller: TabController(length: _tabs.length, vsync: const TestVSync()),
            labelStyle: labelStyle,
            unselectedLabelStyle: unselectedLabelStyle,
          ),
        ),
      ),
    );

    final RenderParagraph selectedLabel = _getText(tester, _tab1Text);
    expect(selectedLabel.text.style!.fontFamily, equals(labelStyle.fontFamily));
    final RenderParagraph unselectedLabel = _getText(tester, _tab2Text);
    expect(unselectedLabel.text.style!.fontFamily, equals(unselectedLabelStyle.fontFamily));
  });

  testWidgets('Tab bar label padding overrides theme label padding', (WidgetTester tester) async {
    const double verticalPadding = 10.0;
    const double horizontalPadding = 10.0;
    const EdgeInsetsGeometry labelPadding = EdgeInsets.symmetric(
      vertical: verticalPadding,
      horizontal: horizontalPadding,
    );

    const double verticalThemePadding = 20.0;
    const double horizontalThemePadding = 20.0;
    const EdgeInsetsGeometry themeLabelPadding = EdgeInsets.symmetric(
      vertical: verticalThemePadding,
      horizontal: horizontalThemePadding,
    );

    const double indicatorWeight = 2.0; // default value

    const TabBarTheme tabBarTheme = TabBarTheme(labelPadding: themeLabelPadding);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(tabBarTheme: tabBarTheme),
        home: Scaffold(body:
          RepaintBoundary(
            key: _painterKey,
            child: TabBar(
              tabs: _sizedTabs,
              isScrollable: true,
              controller: TabController(length: _sizedTabs.length, vsync: const TestVSync()),
              labelPadding: labelPadding,
            ),
          ),
        ),
      ),
    );

    final Rect tabBar = tester.getRect(find.byType(TabBar));
    final Rect tabOneRect = tester.getRect(find.byKey(_sizedTabs[0].key!));
    final Rect tabTwoRect = tester.getRect(find.byKey(_sizedTabs[1].key!));

    // verify coordinates of tabOne
    expect(tabOneRect.left, equals(horizontalPadding));
    expect(tabOneRect.top, equals(verticalPadding));
    expect(tabOneRect.bottom, equals(tabBar.bottom - verticalPadding - indicatorWeight));

    // verify coordinates of tabTwo
    expect(tabTwoRect.right, equals(tabBar.width - horizontalPadding));
    expect(tabTwoRect.top, equals(verticalPadding));
    expect(tabTwoRect.bottom, equals(tabBar.bottom - verticalPadding - indicatorWeight));

    // verify tabOne and tabTwo are separated by 2x horizontalPadding
    expect(tabOneRect.right, equals(tabTwoRect.left - (2 * horizontalPadding)));
  });

  testWidgets('Tab bar theme overrides label color (unselected)', (WidgetTester tester) async {
    const Color unselectedLabelColor = Colors.black;
    const TabBarTheme tabBarTheme = TabBarTheme(unselectedLabelColor: unselectedLabelColor);

    await tester.pumpWidget(buildTabBar(tabBarTheme: tabBarTheme));

    final RenderParagraph textRenderObject = tester.renderObject<RenderParagraph>(find.text(_tab2Text));
    expect(textRenderObject.text.style!.color, equals(unselectedLabelColor));
    final RenderParagraph iconRenderObject = _getIcon(tester, Icons.looks_two);
    expect(iconRenderObject.text.style!.color, equals(unselectedLabelColor));
  });

  testWidgets('Tab bar default tab indicator size', (WidgetTester tester) async {
    await tester.pumpWidget(buildTabBar(useMaterial3: true, isScrollable: true));

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('tab_bar.default.tab_indicator_size.png'),
    );
  });

  testWidgets('Tab bar default tab indicator size', (WidgetTester tester) async {
    await tester.pumpWidget(buildTabBar(useMaterial3: true, isScrollable: true));

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('tab_bar.default.tab_indicator_size.png'),
    );
  });

  testWidgets('Tab bar theme overrides tab indicator size (tab)', (WidgetTester tester) async {
    const TabBarTheme tabBarTheme = TabBarTheme(indicatorSize: TabBarIndicatorSize.tab);

    await tester.pumpWidget(buildTabBar(tabBarTheme: tabBarTheme));

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('tab_bar_theme.tab_indicator_size_tab.png'),
    );
  });

  testWidgets('Tab bar theme overrides tab indicator size (label)', (WidgetTester tester) async {
    const TabBarTheme tabBarTheme = TabBarTheme(indicatorSize: TabBarIndicatorSize.label);

    await tester.pumpWidget(buildTabBar(tabBarTheme: tabBarTheme));

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('tab_bar_theme.tab_indicator_size_label.png'),
    );
  });

  testWidgets('Tab bar theme overrides tab mouse cursor', (WidgetTester tester) async {
    const TabBarTheme tabBarTheme = TabBarTheme(mouseCursor: MaterialStateMouseCursor.textable);

    await tester.pumpWidget(buildTabBar(tabBarTheme: tabBarTheme));

    final Offset tabBar = tester.getCenter(
      find.ancestor(of: find.text('tab 1'),matching: find.byType(TabBar)),
    );
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tabBar);
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
  });

  testWidgets('Tab bar theme - custom tab indicator', (WidgetTester tester) async {
    final TabBarTheme tabBarTheme = TabBarTheme(
      indicator: BoxDecoration(
        border: Border.all(),
      ),
    );

    await tester.pumpWidget(buildTabBar(tabBarTheme: tabBarTheme));

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('tab_bar_theme.custom_tab_indicator.png'),
    );
  });

  testWidgets('Tab bar theme - beveled rect indicator', (WidgetTester tester) async {
    const TabBarTheme tabBarTheme = TabBarTheme(
      indicator: ShapeDecoration(
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
        color: Colors.black,
      ),
    );

    await tester.pumpWidget(buildTabBar(tabBarTheme: tabBarTheme));

    await expectLater(
      find.byKey(_painterKey),
      matchesGoldenFile('tab_bar_theme.beveled_rect_indicator.png'),
    );
  });

  group('Material 2', () {
    // Tests that are only relevant for Material 2. Once ThemeData.useMaterial3
    // is turned on by default, these tests can be removed.

    testWidgets('Tab bar defaults', (WidgetTester tester) async {
      // tests for the default label color and label styles when tabBarTheme and tabBar do not provide any
      await tester.pumpWidget(buildTabBar());

      final RenderParagraph selectedLabel = _getText(tester, _tab1Text);
      expect(selectedLabel.text.style!.fontFamily, equals('Roboto'));
      expect(selectedLabel.text.style!.fontSize, equals(14.0));
      expect(selectedLabel.text.style!.color, equals(Colors.white));
      final RenderParagraph unselectedLabel = _getText(tester, _tab2Text);
      expect(unselectedLabel.text.style!.fontFamily, equals('Roboto'));
      expect(unselectedLabel.text.style!.fontSize, equals(14.0));
      expect(unselectedLabel.text.style!.color, equals(Colors.white.withAlpha(0xB2)));

      // tests for the default value of labelPadding when tabBarTheme and tabBar do not provide one
      await tester.pumpWidget(buildTabBar(tabs: _sizedTabs, isScrollable: true));

      const double indicatorWeight = 2.0;
      final Rect tabBar = tester.getRect(find.byType(TabBar));
      final Rect tabOneRect = tester.getRect(find.byKey(_sizedTabs[0].key!));
      final Rect tabTwoRect = tester.getRect(find.byKey(_sizedTabs[1].key!));

      // verify coordinates of tabOne
      expect(tabOneRect.left, equals(kTabLabelPadding.left));
      expect(tabOneRect.top, equals(kTabLabelPadding.top));
      expect(tabOneRect.bottom, equals(tabBar.bottom - kTabLabelPadding.bottom - indicatorWeight));

      // verify coordinates of tabTwo
      expect(tabTwoRect.right, equals(tabBar.width - kTabLabelPadding.right));
      expect(tabTwoRect.top, equals(kTabLabelPadding.top));
      expect(tabTwoRect.bottom, equals(tabBar.bottom - kTabLabelPadding.bottom - indicatorWeight));

      // verify tabOne and tabTwo is separated by right padding of tabOne and left padding of tabTwo
      expect(tabOneRect.right, equals(tabTwoRect.left - kTabLabelPadding.left - kTabLabelPadding.right));

      final RenderBox tabBarBox = tester.firstRenderObject<RenderBox>(find.byType(TabBar));
      expect(tabBarBox, paints..line(color: const Color(0xff2196f3)));
    });

    testWidgets('Tab bar default tab indicator size', (WidgetTester tester) async {
      await tester.pumpWidget(buildTabBar());

      await expectLater(
        find.byKey(_painterKey),
        matchesGoldenFile('tab_bar.m2.default.tab_indicator_size.png'),
      );
    });
  });
}
