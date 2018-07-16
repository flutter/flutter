// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/mocks_for_image_cache.dart';

Future<Null> pumpWidgetWithBoilerplate(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(
    new Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ),
  );
}

void main() {
  testWidgets('Need at least 2 tabs', (WidgetTester tester) async {
    try {
      await pumpWidgetWithBoilerplate(tester, new CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: const ImageIcon(const TestImageProvider(24, 24)),
            title: const Text('Tab 1'),
          ),
        ],
      ));
      fail('Should not be possible to create a tab bar with just one item');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('items.length'));
      // Exception expected.
    }
  });

  testWidgets('Active and inactive colors', (WidgetTester tester) async {
    await pumpWidgetWithBoilerplate(tester, new MediaQuery(
      data: const MediaQueryData(),
      child: new CupertinoTabBar(
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
        currentIndex: 1,
        activeColor: const Color(0xFF123456),
        inactiveColor: const Color(0xFF654321),
      ),
    ));

    final RichText actualInactive = tester.widget(find.descendant(
      of: find.text('Tab 1'),
      matching: find.byType(RichText),
    ));
    expect(actualInactive.text.style.color, const Color(0xFF654321));

    final RichText actualActive = tester.widget(find.descendant(
      of: find.text('Tab 2'),
      matching: find.byType(RichText),
    ));
    expect(actualActive.text.style.color, const Color(0xFF123456));
  });

  testWidgets('Adjusts height to account for bottom padding', (WidgetTester tester) async {
    final CupertinoTabBar tabBar = new CupertinoTabBar(
      items: const <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: const ImageIcon(const TestImageProvider(24, 24)),
          title: const Text('Aka'),
        ),
        const BottomNavigationBarItem(
          icon: const ImageIcon(const TestImageProvider(24, 24)),
          title: const Text('Shiro'),
        ),
      ],
    );

    // Verify height with no bottom padding.
    await pumpWidgetWithBoilerplate(tester, new MediaQuery(
      data: const MediaQueryData(),
      child: new CupertinoTabScaffold(
        tabBar: tabBar,
        tabBuilder: (BuildContext context, int index) {
          return const Placeholder();
        },
      ),
    ));
    expect(tester.getSize(find.byType(CupertinoTabBar)).height, 50.0);

    // Verify height with bottom padding.
    await pumpWidgetWithBoilerplate(tester, new MediaQuery(
      data: const MediaQueryData(padding: const EdgeInsets.only(bottom: 40.0)),
      child: new CupertinoTabScaffold(
        tabBar: tabBar,
        tabBuilder: (BuildContext context, int index) {
          return const Placeholder();
        },
      ),
    ));
    expect(tester.getSize(find.byType(CupertinoTabBar)).height, 90.0);
  });

  testWidgets('Opaque background does not add blur effects', (WidgetTester tester) async {
    await pumpWidgetWithBoilerplate(tester, new MediaQuery(
      data: const MediaQueryData(),
      child: new CupertinoTabBar(
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
      ),
    ));

    expect(find.byType(BackdropFilter), findsOneWidget);

    await pumpWidgetWithBoilerplate(tester, new MediaQuery(
      data: const MediaQueryData(),
      child: new CupertinoTabBar(
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
        backgroundColor: const Color(0xFFFFFFFF), // Opaque white.
      ),
    ));

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('Tap callback', (WidgetTester tester) async {
    int callbackTab;

      await pumpWidgetWithBoilerplate(tester, new MediaQuery(
        data: const MediaQueryData(),
        child: new CupertinoTabBar(
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
          currentIndex: 1,
          onTap: (int tab) { callbackTab = tab; },
        ),
    ));

    await tester.tap(find.text('Tab 1'));
    expect(callbackTab, 0);
  });
}
