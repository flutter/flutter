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
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: _buildTabBar(),
          tabBuilder: (BuildContext context, int index) {
            return CustomPaint(
              child: Text('Page ${index + 1}'),
              painter: TestCallbackPainter(
                onPaint: () { tabsPainted.add(index); }
              )
            );
          },
        ),
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
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: _buildTabBar(),
          tabBuilder: (BuildContext context, int index) {
            tabsBuilt.add(index);
            return Text('Page ${index + 1}');
          },
        ),
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
    final List<FocusNode> focusNodes = <FocusNode>[FocusNode(), FocusNode()];

    await tester.pumpWidget(
      CupertinoApp(
        home: Material(
          child: CupertinoTabScaffold(
            tabBar: _buildTabBar(),
            tabBuilder: (BuildContext context, int index) {
              return TextField(
                focusNode: focusNodes[index],
                autofocus: true,
              );
            },
          ),
        ),
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
      FocusNode(), FocusNode(), FocusNode(), FocusNode(),
    ];

    await tester.pumpWidget(
      CupertinoApp(
        home: Material(
          child: CupertinoTabScaffold(
            tabBar: _buildTabBar(),
            tabBuilder: (BuildContext context, int index) {
              return Column(
                children: <Widget>[
                  TextField(
                    focusNode: focusNodes[index * 2],
                    decoration: const InputDecoration(
                      hintText: 'TextField 1',
                    ),
                  ),
                  TextField(
                    focusNode: focusNodes[index * 2 + 1],
                    decoration: const InputDecoration(
                      hintText: 'TextField 2',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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

  testWidgets('Programmatic tab switching', (WidgetTester tester) async {
    final List<int> tabsPainted = <int>[];

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: _buildTabBar(),
          tabBuilder: (BuildContext context, int index) {
            return CustomPaint(
              child: Text('Page ${index + 1}'),
              painter: TestCallbackPainter(
                onPaint: () { tabsPainted.add(index); }
              )
            );
          },
        ),
      ),
    );

    expect(tabsPainted, <int>[0]);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: _buildTabBar(selectedTab: 1), // Programmatically change the tab now.
          tabBuilder: (BuildContext context, int index) {
            return CustomPaint(
              child: Text('Page ${index + 1}'),
              painter: TestCallbackPainter(
                onPaint: () { tabsPainted.add(index); }
              )
            );
          },
        ),
      ),
    );

    expect(tabsPainted, <int>[0, 1]);
    // onTap is not called when changing tabs programmatically.
    expect(selectedTabs, isEmpty);

    // Can still tap out of the programmatically selected tab.
    await tester.tap(find.text('Tab 1'));
    await tester.pump();

    expect(tabsPainted, <int>[0, 1, 0]);
    expect(selectedTabs, <int>[0]);
  });
}

CupertinoTabBar _buildTabBar({ int selectedTab = 0 }) {
  return CupertinoTabBar(
    items: const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: ImageIcon(TestImageProvider(24, 24)),
        title: Text('Tab 1'),
      ),
      BottomNavigationBarItem(
        icon: ImageIcon(TestImageProvider(24, 24)),
        title: Text('Tab 2'),
      ),
    ],
    backgroundColor: CupertinoColors.white,
    currentIndex: selectedTab,
    onTap: (int newTab) => selectedTabs.add(newTab),
  );
}
