// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/mocks_for_image_cache.dart';
import '../widgets/semantics_tester.dart';

Future<void> pumpWidgetWithBoilerplate(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ),
  );
}

void main() {
  testWidgets('Need at least 2 tabs', (WidgetTester tester) async {
    try {
      await pumpWidgetWithBoilerplate(tester, CupertinoTabBar(
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
    await pumpWidgetWithBoilerplate(tester, MediaQuery(
      data: const MediaQueryData(),
      child: CupertinoTabBar(
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

  testWidgets('Use active icon', (WidgetTester tester) async {
    const TestImageProvider activeIcon = TestImageProvider(16, 16);
    const TestImageProvider inactiveIcon = TestImageProvider(24, 24);

    await pumpWidgetWithBoilerplate(tester, MediaQuery(
      data: const MediaQueryData(),
      child: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ImageIcon(TestImageProvider(24, 24)),
            title: Text('Tab 1'),
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(inactiveIcon),
            activeIcon: ImageIcon(activeIcon),
            title: Text('Tab 2'),
          ),
        ],
        currentIndex: 1,
        activeColor: const Color(0xFF123456),
        inactiveColor: const Color(0xFF654321),
      ),
    ));

    final Image image = tester.widget(find.descendant(
      of: find.widgetWithText(GestureDetector, 'Tab 2'),
      matching: find.byType(Image)
    ));

    expect(image.color, const Color(0xFF123456));
    expect(image.image, activeIcon);
  });

  testWidgets('Adjusts height to account for bottom padding', (WidgetTester tester) async {
    final CupertinoTabBar tabBar = CupertinoTabBar(
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
    await pumpWidgetWithBoilerplate(tester, MediaQuery(
      data: const MediaQueryData(),
      child: CupertinoTabScaffold(
        tabBar: tabBar,
        tabBuilder: (BuildContext context, int index) {
          return const Placeholder();
        },
      ),
    ));
    expect(tester.getSize(find.byType(CupertinoTabBar)).height, 50.0);

    // Verify height with bottom padding.
    await pumpWidgetWithBoilerplate(tester, MediaQuery(
      data: const MediaQueryData(padding: EdgeInsets.only(bottom: 40.0)),
      child: CupertinoTabScaffold(
        tabBar: tabBar,
        tabBuilder: (BuildContext context, int index) {
          return const Placeholder();
        },
      ),
    ));
    expect(tester.getSize(find.byType(CupertinoTabBar)).height, 90.0);
  });

  testWidgets('Opaque background does not add blur effects', (WidgetTester tester) async {
    await pumpWidgetWithBoilerplate(tester, MediaQuery(
      data: const MediaQueryData(),
      child: CupertinoTabBar(
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

    await pumpWidgetWithBoilerplate(tester, MediaQuery(
      data: const MediaQueryData(),
      child: CupertinoTabBar(
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

      await pumpWidgetWithBoilerplate(tester, MediaQuery(
        data: const MediaQueryData(),
        child: CupertinoTabBar(
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
    final SemanticsTester semantics = SemanticsTester(tester);

    await pumpWidgetWithBoilerplate(tester, MediaQuery(
      data: const MediaQueryData(),
      child: CupertinoTabBar(
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

  testWidgets('Title of items should be nullable', (WidgetTester tester) async {
    const TestImageProvider iconProvider = TestImageProvider(16, 16);
    final List<int> itemsTapped = <int>[];

    await pumpWidgetWithBoilerplate(
        tester,
        MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoTabBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: ImageIcon(
                  TestImageProvider(24, 24),
                ),
                title: Text('Tab 1'),
              ),
              BottomNavigationBarItem(
                icon: ImageIcon(
                  iconProvider,
                ),
              ),
            ],
            onTap: (int index) => itemsTapped.add(index),
          ),
        ));

    expect(find.text('Tab 1'), findsOneWidget);

    final Finder finder = find.byWidgetPredicate(
        (Widget widget) => widget is Image && widget.image == iconProvider);

    await tester.tap(finder);
    expect(itemsTapped, <int>[1]);
  });

  testWidgets('Hide border hides the top border of the tabBar',
      (WidgetTester tester) async {
    await pumpWidgetWithBoilerplate(
        tester,
        MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoTabBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: ImageIcon(
                  TestImageProvider(24, 24),
                ),
                title: Text('Tab 1'),
              ),
              BottomNavigationBarItem(
                icon: ImageIcon(
                  TestImageProvider(24, 24),
                ),
                title: Text('Tab 2'),
              ),
            ],
          ),
        ));

    final DecoratedBox decoratedBox = tester.widget(find.byType(DecoratedBox));
    final BoxDecoration boxDecoration = decoratedBox.decoration;
    expect(boxDecoration.border, isNotNull);

    await pumpWidgetWithBoilerplate(
        tester,
        MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoTabBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: ImageIcon(
                  TestImageProvider(24, 24),
                ),
                title: Text('Tab 1'),
              ),
              BottomNavigationBarItem(
                icon: ImageIcon(
                  TestImageProvider(24, 24),
                ),
                title: Text('Tab 2'),
              ),
            ],
            backgroundColor: const Color(0xFFFFFFFF), // Opaque white.
            border: null,
          ),
        ));

    final DecoratedBox decoratedBoxHiddenBorder =
        tester.widget(find.byType(DecoratedBox));
    final BoxDecoration boxDecorationHiddenBorder =
        decoratedBoxHiddenBorder.decoration;
    expect(boxDecorationHiddenBorder.border, isNull);
  });
}