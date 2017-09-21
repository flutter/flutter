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
}
