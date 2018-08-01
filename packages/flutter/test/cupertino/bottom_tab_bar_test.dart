// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/mocks_for_image_cache.dart';
import '../widgets/semantics_tester.dart';

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
          BottomNavigationBarItem(
            icon: ImageIcon(TestImageProvider(24, 24)),
            title: Text('Tab 1'),
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
          BottomNavigationBarItem(
            icon: ImageIcon(TestImageProvider(24, 24)),
            title: Text('Tab 1'),
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(TestImageProvider(24, 24)),
            title: Text('Tab 2'),
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
        BottomNavigationBarItem(
          icon: ImageIcon(TestImageProvider(24, 24)),
          title: Text('Aka'),
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(TestImageProvider(24, 24)),
          title: Text('Shiro'),
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
      data: const MediaQueryData(padding: EdgeInsets.only(bottom: 40.0)),
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
          BottomNavigationBarItem(
            icon: ImageIcon(TestImageProvider(24, 24)),
            title: Text('Tab 1'),
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(TestImageProvider(24, 24)),
            title: Text('Tab 2'),
          ),
        ],
      ),
    ));

    expect(find.byType(BackdropFilter), findsOneWidget);

    await pumpWidgetWithBoilerplate(tester, new MediaQuery(
      data: const MediaQueryData(),
      child: new CupertinoTabBar(
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
            BottomNavigationBarItem(
              icon: ImageIcon(TestImageProvider(24, 24)),
              title: Text('Tab 1'),
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(TestImageProvider(24, 24)),
              title: Text('Tab 2'),
            ),
          ],
          currentIndex: 1,
          onTap: (int tab) { callbackTab = tab; },
        ),
    ));

    await tester.tap(find.text('Tab 1'));
    expect(callbackTab, 0);
  });

  testWidgets('tabs announce semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await pumpWidgetWithBoilerplate(tester, new MediaQuery(
      data: const MediaQueryData(),
      child: new CupertinoTabBar(
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
      ),
    ));

    expect(semantics, includesNodeWith(
      label: 'Tab 1',
      hint: 'tab, 1 of 2',
      flags: <SemanticsFlag>[SemanticsFlag.isSelected],
      textDirection: TextDirection.ltr,
    ));

    expect(semantics, includesNodeWith(
      label: 'Tab 2',
      hint: 'tab, 2 of 2',
      textDirection: TextDirection.ltr,
    ));

    semantics.dispose();
  });
}
