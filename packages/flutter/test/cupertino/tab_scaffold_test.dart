// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/mocks_for_image_cache.dart';
import '../rendering/rendering_tester.dart';

List<int> selectedTabs;

void main() {
  setUp(() {
    selectedTabs = <int>[];
  });

  testWidgets('Tab switching', (WidgetTester tester) async {
    final List<int> tabsPainted = <int>[];

    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new CupertinoPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              return new CupertinoTabScaffold(
                tabBar: _buildTabBar(),
                tabBuilder: (BuildContext context, int index) {
                  return new CustomPaint(
                    child: new Text('Page ${index + 1}'),
                    painter: new TestCallbackPainter(
                      onPaint: () { tabsPainted.add(index); }
                    )
                  );
                },
              );
            },
          );
        },
      ),
    );

    expect(tabsPainted, <int>[0]);
    RichText tab1 = tester.widget(find.descendant(
      of: find.text('Tab 1'),
      matching: find.byType(RichText),
    ));
    expect(tab1.text.style.color, CupertinoColors.activeBlue);
    RichText tab2 = tester.widget(find.descendant(
      of: find.text('Tab 2'),
      matching: find.byType(RichText),
    ));
    expect(tab2.text.style.color, CupertinoColors.inactiveGray);

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    expect(tabsPainted, <int>[0, 1]);
    tab1 = tester.widget(find.descendant(
      of: find.text('Tab 1'),
      matching: find.byType(RichText),
    ));
    expect(tab1.text.style.color, CupertinoColors.inactiveGray);
    tab2 = tester.widget(find.descendant(
      of: find.text('Tab 2'),
      matching: find.byType(RichText),
    ));
    expect(tab2.text.style.color, CupertinoColors.activeBlue);

    await tester.tap(find.text('Tab 1'));
    await tester.pump();

    expect(tabsPainted, <int>[0, 1, 0]);
    // CupertinoTabBar's onTap callbacks are passed on.
    expect(selectedTabs, <int>[1, 0]);
  });

  testWidgets('Tabs are lazy built and moved offstage when inactive', (WidgetTester tester) async {
    final List<int> tabsBuilt = <int>[];

    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new CupertinoPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              return new CupertinoTabScaffold(
                tabBar: _buildTabBar(),
                tabBuilder: (BuildContext context, int index) {
                  tabsBuilt.add(index);
                  return new Text('Page ${index + 1}');
                },
              );
            },
          );
        },
      ),
    );

    expect(tabsBuilt, <int>[0]);
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    // Both tabs are built but only one is onstage.
    expect(tabsBuilt, <int>[0, 0, 1]);
    expect(find.text('Page 1', skipOffstage: false), isOffstage);
    expect(find.text('Page 2'), findsOneWidget);

    await tester.tap(find.text('Tab 1'));
    await tester.pump();

    expect(tabsBuilt, <int>[0, 0, 1, 0, 1]);
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2', skipOffstage: false), isOffstage);
  });

  testWidgets('Last tab gets focus', (WidgetTester tester) async {
    // 2 nodes for 2 tabs
    final List<FocusNode> focusNodes = <FocusNode>[new FocusNode(), new FocusNode()];

    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new CupertinoPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              return new CupertinoTabScaffold(
                tabBar: _buildTabBar(),
                tabBuilder: (BuildContext context, int index) {
                  return new TextField(
                    focusNode: focusNodes[index],
                    autofocus: true,
                  );
                },
              );
            },
          );
        },
      ),
    );

    expect(focusNodes[0].hasFocus, isTrue);

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    expect(focusNodes[0].hasFocus, isFalse);
    expect(focusNodes[1].hasFocus, isTrue);

    await tester.tap(find.text('Tab 1'));
    await tester.pump();

    expect(focusNodes[0].hasFocus, isTrue);
    expect(focusNodes[1].hasFocus, isFalse);
  });

  testWidgets('Do not affect focus order in the route', (WidgetTester tester) async {
    final List<FocusNode> focusNodes = <FocusNode>[
      new FocusNode(), new FocusNode(), new FocusNode(), new FocusNode(),
    ];

    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new CupertinoPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              return new Material(
                child: new CupertinoTabScaffold(
                  tabBar: _buildTabBar(),
                  tabBuilder: (BuildContext context, int index) {
                    return new Column(
                      children: <Widget>[
                        new TextField(
                          focusNode: focusNodes[index * 2],
                          decoration: const InputDecoration(
                            hintText: 'TextField 1',
                          ),
                        ),
                        new TextField(
                          focusNode: focusNodes[index * 2 + 1],
                          decoration: const InputDecoration(
                            hintText: 'TextField 2',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );

    expect(
      focusNodes.any((FocusNode node) => node.hasFocus),
      isFalse,
    );

    await tester.tap(find.widgetWithText(TextField, 'TextField 2'));

    expect(
      focusNodes.indexOf(focusNodes.singleWhere((FocusNode node) => node.hasFocus)),
      1,
    );

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    await tester.tap(find.widgetWithText(TextField, 'TextField 1'));

    expect(
      focusNodes.indexOf(focusNodes.singleWhere((FocusNode node) => node.hasFocus)),
      2,
    );

    await tester.tap(find.text('Tab 1'));
    await tester.pump();

    // Upon going back to tab 1, the item it tab 1 that previously had the focus
    // (TextField 2) gets it back.
    expect(
      focusNodes.indexOf(focusNodes.singleWhere((FocusNode node) => node.hasFocus)),
      1,
    );
  });
}

CupertinoTabBar _buildTabBar() {
  return new CupertinoTabBar(
    items: const <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: const ImageIcon(const TestImageProvider(24, 24)),
        title: const Text('Tab 1'),
      ),
      const BottomNavigationBarItem(
        icon: const ImageIcon(const TestImageProvider(24, 24)),
        title: const Text('Tab 2'),
      ),
    ],
    backgroundColor: CupertinoColors.white,
    onTap: (int newTab) => selectedTabs.add(newTab),
  );
}