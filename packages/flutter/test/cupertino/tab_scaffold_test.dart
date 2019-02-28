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
              ),
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
              ),
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
              ),
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

  testWidgets('Tab bar respects themes', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: _buildTabBar(),
          tabBuilder: (BuildContext context, int index) {
            return const Placeholder();
          },
        ),
      ),
    );

    BoxDecoration tabDecoration = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(CupertinoTabBar),
      matching: find.byType(DecoratedBox),
    )).decoration;

    expect(tabDecoration.color, const Color(0xCCF8F8F8));

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    // Pump again but with dark theme.
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.destructiveRed,
        ),
        home: CupertinoTabScaffold(
          tabBar: _buildTabBar(),
          tabBuilder: (BuildContext context, int index) {
            return const Placeholder();
          },
        ),
      ),
    );

    tabDecoration = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(CupertinoTabBar),
      matching: find.byType(DecoratedBox),
    )).decoration;

    expect(tabDecoration.color, const Color(0xB7212121));

    final RichText tab1 = tester.widget(find.descendant(
      of: find.text('Tab 1'),
      matching: find.byType(RichText),
    ));
    // Tab 2 should still be selected after changing theme.
    expect(tab1.text.style.color, CupertinoColors.inactiveGray);
    final RichText tab2 = tester.widget(find.descendant(
      of: find.text('Tab 2'),
      matching: find.byType(RichText),
    ));
    expect(tab2.text.style.color, CupertinoColors.destructiveRed);
  });

  testWidgets('Tab contents are padded when there are view insets', (WidgetTester tester) async {
    BuildContext innerContext;

    await tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 200),
          ),
          child: CupertinoTabScaffold(
            tabBar: _buildTabBar(),
            tabBuilder: (BuildContext context, int index) {
              innerContext = context;
              return const Placeholder();
            },
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder)), Rect.fromLTWH(0, 0, 800, 400));
    // Don't generate more media query padding from the translucent bottom
    // tab since the tab is behind the keyboard now.
    expect(MediaQuery.of(innerContext).padding.bottom, 0);
  });

  testWidgets('Tab contents are not inset when resizeToAvoidBottomInset overriden', (WidgetTester tester) async {
    BuildContext innerContext;

    await tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 200),
          ),
          child: CupertinoTabScaffold(
            resizeToAvoidBottomInset: false,
            tabBar: _buildTabBar(),
            tabBuilder: (BuildContext context, int index) {
              innerContext = context;
              return const Placeholder();
            },
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder)), Rect.fromLTWH(0, 0, 800, 600));
    // Media query padding shows up in the inner content because it wasn't masked
    // by the view inset.
    expect(MediaQuery.of(innerContext).padding.bottom, 50);
  });

  testWidgets('Tab and page scaffolds do not double stack view insets', (WidgetTester tester) async {
    BuildContext innerContext;

    await tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 200),
          ),
          child: CupertinoTabScaffold(
            tabBar: _buildTabBar(),
            tabBuilder: (BuildContext context, int index) {
              return CupertinoPageScaffold(
                child: Builder(
                  builder: (BuildContext context) {
                    innerContext = context;
                    return const Placeholder();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder)), Rect.fromLTWH(0, 0, 800, 400));
    expect(MediaQuery.of(innerContext).padding.bottom, 0);
  });

  testWidgets('Deleting tabs after selecting them works', (WidgetTester tester) async {
    final List<int> tabsBuilt = <int>[];

    BottomNavigationBarItem tabGenerator(int index) {
      return BottomNavigationBarItem(
        icon: const ImageIcon(TestImageProvider(24, 24)),
        title: Text('Tab ${index + 1}'),
      );
    }

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            items: List<BottomNavigationBarItem>.generate(4, tabGenerator),
            onTap: (int newTab) => selectedTabs.add(newTab),
          ),
          tabBuilder: (BuildContext context, int index) {
            tabsBuilt.add(index);
            return Text('Page ${index + 1}');
          },
        ),
      ),
    );

    expect(tabsBuilt, <int>[0]);
    // selectedTabs list is appended to on onTap callbacks. We didn't tap
    // any tabs yet.
    expect(selectedTabs, <int>[]);
    tabsBuilt.clear();

    await tester.tap(find.text('Tab 4'));
    await tester.pump();

    // Tabs 1 and 4 are built but only one is onstage.
    expect(tabsBuilt, <int>[0, 3]);
    expect(selectedTabs, <int>[3]);
    expect(find.text('Page 1', skipOffstage: false), isOffstage);
    expect(find.text('Page 4'), findsOneWidget);
    tabsBuilt.clear();

    // Delete 2 tabs.
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            items: List<BottomNavigationBarItem>.generate(2, tabGenerator),
            onTap: (int newTab) => selectedTabs.add(newTab),
          ),
          tabBuilder: (BuildContext context, int index) {
            tabsBuilt.add(index);
            // Change the builder too.
            return Text('Different page ${index + 1}');
          },
        ),
      ),
    );

    expect(tabsBuilt, <int>[0, 1]);
    // We didn't tap on any additional tabs to invoke the onTap callback. We
    // just deleted a tab.
    expect(selectedTabs, <int>[3]);
    // Tab 1 was previously built so it's rebuilt again, albeit offstage.
    expect(find.text('Different page 1', skipOffstage: false), isOffstage);
    // Since all the tabs after tab 2 are deleted, tab 2 is now the last tab and
    // the actively shown tab.
    expect(find.text('Different page 2'), findsOneWidget);
    // No more tab 4 since it's deleted.
    expect(find.text('Different page 4', skipOffstage: false), findsNothing);
    // We also changed the builder so no tabs should be built with the old
    // builder.
    expect(find.text('Page 1', skipOffstage: false), findsNothing);
    expect(find.text('Page 2', skipOffstage: false), findsNothing);
    expect(find.text('Page 4', skipOffstage: false), findsNothing);
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
    currentIndex: selectedTab,
    onTap: (int newTab) => selectedTabs.add(newTab),
  );
}
