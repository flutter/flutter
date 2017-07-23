// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/rendering_tester.dart';
import '../services/mocks_for_image_cache.dart';

List<int> selectedTabs;

void main() {
  setUp(() {
    selectedTabs = <int>[];
  });

  testWidgets('Contents are behind translucent bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          // TODO(xster): change to a CupertinoPageRoute.
          return new PageRouteBuilder<Null>(
            settings: settings,
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              return const CupertinoScaffold(
                // Default nav bar is translucent.
                navigationBar: const CupertinoNavigationBar(
                  middle: const Text('Title'),
                ),
                child: const Center(),
              );
            },
          );
        },
      ),
    );

    expect(tester.getTopLeft(find.byType(Center)), const Offset(0.0, 0.0));
  });

  testWidgets('Contents are between opaque bars', (WidgetTester tester) async {
    final Center page1Center = const Center();

    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          // TODO(xster): change to a CupertinoPageRoute.
          return new PageRouteBuilder<Null>(
            settings: settings,
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              return new CupertinoScaffold.tabbed(
                navigationBar: const CupertinoNavigationBar(
                  backgroundColor: CupertinoColors.white,
                  middle: const Text('Title'),
                ),
                tabBar: _buildTabBar(),
                rootTabPageBuilder: (BuildContext context, int index) {
                   return index == 0 ? page1Center : new Stack();
                }
              );
            },
          );
        },
      ),
    );

    expect(tester.getSize(find.byWidget(page1Center)).height, 600.0 - 44.0 - 50.0);
  });

  testWidgets('Tab switching', (WidgetTester tester) async {
    final List<int> tabsPainted = <int>[];

    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          // TODO(xster): change to a CupertinoPageRoute.
          return new PageRouteBuilder<Null>(
            settings: settings,
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              return new CupertinoScaffold.tabbed(
                navigationBar: const CupertinoNavigationBar(
                  backgroundColor: CupertinoColors.white,
                  middle: const Text('Title'),
                ),
                tabBar: _buildTabBar(),
                rootTabPageBuilder: (BuildContext context, int index) {
                  return new CustomPaint(
                    child: new Text('Page ${index + 1}'),
                    painter: new TestCallbackPainter(
                      onPaint: () { tabsPainted.add(index); }
                    )
                  );
                }
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
  });

  testWidgets('Tabs are lazy built and moved offstage when inactive', (WidgetTester tester) async {
    final List<int> tabsBuilt = <int>[];

    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          // TODO(xster): change to a CupertinoPageRoute.
          return new PageRouteBuilder<Null>(
            settings: settings,
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              return new CupertinoScaffold.tabbed(
                  navigationBar: const CupertinoNavigationBar(
                    backgroundColor: CupertinoColors.white,
                    middle: const Text('Title'),
                  ),
                  tabBar: _buildTabBar(),
                  rootTabPageBuilder: (BuildContext context, int index) {
                    tabsBuilt.add(index);
                    return new Text('Page ${index + 1}');
                  }
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
}

CupertinoTabBar _buildTabBar() {
  return new CupertinoTabBar(
    items: <BottomNavigationBarItem>[
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
