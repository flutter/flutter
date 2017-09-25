// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/mocks_for_image_cache.dart';

/// Integration tests testing both [CupertinoPageScaffold] and [CupertinoTabScaffold].
void main() {
  testWidgets('Contents are behind translucent bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new CupertinoPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              return const CupertinoPageScaffold(
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
          return new CupertinoPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              return new CupertinoTabScaffold(
                tabBar: new CupertinoTabBar(
                  backgroundColor: CupertinoColors.white,
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
                ),
                tabBuilder: (BuildContext context, int index) {
                  return index == 0
                      ? new CupertinoPageScaffold(
                        navigationBar: const CupertinoNavigationBar(
                          backgroundColor: CupertinoColors.white,
                          middle: const Text('Title'),
                        ),
                        child: page1Center,
                      )
                      : new Stack();
                }
              );
            },
          );
        },
      ),
    );

    expect(tester.getSize(find.byWidget(page1Center)).height, 600.0 - 44.0 - 50.0);
  });

  testWidgets('iOS independent tab navigation', (WidgetTester tester) async {
    // A full on iOS information architecture app with 2 tabs, and 2 pages
    // in each with independent navigation states.
    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new CupertinoPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              return new CupertinoTabScaffold(
                tabBar: new CupertinoTabBar(
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
                ),
                tabBuilder: (BuildContext context, int index) {
                  // For 1-indexed readability.
                  ++index;
                  return new CupertinoTabView(
                    builder: (BuildContext context) {
                      return new CupertinoPageScaffold(
                        navigationBar: new CupertinoNavigationBar(
                          middle: new Text('Page 1 of tab $index'),
                        ),
                        child: new Center(
                          child: new CupertinoButton(
                            child: const Text('Next'),
                            onPressed: () {
                              Navigator.of(context).push(
                                new CupertinoPageRoute<Null>(
                                  builder: (BuildContext context) {
                                    return new CupertinoPageScaffold(
                                      navigationBar: new CupertinoNavigationBar(
                                        middle: new Text('Page 2 of tab $index'),
                                      ),
                                      child: new Center(
                                        child: new CupertinoButton(
                                          child: const Text('Back'),
                                          onPressed: (){
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );

    expect(find.text('Page 1 of tab 1'), findsOneWidget);
    expect(find.text('Page 1 of tab 2'), findsNothing); // Lazy building so not built yet.

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    expect(find.text('Page 1 of tab 1'), findsNothing); // It's offstage now.
    expect(find.text('Page 1 of tab 1', skipOffstage: false), findsOneWidget);
    expect(find.text('Page 1 of tab 2'), findsOneWidget);

    // Navigate in tab 2.
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Page 2 of tab 2'), isOnstage);
    expect(find.text('Page 1 of tab 1', skipOffstage: false), isOffstage);

    await tester.tap(find.text('Tab 1'));
    await tester.pump();

    // Independent navigation stacks.
    expect(find.text('Page 1 of tab 1'), isOnstage);
    expect(find.text('Page 2 of tab 2', skipOffstage: false), isOffstage);

    // Navigate in tab 1.
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Page 2 of tab 1'), isOnstage);
    expect(find.text('Page 2 of tab 2', skipOffstage: false), isOffstage);

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    expect(find.text('Page 2 of tab 2'), isOnstage);
    expect(find.text('Page 2 of tab 1', skipOffstage: false), isOffstage);

    // Pop in tab 2
    await tester.tap(find.text('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Page 1 of tab 2'), isOnstage);
    expect(find.text('Page 2 of tab 1', skipOffstage: false), isOffstage);
  });
}
